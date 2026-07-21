import subprocess
import sys
import os
import time

os.chdir(os.path.dirname(os.path.abspath(__file__)))

log = open('uvicorn_e2e.log', 'w', buffering=1)
proc = subprocess.Popen(
    [sys.executable, '-m', 'uvicorn', 'app.main:app',
     '--host', '0.0.0.0', '--port', '8000', '--log-level', 'info'],
    stdout=log,
    stderr=subprocess.STDOUT,
    creationflags=subprocess.CREATE_NO_WINDOW,
)

with open('uvicorn_e2e.pid', 'w') as f:
    f.write(str(proc.pid))

print(f'PID:{proc.pid}')
sys.stdout.flush()
