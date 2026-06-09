@echo off
setlocal EnableExtensions

chcp 65001 >nul
cd /d "%~dp0"

echo.
echo [git_pull] Repository: %CD%
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

echo [git_pull] Current branch: %BRANCH%
echo [git_pull] Remote origin:
git remote get-url origin
echo.

echo [git_pull] Working tree status:
git status --short
echo.

set "CONFIRM="
set /p "CONFIRM=Pull latest changes from origin/%BRANCH% with --ff-only? [y/N] "
if /i not "%CONFIRM%"=="y" (
    echo [git_pull] Aborted.
    goto :done
)

git pull --ff-only origin "%BRANCH%"
if errorlevel 1 goto :fail

echo.
echo [git_pull] Done.
goto :done

:fail
echo.
echo [git_pull] Failed. Please check the message above.
pause
exit /b 1

:done
echo.
pause
exit /b 0
