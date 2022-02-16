FROM ubuntu:20.04

# The number of CPU cores to use when performing compilation
ARG CPU_CORES=8

# The version of libGMP that we will build
ARG GMP_VERSION=6.2.1

# The version of GDB that we will build
ARG GDB_VERSION=11.2

# Install our build dependencies
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt \
	apt-get update && apt-get install -y --no-install-recommends \
		autoconf \
		automake \
		build-essential \
		ca-certificates \
		curl \
		mingw-w64 \
		tar \
		zip

# Create a non-root user and perform all build steps as this user (this simplifies things a little when later copying files out of the container image)
RUN useradd --create-home --home /home/nonroot --shell /bin/bash --uid 1000 nonroot
USER nonroot

# Download and extract the source code for libGMP
RUN mkdir /tmp/src
RUN curl -fSL "https://gmplib.org/download/gmp/gmp-${GMP_VERSION}.tar.xz" -o "/tmp/gmp-${GMP_VERSION}.tar.xz" && \
	tar xvf "/tmp/gmp-${GMP_VERSION}.tar.xz" --directory /tmp/src

# Download and extract the source code for GDB
RUN curl -fSL "https://ftp.gnu.org/gnu/gdb/gdb-${GDB_VERSION}.tar.gz" -o "/tmp/gdb-${GDB_VERSION}.tar.gz" && \
	tar xvf "/tmp/gdb-${GDB_VERSION}.tar.gz" --directory /tmp/src

# Cross-compile libGMP for Windows with MinGW-w64
RUN mkdir -p /tmp/build/gmp && cd /tmp/build/gmp && \
	"/tmp/src/gmp-${GMP_VERSION}/configure" \
		--prefix=/tmp/install/gmp \
		--host=x86_64-w64-mingw32 \
		--enable-static \
		--disable-shared && \
	make "-j${CPU_CORES}" && \
	make install

# Cross-compile GDB for Windows with MinGW-w64, enabling multi-architecture support for debugging both Windows and Linux target applications
# (See:
# - https://stackoverflow.com/a/61363144
# - https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=gdb-multiarch
# - https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-gdb/PKGBUILD)
RUN mkdir -p /tmp/build/gdb && cd /tmp/build/gdb && \
	"/tmp/src/gdb-${GDB_VERSION}/configure" \
		--prefix=/tmp/install/gdb \
		--host=x86_64-w64-mingw32 \
		--target=x86_64-w64-mingw32 \
		--enable-targets=all \
		--with-libgmp-prefix=/tmp/install/gmp \
		--with-static-standard-libraries \
		--enable-static \
		--disable-shared \
		--disable-ld \
		--disable-gold \
		--disable-sim && \
	make "-j${CPU_CORES}" && \
	make install

# Copy the GDB executable from the built files and strip away debug symbols to reduce the filesize
RUN mkdir /tmp/dist && \
	cp /tmp/install/gdb/bin/gdb.exe /tmp/dist/gdb-multiarch.exe && \
	strip -s /tmp/dist/gdb-multiarch.exe

# Copy the license files for GDB and its dependencies
RUN mkdir -p /tmp/dist/licenses/gdb && cp "/tmp/src/gdb-${GDB_VERSION}/COPYING" /tmp/dist/licenses/gdb/ && \
	mkdir -p /tmp/dist/licenses/gmp && cp "/tmp/src/gmp-${GMP_VERSION}/COPYING" /tmp/dist/licenses/gmp/ && \
	mkdir -p /tmp/dist/licenses/bfd && cp "/tmp/src/gdb-${GDB_VERSION}/bfd/COPYING" /tmp/dist/licenses/bfd/ && \
	mkdir -p /tmp/dist/licenses/libiberty && cp "/tmp/src/gdb-${GDB_VERSION}/libiberty/COPYING.LIB" /tmp/dist/licenses/libiberty/ && \
	mkdir -p /tmp/dist/licenses/zlib && cp "/tmp/src/gdb-${GDB_VERSION}/zlib/README" /tmp/dist/licenses/zlib/

# Retrieve the license files for GCC, since libgcc and libstdc++ are statically linked into the GDB executable
RUN mkdir -p /tmp/dist/licenses/gcc && \
	curl -fSL 'https://raw.githubusercontent.com/gcc-mirror/gcc/master/COPYING3' -o /tmp/dist/licenses/gcc/COPYING3 && \
	curl -fSL 'https://raw.githubusercontent.com/gcc-mirror/gcc/master/COPYING.RUNTIME' -o /tmp/dist/licenses/gcc/COPYING.RUNTIME

# Create a README file with links to the locations of the source code for GDB and its dependencies
RUN echo 'This directory contains a distribution of The GNU Project Debugger (GDB) in object form.' >> /tmp/dist/README.txt && \
	echo 'The binary was cross-compiled for Windows with MinGW-w64, and is statically linked against libgcc and libstdc++.' >> /tmp/dist/README.txt && \
	echo 'This distribution of GDB is configured for debugging remote Linux applications from a local Windows system.' >> /tmp/dist/README.txt && \
	echo '' >> /tmp/dist/README.txt && \
	echo 'The licenses for GDB and its dependencies can be found in the `licenses` subdirectory.' >> /tmp/dist/README.txt && \
	echo '' >> /tmp/dist/README.txt && \
	echo 'The source code for GDB and its dependencies can be downloaded from the following URLs:' >> /tmp/dist/README.txt && \
	echo '' >> /tmp/dist/README.txt && \
	echo "- https://ftp.gnu.org/gnu/gdb/gdb-${GDB_VERSION}.tar.gz" >> /tmp/dist/README.txt && \
	echo "- https://gmplib.org/download/gmp/gmp-${GMP_VERSION}.tar.xz" >> /tmp/dist/README.txt && \
	echo '- https://github.com/gcc-mirror/gcc' >> /tmp/dist/README.txt && \
	echo '' >> /tmp/dist/README.txt

# Create a ZIP archive of the files for distribution
RUN cd /tmp/dist && \
	zip -r "gdb-${GDB_VERSION}.zip" gdb-multiarch.exe licenses/ README.txt
