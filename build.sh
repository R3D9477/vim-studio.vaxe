#!/bin/bash

cd "sys/src"
./build.sh

cd "../../template/project/Haxe/GUI Application/StablexUI Application - Empty Project/src"
./build.sh

cd "../../Mint Application - Empty Project/src"
./build.sh

cd "../../HaxeUI Application - Empty Project/src"
./build.sh

cd "../../../Generic/OpenFL Application - Empty Project/src"
./build.sh

cd "../../Lime Application - Empty Project/src"
./build.sh

cd "../../Flow Application - Empty Project/src"
./build.sh

cd "../../../Game/HaxePunk Application - Empty Project/src"
./build.sh

cd "../../HaxeFlixel Application - Hello World/src"
./build.sh
