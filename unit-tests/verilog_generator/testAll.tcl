puts "###################"
puts "SimpleRF Unit Test:"
puts "###################"
cd SimpleRF/
source unit_test_SimpleRF_generator.tcl
cd ../
namespace delete ::osys::rfg
puts "##################"
puts "counter Unit Test:"
puts "##################"
cd counter/
source unit_test_counter_generator.tcl
cd ../
namespace delete ::osys::rfg
puts "################"
puts "ramRF Unit Test:"
puts "################"
cd ram/
source unit_test_ramRF_generator.tcl
cd ../
namespace delete ::osys::rfg
puts "#######################"
puts "hierarchical Unit Test:"
puts "#######################"
cd hierarchicalRF/
source unit_test_hierarchicalRF_generator.tcl
cd ../
namespace delete ::osys::rfg
puts "#########################"
puts "SingleRegister Unit Test:"
puts "#########################"
cd SingleRegister
source unit_test_SingleRegister_generator.tcl
cd ../
namespace delete ::osys::rfg