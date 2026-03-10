"""Email service for transactional emails (invites, password resets)."""

import logging
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from app.core.config import settings

logger = logging.getLogger(__name__)


def _send_smtp(to_email: str, subject: str, html_body: str) -> bool:
    """Send an email via SMTP. Returns True on success."""
    if not settings.smtp_host:
        logger.info("SMTP not configured — email skipped: %s -> %s", subject, to_email)
        return False

    msg = MIMEMultipart("alternative")
    msg["From"] = settings.ses_sender_email
    msg["To"] = to_email
    msg["Subject"] = subject
    msg.attach(MIMEText(html_body, "html"))

    try:
        with smtplib.SMTP(settings.smtp_host, settings.smtp_port) as server:
            server.ehlo()
            server.starttls()
            server.ehlo()
            server.login(settings.smtp_user, settings.smtp_password)
            server.sendmail(settings.ses_sender_email, to_email, msg.as_string())
        return True
    except Exception:
        logger.exception("Failed to send email to %s", to_email)
        return False


def _send_ses(to_email: str, subject: str, html_body: str) -> bool:
    """Send an email via AWS SES. Returns True on success."""
    try:
        import boto3

        client = boto3.client("ses", region_name=settings.ses_region)
        client.send_email(
            Source=settings.ses_sender_email,
            Destination={"ToAddresses": [to_email]},
            Message={
                "Subject": {"Data": subject, "Charset": "UTF-8"},
                "Body": {"Html": {"Data": html_body, "Charset": "UTF-8"}},
            },
        )
        return True
    except Exception:
        logger.exception("Failed to send SES email to %s", to_email)
        return False


def send_email(to_email: str, subject: str, html_body: str) -> bool:
    """Send an email using the configured transport (SMTP or SES)."""
    if settings.smtp_host:
        return _send_smtp(to_email, subject, html_body)
    return _send_ses(to_email, subject, html_body)


def send_invite_email(to_email: str, inviter_name: str, org_name: str, temp_password: str) -> bool:
    """Send a user invitation email with temporary credentials."""
    subject = f"You've been invited to {org_name} on FormFlow"
    html = f"""
    <html>
    <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #1a1a1a;">Welcome to FormFlow</h2>
        <p>{inviter_name} has invited you to join <strong>{org_name}</strong> on FormFlow.</p>
        <p>Use the following credentials to log in:</p>
        <div style="background: #f5f5f5; padding: 16px; border-radius: 8px; margin: 16px 0;">
            <p style="margin: 4px 0;"><strong>Email:</strong> {to_email}</p>
            <p style="margin: 4px 0;"><strong>Temporary Password:</strong> {temp_password}</p>
        </div>
        <p>You'll be prompted to change your password on first login.</p>
        <a href="{settings.base_url}/login" style="display: inline-block; background: #0066FF; color: white; padding: 12px 24px; border-radius: 8px; text-decoration: none; margin-top: 12px;">Log In Now</a>
        <p style="color: #888; font-size: 12px; margin-top: 24px;">If you didn't expect this invitation, you can safely ignore this email.</p>
    </body>
    </html>
    """
    return send_email(to_email, subject, html)


def send_password_reset_email(to_email: str, reset_token: str) -> bool:
    """Send a password reset email with a reset link."""
    reset_url = f"{settings.base_url}/reset-password?token={reset_token}"
    subject = "Reset your FormFlow password"
    html = f"""
    <html>
    <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #1a1a1a;">Password Reset</h2>
        <p>We received a request to reset your FormFlow password.</p>
        <a href="{reset_url}" style="display: inline-block; background: #0066FF; color: white; padding: 12px 24px; border-radius: 8px; text-decoration: none; margin: 16px 0;">Reset Password</a>
        <p>This link expires in 1 hour.</p>
        <p style="color: #888; font-size: 12px; margin-top: 24px;">If you didn't request a password reset, you can safely ignore this email.</p>
    </body>
    </html>
    """
    return send_email(to_email, subject, html)
