@echo off
title dsh-purge: fix crash (safe)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0fix-crash-safe.ps1"
