from fastapi import FastAPI
from pydantic import BaseModel
from typing import Any, Union
import os

version = os.environ.get('MCP_VERSION', '0.1.0')
app = FastAPI(title="mcp-mock", version=version)

class EchoPayload(BaseModel):
    message: Union[dict, list, str, int, float, None] = None

@app.get("/", summary="Service info")
async def index():
    """Show basic service info."""
    return {
        "service": "mcp-mock",
        "version": version,
        "status": "running"
    }

@app.get('/health', summary="Health check")
async def health():
    """Health check endpoint."""
    return {"status": "ok"}

@app.post('/echo', summary="Echo input payload")
async def echo(payload: EchoPayload):
    """Echo back the received message."""
    return {"received": payload.message}