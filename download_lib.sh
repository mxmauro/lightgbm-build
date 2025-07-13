#!/usr/bin/env bash

_lib_version=v4.6.0

saved_cwd=$(pwd)
rm -r -f src
mkdir src
cd src
git clone --branch $_lib_version --recursive --depth 1 https://github.com/microsoft/LightGBM .
exit_code=$?
if [ $exit_code -eq 0 ]; then
	# Remove boost from compute submodule because it gives troubles
	rm -r -f external_libs/compute/include/boost
fi
if [ $exit_code -eq 0 ]; then
	# Remove this line that is not used and make us to require boost filesystem
	sed -i '/^#define BOOST_COMPUTE_USE_OFFLINE_CACHE$/d' src/treelearner/gpu_tree_learner.h
	exit_code=$?
fi
if [ $exit_code -eq 0 ]; then
	# And the requirement for boost filesystem for cmake
	sed -i -E 's|^([[:space:]]*)find_package\(Boost ([^ ]+) COMPONENTS ([^)]*\b)filesystem\b *([^)]*\b)REQUIRED\)|\1find_package(Boost \2 COMPONENTS \3\4REQUIRED)|' CMakeLists.txt
	exit_code=$?
fi
cd $saved_cwd

exit $exit_code
