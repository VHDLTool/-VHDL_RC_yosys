# See https://ghdl.readthedocs.io/en/stable/using/QuickStartGuide.html
#build GHDL project in build_dir
#
#call this script with ./build.sh top
#then go into build_dir folder and execute yosys -m ghdl 
#inside yosys inport project with yosys> ghdl top 

files_regex=".*\.\(vhdl\|vhd\)"
mkdir build_dir
cd build_dir

ghdl --clean
ghdl -a $2 `find ../ -regex $files_regex| tr '\n' ' '`
ghdl -e $2 $1
