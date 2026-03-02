#!/usr/bin/env bash

# Script to index photos in drive.

# Scan photos
find . | grep -E ".*\.[Hh][Ee][Ii][Cc]" > photolist.txt

# Generate hashes
file=$(cat photolist.txt) 
echo "" > photosums.txt
for line in $file
do
	hash=$(shasum -a 256 "$line")
	echo "$hash" >> photosums.txt
done
