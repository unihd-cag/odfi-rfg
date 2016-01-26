cd ../
mkdir RFG.vfs
mkdir RFG.vfs/lib
mv odfi-rfg RFG.vfs/lib/odfi-rfg
cd RFG.vfs/lib/
git clone git@github.com:unihd-cag/odfi-dev-tcl.git
cd ../../
mv RFG.vfs/lib/odfi-rfg/build/main.tcl RFG.vfs/main.tcl
mv RFG.vfs/lib/odfi-rfg/build/basekit basekit
mv RFG.vfs/lib/odfi-rfg/build/sdx.kit
cp basekit basekitcopy

./basekit sdx.kit wrap RFG -runtime basekitcopy
./RFG run_test
