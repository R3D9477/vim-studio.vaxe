#!/bin/bash

ROOT=$PWD

cd "$ROOT/sys/src"
./build.sh

cd "$ROOT/template/project/haXe/GUI Application/StablexUI Application - Empty Project/src"
./build.sh

cd "$ROOT/template/project/haXe/GUI Application/Mint Application - Empty Project/src"
./build.sh

cd "$ROOT/template/project/haXe/GUI Application/HaxeUI Application - Empty Project/src"
./build.sh

cd "$ROOT/template/project/haXe/Generic/OpenFL Application - Empty Project/src"
./build.sh

cd "$ROOT/template/project/haXe/Generic/Lime Application - Empty Project/src"
./build.sh

cd "$ROOT/template/project/haXe/Generic/Flow Application - Empty Project/src"
./build.sh

cd "$ROOT/template/project/haXe/Game/HaxePunk Application - Empty Project/src"
./build.sh

cd "$ROOT/template/project/haXe/Game/HaxeFlixel Application - Hello World/src"
./build.sh
