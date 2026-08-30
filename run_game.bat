@echo off
setlocal

set "NIULAI_GODOT="
if defined GODOT_EXE if exist "%GODOT_EXE%" set "NIULAI_GODOT=%GODOT_EXE%"
if not defined NIULAI_GODOT if exist "D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" set "NIULAI_GODOT=D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
if not defined NIULAI_GODOT if exist "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" set "NIULAI_GODOT=C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
if not defined NIULAI_GODOT for /f "delims=" %%G in ('where godot4 2^>nul') do if not defined NIULAI_GODOT set "NIULAI_GODOT=%%G"
if not defined NIULAI_GODOT for /f "delims=" %%G in ('where godot 2^>nul') do if not defined NIULAI_GODOT set "NIULAI_GODOT=%%G"

if not defined NIULAI_GODOT (
  echo Godot 4 was not found.
  echo.
  echo Set the GODOT_EXE environment variable to your Godot executable,
  echo add godot4 to PATH, or import project.godot from the Godot editor.
  pause
  exit /b 1
)

pushd "%~dp0"
start "Niulai" "%NIULAI_GODOT%" --path "%CD%"
popd
endlocal
