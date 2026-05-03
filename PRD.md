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

### 4.2 Biometric Recovery Feedback (HealthKit)
* **Requirement:** Integrate with Apple Health to pull Sleep, HRV, and Resting Heart Rate data.
* **Outcome:** If biometrics signal poor recovery (e.g., HRV 20% below baseline), the AI "throttles" the scheduled high-intensity workout to a recovery run.

### 4.3 Agentic Plan Generation (Antigravity)
* **Requirement:** Utilize Antigravity to orchestrate the "Reasoning Loop."
* **Logic:** Input (Calendar Conflict) → Analyze (Training Goal) → Evaluate (Biometrics) → Output (New Workout Suggestion).

## 5. Non-Functional Requirements
* **Safety & Integrity (LLM-as-a-Judge):** All AI-generated workouts must pass a "safety check" model to ensure mileage increases do not exceed 10% week-over-week.
* **Latency:** Plan rescheduling should occur in < 5 seconds to ensure a seamless mobile experience.

## 6. Success Metrics (KPIs)
* **Primary Metric (Adherence):** % of users who complete 90% of their "Adaptive Plan" compared to a 60% industry average for static plans.
* **Secondary Metric (Retention):** Month 3 retention rate (target > 40%).
* **North Star Metric:** "Consistent Weeks"—weeks where a user completes at least 3 runs, regardless of intensity.

## 7. Future Roadmap
* **V2:** Community "Challenges" that adapt to the group's collective fatigue levels.
* **V3:** Integration with nutrition APIs to suggest fueling strategies based on predicted workout intensity.
