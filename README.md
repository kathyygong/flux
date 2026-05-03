# Flux: The Anti-Fragile Training Engine

Flux is an AI-native "Adherence Partner" for runners. While traditional training apps provide rigid schedules that break under real-world pressure, Flux treats schedule shifts, physical fatigue, and travel as data points to be negotiated. The goal is to maximize long-term consistency by ensuring a "Plan A" failure always leads to a viable "Plan B."

---

## 🌟 Vision & Strategy

Flux eliminates "Plan Guilt" by transforming life interference into a logical adjustment. It synthesizes calendar events, biometric recovery data, and environmental context to proactively negotiate plan updates with the user.

### Key Features:
- **Triple-Lookahead Intelligence**: 
  - **Macro (Months)**: Identifies major life events (e.g., weddings, trips) and shifts key workouts.
  - **Meso (Weeks)**: Swaps workout days based on weekly calendar density.
  - **Micro (24 Hours)**: Detects poor recovery or emergency conflicts and proposes immediate pivots.
- **Biometric Throttling**: Adjusts intensity by ±5-15% if Sleep or HRV drops below rolling baselines.
- **Jet Lag Protocol**: Automatically converts quality runs to effort-based "Zone 2" runs during the first 48 hours after a >3hr timezone shift.
- **The "1-Tap Handshake"**: Flux never changes a plan silently. Every adjustment is presented as a push notification with a clear rationale.
- **Resiliency Streaks**: Gamifies flexibility. Streaks remain active as long as the user completes the proposed pivot, rewarding adherence rather than perfection.

---

## 🛠 Technology Stack

### Backend
- **Framework**: FastAPI (Python) for asynchronous performance.
- **Database**: PostgreSQL with SQLAlchemy ORM.
- **Task Queue**: Celery with Redis for background lookahead processing.
- **Intelligence**: LLM Reasoning Agent for generating natural language rationale and adaptive sessions.

### Frontend
- **Web Dashboard**: Clean, modern interface for plan management and historical analysis.
- **iOS App**: Native SwiftUI app with deep Apple Health (HealthKit) integration for real-time biometric syncing (HRV, RHR, Sleep).

---

## 📂 Project Structure

```text
├── app/                  # Backend FastAPI application
│   ├── api/              # Endpoints (v1)
│   ├── core/             # Database config and security
│   ├── models/           # SQLAlchemy models (User, Activity, Plan, etc.)
│   ├── services/         # Business logic (Coaching Engine, Reasoning, etc.)
│   └── static/           # Web Dashboard frontend (HTML/CSS/JS)
├── ios/                  # Native SwiftUI iOS Application
├── docker-compose.yml    # Full stack orchestration (API, Postgres, Redis, Workers)
├── Dockerfile            # API container specification
├── prd.txt               # Product Requirements Document
└── requirements.txt      # Python dependencies
```

---

## 🚀 Getting Started

### 1. Prerequisites
- Docker and Docker Compose
- Xcode (for iOS development)
- Python 3.12+ (for local backend development)

### 2. Backend Setup
Clone the repository and start the stack:
```bash
cp .env.example .env
docker compose up --build
```
The API will be available at `http://localhost:8000`. You can explore the interactive docs at `/docs`.

### 3. iOS Setup
1. Navigate to the `ios/` directory.
2. Open `Flux.xcodeproj` in Xcode.
3. Ensure the `baseURL` in `APIClient.swift` points to your running backend.
4. Build and run on a simulator or real device (HealthKit requires a physical device for full data).

---

## 📈 Roadmap

- [x] **Phase 1**: Core API, Dashboard, and iOS scaffolding.
- [ ] **Phase 2**: Deep Apple Health integration and LLM-driven "Proposal Engine."
- [ ] **Phase 3**: Jet Lag logic and Internal Gamification (Resiliency Streaks).

---

## 🛡 Privacy & Ethics
- **Privacy First**: All gamification and progress metrics are strictly private.
- **Human-in-the-loop**: All plan modifications require user approval via the "Handshake" UI.
- **Data Integrity**: Read-only calendar access; no storage of private meeting details.

---

*Flux — Training that bends so you don't break.*
