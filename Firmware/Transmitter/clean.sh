rm -rf output_files
rm -rf db
rm -rf incremental_db
rm -rf ROM
rm -f *.pof
rm -f output_file.map
rm -d ROM.sopcinfo
rm -rf greybox_tmp
rm -f Transmitter.qws

cd Software/tinyduino_lib
make clean
cd ..
make clean
cd ..
