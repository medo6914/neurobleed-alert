@echo off
REM NeuroBleed Alert - Web deployment script (Firebase Hosting)
REM Run from repo root: docs\presentation\deploy_web.bat
setlocal
set ROOT=%~dp0..\..
cd /d "%ROOT%\apps\mobile_flutter" || exit /b 1

echo === Building Flutter Web (full app) ===
call flutter build web --release --dart-define=API_BASE_URL=%API_BASE_URL% 2>&1 || exit /b 1

echo === Deploying to Firebase Hosting: neurobleed-alert ===
cd /d "%ROOT%"
call firebase deploy --only hosting --project neurobleed-alert 2>&1 || exit /b 1

echo === DONE ===
endlocal
