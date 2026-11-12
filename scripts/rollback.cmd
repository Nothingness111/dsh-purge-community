@echo off
title dsh-purge: rollback
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0rollback.ps1"
