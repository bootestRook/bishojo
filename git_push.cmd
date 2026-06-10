@echo off
setlocal EnableExtensions

chcp 65001 >nul
cd /d "%~dp0"

echo.
echo [git_push] Repository: %CD%
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

git remote get-url origin >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Remote "origin" does not exist.
    goto :fail
)

echo [git_push] Current branch: %BRANCH%
echo [git_push] Remote origin:
git remote get-url origin
echo.

echo [git_push] Working tree status before staging:
git -c core.quotepath=false status --short
echo.

git add -A
if errorlevel 1 goto :fail

git reset -q -- .codegraph >nul 2>nul

git diff --cached --quiet
if errorlevel 2 goto :fail
if errorlevel 1 goto :commit_changes

echo [git_push] No staged changes. Pushing existing commits only.
goto :push_changes

:commit_changes
set "COMMIT_MSG=%~1"
if not defined COMMIT_MSG set "COMMIT_MSG=auto: update %DATE% %TIME%"

powershell -NoProfile -ExecutionPolicy Bypass -File tools/verify_text_encoding.ps1 -Staged
if errorlevel 1 goto :fail

echo.
echo [git_push] Staged files:
git -c core.quotepath=false diff --cached --name-status
echo.

git commit -m "%COMMIT_MSG%"
if errorlevel 1 goto :fail

:push_changes
git push -u origin "%BRANCH%"
if errorlevel 1 goto :fail

echo.
echo [git_push] Done.
goto :done

:fail
echo.
echo [git_push] Failed. Please check the message above.
ping -n 11 127.0.0.1 >nul
exit /b 1

:done
echo.
ping -n 4 127.0.0.1 >nul
exit /b 0
