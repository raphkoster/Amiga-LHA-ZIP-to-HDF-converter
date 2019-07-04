#!/usr/bin/env bash

# expands Amiga .lha files and converts them to .hdf files
# expands .zip files of Amiga directories and packs them to .hdf files
# detects .zip files containing .hdf files and merely unzips them
#
# requires blank .hdf files
# requires Python, PiP, amitools, lhasa

source=$1
dest="${1%.*}"
name="${source%.*}"

echo "Extracting $source..."

mkdir amigatooltmp
if [ ! -d "hdf" ]; then
	mkdir hdf
fi

cd amigatooltmp

# is it an .lha?
if [[ $source == *.lha ]]; then
	lha e -q2 "../$source"
# is it a zip?
elif [[ $source == *.zip ]] ;then
	unzip -q "../$source"
fi

# after unzipping, did it give us something with a .info file in it?
if [ ! -f *.info ]; then

	# if it's an hdf, just move it to the target directory
	if [ -f *.hdf ]; then
		cp *.hdf ../hdf
		echo "Copied $dest to /hdf."

		# TODO: add going into the HDF to check for lack of a
		# game.slave file, and if so, find the main slave file and
		# copy it out, delete the original, and write it back in
		# as game.slave

		cd ..
		rm -rf amigatooltmp
		exit 1
	fi
	echo "No Amiga hard drive data found."
	cd ..
	rm -rf amigatooltmp
	exit 1
fi

filesize=$(du -sm | cut -f1)
# add extra space for save games
filesize=$(( filesize + 1 ))
#echo "Need disk larger than $filesize MB"

# copy blank hdf of the right size (larger) into the /hdf directory
blank="../blankhdfs/blank2mb.hdf"
if (( $filesize > 2 )); then
	blank="../blankhdfs/blank4mb.hdf"
fi
if (( $filesize > 4 )); then
	blank="../blankhdfs/blank6mb.hdf"
fi
if (( $filesize > 6 )); then
	blank="../blankhdfs/blank8mb.hdf"
fi
if (( $filesize > 8 )); then
	blank="../blankhdfs/blank10mb.hdf"
fi
if (( $filesize > 10 )); then
	blank="../blankhdfs/blank12mb.hdf"
fi
if (( $filesize > 12 )); then
	blank="../blankhdfs/blank14mb.hdf"
fi
if (( $filesize > 14 )); then
	blank="../blankhdfs/blank38mb.hdf"
fi

#echo "Copying $blank."
cp "$blank" "../hdf/$name.hdf"

# identify the game name
for i in *.info; do
	[ -f "$i" ] || break
	gamename="${i%.*}"
	##echo "Found game named $gamename"

	# cd into the actual game directory
	cd "$gamename"

	# copy each file into the blank hdf
	# unless it's named .slave, in which case we rename it game.slave
	for j in *; do
		if [[ $j == *.slave ]] || [[ $j == *.Slave ]];then
			xdftool "../../hdf/$name.hdf" write "$j" "game.slave"
			#echo "Copying $j into $name.hdf as game.slave"
		else
			xdftool "../../hdf/$name.hdf" write "$j"
			#echo "Copying $j into $name.hdf"
		fi
		echo -ne "."
	done
	echo "Copied $dest to /hdf."

	# back out
	cd ..

done

cd ..

# remove the temporary working space

rm -rf amigatooltmp
exit 1

