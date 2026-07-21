from __future__ import annotations

from typing import Generic, Literal, TypeVar

from pydantic import BaseModel, Field

T = TypeVar("T")
DataT = TypeVar("DataT")


class PaginationParams(BaseModel):
    page: int = Field(default=1, ge=1, description="Page number (1-indexed)")
    per_page: int = Field(default=50, ge=1, le=1000, description="Items per page")
    sort_by: str | None = Field(default=None, description="Column to sort by")
    sort_order: Literal["asc", "desc"] = Field(default="desc", description="Sort direction")


class CursorPaginationParams(BaseModel):
    cursor: str | None = Field(default=None, description="Base64-encoded cursor for pagination")
    limit: int = Field(default=50, ge=1, le=1000, description="Items per page")
    sort_by: str | None = Field(default=None, description="Column to sort by")
    sort_order: Literal["asc", "desc"] = Field(default="desc", description="Sort direction")


class PaginatedResponse(BaseModel, Generic[T]):
    items: list[T]
    total: int
    page: int
    per_page: int
    total_pages: int
    has_next: bool
    has_prev: bool
    next_page: int | None = None
    prev_page: int | None = None

    @classmethod
    def create(
        cls,
        items: list[T],
        total: int,
        page: int,
        per_page: int,
    ) -> PaginatedResponse[T]:
        total_pages = max(1, (total + per_page - 1) // per_page)
        return cls(
            items=items,
            total=total,
            page=page,
            per_page=per_page,
            total_pages=total_pages,
            has_next=page < total_pages,
            has_prev=page > 1,
            next_page=page + 1 if page < total_pages else None,
            prev_page=page - 1 if page > 1 else None,
        )


class CursorPaginatedResponse(BaseModel, Generic[T]):
    items: list[T]
    cursor: str | None = None
    has_more: bool
    total: int

    @classmethod
    def create(
        cls,
        items: list[T],
        total: int,
        cursor: str | None = None,
        has_more: bool = False,
    ) -> CursorPaginatedResponse[T]:
        return cls(
            items=items,
            cursor=cursor,
            has_more=has_more,
            total=total,
        )


def pagination_links(
    base_url: str,
    page: int,
    per_page: int,
    total_pages: int,
    sort_by: str | None = None,
    sort_order: str | None = None,
) -> dict[str, str | None]:
    def _build(p: int) -> str:
        params = f"page={p}&per_page={per_page}"
        if sort_by:
            params += f"&sort_by={sort_by}"
        if sort_order:
            params += f"&sort_order={sort_order}"
        return f"{base_url}?{params}"

    return {
        "first": _build(1),
        "last": _build(total_pages),
        "next": _build(page + 1) if page < total_pages else None,
        "prev": _build(page - 1) if page > 1 else None,
    }


def cursor_pagination_links(
    base_url: str,
    cursor: str | None,
    limit: int,
    sort_by: str | None = None,
    sort_order: str | None = None,
) -> dict[str, str | None]:
    def _build(c: str | None) -> str:
        params = f"limit={limit}"
        if c:
            params += f"&cursor={c}"
        if sort_by:
            params += f"&sort_by={sort_by}"
        if sort_order:
            params += f"&sort_order={sort_order}"
        return f"{base_url}?{params}"

    return {
        "next": _build(cursor) if cursor else None,
    }
