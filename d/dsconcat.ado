#delim ;
prog def dsconcat,rclass;
version 7.0;
/*
 Concatenate a sequence of data sets (or subsets of data sets) into the memory,
 optionally creating additional variables identifying, for each obs,
 the data set from which that obs originated
 and/or the sequential order of that obs within its original data set.
*! Author: Roger Newson
*! Date: 14 August 2003
*/

*
 Extract file list and leave command line ready to be syntaxed
*;
local dslist "";
gettoken dscur 0 : 0,parse(", ") quotes;
while `"`dscur'"'!="" & `"`dscur'"'!="," {;
  local dslist `"`dslist' `dscur'"';
  gettoken dscur 0 : 0,parse(" ,") quotes;
};
local 0 `", `0'"';
local ndset:word count `dslist';
if `ndset'<=0 {;
  disp as error "No input data sets have been specified";
  error 498;
};

* Crack syntax of rest of input line *;
syntax [ , DSId(string) DSName(string) OBSseq(string) noLabel noLDsid SUBset(string asis) ];
/*
 -dsid- is name of new integer variable containing data set ID,
  with value label of the same name if possible, specifying data set names.
 -dsname- is name of new string variable containing data set names.
 -obsseq- is name of new integer variable
  containing sequential order of obs within original data set.
 -nolabel- specifies that labels are not to be copied
  from the input data sets.
 -noldsid- specifies that the -dsid- variable will not have value labels
  (this is useful if the input datasets are numerous and/or repeated
  and/or have incomprehensible -tempfile- names).
 -subset- specifies a subset string
  (ie a combination of -varlist-, -if- clause and -in- clause,
  allowing the user to select a subset of variables and/or observations
  from each of the input data sets to be concatenayed).
*/

preserve;

*
 Create intermediate input data set list
 creating temporary data sets for concatenation if if-list is specified
*;
if `"`subset'"'=="" {;
  local idslist `"`dslist'"';
};
else {;
  local idslist "";
  forv i1=1(1)`ndset' {;
    local dscur:word `i1' of `dslist';
    tempfile ids`i1';
    cap use `subset' using `"`dscur'"',clear `label';
    if _rc!=0 {;
      disp as error "Error reading input data set: " as result `"`dscur'"'
       _n as error "Subset string: " as result `"`subset'"';
      cap noi use `viilist' using `"`dscur'"',clear `label';
      error 498;
    };
    qui save `ids`i1'';
    local idslist `"`idslist' `ids`i1''"';
  };
};

*
 Define temporary variables
 (to be created and renamed to corresponding options
 if and only if none of the input data sets
 contain a variable of the same name)
*;
tempvar dsidt dsnamet obsseqt;

*
 Concatenate input data sets in list
*;
* Input first data set *;
local dscur:word 1 of `dslist';
local idscur:word 1 of `idslist';
qui use `"`idscur'"',clear `label';
* Create newvar options if requested *;
if `"`dsid'"'!="" {;
  qui {;
    gene long `dsidt'=1;
    lab var `dsidt' "Input data set";
  };
};
if `"`dsname'"'!="" {;
  qui {;
    gene str1 `dsnamet'="";
    replace `dsnamet'=`"`dscur'"';
    lab var `dsnamet' "Input data set name";
  };
};
if `"`obsseq'"'!="" {;
  qui {;
    gene long `obsseqt'=_n;
    lab var `obsseqt' "Observation sequence in input data set";
  };
};
local nobs=_N;
* Append other data sets *;
forv i1=2(1)`ndset' {;
  local dscur:word `i1' of `dslist';
  local idscur:word `i1' of `idslist';
  qui append using `"`idscur'"',`label';
  local nobsp=`nobs'+1;
  if `"`dsid'"'!="" {;
    qui replace `dsidt'=`i1' in `nobsp'/l;
  };
  if `"`dsname'"'!="" {;
    qui replace `dsnamet'=`"`dscur'"' in `nobsp'/l;
  };
  if `"`obsseq'"'!="" {;
    qui replace `obsseqt'=_n-`nobs' in `nobsp'/l;
  };
  local nobs=_N;
};

*
 Compress temporary variables
 and rename them to the corresponding user-supplied options if possible
*;
foreach V in dsid dsname obsseq {;
  if `"``V''"'!="" {;
    qui compress ``V't';
    rename ``V't' ``V'';
  };
};

* Create value label for -dsid- if required *;
if `"`dsid'"'!="" & "`ldsid'"!="noldsid" {;
  forv i1=1(1)`ndset' {;
    local dscur:word `i1' of `dslist';
    cap lab def `dsid' `i1' `"`dscur'"',add;
  };
  lab val `dsid' `dsid';
};

restore,not;

return scalar ndset=`ndset';
return scalar nobs=`nobs';

end;
