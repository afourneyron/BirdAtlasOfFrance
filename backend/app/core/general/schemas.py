#!/usr/bin/python

import logging
from typing import List, Optional, Union

from geojson_pydantic.features import Feature, FeatureCollection
from pydantic import BaseModel

logger = logging.getLogger(__name__)


class GeneralStatsCountTaxaSubSchema(BaseModel):
    """[summary]

    Args:
        BaseModel ([type]): [description]
    """

    all_period: int
    breeding: int
    wintering: int


class GeneralStatsProspectingHoursSubSchema(BaseModel):
    """[summary]

    Args:
        BaseModel ([type]): [description]
    """

    other_period: int
    breeding: int
    wintering: int


class GeneralStatsSchema(BaseModel):
    """[summary]

    Args:
        BaseModel ([type]): [description]
    """

    prospecting_hours: GeneralStatsProspectingHoursSubSchema
    count_taxa: GeneralStatsCountTaxaSubSchema

    class Config:
        orm_mode = True


class KnowledgeLevelGeneralStatsSchema(BaseModel):
    """[summary]

    Args:
        BaseModel ([type]): [description]
    """

    from0to25: int
    from25to50: int
    from50to75: int
    from75to100: int
    over100: int

    class Config:
        orm_mode = True
