from fastapi import FastAPI
from pydantic import BaseModel
import os

app = FastAPI(title="mcp-mock", version=os.environ.get('MCP_VERSION', '0.1.0'))

class EchoPayload(BaseModel):
    message: dict | list | str | int | float | None = None

@app.get("/")
async def index():
    return {
        "service": "mcp-mock",
        "version": app.version,
        "status": "running"
    }

@app.get('/health')
async def health():
    return {"status": "ok"}

@app.post('/echo')
async def echo(payload: dict):
    return {"received": payload}

# FastAPI automatically provides OpenAPI at /openapi.json and Swagger UI at /docs
