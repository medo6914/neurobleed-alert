import base64
import json
import time
import uuid
from datetime import datetime, timezone
from typing import Any, Generic, Sequence, TypeVar

from pydantic import BaseModel
from sqlalchemy import Select, UnaryExpression, asc, desc, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import Base
from app.schemas.pagination import (
    CursorPaginatedResponse,
    CursorPaginationParams,
    PaginatedResponse,
    PaginationParams,
)

logger = __import__("logging").getLogger(__name__)

ModelType = TypeVar("ModelType", bound=Base)


class Page(BaseModel):
    items: list
    total: int
    page: int
    per_page: int
    total_pages: int
    has_next: bool
    has_prev: bool


class CursorPage(BaseModel):
    items: list
    cursor: str | None
    has_more: bool
    total: int


class BaseRepository(Generic[ModelType]):
    def __init__(self, model: type[ModelType], db: AsyncSession) -> None:
        self.model = model
        self.db = db
        mapper = self.model.__mapper__
        self._pk_col = mapper.primary_key[0]
        self._has_soft_delete = "is_deleted" in [c.name for c in mapper.columns]
        self._query_timing_enabled = False

    def enable_query_timing(self):
        self._query_timing_enabled = True

    def disable_query_timing(self):
        self._query_timing_enabled = False

    async def _timed_execute(self, stmt: Select, label: str = "") -> Any:
        if not self._query_timing_enabled:
            return await self.db.execute(stmt)
        start = time.perf_counter()
        try:
            return await self.db.execute(stmt)
        finally:
            elapsed = (time.perf_counter() - start) * 1000
            if elapsed > 100:
                logger.warning("Slow query [%s]: %.2fms - %s", label, elapsed, stmt)

    def _apply_soft_delete_filter(self, stmt: Select) -> Select:
        if self._has_soft_delete:
            return stmt.where(self.model.is_deleted == False)  # noqa: E712
        return stmt

    def _apply_filters(self, stmt: Select, filters: list | None = None) -> Select:
        if filters:
            for f in filters:
                stmt = stmt.where(f)
        return stmt

    def _apply_sorts(self, stmt: Select, sorts: list | None = None) -> Select:
        if sorts:
            for s in sorts:
                stmt = stmt.order_by(s)
        return stmt

    def apply_filters(
        self,
        stmt: Select,
        filter_dict: dict[str, Any] | None = None,
    ) -> Select:
        if not filter_dict:
            return stmt
        for field, value in filter_dict.items():
            if not hasattr(self.model, field):
                continue
            column = getattr(self.model, field)
            if value is None:
                stmt = stmt.where(column.is_(None))
            elif isinstance(value, list):
                stmt = stmt.where(column.in_(value))
            elif isinstance(value, dict):
                for op, val in value.items():
                    if op == "gt":
                        stmt = stmt.where(column > val)
                    elif op == "gte":
                        stmt = stmt.where(column >= val)
                    elif op == "lt":
                        stmt = stmt.where(column < val)
                    elif op == "lte":
                        stmt = stmt.where(column <= val)
                    elif op == "ne":
                        stmt = stmt.where(column != val)
                    elif op == "like":
                        stmt = stmt.where(column.ilike(f"%{val}%"))
            else:
                stmt = stmt.where(column == value)
        return stmt

    def apply_sorting(
        self,
        stmt: Select,
        sort_by: str | None = None,
        sort_order: str = "desc",
    ) -> Select:
        if not sort_by or not hasattr(self.model, sort_by):
            return stmt
        column = getattr(self.model, sort_by)
        order_fn = desc if sort_order == "desc" else asc
        return stmt.order_by(order_fn(column))

    def search(
        self,
        stmt: Select,
        search_term: str | None = None,
        search_fields: Sequence[str] | None = None,
    ) -> Select:
        if not search_term or not search_fields:
            return stmt
        conditions = []
        for field in search_fields:
            if hasattr(self.model, field):
                column = getattr(self.model, field)
                conditions.append(column.ilike(f"%{search_term}%"))
        if conditions:
            stmt = stmt.where(or_(*conditions))
        return stmt

    async def get(self, id: uuid.UUID) -> ModelType | None:
        stmt = select(self.model).where(self._pk_col == id)
        stmt = self._apply_soft_delete_filter(stmt)
        result = await self._timed_execute(stmt, "get")
        return result.scalar_one_or_none()

    async def get_multi(self, skip: int = 0, limit: int = 100) -> list[ModelType]:
        stmt = select(self.model)
        stmt = self._apply_soft_delete_filter(stmt)
        stmt = stmt.offset(skip).limit(limit)
        result = await self._timed_execute(stmt, "get_multi")
        return list(result.scalars().all())

    async def create(self, obj_in: dict | BaseModel) -> ModelType:
        if isinstance(obj_in, BaseModel):
            obj_data = obj_in.model_dump(exclude_unset=True)
        else:
            obj_data = obj_in
        obj = self.model(**obj_data)
        self.db.add(obj)
        await self.db.commit()
        await self.db.refresh(obj)
        return obj

    async def update(self, id: uuid.UUID, obj_in: dict | BaseModel) -> ModelType | None:
        obj = await self.get(id)
        if not obj:
            return None
        if isinstance(obj_in, BaseModel):
            update_data = obj_in.model_dump(exclude_unset=True)
        else:
            update_data = obj_in
        for field, value in update_data.items():
            setattr(obj, field, value)
        await self.db.commit()
        await self.db.refresh(obj)
        return obj

    async def delete(self, id: uuid.UUID, soft: bool = True, deleted_by: uuid.UUID | None = None) -> bool:
        obj = await self.get(id)
        if not obj:
            return False
        if soft and self._has_soft_delete:
            obj.is_deleted = True
            obj.deleted_at = datetime.now(timezone.utc)
            if deleted_by is not None:
                obj.deleted_by_id = deleted_by
        else:
            await self.db.delete(obj)
        await self.db.commit()
        return True

    async def count(self, filters: list | None = None) -> int:
        stmt = select(func.count(self._pk_col)).select_from(self.model)
        stmt = self._apply_soft_delete_filter(stmt)
        stmt = self._apply_filters(stmt, filters)
        result = await self._timed_execute(stmt, "count")
        return result.scalar() or 0

    async def exists(self, id: uuid.UUID) -> bool:
        result = await self._timed_execute(
            select(select(self.model).where(self._pk_col == id).exists()),
            "exists",
        )
        return result.scalar() or False

    async def paginate(
        self,
        page: int = 1,
        per_page: int = 50,
        filters: list | None = None,
        sorts: list | None = None,
    ) -> Page:
        if page < 1:
            page = 1
        if per_page < 1:
            per_page = 50

        total = await self.count(filters=filters)
        total_pages = max(1, (total + per_page - 1) // per_page)

        stmt = select(self.model)
        stmt = self._apply_soft_delete_filter(stmt)
        stmt = self._apply_filters(stmt, filters)
        stmt = self._apply_sorts(stmt, sorts)
        stmt = stmt.offset((page - 1) * per_page).limit(per_page)

        result = await self._timed_execute(stmt, "paginate")
        items = list(result.scalars().all())

        return Page(
            items=items,
            total=total,
            page=page,
            per_page=per_page,
            total_pages=total_pages,
            has_next=page < total_pages,
            has_prev=page > 1,
        )

    async def paginate_with_params(
        self,
        params: PaginationParams,
        filter_dict: dict[str, Any] | None = None,
        search_term: str | None = None,
        search_fields: Sequence[str] | None = None,
    ) -> PaginatedResponse:
        stmt = select(self.model)
        stmt = self._apply_soft_delete_filter(stmt)
        stmt = self.apply_filters(stmt, filter_dict)
        stmt = self.search(stmt, search_term, search_fields)
        stmt = self.apply_sorting(stmt, params.sort_by, params.sort_order)

        count_stmt = select(func.count()).select_from(stmt.subquery())
        total_result = await self._timed_execute(count_stmt, "paginate_with_params.count")
        total = total_result.scalar() or 0

        stmt = stmt.offset((params.page - 1) * params.per_page).limit(params.per_page)
        result = await self._timed_execute(stmt, "paginate_with_params")
        items = list(result.scalars().all())

        return PaginatedResponse.create(
            items=items,
            total=total,
            page=params.page,
            per_page=params.per_page,
        )

    async def cursor_paginate(
        self,
        cursor: str | None = None,
        limit: int = 50,
        **filters: Any,
    ) -> CursorPage:
        stmt = select(self.model)
        stmt = self._apply_soft_delete_filter(stmt)

        for field, value in filters.items():
            if hasattr(self.model, field):
                stmt = stmt.where(getattr(self.model, field) == value)

        if cursor:
            try:
                cursor_data = json.loads(base64.b64decode(cursor).decode())
                cursor_id = uuid.UUID(cursor_data["id"])
                stmt = stmt.where(self._pk_col > cursor_id)
            except (json.JSONDecodeError, ValueError, KeyError):
                pass

        stmt = stmt.order_by(self._pk_col).limit(limit + 1)

        result = await self._timed_execute(stmt, "cursor_paginate")
        items = list(result.scalars().all())

        has_more = len(items) > limit
        if has_more:
            items = items[:limit]

        total = await self.count()

        next_cursor = None
        if has_more and items:
            last_id = getattr(items[-1], self._pk_col.name)
            next_cursor = base64.b64encode(
                json.dumps({"id": str(last_id)}).encode()
            ).decode()

        return CursorPage(items=items, cursor=next_cursor, has_more=has_more, total=total)

    async def cursor_paginate_with_params(
        self,
        params: CursorPaginationParams,
        filter_dict: dict[str, Any] | None = None,
        search_term: str | None = None,
        search_fields: Sequence[str] | None = None,
    ) -> CursorPaginatedResponse:
        stmt = select(self.model)
        stmt = self._apply_soft_delete_filter(stmt)
        stmt = self.apply_filters(stmt, filter_dict)
        stmt = self.search(stmt, search_term, search_fields)
        stmt = self.apply_sorting(stmt, params.sort_by, params.sort_order)

        if params.cursor:
            try:
                cursor_data = json.loads(base64.b64decode(params.cursor).decode())
                cursor_id = uuid.UUID(cursor_data["id"])
                stmt = stmt.where(self._pk_col > cursor_id)
            except (json.JSONDecodeError, ValueError, KeyError):
                pass

        stmt = stmt.limit(params.limit + 1)

        result = await self._timed_execute(stmt, "cursor_paginate_with_params")
        items = list(result.scalars().all())

        has_more = len(items) > params.limit
        if has_more:
            items = items[: params.limit]

        total = await self.count()

        next_cursor = None
        if has_more and items:
            last_id = getattr(items[-1], self._pk_col.name)
            next_cursor = base64.b64encode(
                json.dumps({"id": str(last_id)}).encode()
            ).decode()

        return CursorPaginatedResponse.create(
            items=items,
            total=total,
            cursor=next_cursor,
            has_more=has_more,
        )
