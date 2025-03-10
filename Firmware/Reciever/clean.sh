rm -rf output_files
rm -rf db
rm -rf incremental_db
rm -rf ROM
rm *.pof
rm output_file.map
rm Reciever_assignment_defaults.qdf
rm ROM.sopcinfo
rm Reciever.qws

cd Software/tinyduino_lib
make clean
cd ..
make clean
cd ..
