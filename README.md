# Flux API Foundation

FastAPI + PostgreSQL + SQLAlchemy scaffold for Flux.

## Project structure

- `app/models` - SQLAlchemy models
- `app/api` - API routers and endpoints
- `app/services` - business logic and orchestration

## Local setup

1. Copy environment file:
   - `cp .env.example .env`
2. Start dependencies and API:
   - `docker compose up --build`
3. Open API docs:
   - `http://localhost:8000/docs`

## Seed test data

Create a training plan with:

```bash
curl -X POST http://localhost:8000/api/v1/training-plans \
  -H "Content-Type: application/json" \
  -d '{"name":"Half Marathon Build","goal_race":"Half Marathon","weeks":12,"description":"Base + threshold progression"}'
```
