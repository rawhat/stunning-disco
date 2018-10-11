#!/bin/bash
pkill main && echo "Sent kill"
rm -f ./main && echo "Removed old binary"
echo "Going to build and run..."
go build -o main && ./main
