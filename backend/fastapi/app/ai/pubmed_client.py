import json
import os
import time
from datetime import datetime, timedelta

from Bio import Entrez

Entrez.email = os.getenv("PUBMED_EMAIL", "ai@neurobleed.local")
Entrez.api_key = os.getenv("PUBMED_API_KEY", "")


class PubMedClient:
    CACHE_DIR = "data/pubmed_cache"

    def __init__(self, cache_ttl_hours: int = 24):
        self.cache_ttl = timedelta(hours=cache_ttl_hours)
        self._ensure_cache_dir()

    def _ensure_cache_dir(self):
        os.makedirs(self.CACHE_DIR, exist_ok=True)

    def _cache_path(self, key: str) -> str:
        safe = key.replace(" ", "_").replace("/", "_")[:200]
        return os.path.join(self.CACHE_DIR, f"{safe}.json")

    def _read_cache(self, key: str) -> list[dict] | None:
        path = self._cache_path(key)
        if not os.path.exists(path):
            return None
        try:
            with open(path) as f:
                data = json.load(f)
            cached_time = datetime.fromisoformat(data.get("_cached_at", "2000-01-01"))
            if datetime.now() - cached_time > self.cache_ttl:
                return None
            return data.get("results", [])
        except Exception:
            return None

    def _write_cache(self, key: str, results: list[dict]):
        path = self._cache_path(key)
        try:
            with open(path, "w") as f:
                json.dump(
                    {
                        "_cached_at": datetime.now().isoformat(),
                        "results": results,
                    },
                    f,
                )
        except Exception:
            pass

    def search(self, query: str, max_results: int = 20) -> list[dict]:
        cache_key = f"search_{query}_{max_results}"
        cached = self._read_cache(cache_key)
        if cached is not None:
            return cached

        try:
            handle = Entrez.esearch(
                db="pubmed",
                term=query,
                retmax=max_results,
                sort="relevance",
            )
            record = Entrez.read(handle)
            handle.close()

            id_list = record.get("IdList", [])
            count = int(record.get("Count", 0))

            if not id_list:
                return []

            results = self._fetch_details(id_list)
            self._write_cache(cache_key, results)
            return results

        except Exception:
            return []

    def _fetch_details(self, id_list: list[str]) -> list[dict]:
        cache_key = f"details_{'_'.join(id_list)}"
        cached = self._read_cache(cache_key)
        if cached is not None:
            return cached

        try:
            handle = Entrez.efetch(
                db="pubmed",
                id=",".join(id_list),
                rettype="xml",
                retmode="xml",
            )
            records = Entrez.read(handle)
            handle.close()

            results = []
            articles = records.get("PubmedArticle", [])

            for article in articles:
                try:
                    medline = article["MedlineCitation"]
                    article_data = medline["Article"]
                    result = {
                        "pubmed_id": str(medline["PMID"]),
                        "title": str(article_data.get("ArticleTitle", "")),
                        "abstract": str(
                            article_data.get("Abstract", {}).get("AbstractText", [""])[
                                0
                            ]
                        )
                        if isinstance(
                            article_data.get("Abstract", {}).get("AbstractText", [""]),
                            list,
                        )
                        else str(
                            article_data.get("Abstract", {}).get("AbstractText", "")
                        ),
                        "authors": [],
                        "journal": str(
                            article_data.get("Journal", {}).get("Title", "")
                        ),
                        "pub_date": "",
                        "source": "PubMed",
                    }

                    author_list = article_data.get("AuthorList", [])
                    if author_list:
                        result["authors"] = [
                            f"{a.get('LastName', '')} {a.get('Initials', '')}".strip()
                            for a in author_list
                            if isinstance(a, dict)
                        ][:5]

                    result["pub_date"] = str(
                        article_data.get("ArticleDate", [{}])[0]
                        if isinstance(article_data.get("ArticleDate", []), list)
                        and article_data.get("ArticleDate")
                        else article_data.get("Journal", {})
                        .get("JournalIssue", {})
                        .get("PubDate", {})
                    )

                    results.append(result)
                except Exception:
                    continue

            self._write_cache(cache_key, results)
            return results

        except Exception:
            return []

    def search_and_format(self, query: str, max_results: int = 10) -> list[dict]:
        articles = self.search(query, max_results)
        formatted = []
        for art in articles:
            formatted.append(
                {
                    "id": art.get("pubmed_id"),
                    "title": art.get("title", ""),
                    "content": art.get("abstract", ""),
                    "source": f"PubMed/{art.get('journal', '')}",
                    "category": "pubmed",
                    "tags": [
                        "pubmed",
                        art.get("journal", "").lower().replace(" ", "_"),
                    ],
                    "authors": art.get("authors", []),
                    "pub_date": art.get("pub_date", ""),
                }
            )
        return formatted
