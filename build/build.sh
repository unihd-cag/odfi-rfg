cd ../
mkdir RFG.vfs
mkdir RFG.vfs/lib
mv odfi-rfg RFG.vfs/lib/odfi-rfg
cd RFG.vfs/lib/
git clone https://github.com/unihd-cag/odfi-dev-tcl.git
cd odfi-dev-tcl/
git checkout 2a2c6c0a3b8cd339ac80e843ed56a7b72592e3de
cd ../
cd ../../
mv RFG.vfs/lib/odfi-rfg/build/main.tcl RFG.vfs/main.tcl
mv RFG.vfs/lib/odfi-rfg/build/basekit basekit
mv RFG.vfs/lib/odfi-rfg/build/sdx.kit sdx.kit
cp basekit basekitcopy

./basekit sdx.kit wrap RFG -runtime basekitcopy
./RFG run_test
