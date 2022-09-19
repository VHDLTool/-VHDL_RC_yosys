#evaluate rule STD_05100 for one signal passed as parameter
#execute in yosys with yosys> Rule_STD_05100.yosys MysignalNameToAnalyze flipflop stages
#example : yosys> tcl ../Rule_STD_05100.yosys 

############SCRIPT CONSTANTS#############
#name of the file including yosys general function
set PACKAGENAME Package.yosys.tcl

#reference of the Rule analyzed
set RULEID STD_FSM_LIST

#########################################

#get the path of every yosys scripts and use it for package openning
set PackNameAndPath [file dirname [info script]]/$PACKAGENAME

#get general package functions
source $PackNameAndPath

puts "argument count: $argc"
puts "argument 0: [lindex $argv 0]"
puts "script name: $argv0"


#display banner
puts "$RULEID> Evaluating $RULEID Rule"
Get_statemachines


#clear select
yosys select -clear
