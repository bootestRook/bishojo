@echo off
setlocal EnableExtensions

chcp 65001 >nul
cd /d "%~dp0"

echo.
echo [git_commit] Repository: %CD%
echo.

where git >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Git was not found in PATH.
    goto :fail
)

git rev-parse --is-inside-work-tree >nul 2>nul
if errorlevel 1 (
    echo [ERROR] This folder is not a Git repository.
    goto :fail
)

for /f "delims=" %%B in ('git branch --show-current') do set "BRANCH=%%B"
if not defined BRANCH (
    echo [ERROR] Current HEAD is detached. Please switch to a branch first.
    goto :fail
)

echo [git_commit] Current branch: %BRANCH%
echo.

echo [git_commit] Working tree status before staging:
git -c core.quotepath=false status --short
echo.

git add -A
if errorlevel 1 goto :fail

git reset -q -- .codegraph >nul 2>nul

git diff --cached --quiet
if errorlevel 2 goto :fail
if not errorlevel 1 (
    echo [git_commit] No changes to commit.
    goto :done
)

set "COMMIT_MSG=%~1"
if not defined COMMIT_MSG set "COMMIT_MSG=auto: update %DATE% %TIME%"

powershell -NoProfile -ExecutionPolicy Bypass -File tools/verify_text_encoding.ps1 -Staged
if errorlevel 1 goto :fail

echo.
echo [git_commit] Staged files:
git -c core.quotepath=false diff --cached --name-status
echo.

git commit -m "%COMMIT_MSG%"
if errorlevel 1 goto :fail

echo.
echo [git_commit] Done.
goto :done

:fail
echo.
echo [git_commit] Failed. Please check the message above.
ping -n 11 127.0.0.1 >nul
exit /b 1

:done
echo.
ping -n 4 127.0.0.1 >nul
exit /b 0
