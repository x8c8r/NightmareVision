@echo off

cd .haxelib/lime/git/
git submodule update
cd ../../../
haxelib run lime rebuild cpp

echo:
echo Finished rebuilding lime
pause
