from __future__ import annotations

from datetime import datetime, timedelta, timezone
import json
from typing import Any
from urllib import error, parse, request

from app.core.config import settings


class GoogleCalendarService:
    OAUTH_BASE_URL = "https://accounts.google.com/o/oauth2/v2/auth"
    OAUTH_TOKEN_URL = "https://oauth2.googleapis.com/token"
    FREEBUSY_URL = "https://www.googleapis.com/calendar/v3/freeBusy"

    @staticmethod
    def build_oauth_url(state: str, redirect_uri: str = None, scopes: str = None) -> str:
        if not settings.google_client_id:
            raise ValueError("GOOGLE_CLIENT_ID is not configured.")

        query = parse.urlencode(
            {
                "client_id": settings.google_client_id,
                "redirect_uri": redirect_uri or settings.google_oauth_redirect_uri,
                "response_type": "code",
                "scope": scopes or settings.google_oauth_scope,
                "access_type": "offline",
                "include_granted_scopes": "true",
                "prompt": "consent",
                "state": state,
            }
        )
        return f"{GoogleCalendarService.OAUTH_BASE_URL}?{query}"

    @staticmethod
    def exchange_code_for_token(code: str, redirect_uri: str = None) -> dict[str, Any]:
        if not settings.google_client_id or not settings.google_client_secret:
            raise ValueError("Google OAuth client credentials are not configured.")

        payload = parse.urlencode(
            {
                "code": code,
                "client_id": settings.google_client_id,
                "client_secret": settings.google_client_secret,
                "redirect_uri": redirect_uri or settings.google_oauth_redirect_uri,
                "grant_type": "authorization_code",
            }
        ).encode("utf-8")

        req = request.Request(
            url=GoogleCalendarService.OAUTH_TOKEN_URL,
            data=payload,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            method="POST",
        )

        try:
            with request.urlopen(req, timeout=30) as response:
                body = response.read().decode("utf-8")
        except error.HTTPError as exc:
            details = exc.read().decode("utf-8", errors="ignore")
            raise RuntimeError(f"Google token exchange failed ({exc.code}): {details}") from exc
        except error.URLError as exc:
            raise RuntimeError(f"Google token exchange connection error: {exc.reason}") from exc

        parsed = json.loads(body)
        if "access_token" not in parsed:
            raise ValueError("No access_token found in Google token response.")
        return parsed

    @staticmethod
    def fetch_next_7_days_busy_blocks(access_token: str) -> list[dict[str, str]]:
        time_min = datetime.now(timezone.utc)
        time_max = time_min + timedelta(days=7)
        return GoogleCalendarService.fetch_busy_blocks_between(
            access_token=access_token,
            time_min=time_min,
            time_max=time_max,
        )

    @staticmethod
    def fetch_busy_blocks_between(
        access_token: str, time_min: datetime, time_max: datetime
    ) -> list[dict[str, str]]:
        if not access_token:
            raise ValueError("access_token is required.")

        payload = {
            "timeMin": time_min.isoformat(),
            "timeMax": time_max.isoformat(),
            "items": [{"id": "primary"}],
        }

        req = request.Request(
            url=GoogleCalendarService.FREEBUSY_URL,
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {access_token}",
            },
            method="POST",
        )

        try:
            with request.urlopen(req, timeout=30) as response:
                body = response.read().decode("utf-8")
        except error.HTTPError as exc:
            details = exc.read().decode("utf-8", errors="ignore")
            raise RuntimeError(f"Google freebusy request failed ({exc.code}): {details}") from exc
        except error.URLError as exc:
            raise RuntimeError(f"Google freebusy connection error: {exc.reason}") from exc

        parsed = json.loads(body)
        calendars = parsed.get("calendars", {})
        primary = calendars.get("primary", {})
        busy_periods = primary.get("busy", [])

        return [
            {"status": "Busy", "start_time": period["start"], "end_time": period["end"]}
            for period in busy_periods
            if "start" in period and "end" in period
        ]
