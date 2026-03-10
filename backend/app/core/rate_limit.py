"""Simple in-memory rate limiter for auth endpoints.

For production, replace with Redis-backed limiter (e.g., slowapi with Redis).
"""

import time
from collections import defaultdict

from fastapi import HTTPException, Request, status


class RateLimiter:
    """Token-bucket rate limiter keyed by IP address."""

    def __init__(self, requests_per_minute: int = 10):
        self.rpm = requests_per_minute
        self._buckets: dict[str, list[float]] = defaultdict(list)

    def _cleanup(self, key: str, now: float) -> None:
        window_start = now - 60.0
        self._buckets[key] = [t for t in self._buckets[key] if t > window_start]

    def check(self, request: Request) -> None:
        """Raise 429 if rate limit exceeded for this IP."""
        client_ip = request.client.host if request.client else "unknown"
        now = time.monotonic()

        self._cleanup(client_ip, now)

        if len(self._buckets[client_ip]) >= self.rpm:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many requests. Please try again later.",
            )

        self._buckets[client_ip].append(now)


# Shared instance — 10 login attempts per minute per IP
auth_rate_limiter = RateLimiter(requests_per_minute=10)
