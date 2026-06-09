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

echo [git_commit] Working tree status:
git status --short
echo.

set "CONFIRM="
set /p "CONFIRM=Stage all changes and create a commit on %BRANCH%? [y/N] "
if /i not "%CONFIRM%"=="y" (
    echo [git_commit] Aborted.
    goto :done
)

git add -A
if errorlevel 1 goto :fail

git diff --cached --quiet
if errorlevel 2 goto :fail
if not errorlevel 1 (
    echo [git_commit] No changes to commit.
    goto :done
)

set "COMMIT_MSG="
set /p "COMMIT_MSG=Commit message (leave empty for automatic message): "
if not defined COMMIT_MSG set "COMMIT_MSG=auto: update %DATE% %TIME%"

git commit -m "%COMMIT_MSG%"
if errorlevel 1 goto :fail

echo.
echo [git_commit] Done.
goto :done

:fail
echo.
echo [git_commit] Failed. Please check the message above.
pause
exit /b 1

:done
echo.
pause
exit /b 0
