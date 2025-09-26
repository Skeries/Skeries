mcp-mock
=======

A minimal mock MCP server for local development using FastAPI (OpenAPI/Swagger available).

Endpoints:
- GET / -> JSON status and version
- GET /health -> health check
- POST /echo -> echoes JSON body

Run locally with Docker Compose:

```bash
docker compose up --build -d
# Open interactive docs at http://localhost:8080/docs
curl http://localhost:8080/ | jq
```
