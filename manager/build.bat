@echo off
REM build.bat - wrapper build.py untuk Windows (klik dua kali bisa)
setlocal
cd /d "%~dp0"
where python >nul 2>nul
if errorlevel 1 (
  echo Butuh Python di PATH.
  pause
  exit /b 1
)
python build.py %*
if errorlevel 1 (
  echo BUILD GAGAL.
  pause
  exit /b 1
)
echo SELESAI: build\FAF-Manager.apk
pause
