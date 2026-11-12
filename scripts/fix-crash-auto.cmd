@echo off
title dsh-purge: fix crash (auto)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0fix-crash-auto.ps1"
