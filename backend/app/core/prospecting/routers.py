import json
import logging
import time
from typing import Any, List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.utils.db import get_db, settings

from .actions import area_dashboard, area_knowledge_level, area_knowledge_taxa_list, epoc
from .schemas import (
    AreaDashboardSchema,
    AreaDashboardTimeDistribSchema,
    AreaKnowledgeLevelFeatureSchema,
    AreaKnowledgeLevelGeoJson,
    AreaKnowledgeLevelPropertiesSchema,
    AreaKnowledgeTaxaListSchema,
    EpocFeaturePropertiesSchema,
    EpocFeatureSchema,
    EpocSchema,
)

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get(
    "/area/knowledge_level/{type_code}",
    response_model=AreaKnowledgeLevelGeoJson,
    tags=["prospecting"],
    summary="Areas list with general statistics per zone within a bounding box",
    description="""# Area list

This return a list of areas filtered by type (`type_code`)
and within a geographic bounding box (`envelope`) with general stats:
* All period:
  * Count taxa in previous atlas as `old_count` ;
  * Count taxa in this atlas as `new_count` ;
  * Percent knowlegde calculated by Count taa in previous `(count_new/count_old)`.
* wintering, same as all period ;
* Breeding, same as all period.

    """,
)
def area_list_knowledge_level(
    db: Session = Depends(get_db),
    type_code: str = "M10",
    limit: Optional[int] = None,
    envelope: Optional[str] = None,
) -> Any:
    start_time = time.time()
    logger.debug(f"step1: {start_time}")
    if envelope:
        envelope = [float(c) for c in envelope.split(",")]
    logger.debug(f"step2: {(time.time() - start_time) * 1000}")
    areas = area_knowledge_level.get_feature_list(
        db=db, type_code=type_code, limit=limit, envelope=envelope
    )
    features = []
    if len(areas) == 0:
        HTTPException(status_code=404, detail="Data not found")
    logger.debug(f"step3: {(time.time() - start_time) * 1000}")
    for a in areas:
        f = AreaKnowledgeLevelFeatureSchema(
            properties=(AreaKnowledgeLevelPropertiesSchema(**a.properties)),
            geometry=json.loads(a.geometry),
            id=a.id,
        )
        features.append(f)
    logger.debug(f"step4: {(time.time() - start_time) * 1000}")
    return AreaKnowledgeLevelGeoJson(features=features)


@router.get(
    "/area/taxa_list/{id_area}",
    response_model=List[AreaKnowledgeTaxaListSchema],
    tags=["prospecting"],
    summary="List of species by area with qualitative data",
)
def area_taxa_list(
    id_area: int, db: Session = Depends(get_db), limit: Optional[int] = None
) -> Any:
    taxa_list = area_knowledge_taxa_list.get_area_taxa_list(db=db, id_area=id_area)
    logger.debug(taxa_list)
    if len(taxa_list) == 0:
        raise HTTPException(status_code=404, detail="Data not found")
    return taxa_list


@router.get(
    "/area/general_stats/{id_area}",
    response_model=AreaDashboardSchema,
    tags=["prospecting"],
    summary="General stats by area",
)
def area_general_stats(id_area: int, db: Session = Depends(get_db)) -> Any:
    q = area_dashboard.get_area_stats(db=db, id_area=id_area)
    logger.debug(f"<area_general_stats> query {q}")
    if not q:
        raise HTTPException(status_code=404, detail="Data not found")
    return q


@router.get(
    "/area/time_distrib/{id_area}/{time_unit}",
    response_model=List[AreaDashboardTimeDistribSchema],
    tags=["prospecting"],
    summary="General stats by area",
    description="""# Data distribution in time

Count data by time unit during atlas period

**Time unit** must be a [PostgreSQL date field identifier](https://www.postgresql.org/docs/10/functions-datetime.html#FUNCTIONS-DATETIME-EXTRACT). *e.g.* :
  * `month`
  * `year`
  * `week`
  * `quarter`
  * *etc*.
""",
)
def area_contrib_time_distrib(
    id_area: int,
    db: Session = Depends(get_db),
    time_unit: str = "month",
) -> Any:
    q = area_dashboard.get_time_distribution(db=db, id_area=id_area, time_unit=time_unit)
    logger.debug(f"<area_contrib_time_distrib> query {q}")
    if not q:
        raise HTTPException(status_code=404, detail="Data not found")
    return q


@router.get(
    "/epoc",
    response_model=EpocSchema,
    tags=["prospecting"],
    summary="EPOC protocol geolocation",
    description="""# EPOC protocol geolocation

Official EPOC points, with status ("Officiel" vs "Réserve")
    """,
)
def epoc_list(
    db: Session = Depends(get_db),
    envelope: Optional[str] = None,
) -> Any:
    start_time = time.time()
    if envelope:
        envelope = [float(c) for c in envelope.split(",")]
    epocs = epoc.get_epocs(db=db, envelope=envelope)
    features = []
    if len(epocs) == 0:
        HTTPException(status_code=404, detail="Data not found")
    logger.debug(f"step3: {(time.time() - start_time) * 1000}")
    for e in epocs:
        de = e._asdict()
        geojson = de.pop("geometry", None)
        f = EpocFeatureSchema(
            properties=(EpocFeaturePropertiesSchema(**de)),
            geometry=geojson,
            id=e.id_epoc,
        )
        features.append(f)
    logger.debug(f"step4: {(time.time() - start_time) * 1000}")
    return EpocSchema(features=features)
