#!/usr/bin/env bash

# The versions of GDB and libGMP that we will build
GDB_VERSION='11.2'
GMP_VERSION='6.2.1'

# Determine the number of logical CPU cores the host system has
CPU_CORES=`lscpu -e=CORE | tail -n +2 | wc -l`

# Perform the build, using all available CPU cores
docker buildx build --progress=plain --build-arg "CPU_CORES=$CPU_CORES" --build-arg "GMP_VERSION=$GMP_VERSION" --build-arg "GDB_VERSION=$GDB_VERSION" -t "gdb-cross-builder:$GDB_VERSION" .

# Copy the built files to the host filesystem
docker run --rm -ti -v "`pwd`:/hostdir" "gdb-cross-builder:$GDB_VERSION" cp "/tmp/dist/gdb-${GDB_VERSION}.zip" /hostdir/
