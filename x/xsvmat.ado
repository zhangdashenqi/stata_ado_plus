#delim ;
prog def xsvmat;
version 10.0;
/*
  Extended version of svmat
  producing a resultssset and (optionally) extra variables.
*!Author: Roger B. Newson
*!Date: 02 Aprilh 2009
*/

syntax anything(id="input matrix specification")  [ ,
  LIst(string asis) SAving(string asis) noREstore FAST FList(string)
  IDNum(string) NIDNum(name) IDStr(string) NIDStr(name)
  ROWEq(name) ROWNames(name) ROWLabels(name)
  FOrmat(string)
  *
  ];
/*

Output-destination options:

-list- contains a varlist of variables to be listed,
  expected to be present in the output data set
  and referred to by the new names if REName is specified,
  together with optional if and/or in subsetting clauses and/or list_options
  as allowed by the list command.
-saving- specifies a data set in which to save the output data set.
-norestore- specifies that the pre-existing data set
  is not restored after the output data set has been produced
  (set to norestore if FAST is present).
-fast- specifies that -xsvmat- will not preserve the original data set
  so that it can be restored if the user presses Break
  (intended for use by programmers).
  The user must specify at least one of the four options
  list, saving, norestore and fast,
  because they specify whether the output data set
  is listed to the log, saved to a disk file,
  written to the memory (destroying any pre-existing data set),
  or multiple combinations of these possibilities.
-flist- is a global macro name,
  belonging to a macro containing a filename list (possibly empty),
  to which -xsvmat- will append the name of the data set
  specified in the SAving() option.
  This enables the user to build a list of filenames
  in a global macro,
  containing the output of a sequence of model fits,
  which may later be concatenated using dsconcat (if installed) or append.

Output-variable options:

-idnum- is an ID number for the output data set,
  used to create a numeric variable idnum in the output data set
  with the same value for all observations.
  This is useful if the output data set is concatenated
  with other output data sets using -dsconcat- (if installed) or -append-.
-nidnum- specifies a name for the numeric ID variable (defaulting to -idnum-).
-idstr- is an ID string for the output data set,
  used to create a string variable (defaulting to -idstr-) in the output data set
  with the same value for all observations.
-nidstr- specifies a name for the numeric ID variable (defaulting to -idstr-).
-roweq- specifies a name for a new variable containing row equations.
-rownames- specifies the name of a new variable containing row names.
-rowlabels- specifies the name of a new variable containing row labels.
-format- contains a list of the form varlist1 format1 ... varlistn formatn,
  where the varlists are lists of variables in the output data set
  and the formats are formats to be used for these variables
  in the output data sets.

*/


*
 Extract type and input matrix name
*;
local nargs: word count `anything';
if `nargs'<=0 | `nargs'>2 {;
  error 198;
};
else if `nargs'==2 {;
  local type: word 1 of `anything';
  local A: word 2 of `anything';
};
else {;
  local type "float";
  local A: word 1 of `anything';
};


*
 Set restore to norestore if fast is present
 and check that the user has specified one of the four options:
 list and/or saving and/or norestore and/or fast.
*;
if "`fast'"!="" {;
    local restore="norestore";
};
if (`"`list'"'=="")&(`"`saving'"'=="")&("`restore'"!="norestore")&("`fast'"=="") {;
    disp as error "You must specify at least one of the four options:"
      _n "list(), saving(), norestore, and fast."
      _n "If you specify list(), then the output variables specified are listed."
      _n "If you specify saving(), then the new data set is output to a disk file."
      _n "If you specify norestore and/or fast, then the new data set is created in the memory,"
      _n "and any existing data set in the memory is destroyed."
      _n "For more details, see {help xsvmat:on-line help for xsvmat}.";
    error 498;
};


*
 Store variable labels in macros with names of form labi1
 if rowlabels() requested
*;
if "`rowlabels'" != "" {;
        local xvlist : rownames(`A');
        local nxv : word count `xvlist';
        local i1 = 0;
        while `i1' < `nxv' {;
                local i1 = `i1' + 1;
                local xvcur : word `i1' of `xvlist';
                local lab`i1' "";
                if `"`xvcur'"'=="_cons" {;
                    local lab`i1' "Constant";
                };
                else {;
                    capture local lab`i1' : variable label `xvcur';
                };
        };
};


*
 Preserve old data set if restore is set or fast unset
*;
if("`fast'"==""){;
    preserve;
};


*
 Create new dataset
 with 1 obs per matrix row
*;
local nrowsA=rowsof(`A');
drop _all;
qui set obs `nrowsA';
if "`roweq'"!="" {;
  svroweq `A' `roweq';
  label variable `roweq' "Equation name";
};
if "`rownames'"!="" {;
  svrown `A' `rownames';
  label variable `rownames' "Row name";
};
if "`rowlabels'" != "" {;
        qui gene str1 `rowlabels' = "";
        local i1 = 0;
        while `i1' < `nxv' {;
                local i1 = `i1' + 1;
                qui replace `rowlabels' = `"`lab`i1''"' in `i1';
        };
        label variable `rowlabels' "Row variable label";
};
local exmore=c(more);
set more off;
qui svmat `type' `A', `options';
set more `exmore';


*
 Create numeric and/or string ID variables if requested
 and move them to the beginning of the variable order
*;
if ("`nidstr'"=="") local nidstr "idstr";
if("`idstr'"!=""){;
    qui gene str1 `nidstr'="";
    qui replace `nidstr'=`"`idstr'"';
    qui compress `nidstr';
    qui order `nidstr';
    lab var `nidstr' "String ID";
};
if ("`nidnum'"=="") local nidnum "idnum";
if("`idnum'"!=""){;
    qui gene double `nidnum'=real("`idnum'");
    qui compress `nidnum';
    qui order `nidnum';
    lab var `nidnum' "Numeric ID";
};


*
 Format variables if requested
*;
if `"`format'"'!="" {;
    local vlcur "";
    foreach X in `format' {;
        if index(`"`X'"',"%")!=1 {;
            * varlist item *;
            local vlcur `"`vlcur' `X'"';
        };
        else {;
            * Format item *;
            unab Y : `vlcur';
            conf var `Y';
            cap format `Y' `X';
            local vlcur "";
        };
    };
};


*
 List variables if requested
*;
if `"`list'"'!="" {;
    list `list';
};

*
 Save data set if requested
*;
if(`"`saving'"'!=""){;
    capture noisily save `saving';
    if(_rc!=0){;
        disp in red `"saving(`saving') invalid"';
        exit 498;
    };
    tokenize `"`saving'"',parse(" ,");
    local fname `"`1'"';
    if(index(`"`fname'"'," ")>0){;
        local fname `""`fname'""';
    };
    * Add filename to file list in FList if requested *;
    if(`"`flist'"'!=""){;
        if(`"$`flist'"'==""){;
            global `flist' `"`fname'"';
        };
        else{;
            global `flist' `"$`flist' `fname'"';
        };
    };
};

*
 Restore old data set if restore is set
 or if program fails when fast is unset
*;
if "`fast'"=="" {;
    if "`restore'"=="norestore" {;
        restore,not;
    };
    else {;
        restore;
    };
};






end;


program define svroweq;
version 10.0;
/*
 Save row equation names from `matrix' in string variable `roweq'.
 (This routine is designed to be used with svmat.)
*/
args matrix roweq;

if "`matrix'" == "" {;
        di in r "No matrix specified";
        error 498;
};
if "`roweq'" == "" {;
        di in r "No variable name specified";
        error 498;
};
local nrow = rowsof(`matrix');

* Create variable `roweq' *;
tempname tempmat;
qui capture drop `roweq';
qui set obs `nrow';
qui gen str1 `roweq' = "";
local rowind = 0;
while `rowind' < `nrow'{;
        local rowind = `rowind' + 1;
        matr def `tempmat'=`matrix'[`rowind'..`rowind',1..1];
        local namec : roweq(`tempmat');
        qui replace `roweq' = "`namec'" in `rowind';
};

end;


program define svrown;
version 10.0;
/*
 Save row names from `matrix' in string variable `rowname'.
 (This routine is designed to be used with svmat.)
*/
args matrix rowname;

if "`matrix'" == "" {;
        di in r "No matrix specified";
        error 498;
};
if "`rowname'" == "" {;
        di in r "No variable name specified";
        error 498;
};
local nrow = rowsof(`matrix');

* Create variable `rowname' *;
tempname tempmat;
qui capture drop `rowname';
qui set obs `nrow';
qui gene str1 `rowname' = "";
local rowind = 0;
while  `rowind' < `nrow' {;
        local rowind = `rowind' + 1;
        matr def `tempmat'=`matrix'[`rowind'..`rowind',1..1];
        local namec : rownames(`tempmat');
        qui replace `rowname' = "`namec'" in `rowind';
};

end;
