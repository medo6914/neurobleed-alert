from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql+asyncpg://neurobleed:neurobleed_dev@localhost:5432/neurobleed"
    REDIS_URL: str = "redis://localhost:6379/0"
    SECRET_KEY: str = ""
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    ENVIRONMENT: str = "development"
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    FIREBASE_CREDENTIALS_PATH: str | None = None
    FIREBASE_API_KEY: str | None = None
    FIREBASE_PROJECT_ID: str | None = None

    TWILIO_ACCOUNT_SID: str | None = None
    TWILIO_AUTH_TOKEN: str | None = None
    TWILIO_PHONE_NUMBER: str | None = None

    GOOGLE_CLIENT_ID: str | None = None
    GOOGLE_CLIENT_SECRET: str | None = None

    SMTP_HOST: str | None = None
    SMTP_PORT: int = 587
    SMTP_USER: str | None = None
    SMTP_PASSWORD: str | None = None
    SMTP_FROM_EMAIL: str = "noreply@neurobleed.com"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
