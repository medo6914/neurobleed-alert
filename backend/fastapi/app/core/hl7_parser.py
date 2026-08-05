import logging
import re
from datetime import datetime

logger = logging.getLogger(__name__)


class HL7Message:
    def __init__(self, raw_message: str):
        self.raw = raw_message
        self.segments: list[HL7Segment] = []
        self._parse(raw_message)

    def _parse(self, raw: str):
        for line in raw.strip().split("\r"):
            line = line.strip()
            if not line:
                continue
            self.segments.append(HL7Segment(line))

    def get_segments(self, segment_id: str) -> list["HL7Segment"]:
        return [s for s in self.segments if s.segment_id == segment_id]

    def get_segment(self, segment_id: str) -> "HL7Segment | None":
        segments = self.get_segments(segment_id)
        return segments[0] if segments else None

    def to_dict(self) -> dict:
        return {
            "segments": [s.to_dict() for s in self.segments],
            "patient_data": self._extract_patient_data(),
            "observation_data": self._extract_observation_data(),
        }

    def _extract_patient_data(self) -> dict:
        pid = self.get_segment("PID")
        if not pid:
            return {}

        data = {}
        patient_name = pid.get_field(5)
        if patient_name:
            parts = patient_name.split("^")
            data["last_name"] = parts[0] if len(parts) > 0 else ""
            data["first_name"] = parts[1] if len(parts) > 1 else ""
            data["middle_name"] = parts[2] if len(parts) > 2 else ""

        dob = pid.get_field(7)
        if dob:
            data["date_of_birth"] = self._parse_hl7_date(dob)

        gender = pid.get_field(8)
        if gender:
            data["gender"] = (
                "male"
                if gender.upper() == "M"
                else "female"
                if gender.upper() == "F"
                else "other"
            )

        mrn = pid.get_field(3)
        if mrn:
            data["mrn"] = mrn.split("^")[0] if "^" in mrn else mrn

        phone = pid.get_field(13)
        if phone:
            data["phone"] = phone.split("^")[0] if "^" in phone else phone

        address = pid.get_field(11)
        if address:
            parts = address.split("^")
            data["address"] = parts[0] if len(parts) > 0 else ""
            data["city"] = parts[2] if len(parts) > 2 else ""

        return data

    def _extract_observation_data(self) -> list[dict]:
        observations = []
        for obx in self.get_segments("OBX"):
            obs = {}
            obs["set_id"] = obx.get_field(1)
            obs["value_type"] = obx.get_field(2)
            obs["identifier"] = obx.get_field(3)
            obs["value"] = obx.get_field(5)
            obs["unit"] = obx.get_field(6)
            obs["reference_range"] = obx.get_field(7)
            obs["abnormal_flags"] = obx.get_field(8)
            obs["status"] = obx.get_field(11)
            obs["date_time"] = obx.get_field(14)

            identifier = obx.get_field(3) or ""
            if "^" in identifier:
                parts = identifier.split("^")
                obs["code"] = parts[0] if len(parts) > 0 else ""
                obs["display_name"] = parts[1] if len(parts) > 1 else ""
            else:
                obs["code"] = identifier

            observations.append(obs)
        return observations

    @staticmethod
    def _parse_hl7_date(date_str: str) -> str:
        try:
            date_str = date_str.split("+")[0].split("-")[0]
            formats = ["%Y%m%d", "%Y%m%d%H%M", "%Y%m%d%H%M%S"]
            for fmt in formats:
                try:
                    return datetime.strptime(
                        date_str[
                            : len(
                                fmt.replace("%Y", "2025")
                                .replace("%m", "01")
                                .replace("%d", "01")
                                .replace("%H", "00")
                                .replace("%M", "00")
                                .replace("%S", "00")
                            )
                        ],
                        fmt,
                    ).strftime("%Y-%m-%d")
                except ValueError:
                    continue
        except Exception:
            pass
        return date_str


class HL7Segment:
    def __init__(self, raw: str):
        self.raw = raw
        self.segment_id = raw[:3] if len(raw) >= 3 else raw
        self.fields: list[str] = raw.split("|") if "|" in raw else [raw]

    def get_field(self, index: int) -> str | None:
        if 0 <= index < len(self.fields):
            return self.fields[index]
        return None

    def to_dict(self) -> dict:
        return {
            "segment_id": self.segment_id,
            "fields": self.fields,
        }


class HL7Parser:
    MSH_SEGMENT = "MSH"
    PID_SEGMENT = "PID"
    OBX_SEGMENT = "OBX"
    OBR_SEGMENT = "OBR"

    @staticmethod
    def parse(raw_message: str) -> HL7Message:
        return HL7Message(raw_message)

    @staticmethod
    def extract_patient(hl7_msg: HL7Message) -> dict:
        return hl7_msg._extract_patient_data()

    @staticmethod
    def extract_observations(hl7_msg: HL7Message) -> list[dict]:
        return hl7_msg._extract_observation_data()

    @staticmethod
    def message_type(hl7_msg: HL7Message) -> str:
        msh = hl7_msg.get_segment("MSH")
        if msh:
            msg_type = msh.get_field(9)
            if msg_type:
                return msg_type.replace("^", "")
        return "UNKNOWN"


class HL7v2Parser:
    def __init__(self):
        self.hl7_parser = HL7Parser()

    def parse_patient_admit(self, raw_message: str) -> dict:
        msg = self.hl7_parser.parse(raw_message)
        msg_type = HL7Parser.message_type(msg)

        data = HL7Parser.extract_patient(msg)
        data["message_type"] = msg_type

        if msg_type.startswith("ADT"):
            if "^A01" in msg_type or "ADTA01" in msg_type:
                data["event"] = "admission"
            elif "^A03" in msg_type or "ADTA03" in msg_type:
                data["event"] = "discharge"
            elif "^A02" in msg_type or "ADTA02" in msg_type:
                data["event"] = "transfer"

        observations = HL7Parser.extract_observations(msg)
        if observations:
            data["observations"] = observations

        return data

    def parse_oru_message(self, raw_message: str) -> dict:
        msg = self.hl7_parser.parse(raw_message)
        data = HL7Parser.extract_patient(msg)
        data["message_type"] = HL7Parser.message_type(msg)
        data["observations"] = HL7Parser.extract_observations(msg)
        return data

    def to_fhir(self, raw_message: str) -> dict | None:
        msg = self.hl7_parser.parse(raw_message)
        msg_type = HL7Parser.message_type(msg)

        if msg_type.startswith("ADT"):
            patient_data = HL7Parser.extract_patient(msg)
            return {
                "resourceType": "Patient",
                "identifier": [
                    {"system": "urn:hl7:temp", "value": patient_data.get("mrn", "")}
                ],
                "name": [
                    {
                        "family": patient_data.get("last_name", ""),
                        "given": [patient_data.get("first_name", "")],
                    }
                ],
                "gender": patient_data.get("gender", "unknown"),
                "birthDate": patient_data.get("date_of_birth", ""),
                "telecom": [{"system": "phone", "value": patient_data.get("phone", "")}]
                if patient_data.get("phone")
                else [],
            }

        if msg_type.startswith("ORU"):
            observations = HL7Parser.extract_observations(msg)
            return {
                "resourceType": "Bundle",
                "type": "collection",
                "entry": [
                    {
                        "resource": {
                            "resourceType": "Observation",
                            "status": "final",
                            "code": {
                                "coding": [
                                    {
                                        "code": obs.get("code", ""),
                                        "display": obs.get("display_name", ""),
                                    }
                                ]
                            },
                            "valueString": obs.get("value", ""),
                            "referenceRange": [{"text": obs.get("reference_range", "")}]
                            if obs.get("reference_range")
                            else [],
                            "interpretation": [{"text": obs.get("abnormal_flags", "")}]
                            if obs.get("abnormal_flags")
                            else [],
                        }
                    }
                    for obs in observations
                ],
            }

        return None


hl7_v2_parser = HL7v2Parser()
