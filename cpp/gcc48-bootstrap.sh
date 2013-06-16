#! /bin/bash
mkdir -p build
mkdir -p bin
(cd build >/dev/null 2>&1 && CC=/home/jbian/local/bin/gcc CXX=/home/jbian/local/bin/g++ cmake .. -DCMAKE_SHARED_LINKER_FLAGS="-Wl,-rpath=/home/jbian/local/lib64" -DCMAKE_EXE_LINKER_FLAGS="-Wl,-rpath=/home/jbian/local/lib64" -DCMAKE_MODULE_LINKER_FLAGS="-Wl,-rpath=/home/jbian/local/lib64" -DCONFIGURATE_CFLAGS="-I/home/jbian/local/include" -DCONFIGURATE_CXXFLAGS="-I/home/jbian/local/include" -DCONFIGURATE_LDFLAGS="-Wl,-rpath=/home/jbian/local/lib64 -L/home/jbian/local/lib64 -L/home/jbian/local/lib" "$@")
