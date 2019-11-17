#delim ;
prog def listtex;
version 8.0;
*
 List the variables in -varlist- as a table
 to the file in -using- and/or to the Stata log
 with a value delimiter string
 and (optionally) a begin-line and/or end-line string.
 This program is mainly intended to output data to a file
 which is then input into a TeX table,
 in which case the value delimiter is usually "&"
 and the line terminator is usually "\cr".
*! Author: Roger Newson
*! Date: 19 May 2004
*;

syntax [varlist (min=1)] [using/] [if] [in]
 [, Begin(string) Delimiter(string) End(string) Missnum(string)
  RStyle(string)
  HEadlines(string asis) FOotlines(string asis)
  noLabel Type REPLACE APpendto(string asis) HAndle(name) ];
*
  -varlist- specifies variables to be written to output file.
  -using- specifies output file.
  -begin()- is string at beginning of each obs
    (set to "" if absent).
  -delimiter()- is delimiter for separating values of same obs
    (set in default to "&").
  -end()- is string at end of each obs
    (set to "" if absent).
  -missnum()- is string code for missing numeric value
    (defaulting to empty string if absent)
  -rstyle()- is a row style
    (a named combination of -begin-, -end-, -using- and -missnum-)
  -headlines()- is a list of head lines to be added to the -using- file
  -footlines()- is a list of foot lines to be added to the -using- file
  -nolabel- specifies that numeric variables with value labels
    must be output as numbers and not as value labels.
  -type- specifies that the output file must be typed to the Stata log.
  -replace- specifies that any pre-existing file
    with the same name as the -using- file must be overwritten.
  -appendto()- specifies the name of a file not currently open,
    to which the variables (and headlines and footlines if specified)
    will be written, closing the file at the end of execution.
  -handle()- specifies a handle of a file currently open
    as a text file in write mode (using the -file open- command),
    to which the variables (and headlines and footlines if specified)
    will be written, leaving the file open at the end of execution,
    so that further output can be added using the -file- command.
*;

* Check that the user has specified either -using-, -type-, -appendto()- or -handle()- *;
if (`"`using'"'=="")&("`type'"=="")&(`"`appendto'"'=="")&("`handle'"=="") {;
  disp as error "You must specify using and/or type and/or appendto() and/or handle()."
    _n "If type is specified, then data are typed to the Stata log."
    _n "If using is specified, then data are output to a file."
    _n "If appendto() is specified, then data are appended to a file."
    _n "If handle() is specified, then data are added to a file already open with that handle.";
  error 498;
};

* Default output file *;
if "`using'"=="" {;
  tempfile tf0;
  local using `"`tf0'"';
};

* Interpret row styles *;
if `"`rstyle'"'=="html" {;
  if `"`begin'"'=="" {;local begin "<tr><td>";};
  if `"`delimiter'"'=="" {;local delimiter "</td><td>";};
  if `"`end'"'=="" {;local end "</td></tr>";};
};
else if `"`rstyle'"'=="htmlhead" {;
  if `"`begin'"'=="" {;local begin "<tr><th>";};
  if `"`delimiter'"'=="" {;local delimiter "</th><th>";};
  if `"`end'"'=="" {;local end "</th></tr>";};
};
else if `"`rstyle'"'=="tabular" {;
  if `"`delimiter'"'=="" {;local delimiter "&";};
  if `"`end'"'=="" {;local end "\\\\";};
};
else if `"`rstyle'"'=="halign" {;
  if `"`delimiter'"'=="" {;local delimiter "&";};
  if `"`end'"'=="" {;local end "\cr";};
};
else if `"`rstyle'"'=="settabs" {;
  if `"`begin'"'=="" {;local begin "\+";};
  if `"`delimiter'"'=="" {;local delimiter "&";};
  if `"`end'"'=="" {;local end "\cr";};
};
else if `"`rstyle'"'=="tabdelim" {;
  if `"`delimiter'"'=="" {;local delimiter=char(9);};
};
else if `"`rstyle'"'!="" {;
  disp as text "Unrecognised row style: " as result `"`rstyle'"';
  disp as text "Default row style used instead";
};

* Default delimiter *;
if `"`delimiter'"'=="" {;local delimiter "&";};

local nvar:word count `varlist';

marksample touse,novarlist strok;

*
 Create temporary variables
 containing begin, delimiter and end strings
*;
tempvar beginv delimv endv;
qui{;
  gene str1 `beginv'="";
  gene str1 `delimv'="";
  gene str1 `endv'="";
  replace `beginv'=`"`begin'"' if `touse';
  replace `delimv'=`"`delimiter'"' if `touse';
  replace `endv'=`"`end'"' if `touse';
};

*
 Create list of output variables
*;
local ovarlist "`beginv'";
forvalues i1=1(1)`nvar' {;
  local vari1:word `i1' of `varlist';
  local typei1:type `vari1';
  if substr("`typei1'",1,3)=="str" {;
    * String variable - do not convert *;
    local ovarlist "`ovarlist' `vari1'";
  };
  else {;
    * Numeric variable - convert to temporary string variable *;
    tempvar sv`i1';
    local vli1:value label `vari1';
    if ("`label'"!="nolabel")&("`vli1'"!="") {;
      qui decode `vari1',gene(`sv`i1'');
    };
    else{;
      local fmti1:format `vari1';
      qui gene str1 `sv`i1''="";
      qui replace `sv`i1''=string(`vari1',"`fmti1'") if `touse';
      qui replace `sv`i1''=`"`missnum'"' if `touse' & missing(`vari1');
    };
    local ovarlist "`ovarlist' `sv`i1''";
  };
  * Append delimiter or end *;
  if `i1'==`nvar' {;local ovarlist "`ovarlist' `endv'";};
  else {;local ovarlist "`ovarlist' `delimv'";};
};

* Output to file *;
outfile `ovarlist' using `using' if `touse',runtogether `replace';

* Add headlines and footlines if requested *;
local nhead:word count `headlines';
local nfoot:word count `footlines';
if `nhead'>0 | `nfoot'>0 {;
  tempfile tempusing;
  tempname tuhandle uhandle;
  file open `tuhandle' using `tempusing',write text;
  forv i1=1(1)`nhead' {;
    local linecur:word `i1' of `macval(headlines)';
    file write `tuhandle' `"`macval(linecur)'"' _n;
  };
  file open `uhandle' using `using',read;
  file read `uhandle' linecur;
  while r(eof)==0 {;
    file write `tuhandle' `"`macval(linecur)'"' _n;
    file read `uhandle' linecur;
  };
  file close `uhandle';
  forv i1=1(1)`nfoot' {;
    local linecur:word `i1' of `macval(footlines)';
    file write `tuhandle' `"`macval(linecur)'"' _n;
  };
  file close `tuhandle';
  copy `tempusing' `using',replace;
};

* Append to a file if -appendto()- is requested *;
if `"`appendto'"'!="" {;
  tempname aphandle uhandle;
  file open `aphandle' using `appendto', write append text;
  file open `uhandle' using `using', read;
  file read `uhandle' linecur;
  while r(eof)==0 {;
    file write `aphandle' `"`macval(linecur)'"' _n;
    file read `uhandle' linecur;
  };
  file close `uhandle';
  file close `aphandle';
};

* Add to an already open text file if -handle()- is requested *;
if "`handle'"!="" {;
  tempname uhandle;
  file open `uhandle' using `using', read;
  file read `uhandle' linecur;
  while r(eof)==0 {;
    file write `handle' `"`macval(linecur)'"' _n;
    file read `uhandle' linecur;
  };
  file close `uhandle';
};

* Type to the Stata log if requested *;
if "`type'"!="" {;type `"`using'"';};

end;
