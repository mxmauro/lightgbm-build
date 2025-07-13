#!/usr/bin/env bash

if ! [ -d src/ ]; then
	echo "Error: Run the download library script before this one."
	exit 1
fi

# Parse command line arguments
gpu_support="-DUSE_GPU=OFF"

while [[ $# -gt 0 ]]; do
	case "$1" in
		--enable-gpu)
			gpu_support="-DUSE_GPU=ON"
			# gpu_support="$gpu_support -DBoost_NO_BOOST_CMAKE=ON"
			gpu_support="$gpu_support -DBoost_USE_STATIC_LIBS=ON"
			# gpu_support="$gpu_support -DBoost_USE_STATIC_RUNTIME=ON"
			gpu_support="$gpu_support -DBoost_VERBOSE=ON"
			gpu_support="$gpu_support -DCMAKE_CXX_FLAGS=-static-libstdc++ -DCL_TARGET_OPENCL_VERSION=300"
			shift 1
			;;
		*)
			echo "Error: Invalid parameter '$1'."
			exit 1
			;;
	esac
done

# Build projects
saved_cwd=$(pwd)
cd src
rm -r -f ../build/linux
cmake -B ../build/linux/debug/project -S . -G "Unix Makefiles" \
	-DUSE_DEBUG=ON \
	-DCMAKE_BUILD_TYPE=Debug \
	-DBUILD_STATIC_LIB=OFF \
	-DUSE_GPU=$gpu_support \
	-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=../bin \
	-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=../bin \
	-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY=../lib
exit_code=$?
if [ $exit_code -eq 0 ]; then
	cmake -B ../build/linux/release/project -S . -G "Unix Makefiles" \
		-DUSE_DEBUG=OFF \
		-DCMAKE_BUILD_TYPE=RelWithDebInfo \
		-DBUILD_STATIC_LIB=OFF \
		-DUSE_GPU=$gpu_support \
		-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=../bin \
		-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=../bin \
		-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY=../lib
	exit_code=$?
fi
cd $saved_cwd

exit $exit_code
