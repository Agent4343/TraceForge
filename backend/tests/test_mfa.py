"""Tests for MFA service."""

import pytest

from app.services.mfa import generate_mfa_secret, get_totp, verify_totp_code


def test_generate_secret():
    secret = generate_mfa_secret()
    assert len(secret) == 32  # pyotp default base32 length


def test_verify_valid_code():
    secret = generate_mfa_secret()
    totp = get_totp(secret)
    code = totp.now()
    assert verify_totp_code(secret, code) is True


def test_verify_invalid_code():
    secret = generate_mfa_secret()
    assert verify_totp_code(secret, "000000") is False


def test_verify_wrong_length():
    secret = generate_mfa_secret()
    assert verify_totp_code(secret, "12345") is False
