#delim ;
program define sencode;
version 7.0;
/*
 Sequentially encode string label -varname- into -generate-
 encoding in order of appearance,
 using variable label -label'- if specified
 (like encode,
 except that the codes are in order of appearance in the data set
 instead of in alphabetical order).
*! Author: Roger Newson
*! Date: 09 February 2004
*/
syntax varname(string) [if] [in] , [ Generate(string) replace Label(string) * ];
/*
  -generate- is the name of the new coded variable to be generated.
  -replace- specifies that the new coded variable will replace the input string variable.
  -label- is the name of a variable label to be used (and added to if necessary).
*/

*
 Check that either -generate- or -replace- is present (but not both)
 and initialise -generate- accordingly
 *;
if "`replace'"!="" {;
  if "`generate'"!="" {;
    disp as error "options generate() and replace are mutually exclusive";
    error 198;
  };
  * Save old variable order *;
  unab oldvars: *;
  tempvar generate;
};
else {;
  if "`generate'"=="" {;
    disp as error "must specify either generate() or replace option";
    error 198;
  };
  confirm new variable generate;
};

* Initialize -label- if absent *;
if("`label'"==""){;
  if "`replace'"!="" {;
    local label "`varlist'";
  };
  else {;
    local label "`generate'";
  };
};

preserve;

*
 Call _sencode to do the work involving sorting and resorting
 (which should be protected by -sortpreserve-)
*;
_sencode `varlist' `if' `in' , generate(`generate') label(`label') `options';

*
 Replace input string variable with generated coded variable
 if -replace- is specified
*;
if "`replace'"!="" {;
  char rename `varlist' `generate';
  drop `varlist';
  rename `generate' `varlist';
  order `oldvars';
};

restore,not;

end;

program define _sencode, sortpreserve;
version 7.0;
/*
 Execute the middle parts of the -sencode- process,
 involving sorting and resorting of data
 (which should be protected by -sortpreserve-).
*/
syntax varname(string) [if] [in] , Generate(string)
  [ Label(string) GSort(string) MANyto1 ];
/*
  -generate- is the name of the new coded variable to be generated.
  -label- is the name of a variable label to be used (and added to if necessary).
  -gsort- specifies the order in which numbers are allocated to the labels.
  -manyto1- specifies that the mapping from string values to encoded numeric values
   can be many-to-one (so repeated string values have multiple codes).
*/

marksample touse,strok;

* Name of input string variable *;
local inputstr "`varlist'";

* Ensure that -label- exists (and is possibly empty) *;
tempvar generate2;
encode `inputstr' if 0,gene(`generate2') label(`label');
drop `generate2';

*
 Find old maximum value for -label-
*;
tempfile labf;
qui lab save `label' using `"`labf'"',replace;
tempname inf;
file open `inf' using `"`labf'"', r;
file read `inf' curline;
if `"`curline'"'!="" {;local lastline `"`curline'"';};
while r(eof)==0 {;
  file read `inf' curline;
  if `"`curline'"'!="" {;local lastline `"`curline'"';};
};
local ovalmax : word 4 of `lastline';
if `"`ovalmax'"'=="" {;local ovalmax=0;};

* Set -gsort- to default value if missing *;
if `"`gsort'"'=="" {;local gsort "`_sortindex'";};

*
 Group observations
 and define first version of new variable -generate-
 (with groups numbered from maximum existing code + 1
 to maximum existing code + number of possible new codes)
*;
gsort `touse' `gsort' `inputstr',gene(`generate');
if "`manyto1'"=="" {;
  * One-to-one mapping from codes to string labels *;
  sort `touse' `inputstr' `generate' `_sortindex';
  qui by `touse' `inputstr':replace `generate'=`generate'[1];
  gsort `touse' `generate',gene(`generate2');
  qui replace `generate'=`generate2';
  drop `generate2';
};
sort `_sortindex';
qui summ `generate' if `touse';
if r(N)>0 {;
  qui replace `generate'=`generate'-r(min)+1+`ovalmax' if `touse';
};
qui replace `generate'=. if !`touse';

*
 Create new value labels
 and final version of new variable -generate-
*;
qui summ `generate' if `touse';
if r(N)>0 {;
  local genmin=r(min);
  local genmax=r(max);
  if "`manyto1'"=="" {;
    * One-to-one mapping from codes to string labels *;
    forv i1=`genmin'(1)`genmax' {;
      encode `inputstr' if `generate'==`i1',label(`label') gene(`generate2');
      drop `generate2';
    };
    drop `generate';
    encode `inputstr' if `touse',label(`label') gene(`generate');
  };
  else {;
    * Many-to-one mapping from codes to string labels *;
    forv i1=`genmin'(1)`genmax' {;
      qui summ `_sortindex' if `generate'==`i1';
      local i2=r(min);
      local labcur=`inputstr'[`i2'];
      *
       Add leading blanks to label if necessary.
       (This bug fix was added to deal with non-missing blank labels
       by Roger Newson on 9 June 2003.)
      *;
      local nlblanks=length(`inputstr'[`i2'])-length(`"`labcur'"');
      local lblanks "";
      forv i3=1(1)`nlblanks' {;local lblanks "_`lblanks'";};
      local lblanks:subinstr local lblanks "_" " ",all;
      label define `label' `i1' `"`lblanks'`labcur'"',add;
    };
  };
};
qui compress `generate';
lab val `generate' `label';
local inputlab:var lab `inputstr';
lab var `generate' `"`inputlab'"';

end;
