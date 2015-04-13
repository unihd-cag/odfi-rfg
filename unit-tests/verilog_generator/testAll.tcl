puts "###################"
puts "SimpleRF Unit Test:"
puts "###################"
cd SimpleRF/
source unit_test_SimpleRF_generator.tcl
file delete SimpleRF.iverilog
file delete SimpleRF.vcd
file delete compare_data/SimpleRF.v
cd ../
##namespace delete ::osys::rfg
puts "##################"
puts "counter Unit Test:"
puts "##################"
cd counter/
source unit_test_counter_generator.tcl
file delete counter_RF.iverilog
file delete counter_RF.vcd
file delete compare_data/counter_RF.v
cd ../
##namespace delete ::osys::rfg
puts "################"
puts "ramRF Unit Test:"
puts "################"
cd ram/
source unit_test_ramRF_generator.tcl
file delete ramRF.iverilog
file delete ramRF.vcd
file delete compare_data/ramRF.v
cd ../
##namespace delete ::osys::rfg
puts "#######################"
puts "hierarchical Unit Test:"
puts "#######################"
cd hierarchicalRF/
source unit_test_hierarchicalRF_generator.tcl
file delete hierarchicalRF.iverilog
file delete hierarchicalRF.vcd
file delete compare_data/hierarchicalRF.v
cd ../
##namespace delete ::osys::rfg
puts "#########################"
puts "SingleRegister Unit Test:"
puts "#########################"
cd SingleRegister
source unit_test_SingleRegister_generator.tcl
file delete SingleRegister.iverilog
file delete SingleRegister.vcd
file delete SingleRF.v
cd ../
namespace delete ::osys::rfg
