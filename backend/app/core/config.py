from pydantic_settings import BaseSettings


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

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


settings = Settings()
