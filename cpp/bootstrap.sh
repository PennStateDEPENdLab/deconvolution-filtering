#! /bin/bash
mkdir -p build
mkdir -p bin
(cd build >/dev/null 2>&1 && CC=gcc-4.9 CXX=g++-4.9 cmake .. "$@")
