import logging

from pydantic_settings import BaseSettings

logger = logging.getLogger("formflow")


class Settings(BaseSettings):
    app_name: str = "FormFlow API"
    debug: bool = False

    # Database
    database_url: str = "postgresql+asyncpg://formflow:formflow@localhost:5432/formflow"

    # JWT
    secret_key: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 30

    # APNs
    apns_key_id: str = ""
    apns_team_id: str = ""
    apns_bundle_id: str = "com.formflow.app"
    apns_key_path: str = ""
    apns_use_sandbox: bool = True

    # S3 / storage
    s3_bucket: str = "formflow-pdfs"
    s3_region: str = "us-east-1"

    # Redis (for Celery)
    redis_url: str = "redis://localhost:6379/0"

    # Email (SES)
    ses_region: str = "us-east-1"
    ses_sender_email: str = "noreply@formflow.io"
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""

    # MFA
    mfa_issuer_name: str = "FormFlow"

    # PDF templates
    pdf_templates_dir: str = "app/templates"

    # Base URL for links in emails
    base_url: str = "https://app.formflow.io"

    # CORS — comma-separated allowed origins (use * only in development)
    cors_origins: str = "https://app.formflow.io"

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}

    def validate_production_config(self) -> list[str]:
        """Return a list of warnings about insecure configuration."""
        warnings: list[str] = []
        if self.secret_key == "change-me-in-production":
            warnings.append("SECRET_KEY is using the default value — set a unique secret for production")
        if self.cors_origins == "*":
            warnings.append("CORS_ORIGINS is set to '*' — restrict to specific domains in production")
        if not self.debug and not self.smtp_host and not self.ses_sender_email:
            warnings.append("No email transport configured — invite and reset emails will not be sent")
        return warnings


settings = Settings()

# Log configuration warnings at import time
for warning in settings.validate_production_config():
    logger.warning("CONFIG: %s", warning)
