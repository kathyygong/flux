from __future__ import annotations

from datetime import datetime
import json
from typing import Any
from urllib import error, request

def _to_datetime(value: Any) -> datetime | None:
    if isinstance(value, datetime):
        return value
    if isinstance(value, str):
        normalized = value.replace("Z", "+00:00")
        try:
            return datetime.fromisoformat(normalized)
        except ValueError:
            return None
    return None


def detect_conflict(workout: dict[str, Any], calendar_events: list[dict[str, Any]]) -> bool:
    workout_start = _to_datetime(workout.get("start_time"))
    workout_end = _to_datetime(workout.get("end_time"))
    if workout_start is None or workout_end is None or workout_start >= workout_end:
        return False

    for event in calendar_events:
        if str(event.get("status", "")).lower() != "busy":
            continue

        event_start = _to_datetime(event.get("start_time"))
        event_end = _to_datetime(event.get("end_time"))
        if event_start is None or event_end is None or event_start >= event_end:
            continue

        if workout_start < event_end and workout_end > event_start:
            return True

    return False


def _find_conflicting_busy_event(
    workout: dict[str, Any], calendar_events: list[dict[str, Any]]
) -> dict[str, Any] | None:
    workout_start = _to_datetime(workout.get("start_time"))
    workout_end = _to_datetime(workout.get("end_time"))
    if workout_start is None or workout_end is None or workout_start >= workout_end:
        return None

    for event in calendar_events:
        if str(event.get("status", "")).lower() != "busy":
            continue

        event_start = _to_datetime(event.get("start_time"))
        event_end = _to_datetime(event.get("end_time"))
        if event_start is None or event_end is None or event_start >= event_end:
            continue

        if workout_start < event_end and workout_end > event_start:
            return event

    return None


def _extract_json_object(text: str) -> dict[str, Any]:
    stripped = text.strip()
    if stripped.startswith("```"):
        lines = stripped.splitlines()
        if lines and lines[0].startswith("```"):
            lines = lines[1:]
        if lines and lines[-1].strip() == "```":
            lines = lines[:-1]
        stripped = "\n".join(lines).strip()
        if stripped.startswith("json"):
            stripped = stripped[4:].strip()

    try:
        parsed = json.loads(stripped)
    except json.JSONDecodeError as exc:
        raise ValueError("Gemini returned non-JSON output.") from exc

    if not isinstance(parsed, dict):
        raise ValueError("Gemini output must be a JSON object.")
    return parsed


def generate_proposal(
    workout: dict[str, Any],
    conflict_details: dict[str, Any],
    recovery_score: float | int,
) -> dict[str, Any]:
    from app.core.config import settings

    if not settings.gemini_api_key:
        raise ValueError("GEMINI_API_KEY is not configured.")

    prompt = (
        "Review this runner context and propose a safe workout adjustment.\n"
        "Return ONLY valid JSON with keys: new_parameters (object), short_rationale (string).\n"
        f"Workout: {json.dumps(workout, default=str)}\n"
        f"Conflict details: {json.dumps(conflict_details, default=str)}\n"
        f"Recovery score: {recovery_score}"
    )

    payload = {
        "systemInstruction": {
            "parts": [
                {
                    "text": (
                        "You are a world-class running coach. "
                        "You optimize training quality while minimizing injury risk and schedule conflicts."
                    )
                }
            ]
        },
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {"temperature": 0.3, "responseMimeType": "application/json"},
    }

    url = (
        f"https://generativelanguage.googleapis.com/v1beta/models/"
        f"{settings.gemini_model}:generateContent?key={settings.gemini_api_key}"
    )
    req = request.Request(
        url=url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        with request.urlopen(req, timeout=30) as response:
            body = response.read().decode("utf-8")
    except error.HTTPError as exc:
        details = exc.read().decode("utf-8", errors="ignore")
        raise RuntimeError(f"Gemini API HTTP error {exc.code}: {details}") from exc
    except error.URLError as exc:
        raise RuntimeError(f"Gemini API connection error: {exc.reason}") from exc

    response_payload = json.loads(body)
    candidates = response_payload.get("candidates", [])
    if not candidates:
        raise ValueError("Gemini API returned no candidates.")

    parts = candidates[0].get("content", {}).get("parts", [])
    text = ""
    for part in parts:
        if isinstance(part, dict) and "text" in part:
            text += str(part["text"])
    if not text.strip():
        raise ValueError("Gemini API returned an empty response.")

    proposal = _extract_json_object(text)
    if "new_parameters" not in proposal or "short_rationale" not in proposal:
        raise ValueError("Gemini response is missing required keys.")
    if not isinstance(proposal.get("new_parameters"), dict):
        raise ValueError("Gemini response key 'new_parameters' must be an object.")
    if not isinstance(proposal.get("short_rationale"), str):
        raise ValueError("Gemini response key 'short_rationale' must be a string.")

    return proposal


def resolve_workout_conflict_with_ai(
    workout: dict[str, Any],
    calendar_events: list[dict[str, Any]],
    recovery_score: float | int,
    biometric_throttle: dict[str, Any] | None = None,
    jet_lag_active: bool = False,
) -> dict[str, Any]:
    conflict_event = _find_conflicting_busy_event(workout, calendar_events)
    
    needs_adjustment = False
    conflict_details = {}
    
    if conflict_event is not None:
        needs_adjustment = True
        conflict_details["calendar_conflict"] = conflict_event
        
    if biometric_throttle and biometric_throttle.get("should_throttle"):
        needs_adjustment = True
        conflict_details["biometric_conflict"] = biometric_throttle.get("reason")
        
    if jet_lag_active:
        needs_adjustment = True
        conflict_details["jet_lag_protocol"] = "JET LAG ACTIVE: User changed timezones by >3 hours. You MUST convert this run into a 'Zone 2' effort-based run if it is a 'Quality' run (Intervals/Tempo) to mitigate cardiovascular stress."
        
    if not needs_adjustment:
        return {
            "has_conflict": False,
            "conflict_details": None,
            "proposal": None,
        }

    proposal = generate_proposal(
        workout=workout,
        conflict_details=conflict_details,
        recovery_score=recovery_score,
    )
    return {
        "has_conflict": True,
        "conflict_details": conflict_details,
        "proposal": proposal,
    }
