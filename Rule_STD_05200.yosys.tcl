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


#split the result table  by line
set SplitStatResult [split $StatResult \n]

#search cells numbers in stat
set cellnum [Get_Yosys_Table_value $SplitStatResult $CELLPATTERN ":" $RULEID]
puts "$RULEID> Found $cellnum cells"

#search buf numbers in stat
set bufnum [Get_Yosys_Table_value $SplitStatResult $BUFPATTERN " " $RULEID]
puts "$RULEID> Found $bufnum buffers cells"

#search pos numbers in stat
set posnum [Get_Yosys_Table_value $SplitStatResult $POSPATTERN " " $RULEID]
puts "$RULEID> Found $posnum pos cells"

#combinatorial cell evaluation
set combnum [expr $cellnum - $bufnum -$posnum]
puts "$RULEID> Found $combnum combinatorial cells"

if {$combnum !=0} {
   puts "$RULEID> VIOLATION on $SigToAnalyze"
}

#clear select
yosys select -clear
