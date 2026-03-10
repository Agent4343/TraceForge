"""TOTP-based multi-factor authentication service."""

import base64
import io

import pyotp
import qrcode

from app.core.config import settings


def generate_mfa_secret() -> str:
    """Generate a new TOTP secret key."""
    return pyotp.random_base32()


def get_totp(secret: str) -> pyotp.TOTP:
    """Create a TOTP instance for the given secret."""
    return pyotp.TOTP(secret)


def verify_totp_code(secret: str, code: str) -> bool:
    """Verify a TOTP code against a secret. Allows 1-step window for clock drift."""
    totp = get_totp(secret)
    return totp.verify(code, valid_window=1)


def generate_provisioning_uri(secret: str, email: str) -> str:
    """Generate the otpauth:// URI for QR code scanning."""
    totp = get_totp(secret)
    return totp.provisioning_uri(name=email, issuer_name=settings.mfa_issuer_name)


def generate_qr_code_base64(secret: str, email: str) -> str:
    """Generate a QR code image as a base64-encoded PNG string."""
    uri = generate_provisioning_uri(secret, email)
    img = qrcode.make(uri)
    buffer = io.BytesIO()
    img.save(buffer, format="PNG")
    buffer.seek(0)
    return base64.b64encode(buffer.read()).decode("utf-8")
