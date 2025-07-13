@ECHO OFF

IF NOT EXIST build\windows\debug\project\ (
	ECHO Error: Projects were not generated yet.
	EXIT /b 1
)

REM Build projects
PUSHD build\windows\debug\project
nmake
SET "_EXIT_CODE=%ERRORLEVEL%"
IF %_EXIT_CODE% == 0 (
	cd ..\..\release\project
	nmake
	SET "_EXIT_CODE=%ERRORLEVEL%"
)
POPD

EXIT /b %_EXIT_CODE%
