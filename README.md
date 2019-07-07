# Amiga-LHA-ZIP-to-HDF-converter
This bash script converts LHAs, .HDFs, or zipped directories to HDFs usable in lr-puae in RetroPie.

## Installation
This requires Python, PiP, amitools, and lha.

```
sudo apt-get update
sudo apt-get install python-pip
sudo pip install amitools
sudo apt-get install -y lhasa
apt-get install zip unzip
```

Then download and install this package. It currently requires there to be a set of blank HDF files in a subdirectory.

```
sudo chmod a+x amigatool*
sudo chown pi:pi amigatool*
```

## Usage

Put the entire package (scripts, blankhdfs folder) in the directory with your Amiga roms.

### To run on a single file
```
./amigatool.sh filename
```

If the file is a `.lha`, it will be unpacked into a temporary directory, then rebuilt into an .`hdf` and placed in a new `/hdf` directory with the main .slave file renamed to game.slave. This will then run directly in lr-puae just like an `.adf`.

If the file is a `.zip` with the Amiga files loose in it, it will be unzipped, then rebuilt into an `.hdf` compatible with lr-puae and copied to the /hdf directory.

If the file is a `.zip` with an `.hdf` in it already, the `.hdf` will be converted to be compatible, if necessary, and moved to the `/hdf` folder.

If the file is a `.hdf`, it will be converted if necessary, then moved to the `/hdf` folder.

Note that these are not bootable `.hdf` files, as they do not have Kickstarts in them. They presume that you have properly set up WHDLoad.hdf and placed it in `~/RetroPie/BIOS`

The files will be output as zipped `.hdf` files which can then be scraped. Note that unzipped .hdf files will not work with some scrapers.

### To convert an entire directory
```
./amigatool-batch.sh
```

This will go through every file in the folder in which it is run, and call the previous script on each one.
