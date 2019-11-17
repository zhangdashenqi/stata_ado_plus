#delim ;
prog def parmby,rclass;
version 8;
*
 Call a regression command followed by -parmest- with by-variables,
 creating an output data set containing the by-variables
 together with the parameter sequence number -parmseq-
 and all the variables in a -parmest- output data set.
*! Author: Roger Newson
*! Date: 15 August 2003
*;


gettoken cmd 0: 0;
if `"`cmd'"' == `""' {;error 198;};

syntax [ , LIst(passthru) SAving(passthru) noREstore FAST * ];
/*
-norestore- specifies that the pre-existing data set
  is not restored after the output data set has been produced
  (set to norestore if FAST is present).
-fast- specifies that parmest will not preserve the original data set
  so that it can be restored if the user presses Break
  (intended for use by programmers).
All other options are passed to -_parmby-.
*/

*
 Set restore to norestore if -fast- is present
 and check that the user has specified one of the four options:
 -list()- and/or -saving()- and/or -norestore- and/or -fast-.
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
      _n "For more details, see {help parmest:on-line help for parmby and parmest}.";
    error 498;
};

*
 Preserve old data set if -restore- is set or -fast- unset
*;
if("`fast'"==""){;
    preserve;
};

* Call -_parmby- with all other options *;
_parmby `"`cmd'"' , `list' `saving' `options';
return add;

*
 Restore old data set if -restore- is set
 or if program fails when -fast- is unset
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

prog def _parmby,rclass;
version 8.0;
*
 Call a regression command followed by -parmest- with by-variables,
 creating an output data set containing the by-variables
 together with the parameter sequence number -parmseq-
 and all the variables in a -parmest- output data set.
*;

gettoken cmd 0: 0;

syntax [ ,BY(varlist) COMmand LIst(string asis) SAving(string asis) FList(string) REName(string) FOrmat(string) * ];
*
 -by- is list of by-variables.
 -command- specifies that the regression command is saved in the output data set
  as a string variable named -command-.
 Other options are as defined for -parmest-.
*;

* Echo the command and by-variables *;
disp in green "Command: " in yellow `"`cmd'"';
if "`by'"!="" {;disp in green "By variables: " in yellow "`by'";};


*
 Execute the command once or once per by-group,
 depending on whether -by()- is specified,
 saving the output data set in memory.
*;
if "`by'"=="" {;
  *
   Beginning of non-by-group section.
   (Execute the command and -parmest- only once for the whole data set.)
  *;
  * Beginning of common section to be executed with or without -by- *;
  cap noi {;
    `cmd';
  };
  if _rc!=0 {;
    drop *;
  };
  else {;
    parmest, `options' fast;
    qui {;
      gene long parmseq=_n;
      qui compress parmseq;
      order parmseq;
      lab var parmseq "Parameter sequence number";
    };
  };
  * End of common section to be executed with or without -by- *;
  * Error if no parameters, otherwise sort parameters *;
  if _N==0 {;
    disp as error "Command was not completed successfully";
    error 498;
  };
  sort parmseq;
  *
   End of non-by-group section.
  *;
};
else {;
  *
   Beginning of by-group section.
   (Create grouping variable -group- defining by-group
   and data set -tf0- with 1 obs per by-group,
   execute the command and -parmest- on each by-group in turn,
   saving the results to temporary files,
   and concatenate temporary files.)
  *;
  *
   Create grouping variable -group-
   and macro -ngroup- containing number of groups
  *;
  qui {;
    sort `by', stable;
    tempvar group;
    by `by':gene long `group'=_n==1;
    replace `group'=sum(`group');
    compress `group';
    summ `group';
    local ngroup=r(max);
  };
  * Preserve total data set so by-groups can be restored for estimation *;
  preserve;
  * Create data set -tf0- with 1 obs per by-group *;
  qui {;
    tempfile tf0;
    keep `by' `group';
    by `by': keep if _n==1;
    sort `group';
    save `tf0',replace;
  };
  * Execute command for each by-group *;
  forv i1=1(1)`ngroup' {;
    * Restore current by-group and print by-group header *;
    restore,preserve;
    qui keep if `group'==`i1';
    by `by':list if 0;
    * Beginning of common section to be executed with or without -by- *;
    cap noi {;
      `cmd';
    };
    if _rc!=0 {;
      drop *;
    };
    else {;
      parmest, `options' fast;
      qui {;
        gene long parmseq=_n;
        qui compress parmseq;
        order parmseq;
        lab var parmseq "Parameter sequence number";
      };
    };
    * End of common section to be executed with or without -by- *;
    * Add group to -parmest- output and save in temporary file *;
    qui {;
      gene long `group'=`i1';
      compress `group';
      tempfile tf`i1';
      save `tf`i1'', emptyok;
    };
  };
  * Cancel the -preserve- for the total data set *;
  restore,not;
  * Concatenate temporary files *;
  qui {;
    use `tf1', clear;
    forv i1=2(1)`ngroup' {;append using `tf`i1'';};
  };
  * Error if no parameters, otherwise sort parameters *;
  if _N==0 {;
    disp as error "Command was not completed successfully for any by-group";
    error 498;
  };
    sort `group' `parmseq';
  *
   End of by-group section.
  *;
};


* Add variable -command- if requested *;
if "`command'"!="" {;
  qui gene str1 command="";
  qui replace command=`"`cmd'"';
  lab var command "Estimation command";
  order parmseq command;
};

*
 Rename variables if requested
 (including -parmseq- and -command-, which cannot be renamed by -parmest-)
 and create macros -parmseqv- and -commandv-,
 containing -parmseq- and -command- variable names
*;
local parmseqv "parmseq";
if "`command'"=="" {;local commandv "";};
else {;local commandv "command";};
if "`rename'"!="" {;
    local nrename:word count `rename';
    if mod(`nrename',2) {;
        disp in green 
          "Warning: odd number of variable names in rename list - last one ignored";
        local nrename=`nrename'-1;
    };
    local nrenp=`nrename'/2;
    local i1=0;
    while `i1'<`nrenp' {;
        local i1=`i1'+1;
        local i3=`i1'+`i1';
        local i2=`i3'-1;
        local oldname:word `i2' of `rename';
        local newname:word `i3' of `rename';
        cap{;
            confirm var `oldname';
            confirm new var `newname';
        };
        if _rc!=0 {;
            disp in green
             "Warning: it is not possible to rename `oldname' to `newname'";
        };
        else {;
            rename `oldname' `newname';
            if "`oldname'"=="parmseq" {;local parmseqv "`newname'";};
            if "`oldname'"=="command" {;local commandv "`newname'";};
        };
    };
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

* Add by-variables from file -tf0- if present *;
if "`by'"!="" {;
  tempvar merg;
  qui merge `group' using `"`tf0'"',_merge(`merg');
  qui keep if `merg'==3;
  drop `group' `merg';
  order `by';
  sort `by' `parmseqv';
};

*
 List variables if requested
*;
if `"`list'"'!="" {;
    if "`by'"=="" {;
        disp _n as text "Listing of results:";
        list `list';
    };
    else {;
        disp _n as text "Listing of results by: " as result "`by'";
        by `by':list `list';
    };
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


* Return results *;
return local by "`by'";
return local command `"`cmd'"';

end;
