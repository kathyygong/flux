# Product Requirements Document: Project Flux

**Author:** Katherine Gong  
**Status:** In Development (Alpha)  
**Last Updated:** May 2026

## 1. Executive Summary
Flux is an AI-native training engine designed to solve the "consistency gap" in endurance sports. Unlike static training platforms, Flux utilizes real-time biometric and calendar data to dynamically adapt training schedules, ensuring users stay on track regardless of external life stressors.

## 2. Problem Statement
Existing training apps (Strava, Nike Run Club, Garmin Connect) create rigid plans that do not account for the volatility of a modern user's schedule. 
* **The Result:** Users miss workouts due to work/life conflicts, leading to "all-or-nothing" thinking and plan abandonment.
* **The Opportunity:** An agentic system that treats a training plan as a fluid optimization problem rather than a static list of tasks.

## 3. Target Audience
* **The "Busy Professional" Runner:** High-achievers who value fitness but have unpredictable schedules.
* **The "Data-Forward" Athlete:** Users with wearables (Oura, Garmin, Apple Watch) who want their data to actually *do* something rather than just provide a report.

## 4. Functional Requirements

### 4.1 Multi-Tier Calendar Integration
* **Requirement:** The system must sync with Google/Outlook calendars to identify "High-Intensity Work Blocks" or travel.
* **Outcome:** AI automatically suggests shorter/lower-intensity runs during busy periods to maintain consistency.

### 4.2 Biometric Intelligence & Environmental Adaptation
* **Requirement:** Integrate with Apple Health and wearable tech (Oura, Garmin, etc.) to pull Sleep, HRV, and Resting Heart Rate data.
* **Physiological Guardrails:** If biometrics signal poor recovery (e.g., HRV/sleep drops below rolling 3-month baseline), the AI "throttles" the scheduled session intensity by 5-15%.
* **Jet Lag Protocol:** Detects timezone shifts >3 hours. Converts "Quality" runs into effort-based "Zone 2" runs for the first 48 hours to mitigate cardiovascular stress.

### 4.3. Informed Proposal Model
Flux never changes a plan silently. To maintain user agency, Flux utilizes an "Informed Proposal" model rather than silent automation. Every adjustment is presented as a push notification.
* **Rationale-First Delivery:** Push notifications lead with the *reasoning* (e.g., "Noticing 5h sleep and a 9 AM meeting...") before showing the adjustment.
* **Actionable Handshake UI:** Users are presented with a clear choice: **[Accept Adjustment]** or **[Keep Original Plan]**. 

### 4.4 Internal Gamification 
* **Resiliency Streaks:** Streaks remain active as long as the user engages with the Handshake UI and completes a suggested pivot.
* **Achievement Badges:** Private milestones for navigating interference (e.g., "Jet Lag Juggernaut," "Adaptive Master").
* **Recovery Boosts:** Incentivizes rest by rewarding users for completing recommended recovery sessions during "High Strain" biometric events.

### 4.5 Agentic Plan Generation (Antigravity)
* **Requirement:** Utilize Antigravity to orchestrate the "Reasoning Loop."
* **Logic:** Input (Calendar Conflict) → Analyze (Training Goal) → Evaluate (Biometrics) → Output (New Workout Suggestion).

## 5. Non-Functional Requirements
* **Safety & Integrity (LLM-as-a-Judge):** All AI-generated workouts must pass a "safety check" model to ensure mileage increases do not exceed 10% week-over-week.
* **Latency:** Plan rescheduling should occur in < 5 seconds to ensure a seamless mobile experience.

## 6. Success Metrics (KPIs)
| Priority | Metric | Definition |
| :--- | :--- | :--- |
| **P0** | **Plan Completion Rate (PCR)** | % of total training plans successfully finished. |
| **P0** | **Resiliency Score** | Ratio of (Adjusted Runs + Original Runs) to (Skipped Runs). |
| **P1** | **Retention-After-Crisis** | User churn rate in the 14 days following a major calendar conflict/trip. |
| **P1** | **Proposal Acceptance Rate** | % of AI-generated suggestions accepted by the user via the Handshake UI. |

## 7. Roadmap

### V1: The Functional Foundation (MVP)
* Calendar/Health OAuth integrations.
* Calendar scheduler logic.
* Basic 1-tap Handshake UI.

### V2: Contextual Grounding & Personalization
* **Feature:** RAG-enhanced "Coach Memory."
* **Logic:** The AI synthesizes historical adherence data to learn user preferences (e.g., preferred time of day, surface preference, or response to specific workout types).
* **PM Goal:** Close the "Trust Gap" by ensuring adaptive suggestions align with personal habits, not just technical availability.

### V3: Gamification
* **Feature:** Resiliency gamification, including Resiliency Streaks, Adaptive Achievement Badges, and Recovery Smart Boosts.
* **Logic:** A centralized reward system that triggers progress milestones and streak maintenance whenever a user negotiates a pivot or adheres to biometric-triggered rest days.
* **PM Goal:** Minimize "all-or-nothing" abandonment by transitioning user identity from raw performance achievement to consistency.

### V4: Dynamic Fueling Integration
* **Feature:** Adaptive Nutrition Strategy.
* **Logic:** Integration with nutrition platforms to provide real-time fueling adjustments based on changes in the training plan.
* **PM Goal:** Expand the "Performance" value prop by ensuring the user is physically fueled for the workouts the AI suggests.
