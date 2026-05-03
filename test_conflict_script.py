from app.services import detect_conflict


def main() -> None:
    workout = {
        "name": "Morning Run",
        "start_time": "2026-05-01T09:00:00+00:00",
        "end_time": "2026-05-01T10:00:00+00:00",
    }

    calendar_events = [
        {
            "title": "Team Meeting",
            "status": "Busy",
            "start_time": "2026-05-01T09:30:00+00:00",
            "end_time": "2026-05-01T10:30:00+00:00",
        }
    ]

    has_conflict = detect_conflict(workout, calendar_events)
    print(f"Conflict detected: {has_conflict}")
    assert has_conflict is True, "Expected overlap with busy meeting."


if __name__ == "__main__":
    main()
