#!/bin/bash

set -e
set -o pipefail
# set -o xtrace

expected_header=$(head -n 16 .github/workflows/license.txt)
error_code=0
files_with_erroneous_header=''

for f in $(find ./scripts -name '*.tcl' -or -name '*.yosys'); do
  if [[ $(head -n 16 $f) != $expected_header ]]; then
    files_with_erroneous_header+="$f\n"
    error_code=1
  fi
done

 if [[ error_code != $0 ]]; then
   printf "Files with erroneous header:\n"
   printf "$files_with_erroneous_header"
 fi

exit $error_code
