"""S3 storage service for PDFs and signature images."""

import io
import logging
from uuid import UUID

import boto3
from botocore.exceptions import ClientError

from app.core.config import settings

logger = logging.getLogger(__name__)


def _get_s3_client():
    return boto3.client("s3", region_name=settings.s3_region)


def upload_pdf(workflow_id: UUID, pdf_bytes: bytes) -> str | None:
    """Upload a PDF to S3 and return the public URL."""
    key = f"workflows/{workflow_id}/report.pdf"
    try:
        client = _get_s3_client()
        client.put_object(
            Bucket=settings.s3_bucket,
            Key=key,
            Body=pdf_bytes,
            ContentType="application/pdf",
            ContentDisposition=f'attachment; filename="workflow-{workflow_id}.pdf"',
        )
        url = f"https://{settings.s3_bucket}.s3.{settings.s3_region}.amazonaws.com/{key}"
        return url
    except ClientError:
        logger.exception("Failed to upload PDF for workflow %s", workflow_id)
        return None


def upload_signature_image(workflow_id: UUID, step_number: int, signer_id: UUID, image_data: bytes) -> str | None:
    """Upload a signature image to S3 and return the URL."""
    key = f"workflows/{workflow_id}/signatures/step{step_number}_{signer_id}.png"
    try:
        client = _get_s3_client()
        client.put_object(
            Bucket=settings.s3_bucket,
            Key=key,
            Body=image_data,
            ContentType="image/png",
        )
        url = f"https://{settings.s3_bucket}.s3.{settings.s3_region}.amazonaws.com/{key}"
        return url
    except ClientError:
        logger.exception("Failed to upload signature for workflow %s step %d", workflow_id, step_number)
        return None


def generate_presigned_url(key: str, expires_in: int = 3600) -> str | None:
    """Generate a pre-signed URL for accessing an S3 object."""
    try:
        client = _get_s3_client()
        url = client.generate_presigned_url(
            "get_object",
            Params={"Bucket": settings.s3_bucket, "Key": key},
            ExpiresIn=expires_in,
        )
        return url
    except ClientError:
        logger.exception("Failed to generate presigned URL for %s", key)
        return None
