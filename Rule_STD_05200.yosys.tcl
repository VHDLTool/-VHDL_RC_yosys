#evaluate rule STD_05200 for one signal passed as parameter
#execute in yosys with yosys> Rule_STD_05200.yosys MysignalNameToAnalyze
#example : yosys> tcl ../Rule_STD_05200.yosys I2C_slave/o_vz

############SCRIPT CONSTANTS#############
#name of the file including yosys general function
set PACKAGENAME Package.yosys.tcl

#reference of the Rule analyzed
set RULEID STD_05200

#########################################

#get the path of every yosys scripts and use it for package openning
set PackNameAndPath [file dirname [info script]]/$PACKAGENAME

#get general package functions
source $PackNameAndPath

puts "argument count: $argc"
puts "argument 0: [lindex $argv 0]"
puts "script name: $argv0"

#evaluate arguments
set SigToAnalyze [lindex $argv 0]

#display banner
puts "$RULEID> Evaluating $RULEID Rule for signal : $SigToAnalyze"

#select logical cone for output signal 
yosys select $SigToAnalyze %cie*
puts "$RULEID> yosys> Select $SigToAnalyze %cie*"

#save stat for this selection
puts "$RULEID> yosys> stat"
set StatResult [capture_stdout "stat"]

set combnum [Get_Comb_cells $StatResult $RULEID]

if {$combnum != 0} {
   puts "$RULEID> VIOLATION on $SigToAnalyze"
}

#clear select
yosys select -clear
