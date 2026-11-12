@echo off
title dsh-purge: publish
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish.ps1"
