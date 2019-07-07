#!/usr/bin/env bash

# expands Amiga .lha files and converts them to .hdf files
# expands .zip files of Amiga directories and packs them to .hdf files
# detects .zip files containing .hdf files and merely unzips them
#
# requires blank .hdf files
# requires Python, PiP, amitools, lhasa

source=$1

# errcodes for the batch processor
skipped=1
invalid=2
nowhd=3
compat=4
corrupt=5

if [[ ! -f "$source" ]]; then
    echo -e "\e[1m$source:\e[0m is a directory, skipping."
    exit $skipped
fi

dest="${1%.*}"
name="${source%.*}"

if [[ ! "$source" == *.zip ]] && [[ ! "$source" == *.lha ]] && [[ ! "$source" = *.hdf ]]; then
    echo -e "\e[1m$source:\e[0m is not an .lha, .zip., or .hdf, skipping."
    exit $invalid
fi

mkdir amigatooltmp
if [ ! -d "hdf" ]; then
	mkdir hdf
fi

cd amigatooltmp

# is it an .lha?
if [[ $source == *.lha ]]; then
    echo -ne "\e[1m$source:\e[0m extracting..."
	lha eq2 "../$source"
# is it a zip?
elif [[ $source == *.zip ]] ;then
    echo -ne "\e[1m$source:\e[0m unzipping..."
	unzip -q "../$source"
elif [[ $source == *.hdf ]] ;then
    echo -ne "\e[1m$source:\e[0m "
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
            		echo -ne "zipping..."
					zip -q "$name.zip" "$filename"
                    cp "$name.zip" ../hdf
            		echo -e "\e[1m\e[32malready compatible!\e[39m\e[0m"
					cd ..
					rm -rf amigatooltmp
					exit $compat
				fi
                echo -ne "processing."

				# no .slave file?
                # is there instead a directory and a .info?
				# move everything from the directory up
				if [[ ! -f "$*.slave" ]] && [[ ! -f "*.Slave" ]]; then
                    for i in *.info; do
                        echo -ne "."
	                    [ -f "$i" ] || break
	                    if [[ -d "$i" ]]; then
                            gamename="${i%.*}"
	                        #echo "Found game named $gamename, copying out of subdirectory"
                            echo -ne "found game."
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
                        		echo -ne "zipping..."
			            		zip -q "$name.zip" "$filename"
                                cp "$name.zip" ../hdf
		     		    		rm "$filename"
                                echo -e "\e[1m\e[32mDone!\e[39m\e[0m"
			    	    		cd ..
				        		rm -rf amigatooltmp
					         	exit 0
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
                    if [[ "$slave" == "$name.slave" ]] || [[ "$slave" == "$name.Slave" ]]; then
						#echo "Found $slave, copying to game.slave"
                        # rename, cd up, del the old hdf, repack
                        echo -ne "fixing..."
                        mv "$slave" "game.slave"
						cd ..
						rm "$filename"
                        echo -ne "packing..."
						xdftool "$filename" pack "$name"
						rm -rf "$name"
                   		echo -ne "zipping..."
                		zip -q "$name.zip" "$filename"
                        rm "$filename"
                        cp "$name.zip" ../hdf
						echo -e "\e[1m\e[32mDone!\e[39m\e[0m"
						cd ..
						rm -rf amigatooltmp
						exit 0
                    fi
				done
                cd ..
			fi
		done
	fi
	echo -e "...\e[31mNo WHDLoad game found.\e[39m"
	cd ..
	sudo rm -rf amigatooltmp
	exit $nowhd
fi

filesize=$(du -sm | cut -f1)
# add extra space for save games
filesize=$(( filesize + 1 ))
#echo "Need disk larger than $filesize MB"
echo -ne "."

# remove previous pass if it exists
if [[ -f ../hdf/$name.hdf ]]; then
    #echo -ne "overwriting old..."
    rm ../hdf/$name.hdf
fi
if [[ -f ../hdf/$name.zip ]]; then
    #echo -ne "overwriting old..."
    rm ../hdf/$name.zip
fi

#calculate new hdf filesize... want to make it 1.25x the orig size, so room for saved games
newsize=$(echo "scale=0;($filesize*1.25+0.5)/1" | bc)
xdftool ../hdf/$name.hdf create size=${newsize}M + format Work ffs

# identify the game name
for i in *.info; do
    echo -ne "."
	[ -f "$i" ] || break
	gamename="${i%.*}"
	echo -ne "found game...building"

	# cd into the actual game directory
	cd "$gamename"

	# copy each file into the blank hdf
	# unless it's named .slave, in which case we rename it game.slave
	for j in *; do

		if [[ $j == "$gamename.slave" ]] || [[ $j == "$gamename.Slave" ]];then
			xdftool "../../hdf/$name.hdf" write "$j" "game.slave" > /dev/null 2>&1
			if [ ! $? -eq 0 ]; then
               	echo -e "...\e[31mCorrupt!\e[39m"
                rm "../../hdf/$name.hdf"
                cd ../..
                rm -rf amigatooltmp
                exit $corrupt
            fi
            #echo "Copying $j into $name.hdf as game.slave"
		else
			xdftool "../../hdf/$name.hdf" write "$j" > /dev/null 2>&1
			if [ ! $? -eq 0 ]; then
               	echo -e "...\e[31mCorrupt!\e[39m"
                rm "../../hdf/$name.hdf"
                cd ../..
                rm -rf amigatooltmp
                exit $corrupt
            fi
			#echo "Copying $j into $name.hdf"
		fi
		echo -ne "."
	done

    echo -ne "zipping..."
    cd ../../hdf
    zip -q "$name.zip" "$name.hdf"
    rm "$name.hdf"
	echo -e "\e[1m\e[32mDone!\e[39m\e[0m"

done

cd ..

# remove the temporary working space

rm -rf amigatooltmp
exit 0
