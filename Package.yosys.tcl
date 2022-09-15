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



#this function return the list of clock in the current module selection
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
  return [lindex $Listcleaned 1 end]
  
}

