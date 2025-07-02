#!/bin/bash
VERSION=v1.0.5
rm -rf build
make -C code/$VERSION/ all
