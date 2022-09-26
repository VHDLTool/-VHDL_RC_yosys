# CNES and Linty Services
# Copyright (C) 2022-2022
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#-------------------------------------------------------------------------------------------------
#-- Description : evaluate rule "STD_05100:Metastability management" for one signal input passed as parameter
#--
#-- Execution  : execute in yosys (after design elaboration) with
#--              yosys> Rule_STD_05100.yosys <MysignalNameToAnalyze> <flipflop stages to analyze>
#--
#-- Limitations : the way the Package.yosys.tcl script path is namaged should be improved
#--               This script do soe synthesys pass , therefore the design is altered, it is adviced
#--               To reload the project from the ground to avoid strange behavior due to synthesis.
#--
#--               depending on CONEDEPTH the combinatorial path can include several layer of flipflop
#--               Which is not wanted and should be corrected
#--
#--               There is no check made to verify if signal exists or is really an input
#-------------------------------------------------------------------------------------------------

############SCRIPT CONSTANTS#############
#name of the file including yosys general function
set PACKAGENAME Package.yosys.tcl

#reference of the Rule analyzed
set RULEID STD_05100

#set depth of logical cone for input
set CONEDEPTH 5
#########################################

#get the path of every yosys scripts and use it for package openning
set PackNameAndPath [file dirname [info script]]/$PACKAGENAME
#get general package functions
source $PackNameAndPath

#debug
#puts "argument count: $argc"
#puts "argument 0: [lindex $argv 0]"
#puts "script name: $argv0"

#evaluate arguments
set SigToAnalyze [lindex $argv 0]
set FfStages [lindex $argv 1]

#display banner
puts "$RULEID> Evaluating $RULEID Rule for signal : $SigToAnalyze"
puts "$RULEID> Evaluating $RULEID Rule for flipflop stages : $FfStages"

#select first level of logical cone
puts "$RULEID> FF Stage 1"

# create "select mySig %co " to get the combinatorial cone to the register
set yosyscmd "select $SigToAnalyze %co$CONEDEPTH"
eval "yosys $yosyscmd"
puts "$RULEID> yosys>Stage 1> $yosyscmd"

#evaluate first if first stage includes combinatorials
set StatResult [capture_stdout "stat"]
set combnum [Get_Comb_cells $StatResult $RULEID]


if {$combnum !=0} {
    puts "$RULEID>Stage 1> VIOLATION on $SigToAnalyze "
} else {
    #evaluate next level of input
    #start at 1 because stage 1 was already done
    for {set i 1} {$i <$FfStages} {incr i} {
        #clear selection
        yosys select -clear
        set stagenum [expr $i + 1]
        puts "$RULEID> FF Stage $stagenum"

        #construct command to get the name of the next stage flipflops and apply logical cone on them
        set yosyscmd "$yosyscmd t:*ff* %i %co$CONEDEPTH"
        puts "$RULEID> yosys>Stage $$stagenum> $yosyscmd"
        eval "yosys $yosyscmd"

        #search for combinatorial
        set StatResult [capture_stdout "stat"]
        set combnum [Get_Comb_cells $StatResult $RULEID]

        if {$combnum !=0} {
            #found combinatorial => exit
            puts "$RULEID>Stage $stagenum> VIOLATION on $SigToAnalyze"
            break
        }
    }
}

#clear select
yosys select -clear
