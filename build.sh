#!/bin/bash

ROOT=$PWD

cd "$ROOT/sys/src"
./build.sh

cd "$ROOT/template/project/Haxe/GUI Application/StablexUI Application - Empty Project/src"
./build.sh

cd "$ROOT/template/project/Haxe/GUI Application/Mint Application - Empty Project/src"
./build.sh

cd "$ROOT/template/project/Haxe/GUI Application/HaxeUI Application - Empty Project/src"
./build.sh

cd "$ROOT/template/project/Haxe/Generic/OpenFL Application - Empty Project/src"
./build.sh

cd "$ROOT/template/project/Haxe/Generic/Lime Application - Empty Project/src"
./build.sh

cd "$ROOT/template/project/Haxe/Generic/Flow Application - Empty Project/src"
./build.sh

cd "$ROOT/template/project/Haxe/Game/HaxePunk Application - Empty Project/src"
./build.sh

cd "$ROOT/template/project/Haxe/Game/HaxeFlixel Application - Hello World/src"
./build.sh
