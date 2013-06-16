#! /bin/bash
mkdir -p build
mkdir -p bin
(cd build >/dev/null 2>&1 && CC=/home/jbian/local/bin/gcc CXX=/home/jbian/local/bin/g++ cmake .. "$@")
