echo off

git remote add upstream https://github.com/cesarliws/dext.git
git fetch upstream
git checkout main
git rebase upstream/main

echo terminado.
pause