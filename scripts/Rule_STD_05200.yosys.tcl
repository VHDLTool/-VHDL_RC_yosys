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
#-- Description : evaluate rule "STD_05200:Output signal registration" for one signal output passed as parameter
#--
#-- Execution  : execute in yosys (after design elaboration) with
#--              yosys> STD_05200.yosys <MysignalNameToAnalyze>
#--
#-- Limitations : the way the Package.yosys.tcl script path is namaged should be improved
#--               This script do soe synthesys pass , therefore the design is altered, it is adviced
#--               To reload the project from the ground to avoid strange behavior due to synthesis.
#--
#--               There is no check made to verify if signal exists or is really an ouptut
#-------------------------------------------------------------------------------------------------

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

#debug
#puts "argument count: $argc"
#puts "argument 0: [lindex $argv 0]"
#puts "script name: $argv0"

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
