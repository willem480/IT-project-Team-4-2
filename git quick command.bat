@echo off
cd /d "%~dp0"

:: Stage changes
git add .
git add "git quick command.bat"
echo Files added to staging.

:: Prompt for commit message
set /p "commitMsg=Enter commit message: "
git commit -m "%commitMsg%"

:: Push to the current branch
git push

pause


