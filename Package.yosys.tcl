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
      puts "$RuleId> Found pattern: $ListElmt"

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


##this function calculate the number of combinatorial elements in a stat log
proc Get_Comb_cells {StatResult RuleId} {
   global CELLPATTERN
   global BUFPATTERN
   global POSPATTERN
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

#combinatorial cell evaluation
set combnum [expr $cellnum - $bufnum -$posnum]
puts "$RuleId> Found $combnum combinatorial cells"

return [expr $combnum]
}

#this function return the list of clock in the current module selection
## FIXME be careful that for now Yosys script for clock call 2 times stat
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
