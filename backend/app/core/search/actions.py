#!/usr/bin/python
"""Search actions module"""

import logging
from typing import List, Optional

# from sqlalchemy_utils.functions import json_sql
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.actions.crud import BaseReadOnlyActions

from .models import MvSearchAreas, MvSearchTaxa

logger = logging.getLogger(__name__)


class MvSearchAreasActions(BaseReadOnlyActions[MvSearchAreas]):
    """Post actions with basic CRUD operations"""

    def get_search_list(
        self, db: Session, limit: int, search: str = None, type_code: str = None
    ) -> List:
        search = search.lower()
        search_string = f"%{search}%"
        q = db.query(
            self.model.id,
            self.model.type_name,
            self.model.type_code,
            self.model.name,
            self.model.code,
            self.model.html_repr,
            self.model.bounds,
        )
        if search is not None:
            q = q.filter(self.model.search_string.like(func.unaccent(search_string)))
        if type_code is not None:
            q = q.filter(self.model.type_code == type_code)
        return q.limit(limit).all()


class MvSearchTaxaActions(BaseReadOnlyActions[MvSearchTaxa]):
    """Post actions with basic CRUD operations"""

    def get_search_list(self, db: Session, limit: int, search: str = None) -> List:
        search = search.lower()
        search_string = f"%{search}%"
        q = db.query(
            self.model.code,
            self.model.name,
            self.model.html_repr,
        )
        if search is not None:
            q = q.filter(self.model.search_string.like(func.unaccent(search_string)))
        return q.limit(limit).all()


mv_search_areas = MvSearchAreasActions(MvSearchAreas)
mv_search_taxa = MvSearchTaxaActions(MvSearchTaxa)
