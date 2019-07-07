#!/usr/bin/env bash

# errcodes for the batch processor
skipped=1
invalid=2
nowhd=3
compat=4
corrupt=5

#count the files
shopt -s nullglob
numfiles=(*)
numfiles=${#numfiles[@]}

#counters
count=0
skippedfiles=0
invalidfiles=0
nowhdfiles=0
compatfiles=0
corruptfiles=0

echo -e "\e[1mBatch processing $numfiles files for conversion to lr-puae .hdf roms.\e[0m"
echo "---------------------------------------------------"
for f in * ; do
    echo -ne "\e[32m$count/$numfiles\e[39m "
    ./amigatool.sh "$f"
    retcode=$?

    count=$(( $count + 1 ))

    case $retcode in
        $skipped)
            let skippedfiles=$(( skippedfiles + 1 ))
            ;;
        $invalid)
            let invalidfiles=$(( invalidfiles + 1 ))
            ;;
        $nowhd)
            let nowhdfiles=$(( nowhdfiles + 1 ))
            ;;
        $compat)
            let compatfiles=$(( compatfiles + 1 ))
            ;;
        $corrupt)
            let corruptfiles=$(( corruptfiles + 1 ))
            ;;
    esac
done
converts=$(( $count - $skippedfiles - $invalidfiles - $nowhdfiles - $compatfiles - $corruptfiles ))
echo "---------------------------------------------------"
echo "amigatool batch process complete."
echo -e "\e[1mTotal processed:                 $count\e[0m"
echo "  Skipped directories:           $skippedfiles"
echo "  Skipped files:                 $invalidfiles"
echo -e "  \e[31mDidn't contain a WHDload game: $nowhdfiles\e[39m"
echo -e "  \e[31mFile was corrupt:              $corruptfiles\e[39m"
echo -e "  \e[32mAlready compatible files:      $compatfiles\e[39m"
echo -e "  \e[32mConverted files:               $converts\e[39m"
echo "Converted .hdf files are located in the /hdf folder."

exit 0

