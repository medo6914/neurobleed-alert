import os
import time
from pathlib import Path

import yaml

from app.ai.schemas import MedicalRuleResult


class MedicalRulesEngine:
    RULES_DIR = Path(__file__).parent / "rules"

    def __init__(self, rules_file: str = "clinical_rules.yaml"):
        self.rules = self._load_rules(rules_file)

    def _load_rules(self, rules_file: str) -> list[dict]:
        path = self.RULES_DIR / rules_file
        if not path.exists():
            return []
        with open(path) as f:
            data = yaml.safe_load(f)
        return sorted(
            data.get("rules", []), key=lambda r: r.get("priority", 0), reverse=True
        )

    def evaluate(self, vitals: dict) -> list[MedicalRuleResult]:
        results = []
        for rule in self.rules:
            condition = rule["condition"]
            triggered = self._evaluate_condition(condition, vitals)
            if triggered:
                results.append(
                    MedicalRuleResult(
                        rule_name=rule["name"],
                        triggered=True,
                        priority=rule.get("priority", 500),
                        action=rule.get("action"),
                        severity=rule.get("severity", "info"),
                    )
                )
        return results

    def _evaluate_condition(self, condition: str, vitals: dict) -> bool:
        condition = condition.strip()

        if " AND " in condition:
            parts = [p.strip() for p in condition.split(" AND ")]
            return all(self._evaluate_simple_condition(p, vitals) for p in parts)

        if " OR " in condition:
            parts = [p.strip() for p in condition.split(" OR ")]
            return any(self._evaluate_simple_condition(p, vitals) for p in parts)

        return self._evaluate_simple_condition(condition, vitals)

    def _evaluate_simple_condition(self, condition: str, vitals: dict) -> bool:
        condition = condition.strip()

        if " BETWEEN " in condition:
            import re

            m = re.match(
                r"(\w+)\s+BETWEEN\s+(\d+(?:\.\d+)?)\s+AND\s+(\d+(?:\.\d+)?)", condition
            )
            if m:
                key, lo, hi = m.group(1), float(m.group(2)), float(m.group(3))
                val = vitals.get(key)
                return val is not None and lo <= val <= hi

        for op in [">=", "<=", ">", "<", "==", "!="]:
            if op in condition:
                parts = condition.split(op)
                if len(parts) == 2:
                    key = parts[0].strip()
                    val = vitals.get(key)
                    if val is None:
                        return False
                    target = float(parts[1].strip())
                    if op == ">=":
                        return val >= target
                    if op == "<=":
                        return val <= target
                    if op == ">":
                        return val > target
                    if op == "<":
                        return val < target
                    if op == "==":
                        return val == target
                    if op == "!=":
                        return val != target

        if " IN " in condition:
            parts = condition.split(" IN ")
            key = parts[0].strip()
            val = vitals.get(key)
            if val is None:
                return False
            targets = parts[1].strip().strip("()").split(",")
            targets = [t.strip().strip("'\"") for t in targets]
            return str(val) in targets

        return False

    def get_highest_priority_rule(self, vitals: dict) -> MedicalRuleResult | None:
        for rule in self.rules:
            if self._evaluate_condition(rule["condition"], vitals):
                return MedicalRuleResult(
                    rule_name=rule["name"],
                    triggered=True,
                    priority=rule.get("priority", 500),
                    action=rule.get("action"),
                    severity=rule.get("severity", "info"),
                )
        return None

    def override_risk_if_needed(
        self, vitals: dict, risk_score: float, risk_level: str
    ) -> tuple[float, str, list[str]]:
        triggered_rules = self.evaluate(vitals)
        rules_triggered = [r.rule_name for r in triggered_rules]

        for rule in triggered_rules:
            if rule.priority >= 950 and rule.severity == "critical":
                return 1.0, "critical", rules_triggered
            if rule.priority >= 900 and rule.severity in ("critical", "high"):
                current_score = max(risk_score, 0.85)
                current_level = "critical" if current_score >= 0.8 else "high"
                return current_score, current_level, rules_triggered
            if rule.priority >= 800:
                current_score = max(risk_score, 0.7)
                current_level = "high"
                return current_score, current_level, rules_triggered

        return risk_score, risk_level, rules_triggered
