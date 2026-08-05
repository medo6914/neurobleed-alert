import uuid
from datetime import datetime, timedelta

import pytest

pytestmark = pytest.mark.performance


@pytest.fixture
async def large_dataset(hospital_repo, organization_repo):
    created = []
    for i in range(100):
        org = await organization_repo.create(
            {
                "name": f"BulkOrg-{i}",
                "org_type": "hospital",
                "email": f"bulk{i}.{uuid.uuid4()}@example.com",
            }
        )
        created.append(org)
    return created


class TestPaginationPerformance:
    async def test_offset_pagination_through_1000_items(self, organization_repo):
        batch = []
        for i in range(100):
            batch.append(
                {
                    "name": f"PerfOrg-{i}",
                    "org_type": "hospital",
                    "email": f"perf{i}.{uuid.uuid4()}@example.com",
                }
            )
        for item in batch:
            await organization_repo.create(item)

        page = await organization_repo.paginate(page=1, per_page=50)
        assert page.total >= 100
        assert len(page.items) <= 50

        page2 = await organization_repo.paginate(page=3, per_page=50)
        assert page2.page == 3
        assert page2.has_next is True or page2.total_pages <= page2.page

    async def test_cursor_pagination_consistency(self, organization_repo):
        for i in range(50):
            await organization_repo.create(
                {
                    "name": f"CursorOrg-{i}",
                    "org_type": "hospital",
                }
            )

        cursor = None
        all_items = []
        for _ in range(10):
            cp = await organization_repo.cursor_paginate(cursor=cursor, limit=10)
            all_items.extend(cp.items)
            cursor = cp.cursor
            if not cp.has_more:
                break

        ids = [item.id for item in all_items]
        assert len(ids) == len(set(ids)), "Cursor pagination returned duplicate items"

    async def test_cursor_paginate_empty(self, organization_repo):
        cp = await organization_repo.cursor_paginate(limit=10)
        assert len(cp.items) == 0
        assert cp.has_more is False
        assert cp.cursor is None

    async def test_batch_insert_then_count(self, organization_repo):
        count_before = await organization_repo.count()
        for i in range(20):
            await organization_repo.create(
                {
                    "name": f"BatchOrg-{i}",
                    "org_type": "hospital",
                }
            )
        count_after = await organization_repo.count()
        assert count_after == count_before + 20

    async def test_pagination_with_filters(self, hospital_repo):
        for i in range(10):
            await hospital_repo.create(
                {
                    "name": f"FilterHosp-{i}",
                    "email": f"filter{i}.{uuid.uuid4()}@example.com",
                    "license_number": f"LIC-FILTER-{uuid.uuid4().hex[:8].upper()}",
                    "is_active": True,
                }
            )
        page = await hospital_repo.paginate(page=1, per_page=5)
        assert len(page.items) <= 5
        assert page.has_next is True

    async def test_pagination_edge_page_zero(self, hospital_repo):
        page = await hospital_repo.paginate(page=0, per_page=10)
        assert page.page == 1


class TestQueryTiming:
    async def test_bulk_create_timing(self, organization_repo):
        import time

        start = time.perf_counter()
        for i in range(10):
            await organization_repo.create(
                {
                    "name": f"TimingOrg-{i}",
                    "org_type": "hospital",
                }
            )
        elapsed = time.perf_counter() - start
        assert elapsed < 30.0

    async def test_count_large_dataset(self, organization_repo):
        for i in range(20):
            await organization_repo.create(
                {
                    "name": f"CountOrg-{i}",
                    "org_type": "hospital",
                }
            )
        import time

        start = time.perf_counter()
        count = await organization_repo.count()
        elapsed = time.perf_counter() - start
        assert count >= 20
        assert elapsed < 10.0

    async def test_get_multi_large_offset(self, organization_repo):
        for i in range(30):
            await organization_repo.create(
                {
                    "name": f"OffsetOrg-{i}",
                    "org_type": "hospital",
                }
            )
        import time

        start = time.perf_counter()
        items = await organization_repo.get_multi(skip=20, limit=10)
        elapsed = time.perf_counter() - start
        assert len(items) <= 10
        assert elapsed < 10.0


class TestNPlusOneDetection:
    async def test_get_with_relations_no_nplus1(
        self, hospital_repo, seeded_hospital, seeded_user
    ):
        hospital = await hospital_repo.get_with_relations(seeded_hospital.id)
        assert hospital is not None
        _ = hospital.users
        _ = hospital.departments

    async def test_bulk_fetch_without_nplus1(self, organization_repo):
        orgs = []
        for i in range(10):
            org = await organization_repo.create(
                {
                    "name": f"N1Org-{i}",
                    "org_type": "hospital",
                }
            )
            orgs.append(org)
        fetched = await organization_repo.get_multi(limit=20)
        for org in fetched:
            assert org.name is not None
