#! /bin/bash
mkdir -p build
mkdir -p bin
(cd build >/dev/null 2>&1 && CC=gcc-4.8 CXX=g++-4.8 cmake .. "$@")
