 # Flux | AI-Driven Adaptive Training Engine

**Adaptive training plans for a dynamic life.** *Built with Next.js, Antigravity, and Cursor.*

[![Project Status: Active Development](https://img.shields.io/badge/Status-Active%20Development-green)](https://github.com/kathyygong/flux)
[**View the Full PRD**](./PRD.md)

## 🏃 The Problem
Most running apps provide static plans that exist in a vacuum. When life happens—a late-night meeting, poor sleep, or an unexpected trip—the plan breaks. Users are left to manually adjust their training or, more often, lose consistency and abandon the plan entirely.

**Flux** transforms the training plan into a living agent that responds to real-time constraints, ensuring training consistency even when schedules shift.

## ✨ Key Product Features
* **Adaptive Calendar Synchronization:** * **Strategic:** Pre-builds plans around known blockers (work cycles, travel).
    * **Reactive (24-Hour):** Adjusts or swaps workouts in real-time based on last-minute calendar conflicts.
* **Apple Health Integration:** Aggregates biometric data (HRV, Sleep, Resting HR) from wearable devices via HealthKit to "throttle" training intensity based on physiological recovery.
* **Intelligent Rescheduling:** If a workout is missed, Flux re-optimizes the remaining week to maintain the physiological objective of the training block rather than just "moving" the task.

## 🛠 The AI Stack & Strategy
As a Product Manager, I built Flux to explore **Agentic Orchestration** and **Automated Quality Benchmarking**.

* **Antigravity (Orchestration):** The "reasoning engine" that synthesizes multi-variable inputs (Calendar + Apple Health + Training History) into actionable plan shifts.
* **Cursor (AI-Assisted Dev):** Leveraged AI-native pair programming to accelerate the feedback loop from PRD to functional MVP.
* **LLM-as-a-Judge (Evaluation):** Implemented an automated evaluation framework to benchmark plan safety. Every generated workout is "judged" by a secondary model against sports science constraints (e.g., preventing excessive weekly mileage spikes) to ensure plan integrity.

## 📂 Project Documentation
* **[Product Requirements Document (PRD)](./PRD.md):** Strategy, User Personas, and Success Metrics.
* **[Architecture Overview](./Architecture.md):** Data flow between HealthKit, Antigravity, and Postgres.
