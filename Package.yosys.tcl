##########Global definitions#######################
#script file location
set PACKAGEPATH [file dirname  [info script]]

#Yosys general script command file name
set YOSYSSCRIPTNAME  Script_list.yosys

#pattern to find cells in yosys stat command
set CELLPATTERN "Number of cells:"

#pattern to find buffers cells in yosys stat command
set BUFPATTERN "BUF"

#pattern to find pos cells in yosys stat command
set POSPATTERN "pos"

#pattern to find flipflops in stat commands
set FFPATTERN "ff"

################################################


#######################Global variable############
#yosys script name with path
set YOSYSSCRIPTNAMEPATH $PACKAGEPATH/$YOSYSSCRIPTNAME

##################################################


#This function capture output from Yosys in a temp file
#and expose the content to TCL
#https://github.com/YosysHQ/yosys/issues/2980
proc capture_stdout {args} {    
    #open a tmpfile.
    set temp [exec mktemp]

    #Run the yosys command
    yosys tee -o $temp {*}$args

    #read the temp file
    set response [open $temp r]
    set retval [read $response]
    close $response
    
    #Cleanup
    file delete $temp

    #return what we read
    return $retval
}

#This function get the value from a table
# the search is made by Line 
# first we look for a pattern
# then we get the value after the table separator
proc Get_Yosys_Table_value {TextList TextPattern TextSeparator RuleId} {

set ResValue 0

foreach ListElmt $TextList {
   if {[string first $TextPattern $ListElmt]!= -1} {
      #puts "$RuleId> Found pattern: $ListElmt"

      #separator for table is space
      switch $TextSeparator {

         ":" { #separator is :
            #remove space seprator
            set CellField [string map {" " ""} $ListElmt];
            #split by :
            set SplitCellField [split $CellField :]
            set ResValuePat [expr [lindex $SplitCellField 1]]
         }

         " " {#separator is space
            #split by space
            set SplitCellField [regexp -all -inline {\S+} $ListElmt ]
            set ResValuePat [expr [lindex $SplitCellField 1]]
         }
      }
      # add result to previous one (in case of multiple pattern hits)
      set ResValue [expr {$ResValue + $ResValuePat}]
   }
}
return $ResValue
}
########################################################################################

##this function calculate the number of combinatorial elements in a stat log
proc Get_Comb_cells {StatResult RuleId} {
   global CELLPATTERN
   global BUFPATTERN
   global POSPATTERN
   global FFPATTERN
#split the result table  by line
set SplitStatResult [split $StatResult \n]

#search cells numbers in stat
set cellnum [Get_Yosys_Table_value $SplitStatResult $CELLPATTERN ":" $RuleId]
puts "$RuleId> Found $cellnum cells"

#search buf numbers in stat
set bufnum [Get_Yosys_Table_value $SplitStatResult $BUFPATTERN " " $RuleId]
puts "$RuleId> Found $bufnum buffers cells"

#search pos numbers in stat
set posnum [Get_Yosys_Table_value $SplitStatResult $POSPATTERN " " $RuleId]
puts "$RuleId> Found $posnum pos cells"

#search flipflop  numbers in stat
set ffnum [Get_Yosys_Table_value $SplitStatResult $FFPATTERN " " $RuleId]
puts "$RuleId> Found $ffnum flipflops "

#combinatorial cell evaluation
set combnum [expr $cellnum - $bufnum -$posnum -$ffnum]
puts "$RuleId> Found $combnum combinatorial cells"

return [expr $combnum]
}

#this function return the list of clock in the current module selection
## FIXME be careful that for now Yosys script for clock call 2 times stat looking for two differents way of signaling clocks
## the yosys script should be modified to make only one call to stat (so use stack to store select results)
proc Get_Clocks {} {
  global YOSYSSCRIPTNAMEPATH
  #use yosys script to get clock list
  set CmdResult [capture_stdout "script" "$YOSYSSCRIPTNAMEPATH" "clocks"]

  #split by line
  set SplitCmdResult [split $CmdResult \n]

   #remove empty fields
   set Listcleaned {}
   foreach ListElmt $SplitCmdResult {
      if {$ListElmt!={}} {
         lappend Listcleaned $ListElmt
      }
   }
      
  #remove header line -- Executing script file `../Script_list.yosys' --
  return [lrange $Listcleaned 1 end]
  
}

#this function return the list of outputs in the current module selection
proc Get_outputs {} {
  global YOSYSSCRIPTNAMEPATH
  #use yosys script to get clock list
  set CmdResult [capture_stdout "script" "$YOSYSSCRIPTNAMEPATH" "output"]

  #split by line
  set SplitCmdResult [split $CmdResult \n]

   #remove empty fields
   set Listcleaned {}
   foreach ListElmt $SplitCmdResult {
      if {$ListElmt!={}} {
         lappend Listcleaned $ListElmt
      }
   }

  #remove header line -- Executing script file `../Script_list.yosys' --
  return [lrange $Listcleaned 1 end]
}

#this function return the list of outputs in the current module selection
proc Get_inputs {} {
  global YOSYSSCRIPTNAMEPATH
  #use yosys script to get clock list
  set CmdResult [capture_stdout "script" "$YOSYSSCRIPTNAMEPATH" "input"]

  #split by line
  set SplitCmdResult [split $CmdResult \n]

   #remove empty fields
   set Listcleaned {}
   foreach ListElmt $SplitCmdResult {
      if {$ListElmt!={}} {
         lappend Listcleaned $ListElmt
      }
   }

  #remove header line -- Executing script file `../Script_list.yosys' --
  return [lrange $Listcleaned 1 end]
}


#this function return the list of state machine in the design
proc Get_statemachines {} {
   global YOSYSSCRIPTNAMEPATH

   #execute cmd script fsm
   set yosyscmd "script $YOSYSSCRIPTNAMEPATH fsm"
   eval capture_stdout $yosyscmd
   puts "FSM>yosys> script $YOSYSSCRIPTNAMEPATH fsm"

   #get log about FSM
   set FsmResult [capture_stdout "fsm_detect"]

   #split result by line
   set SplitFsmResult [split $FsmResult \n]

   #look for ignored FSM
   #example line
   #             Not marking mealy_4s.sm_state_mealy as FSM state register: 
   foreach FsmElmt $SplitFsmResult {
      if {[string first "Not marking " $FsmElmt]!= -1} {
         #found state machine ignored
         puts "FSM> Found \" $FsmElmt\""

         #split by space and get the 3rd word
         set SMName [split $FsmElmt " "]
         set SMName [lindex $SMName 2]

         #Change . extender to / (recognized by yosys)
         set SMName [string map {. /} $SMName]

         #force FSM encoding
         yosys "setattr" "-set" "fsm_encoding" "\"auto\"" $SMName
         puts "FSM>yosys> setattr -set fsm_encoding \"auto\" $SMName"
      }
   }

   #extract FSM
   set FsmResult [capture_stdout "fsm_extract"]
   puts "FSM>yosys> fsm_extract"

   #split by line
   set SplitFsmResult [split $FsmResult \n]

   #search for state machine names and path
   #in this search FSM extraction log comes just before state register filename
   set ListFSM {} 
   set CurrentFSM {}
   foreach FsmElmt $SplitFsmResult {
      #search for state machine name and module
      #example line : 
      #                 Extracting FSM `\sm_state_mealy' from module `\mealy_4s'.
      #
      if {[string first "Extracting FSM " $FsmElmt]!= -1} {

         #this is the beginning of a state machine log block 
         #check if current fsm is empty (otherwise save it)
         if { [llength $CurrentFSM] != 0} {
            puts "FSM> Warning: Found State machine [lindex $CurrentFSM 0] in module [lindex $CurrentFSM 1] from file UNKNOWN"   
            lappend ListFSM $CurrentFSM

            #reset current fsm
            set CurrentFSM {}
         }


         puts "FSM> Found \" $FsmElmt\""
         #yosys log file mix ` and ' replace `
         set FsmElmt [string map {`\\ '} $FsmElmt]

         #split by '
         set SMName [split $FsmElmt "'"]
         #get 2nd and 4th element
         set StateMachineName [lindex $SMName 1]
         set StateMachineModule [lindex $SMName 3]
         lappend CurrentFSM $StateMachineName $StateMachineModule    
      }

      #search for file name 
      #example line (from verific):
      #                  found $adff cell for state register: $verific$sm_state_mealy_reg$./FSM/mealy_4s.vhd:65$25  
      #example line from GHDL
      #                 
      #
      if {[string first "for state register: " $FsmElmt]!= -1} {
         #found state machine log
         puts "FSM> Found \"$FsmElmt\""
         #split by space and get the last word
         set SMName [split $FsmElmt " "]
         set SMName [lindex $SMName end]

         #check if parser is verific
         if {[string first "\$verific\$" $FsmElmt]!= -1} {
            puts "FSM> Verific Parser Detected"
            
            #split by :
            set FsmElmt [split $FsmElmt ":"]

            #take the one before end element
            set FsmElmt [lindex $FsmElmt end-1]

            #split by .
            set FsmElmt [split $FsmElmt "."]

            #get the last 2 elements 
            set FsmElmt [lindex $FsmElmt end-1].[lindex $FsmElmt end]

            #add to result list
            lappend CurrentFSM .$FsmElmt

            #add discovered state machines
            if { [llength $CurrentFSM] == 3} { 
               lappend ListFSM $CurrentFSM

               #reset current fsm
               set CurrentFSM {}
            }
         }
         #### TODO add else if parser is ghdl


      }
   }

   #save last current (in case filename not found)
            #check if current fsm is empty (otherwise save it)
   if { [llength $CurrentFSM] != 0} {
      puts "FSM>Warning : Found State machine [lindex $CurrentFSM 0] in module [lindex $CurrentFSM 1] from file UNKNOWN"   
      lappend ListFSM $CurrentFSM

      #reset current fsm
      set CurrentFSM {}
   }
   return $ListFSM
}