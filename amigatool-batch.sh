#!/usr/bin/env bash

shopt -s nullglob
numfiles=(*)
numfiles=${#numfiles[@]}
count=0

echo "Batch processing $numfiles file for conversion to lr-puae .hdf roms."
for f in * ; do
    echo -ne "\e[32m$count/$numfiles\e[39m "
    sudo ./amigatool.sh "$f"
    count=$(( $count + 1 ))
done
echo "Converted .hdf files are located in the /hdf folder."

