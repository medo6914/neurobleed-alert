import json
import os
import pickle

import faiss
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer


class RAGEngine:
    def __init__(
        self,
        index_path: str = "data/faiss_index",
        vectorizer_path: str = "data/vectorizer.pkl",
    ):
        self.index_path = index_path
        self.vectorizer_path = vectorizer_path
        self.index: faiss.IndexFlatL2 | None = None
        self.vectorizer: TfidfVectorizer | None = None
        self.documents: list[dict] = []
        self.doc_ids: list[str] = []
        self.dimension: int = 256
        self._loaded = False

    def _ensure_dir(self):
        os.makedirs(os.path.dirname(self.index_path) or ".", exist_ok=True)

    def build_index(self, documents: list[dict]):
        texts = [
            d.get("content", "") + " " + (d.get("title", "") or "") for d in documents
        ]
        self.documents = documents
        self.doc_ids = [str(d.get("id", i)) for i, d in enumerate(documents)]

        if not texts:
            self.vectorizer = TfidfVectorizer(max_features=self.dimension)
            self.vectorizer.fit(["placeholder text"])
            self.index = faiss.IndexFlatL2(self.dimension)
            self._loaded = True
            return

        self.vectorizer = TfidfVectorizer(
            max_features=self.dimension, stop_words="english"
        )
        embeddings = self.vectorizer.fit_transform(texts).toarray().astype(np.float32)

        actual_dim = embeddings.shape[1]
        if actual_dim < self.dimension:
            padded = np.zeros((embeddings.shape[0], self.dimension), dtype=np.float32)
            padded[:, :actual_dim] = embeddings
            embeddings = padded

        self.index = faiss.IndexFlatL2(self.dimension)
        self.index.add(embeddings)
        self._loaded = True

        self._persist()

    def add_documents(self, documents: list[dict]):
        if not self._loaded:
            self.build_index(documents)
            return

        texts = [
            d.get("content", "") + " " + (d.get("title", "") or "") for d in documents
        ]
        start_idx = len(self.documents)
        for i, d in enumerate(documents):
            self.documents.append(d)
            self.doc_ids.append(str(d.get("id", start_idx + i)))

        embeddings = self.vectorizer.transform(texts).toarray().astype(np.float32)
        actual_dim = embeddings.shape[1]
        if actual_dim < self.dimension:
            padded = np.zeros((embeddings.shape[0], self.dimension), dtype=np.float32)
            padded[:, :actual_dim] = embeddings
            embeddings = padded

        self.index.add(embeddings)
        self._persist()

    def similarity_search(self, query: str, k: int = 10) -> list[dict]:
        if not self._loaded or self.index is None or self.vectorizer is None:
            return []

        query_vec = self.vectorizer.transform([query]).toarray().astype(np.float32)
        actual_dim = query_vec.shape[1]
        if actual_dim < self.dimension:
            padded = np.zeros((1, self.dimension), dtype=np.float32)
            padded[:, :actual_dim] = query_vec
            query_vec = padded

        distances, indices = self.index.search(query_vec, min(k, len(self.documents)))

        results = []
        for idx, dist in zip(indices[0], distances[0]):
            if idx < len(self.documents):
                doc = dict(self.documents[idx])
                doc["score"] = float(1.0 / (1.0 + dist))
                doc["distance"] = float(dist)
                results.append(doc)

        return results

    def _persist(self):
        self._ensure_dir()
        if self.index is not None:
            faiss.write_index(self.index, self.index_path)
        if self.vectorizer is not None:
            with open(self.vectorizer_path, "wb") as f:
                pickle.dump(self.vectorizer, f)
        meta = {
            "documents": self.documents,
            "doc_ids": self.doc_ids,
            "dimension": self.dimension,
        }
        with open(self.index_path + ".meta.json", "w") as f:
            json.dump(meta, f)

    def load_index(self) -> bool:
        try:
            if os.path.exists(self.index_path):
                self.index = faiss.read_index(self.index_path)
            if os.path.exists(self.vectorizer_path):
                with open(self.vectorizer_path, "rb") as f:
                    self.vectorizer = pickle.load(f)
            meta_path = self.index_path + ".meta.json"
            if os.path.exists(meta_path):
                with open(meta_path) as f:
                    meta = json.load(f)
                self.documents = meta.get("documents", [])
                self.doc_ids = meta.get("doc_ids", [])
                self.dimension = meta.get("dimension", self.dimension)
            self._loaded = self.index is not None
            return self._loaded
        except Exception:
            return False

    def get_stats(self) -> dict:
        return {
            "loaded": self._loaded,
            "document_count": len(self.documents),
            "index_dimension": self.dimension,
            "index_path": self.index_path,
        }
