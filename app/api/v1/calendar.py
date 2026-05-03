from pydantic import BaseModel, Field
from fastapi import APIRouter, HTTPException, Query

from app.services.google_calendar_service import GoogleCalendarService

router = APIRouter(prefix="/calendar/google", tags=["calendar"])


class BusyBlocksRequest(BaseModel):
    access_token: str = Field(min_length=1)


@router.get("/oauth/start")
def google_oauth_start(state: str = Query(default="flux-dev")) -> dict[str, str]:
    try:
        oauth_url = GoogleCalendarService.build_oauth_url(state=state)
    except ValueError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    return {"authorization_url": oauth_url}


@router.get("/callback")
def google_oauth_callback(code: str, state: str | None = None) -> dict:
    try:
        token_response = GoogleCalendarService.exchange_code_for_token(code=code)
    except (ValueError, RuntimeError) as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return {
        "state": state,
        "token": token_response,
    }


@router.post("/busy-blocks")
def get_busy_blocks(payload: BusyBlocksRequest) -> dict[str, list[dict[str, str]]]:
    try:
        busy_blocks = GoogleCalendarService.fetch_next_7_days_busy_blocks(
            access_token=payload.access_token
        )
    except (ValueError, RuntimeError) as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    return {"busy_blocks": busy_blocks}
