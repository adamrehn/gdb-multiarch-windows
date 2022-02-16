# GDB multi-architecture build for Windows

This repository contains build scripts to cross-compile [The GNU Project Debugger (GDB)](https://www.sourceware.org/gdb/) for Windows using [MinGW-w64](https://www.mingw-w64.org/) with all dependencies statically linked and all target architectures enabled. The resulting standalone executable can be used to connect to [gdbserver](https://sourceware.org/gdb/onlinedocs/gdb/Server.html) instances and perform remote debugging of any supported target platform and architecture from a local Windows machine. Paired with the [support for GDB in Visual Studio Code](https://code.visualstudio.com/docs/cpp/cpp-debug), this provides a free and flexible alternative to the [remote GDB debugging functionality in Visual Studio](https://docs.microsoft.com/en-us/cpp/linux/deploy-run-and-debug-your-linux-project).

**You can download pre-compiled binaries from the [releases page](https://github.com/adamrehn/gdb-multiarch-windows/releases).**


## Building from source

To run the build scripts, you will need a system with a bash shell and a recent version of [Docker](https://www.docker.com/). To perform a build, simply run:

```bash
./build.sh
```


## Legal

The build scripts are Copyright &copy; 2022, Adam Rehn and are licensed under the MIT License. See the file [LICENSE](./LICENSE) for details.

Binary distributions created by the build scripts encapsulate GDB and its dependencies in object form, all statically linked into a single executable. See the `README.txt` file and `license` subdirectory included in each binary distribution ZIP archive for details on the licenses of these components and the locations from which their source code can be obtained.
