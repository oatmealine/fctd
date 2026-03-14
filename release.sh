#!/bin/sh
# this will only work on my machin esorry
love-release -W 64 && love.js releases/Hotel\ Otel.love releases/web -c -t "hotel" -m 33554432
cp releases/_web/* releases/web/
nix run nixpkgs#devd -- -o releases/web/