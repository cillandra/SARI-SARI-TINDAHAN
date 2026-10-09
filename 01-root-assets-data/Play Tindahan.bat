@echo off
if exist "%~dp0main.lua" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-game.ps1" -Source
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-game.ps1"
)
if errorlevel 1 pause
