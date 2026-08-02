from pydantic import BaseModel, Field


class HL7MessageRequest(BaseModel):
    message: str = Field(..., min_length=10, description="Raw HL7 v2 message text")


class HL7ParseResponse(BaseModel):
    success: bool
    message_type: str
    data: dict
    error: str | None = None
