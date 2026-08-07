import asyncio
import subprocess
import sys
import os

def run_cmd(cmd):
    result = subprocess.run(cmd)
    return result.returncode == 0

async def main():
    port = os.environ.get("PORT", "8000")

    run_cmd([sys.executable, "-m", "app.seed_data"])
    os.execvp(sys.executable, [
        sys.executable, "-m", "uvicorn", "app.main:app",
        "--host", "0.0.0.0",
        "--port", port
    ])

asyncio.run(main())
