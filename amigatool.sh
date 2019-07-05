#!/usr/bin/env bash

# expands Amiga .lha files and converts them to .hdf files
# expands .zip files of Amiga directories and packs them to .hdf files
# detects .zip files containing .hdf files and merely unzips them
#
# requires blank .hdf files
# requires Python, PiP, amitools, lhasa

source=$1

if [[ ! -f "$source" ]]; then
    echo "Skipping directory $source."
    exit 1
fi

dest="${1%.*}"
name="${source%.*}"

if [[ ! "$source" == *.zip ]] && [[ ! "$source" == *.lha ]] && [[ ! "$source" = *.hdf ]]; then
    echo "$source isn't a .zip, .lha, or .hdf."
    exit 1
fi

echo -ne "\e[1m$source:\e[0m extracting..."

mkdir amigatooltmp
if [ ! -d "hdf" ]; then
	mkdir hdf
fi

cd amigatooltmp

# is it an .lha?
if [[ $source == *.lha ]]; then
	lha eq2 "../$source"
# is it a zip?
elif [[ $source == *.zip ]] ;then
	unzip -q "../$source"
elif [[ $source == *.hdf ]] ;then
    cp "../$source" "$source"
fi

# after unzipping, did it give us something with a .info file in it?
if [ ! -f *.info ]; then
	#echo -ne "finding game."
    # if it's an hdf
	if [ -f *.hdf ]; then
		#echo ".hdf file found."

        # unpack it first
		for file in * ; do
            echo -ne "."
			filename=$(basename -- "$file")
			extension="${filename##*.}"
			name="${filename%.*}"
			if [[ $file = *.hdf ]]; then
				echo -ne "unpacking..."

				xdftool "$file" unpack "$name"
				cd "$name"

				# is there a game.slave here? if so, delete the unpack, we're done
				if [[ -f "game.slave" ]] || [[ -f "game.Slave" ]]; then
					cd ..
					rm -rf "$name"
					cp "$file" ../hdf
            		echo -e "copying to /hdf... \e[1m\e[32mDone!\e[39m\e[0m"
					cd ..
					rm -rf amigatooltmp
					exit 1
				fi
                echo -ne "processing."

				# no .slave file?
                # is there instead a directory and a .info?
				# move everything from the directory up
				if [[ ! -f "*.slave" ]] && [[ ! -f "*.Slave" ]]; then
                    for i in *.info; do
                        echo -ne "."
	                    [ -f "$i" ] || break
	                    if [[ -d "$i" ]]; then
                            gamename="${i%.*}"
	                        #echo "Found game named $gamename, copying out of subdirectory"
                            echo -ne "found $gamename."
	                        # move contents out of the actual game directory
                            chmod a+w "$gamename"/*
                            find . -mindepth 2 -type f -print -exec mv {} . \;
                            rmdir "$gamename"

            				if [[ -f "game.slave" ]] || [[ -f "game.Slave" ]]; then
	    	        			cd ..
    	    					rm "$filename"
                                echo -ne "packing..."
	    		    			xdftool "$filename" pack "$name"
	    			    		rm -rf "$name"
	    			    		cp "$filename" ../hdf
		     		    		echo -e "copying to /hdf...  \e[1m\e[32mDone!\e[39m\e[0m"
			    	    		cd ..
				        		rm -rf amigatooltmp
					         	exit 1
                            else
                                echo -ne "processing..."
                            fi
                        fi
                    done
                else
                    #echo "No subdirectory, checking for slave file."
                    echo -ne "processing..."
                fi

				# is there a different slave file?
				for slave in * ; do
                    echo -ne "."
					if [[ "$slave" == *.slave ]] || [[ "$slave" == *.Slave ]]; then
						#echo "Found $slave, copying to game.slave"
                        # rename, cd up, del the old hdf, repack
                        mv "$slave" "game.slave"
						cd ..
						rm "$filename"
                        echo -ne "packing..."
						xdftool "$filename" pack "$name"
						rm -rf "$name"
						cp "$filename" ../hdf
						echo -e "copying to /hdf...  \e[1m\e[32mDone!\e[39m\e[0m"
						cd ..
						rm -rf amigatooltmp
						exit 1
                    fi
				done
                cd ..
			fi
		done
	fi
	echo -e "...\e[31mThis file does not contain a WHDLoad game.\e[39m"
	cd ..
	sudo rm -rf amigatooltmp
	exit 1
fi

filesize=$(du -sm | cut -f1)
# add extra space for save games
filesize=$(( filesize + 1 ))
#echo "Need disk larger than $filesize MB"
echo -ne "."
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
    echo -ne "."
	[ -f "$i" ] || break
	gamename="${i%.*}"
	echo -ne "found game $gamename...packing"

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
	echo -e "copying to /hdf...  \e[1m\e[32mDone!\e[39m\e[0m"

	# back out
	cd ..

done

cd ..

# remove the temporary working space

rm -rf amigatooltmp
exit 1
