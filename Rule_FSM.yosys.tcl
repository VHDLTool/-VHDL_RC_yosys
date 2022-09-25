#-------------------------------------------------------------------------------------------------
#-- Company   : CNES
#-- Author    : Florent Manni (CNES)
#-- Copyright : Copyright (c) CNES.
#-- Licensing : GNU GPLv3
#-------------------------------------------------------------------------------------------------
#-- Version         : V1
#-- Version history :
#--    V1 : 2022-09-21 : Florent Manni (CNES): Creation
#-------------------------------------------------------------------------------------------------
#-- Description : This is not a direct rule but a main algorithm used by other rules.
#--               It look for all FSM in the elaborated design
#--               It return a list of FSMs exposed as a list including:
#--                        - state machine signal name
#--                        - state machine module instanciation name
#--                        - name of the file including the state machine
#--
#-- Execution  : execute in yosys (after elaboration of a design) with yosys>tcl Rule_FSM.tcl
#--
#-- Limitations : the way the Package.yosys.tcl script path is namaged should be improved
#--               This script do soe synthesys pass , therefore the design is altered, it is adviced
#--               To reload the project from the ground to avoid strange behavior due to synthesis.
#--
#-------------------------------------------------------------------------------------------------

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

#debug
#puts "argument count: $argc"
#puts "argument 0: [lindex $argv 0]"
#puts "script name: $argv0"


#display banner
puts "$RULEID> Evaluating $RULEID Rule"
#get state machine info
#it return a list of ( list of state machine name , module patch , file)
set SMlist [Get_statemachines]

foreach ListElmt $SMlist {
    puts "RULE_FSM> Found State machine [lindex $ListElmt 0] in module [lindex $ListElmt 1] from file [lindex $ListElmt 2]"
}

#clear selection
yosys select -clear
