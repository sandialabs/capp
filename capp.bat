@echo off
SET mypath=%~dp0
cmake.exe -P "%mypath%/capp.cmake" %*
