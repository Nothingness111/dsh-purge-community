@echo off
title dsh-purge: setup repo
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-repo.ps1"
