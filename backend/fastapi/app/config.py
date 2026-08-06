from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = (
        "postgresql+asyncpg://neurobleed:neurobleed_dev@localhost:5432/neurobleed"
    )
    REDIS_URL: str = "redis://localhost:6379/0"
    SECRET_KEY: str = ""
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    ENVIRONMENT: str = "development"
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    SUPER_ADMIN_EMAILS: str = "medomaree11@gmail.com"
    SUPER_ADMIN_PASSWORD: str = "medo2011"
    SEED_USER_EMAIL: str = "Ziad@gmail.com"
    SEED_USER_PASSWORD: str = "ziad1111"

    FIREBASE_CREDENTIALS_PATH: str | None = None
    FIREBASE_API_KEY: str | None = None
    FIREBASE_PROJECT_ID: str | None = None

    TWILIO_ACCOUNT_SID: str | None = None
    TWILIO_AUTH_TOKEN: str | None = None
    TWILIO_PHONE_NUMBER: str | None = None
    TWILIO_WHATSAPP_NUMBER: str | None = None

    VONAGE_API_KEY: str | None = None
    VONAGE_API_SECRET: str | None = None
    VONAGE_PHONE_NUMBER: str | None = None

    WHATSAPP_ACCESS_TOKEN: str | None = None
    WHATSAPP_PHONE_NUMBER_ID: str | None = None

    GOOGLE_CLIENT_ID: str | None = None
    GOOGLE_CLIENT_SECRET: str | None = None

    SMTP_HOST: str | None = None
    SMTP_PORT: int = 587
    SMTP_USER: str | None = None
    SMTP_PASSWORD: str | None = None
    SMTP_FROM_EMAIL: str = "noreply@neurobleed.com"
    EMAIL_PROVIDER: str = "smtp"

    RESEND_API_KEY: str | None = None
    SENDGRID_API_KEY: str | None = None
    SENDGRID_FROM_EMAIL: str | None = None

    OPENAI_API_KEY: str | None = None
    OPENAI_MODEL: str = "gpt-4o-mini"
    GEMINI_API_KEY: str | None = None
    GEMINI_MODEL: str = "gemini-2.0-flash"
    HUGGINGFACE_API_KEY: str | None = None
    HUGGINGFACE_MODEL: str = "mistralai/Mistral-7B-Instruct-v0.3"
    OLLAMA_BASE_URL: str = "http://localhost:11434"
    OLLAMA_MODEL: str = "llama3.2"
    LLM_PROVIDER: str = "ollama"

    STRIPE_SECRET_KEY: str | None = None
    STRIPE_WEBHOOK_SECRET: str | None = None
    PAYMOB_API_KEY: str | None = None
    PAYMOB_INTEGRATION_ID: str | None = None
    PAYPAL_CLIENT_ID: str | None = None
    PAYPAL_CLIENT_SECRET: str | None = None

    SENTRY_DSN: str | None = None

    CLOUDINARY_CLOUD_NAME: str | None = None
    CLOUDINARY_API_KEY: str | None = None
    CLOUDINARY_API_SECRET: str | None = None

    OPENWEATHER_API_KEY: str | None = None
    OPENWEATHER_UNITS: str = "metric"

    NOMINATIM_BASE_URL: str = "https://nominatim.openstreetmap.org"
    OSRM_BASE_URL: str = "https://router.project-osrm.org"
    OVERPASS_BASE_URL: str = "https://overpass-api.de/api/interpreter"
    OSM_TILE_URL: str = "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
    MAP_SEARCH_REGION: str = "Cairo, Egypt"

    REPORT_STORAGE_PATH: str = "./reports"
    REPORT_BASE_URL: str = "/reports"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
