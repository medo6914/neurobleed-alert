from __future__ import annotations

import base64
import json
from typing import Any, Sequence

from sqlalchemy import Select, asc, desc, func, or_
from sqlalchemy.orm import DeclarativeBase

from app.schemas.pagination import (
    CursorPaginationParams,
    CursorPaginatedResponse,
    PaginatedResponse,
    PaginationParams,
)


def apply_sorting(
    query: Select,
    model: type[DeclarativeBase],
    sort_by: str | None = None,
    sort_order: str = "desc",
) -> Select:
    if not sort_by:
        return query
    if not hasattr(model, sort_by):
        return query
    column = getattr(model, sort_by)
    order_fn = desc if sort_order == "desc" else asc
    return query.order_by(order_fn(column))


def apply_filters(
    query: Select,
    model: type[DeclarativeBase],
    filters: dict[str, Any] | None = None,
) -> Select:
    if not filters:
        return query
    for field, value in filters.items():
        if not hasattr(model, field):
            continue
        column = getattr(model, field)
        if value is None:
            query = query.where(column.is_(None))
        elif isinstance(value, list):
            query = query.where(column.in_(value))
        elif isinstance(value, dict):
            for op, val in value.items():
                if op == "gt":
                    query = query.where(column > val)
                elif op == "gte":
                    query = query.where(column >= val)
                elif op == "lt":
                    query = query.where(column < val)
                elif op == "lte":
                    query = query.where(column <= val)
                elif op == "ne":
                    query = query.where(column != val)
                elif op == "like":
                    query = query.where(column.ilike(f"%{val}%"))
        else:
            query = query.where(column == value)
    return query


def apply_search(
    query: Select,
    model: type[DeclarativeBase],
    search_term: str | None = None,
    search_fields: Sequence[str] | None = None,
) -> Select:
    if not search_term or not search_fields:
        return query
    conditions = []
    for field in search_fields:
        if hasattr(model, field):
            column = getattr(model, field)
            conditions.append(column.ilike(f"%{search_term}%"))
    if conditions:
        query = query.where(or_(*conditions))
    return query


def apply_pagination(
    query: Select,
    model: type[DeclarativeBase],
    params: PaginationParams,
    filters: dict[str, Any] | None = None,
    search_term: str | None = None,
    search_fields: Sequence[str] | None = None,
) -> tuple[Select, Select]:
    query = apply_filters(query, model, filters)
    query = apply_search(query, model, search_term, search_fields)
    query = apply_sorting(query, model, params.sort_by, params.sort_order)

    count_query = select_count(query)
    page_query = query.offset((params.page - 1) * params.per_page).limit(
        params.per_page
    )
    return page_query, count_query


def apply_cursor_pagination(
    query: Select,
    model: type[DeclarativeBase],
    params: CursorPaginationParams,
    filters: dict[str, Any] | None = None,
    search_term: str | None = None,
    search_fields: Sequence[str] | None = None,
    cursor_column: str | None = None,
) -> tuple[Select, Select]:
    query = apply_filters(query, model, filters)
    query = apply_search(query, model, search_term, search_fields)
    query = apply_sorting(query, model, params.sort_by, params.sort_order)

    count_query = select_count(query)

    pk_name = cursor_column or _get_pk_name(model)
    if params.cursor:
        try:
            cursor_data = json.loads(base64.b64decode(params.cursor).decode())
            cursor_val = cursor_data.get("id")
            pk_col = getattr(model, pk_name)
            query = query.where(pk_col > cursor_val)
        except (json.JSONDecodeError, ValueError, KeyError):
            pass

    page_query = query.limit(params.limit + 1)
    return page_query, count_query


def build_paginated_response(
    items: list,
    total: int,
    params: PaginationParams,
) -> PaginatedResponse:
    return PaginatedResponse.create(
        items=items,
        total=total,
        page=params.page,
        per_page=params.per_page,
    )


def build_cursor_paginated_response(
    items: list,
    total: int,
    limit: int,
) -> tuple[CursorPaginatedResponse, list]:
    has_more = len(items) > limit
    if has_more:
        items = items[:limit]
    next_cursor = None
    if has_more and items:
        last_id = getattr(items[-1], _get_pk_name(type(items[0])), None)
        if last_id:
            next_cursor = base64.b64encode(
                json.dumps({"id": str(last_id)}).encode()
            ).decode()
    return CursorPaginatedResponse.create(
        items=items,
        total=total,
        cursor=next_cursor,
        has_more=has_more,
    ), items


def _get_pk_name(model: type[DeclarativeBase]) -> str:
    mapper = model.__mapper__
    return mapper.primary_key[0].name


def select_count(query: Select) -> Select:
    return query.with_only_columns(func.count(), maintain_column_order=False).order_by(
        None
    )
