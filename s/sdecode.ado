#delim ;
program define sdecode;
version 9.0;
/*
  Decode an input numeric variable to an output string variable,
  which may be new or replace the input variable,
  optionally replacing unlabelled input values with formatted values.
*! Author: Roger Newson
*! Date: 20 February 2007
*/

syntax varname(numeric) [if] [in] , [ Generate(string) replace MAXLength(string) FORMat(string) LABOnly Missing
  PRefix(string) SUffix(string) ];
/*
  -generate()- is a new output string variable.
  -replace- specifies that the output string variable will replace the input numeric variable.
  -maxlength- is the maximum length of the output string variable.
  -format- is a string or string variable name specifying the format
    used to define output string variable values
    corresponding to unlabelled input numeric variable values.
  -labonly- specifies that only labelled values are to be decoded.
  -missing- specifies that missing values will be decoded (using formats).
  -prefix- specifies a prefix string (to be added on the left).
  -suffix- specifies a suffix string (to be added on the right).
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

*
 Initialise -maxlength- if absent
 and check that -maxlength- is legal otherwise
*;
local maxmaxl=c(maxstrvarlen);
if "`maxlength'"=="" {;
  local maxlength=`maxmaxl';
};
else {;
  cap confirm integer number `maxlength';
  if _rc!=0 {;
    disp as error "option maxl() incorrectly specified";
    error 198;
  };
  if `maxlength'<1 | `maxlength'>`maxmaxl' {;
    disp as error "maxlength() must be between 1 and `maxmaxl' in this form of Stata";
    error 198;
  };
};

* Initialise -format- if absent *;
if "`format'"=="" {;
  local format:format `varlist';
};

preserve;

marksample touse, novarlist;

*
 Decode labelled values (and unlabelled values if specified)
*;
cap decode `varlist' if `touse', gene(`generate') maxlength(`maxlength');
if _rc!=0 {;
  * -decode- may have failed because no value label is present *;
  qui gene str1 `generate'="";
  local Glab: var lab `varlist';
  lab var `generate' `"`Glab'"';
};
if "`labonly'"=="" {;
  cap confirm string variable `format';
  if _rc==0 {;
    * -format()- is a string variable *;
    qui replace `generate'=substr(string(`varlist',`format'),1,`maxlength') if `touse' & missing(`generate');
  };
  else {;
    * -format()- is a format *;
    qui replace `generate'=substr(string(`varlist',"`format'"),1,`maxlength') if `touse' & missing(`generate');
  };
  if "`missing'"=="" {;qui replace `generate'="" if `touse' & missing(`varlist');};
};
qui compress `generate';

*
 Add prefix and/or suffix if specified
*;
if `"`prefix'"'!="" {;
  qui replace `generate'=`"`prefix'"'+`generate' if `touse';
};
if `"`suffix'"'!="" {;
  qui replace `generate'=`generate'+`"`suffix'"' if `touse';
};

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

restore, not;

end;
