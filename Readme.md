# VHDL RuleChecker for synthesis
This repository store the proof of concept for implementation of VHDL Ruleset ([Standard](https://github.com/VHDLTool/VHDL_Handbook_CNE/releases) and [CNES](https://github.com/VHDLTool/VHDL_Handbook_CNE/releases)).
It includes a collection of yosys and TCL scripts made to check compliance with several rules.
This scripts can be run with tabbycad (using verific parser inside yosys) or osscad (with the help of GHDL plugin for yosys).
These scripts should work with verilog also even it they are not tested.   

This is still a work in progress algorithm might change.

## Example
Script use example can be found in the TESTS folder. For example (when using tabbycad-yosys with verific):
1.  go to `./TESTS/FSM/I2c/` 
2. launch yosys
3. execute `script I2C_slave.yoys`   

When using ghdl :
1.  go to `./TESTS/FSM/I2c/` 
2. execute `./build.sh`
3. go into `build_dir` folder
4. launch yosys with `yosys -m ghdl` (if ghdl is built as an external module or simply `yosys` if not)
5. in yosys do:
-  `ghdl`
-  `tcl ../../../Rule_FSM.yosys.tcl`

## License
The scripts are published under the GNU GPLv3 license, available in the LICENSE file.