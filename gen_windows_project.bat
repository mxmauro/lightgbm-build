@ECHO OFF
SETLOCAL enabledelayedexpansion enableextensions

IF NOT EXIST src\ (
	ECHO Error: Run the download library script before this one.
	EXIT /b 1
)
IF "%VSINSTALLDIR%" == "" (
	ECHO Error: This script must be run from a Visual Studio Developer Command Prompt.
	EXIT /b 1
)

REM Get the compiler version
SET _CL_VER=
FOR /f "tokens=7" %%a IN ('cl 2^>^&1 ^| FINDSTR /b /c:"Microsoft (R) C/C++"') DO (
	SET "_CL_VER=%%a"
)
IF "!_CL_VER!" == "" (
	ECHO Error: MSVC compiler not found in PATH.
	EXIT /b 1
)

REM Extract major.minor version
SET _CL_MAJOR=
SET _CL_MINOR=
FOR /f "tokens=1,2 delims=." %%i IN ("!_CL_VER!") DO (
	SET "_CL_MAJOR=%%i"
	SET "_CL_MINOR=%%j"
)

REM Determine toolset from version
IF "!_CL_MAJOR!" == "19" (
	IF "!_CL_MINOR!" geq "30" (
		SET _MSVC_VERSION=14.3
	) ELSE IF "!_CL_MINOR!" geq "20" (
		SET _MSVC_VERSION=14.2
	) ELSE IF "!_CL_MINOR!" geq "10" (
		SET _MSVC_VERSION=14.1
	) ELSE (
		ECHO Error: Unknown or unsupported compiler version: !_CL_VER!
		EXIT /b 1
	)
) ELSE (
	ECHO Error: Unknown or unsupported compiler version: !_CL_VER!
	EXIT /b 1
)

REM Parse command line arguments
SET _ENABLE_GPU=OFF
SET _BOOST_BASE_DIR=
SET _OPENCL_BASE_DIR=
SET _CMAKE_CXX_FLAGS=/EHsc

:parse_args
IF "%~1" == "" GOTO parse_args_done

IF "%~1" == "--enable-gpu" (
	SET _ENABLE_GPU=ON
	SHIFT /1
	GOTO parse_args
)
IF "%~1" == "--boost-dir" (
	IF "%~2" == "" (
		ECHO Error: --boost-dir requires a directory path.
		EXIT /b 1
	)
	SET "_BOOST_BASE_DIR=%~2"
	SHIFT /1
	SHIFT /1
	GOTO parse_args
)
IF "%~1" == "--opencl-dir" (
	IF "%~2" == "" (
		ECHO Error: --opencl-dir requires a directory path.
		EXIT /b 1
	)
	SET "_OPENCL_BASE_DIR=%~2"
	SHIFT /1
	SHIFT /1
	GOTO parse_args
)

ECHO Error: Invalid parameter '%~1'
EXIT /b 1
:parse_args_done

REM Check options
IF "!_ENABLE_GPU!" == "ON" (
	IF "!_OPENCL_BASE_DIR!" == "auto" (
		IF NOT "%CUDA_PATH%" == "" (
			ECHO Info: Detected CUDA in directory '%CUDA_PATH%'
			SET "_OPENCL_BASE_DIR=%CUDA_PATH%"
		) ELSE (
			ECHO Error: Unable to discover OpenCL location.
			EXIT /b 1
		)
	)
	IF "!_OPENCL_BASE_DIR!" == "" (
		ECHO Error: Missing --opencl-dir argument.
		EXIT /b 1
	)
	IF "!_BOOST_BASE_DIR!" == "" (
		ECHO Error: Missing --boost-dir argument.
		EXIT /b 1
	)

	SET _GPU_SUPPORT=-DUSE_GPU=ON ^
		-DBoost_NO_SYSTEM_PATHS=ON ^
		-DBoost_USE_STATIC_LIBS=ON ^
		-DBoost_USE_STATIC_RUNTIME=ON ^
		-DBOOST_ROOT="!_BOOST_BASE_DIR!" ^
		-DBOOST_LIBRARYDIR="!_BOOST_BASE_DIR!/lib64-msvc-!_MSVC_VERSION!" ^
		-DOpenCL_LIBRARY="!_OPENCL_BASE_DIR!/lib/x64/OpenCL.lib" ^
		-DOpenCL_INCLUDE_DIR="!_OPENCL_BASE_DIR!/include"
	SET _CMAKE_CXX_FLAGS=!_CMAKE_CXX_FLAGS! -DCL_TARGET_OPENCL_VERSION=300
) ELSE (
	SET _GPU_SUPPORT=-DUSE_GPU=OFF
)

REM Build projects
PUSHD src
RMDIR /S /Q ..\build\windows 2>NUL
cmake -B ..\build\windows\debug\project -S . -G "NMake Makefiles" ^
	-DUSE_DEBUG=ON ^
	-DCMAKE_BUILD_TYPE=Debug ^
	-DBUILD_STATIC_LIB=OFF ^
	!_GPU_SUPPORT! ^
	-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=../bin ^
	-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=../bin ^
	-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY=../lib ^
	-DCMAKE_MSVC_RUNTIME_LIBRARY="MultiThreadedDebug" ^
	-DCMAKE_CXX_FLAGS="!_CMAKE_CXX_FLAGS!"
SET "_EXIT_CODE=!ERRORLEVEL!"
IF !_EXIT_CODE! == 0 (
	cmake -B ..\build\windows\release\project -S . -G "NMake Makefiles" ^
		-DUSE_DEBUG=OFF ^
		-DCMAKE_BUILD_TYPE=RelWithDebInfo ^
		-DBUILD_STATIC_LIB=OFF ^
		!_GPU_SUPPORT! ^
		-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=../bin ^
		-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=../bin ^
		-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY=../lib ^
		-DCMAKE_MSVC_RUNTIME_LIBRARY="MultiThreaded" ^
		-DCMAKE_CXX_FLAGS="!_CMAKE./_CXX_FLAGS!"
	SET "_EXIT_CODE=!ERRORLEVEL!"
)
POPD

EXIT /b !_EXIT_CODE!
