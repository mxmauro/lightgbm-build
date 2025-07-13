#!/usr/bin/env bash

if ! [ -d build/linux/debug/project/ ]; then
	echo "Error: Projects were not generated yet."
	exit 1
fi

# Build projects
saved_cwd=$(pwd)
cd build/linux/debug/project
make
exit_code=$?
if [ $exit_code -eq 0 ]; then
	cd ../../release/project
	make
	exit_code=$?
fi
cd $saved_cwd

exit $exit_code
