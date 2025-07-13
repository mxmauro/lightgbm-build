@ECHO OFF

SET _LIB_VERSION=v4.6.0

PUSHD
RMDIR /S /Q src >NUL 2>NUL
MKDIR src
CD src
git clone --branch %_LIB_VERSION% --recursive --depth 1 https://github.com/microsoft/LightGBM .
SET "_EXIT_CODE=%ERRORLEVEL%"
IF %_EXIT_CODE% == 0 (
	REM Remove boost from compute submodule because it gives troubles
	RMDIR /S /Q external_libs\compute\include\boost >NUL 2>NUL
)

IF %_EXIT_CODE% == 0 (
	REM Remove this line that is not used and make us to require boost filesystem
	powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-Content 'src\\treelearner\\gpu_tree_learner.h') | Where-Object { $_ -notmatch '^#define BOOST_COMPUTE_USE_OFFLINE_CACHE$' } | Set-Content 'src\\treelearner\\gpu_tree_learner.h'"
	SET "_EXIT_CODE=%ERRORLEVEL%"
)
IF %_EXIT_CODE% == 0 (
	REM And the requirement for boost filesystem for cmake
	powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-Content 'CMakeLists.txt') | ForEach-Object { $_ -replace '^([ \t]*)find_package\(Boost ([^ ]+) COMPONENTS (.*?)(\bfilesystem\b ?)?(.*?)(\bREQUIRED\b)\)', '$1find_package(Boost $2 COMPONENTS $3$5REQUIRED)' } | Set-Content 'CMakeLists.txt'"
	SET "_EXIT_CODE=%ERRORLEVEL%"
)
POPD

EXIT /b %_EXIT_CODE%
