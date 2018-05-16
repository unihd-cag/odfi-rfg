cd ../
mkdir RFG.vfs
mkdir RFG.vfs/lib
mv odfi-rfg RFG.vfs/lib/odfi-rfg
cd RFG.vfs/lib/
git clone https://github.com/unihd-cag/odfi-dev-tcl.git
cd odfi-dev-tcl/
git checkout 35e09f3960b4dc9439bd542bc13c29b87694fad1
cd ../
cd ../../
mv RFG.vfs/lib/odfi-rfg/build/main.tcl RFG.vfs/main.tcl
mv RFG.vfs/lib/odfi-rfg/build/basekit basekit
mv RFG.vfs/lib/odfi-rfg/build/sdx.kit sdx.kit
cp basekit basekitcopy

./basekit sdx.kit wrap RFG -runtime basekitcopy
./RFG run_test
