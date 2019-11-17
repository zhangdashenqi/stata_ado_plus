*! version 1.0.0            (STB-58: sg153)
*! Dean Jolliffe, Bohdan Krushelnytskyy and Anastassia Semykina, CERGE-EI
*! CLAD estimation with bootstrap standard errors
#delimit ;

program define clad;
  version 5.0;
  local varlist "required existing min(2)";
  local if "optional";
  local in "optional";
  local options "Reps(integer 100) psu(string) Level(integer $S_level)
                 Dots SAving(string) replace
                 LLfir ULfir LLsec(real 123456) ULsec(real 123456) *";
  parse "`*'";
  parse "`varlist'", parse(" ");

  quietly
  {;
    if `reps'<1 {; display in red "reps() must be positive"; exit; };
    if `level' <= 0 | `level' >= 100
    {; display in red "level() must be between 0 and 100"; exit; };
    if "`replace'" ~= "" & "`saving'" == ""
    {; display in red "replace can only be specified with saving()"; exit; };

    if `llsec'==123456 {; local llsec ""; };
    if `ulsec'==123456 {; local ulsec ""; };

    if ("`llfir'" ~= "" & "`llsec'" ~= "") | ("`ulfir'" ~= "" & "`ulsec'" ~= "")
    {; display in red "Wrong syntax: double option specification."; exit; };
    if ("`llfir'" ~= "" | "`llsec'" ~= "") & ("`ulfir'" ~= "" | "`ulsec'" ~= "")
    {; display in red "ll and ul cannot be specified together."; exit; };

    if "`llfir'" ~= ""
    {; summarize `1'; global ll=_result(5); };
    if "`ulfir'" ~= ""
    {; summarize `1'; global ul=_result(6); };
    if "`llsec'" ~= ""
    {; global ll=`llsec'; };
    if "`ulsec'" ~= ""
    {; global ul=`ulsec'; };
    if "$ll" == "" & "$ul" == ""
    {; global ll=0; };

    if "`dots'" ~= "" {; local dots "noisily"; };

    preserve;
    tempvar use;
    generate byte `use'=1 `if' `in';
    drop if `use'~=1;

    summarize `1';
    if "$ll" ~= ""
    {;
      if $ll<_result(5)
      {; noisily display in blue "Note: Lower censoring limit is less then mimimum of dependent variable."; };
    };
    else
    {;
      if $ul>_result(6)
      {; noisily display in blue "Note: Upper censoring limit is greater then maximum of dependent variable."; };
    };
    count if `1'==.;
    drop if `1'==.;
    if _result(1)>0
    {; noisily display in blue "Note: Dependent variable has " _result(1) " missing value(s). Not used in calculations."; };

    local num : word count `varlist';

    if "`psu'"==""
    {;
      tempname memfile beta;
      tempfile datfile resfile;
      keep `varlist';
      save `datfile', replace;

      local issize=_N;
      cnqreg `varlist', level(`level') `options';
      matrix `beta'=get(_b);
      local fssize=$S_E_nobs;
      local pr2=1-$S_E_msd/$S_E_rsd;

      postfile `memfile' `varlist' const using `resfile', replace;
      local i=1;
      while `i'<=`reps'
      {;
        use `datfile', clear;
        bsample;
        cnqreg `varlist', level(`level') `options';

        local k=2;
        local poststr "";
        while `k'<=`num'
        {;
          local poststr "`poststr' (_b[``k''])";
          local k=`k'+1;
        };

        post `memfile' 0 `poststr' (_b[_cons]);
        `dots' display "." _continue;
        local i=`i'+1;
      };
      postclose `memfile';
    };
    else
    {;
      unabbrev `psu', max(1);
      local psu "$S_1";

      count if `psu'==.;
      drop if `psu'==.;
      if _result(1)>0
      {; noisily display in blue "Note: PSU-variable has " _result(1) " missing value(s). Not used in calculations."; };

      tempname memfile beta;
      tempfile datfile resfile uniqpsu;
      tempvar bootvar count;
      keep `varlist' `psu';
      sort `psu';
      save `datfile', replace;

      local issize=_N;
      cnqreg `varlist', level(`level') `options';
      matrix `beta'=get(_b);
      local fssize=$S_E_nobs;
      local pr2=1-$S_E_msd/$S_E_rsd;

      * create the datafile with unique PSUs;
      collapse `1', by(`psu');
      keep `psu';
      save `uniqpsu', replace;

      postfile `memfile' `varlist' const using `resfile', replace;
      local i=1;
      while `i'<=`reps'
      {;
        * select PSUs;
        use `uniqpsu', clear;
        generate `bootvar'=`psu'[int(_N*uniform())+1];
        collapse (count) `count'=`psu', by(`bootvar');
        rename `bootvar' `psu';

        * merge with the original dataset;
        merge `psu' using `datfile';
        keep if _merge==3;
        expand `count';
        keep `varlist' `psu';

        * randomly select observations from each PSU;
        sort `psu' `varlist';
        by `psu': generate `count'=int(_N*uniform())+1;
        local k=1;
        while `k'<=`num'
        {;
          by `psu': generate `bootvar'=``k''[`count'];
          drop ``k'';
          rename `bootvar' ``k'';
          local k=`k'+1;
        };

        cnqreg `varlist', level(`level') `options';

        local k=2;
        local poststr "";
        while `k'<=`num'
        {;
          local poststr "`poststr' (_b[``k''])";
          local k=`k'+1;
        };

        post `memfile' 0 `poststr' (_b[_cons]);
        `dots' display "." _continue;
        local i=`i'+1;
      };
      postclose `memfile';
    };
    use `resfile', clear;
    local k=2;
    while `k'<=`num'
    {;
       local charact=`beta'[1,`k'-1];
       char ``k''[bstrap] `charact';
       local k=`k'+1;
    };
    local charact=`beta'[1,`num'];
    char const[bstrap] `charact';
    drop `1';
    `dots' display;
    noisily display _newline "Initial sample size = " `issize';
    noisily display "Final sample size = " `fssize';
    noisily display "Pseudo R2 = " `pr2';
    noisily bstat, level(`level');
    if "`saving'" ~= "" {; save `saving', `replace'; };
    macro drop ll ul;
  };
end;

program define cnqreg;
  version 5.0;
  local varlist "required existing min(2)";
  local options "*";
  parse "`*'";
  parse "`varlist'", parse(" ");

  preserve;
  local t: word count `varlist';
  tempvar yhat;

  if "$ll" ~= ""
  {;
    local min=$ll-1;
    while `min'<$ll
    {;
      if _N<`t'
      {;
        display in red "Program did not converge," _newline
        "trimmed sample size is smaller than number of degrees of freedom.";
        exit 2001;
      };
      qreg `varlist', `options';
      predict `yhat';
      summarize `yhat';
      local min=_result(5);
      drop if `yhat'<$ll;
      drop `yhat';
    };
  };
  else
  {;
    local max=$ul+1;
    while `max'>$ul
    {;
      if _N<`t'
      {;
        display in red "Program did not converge," _newline
        "trimmed sample size is smaller than number of degrees of freedom.";
        exit 2001;
      };
      qreg `varlist', `options';
      predict `yhat';
      summarize `yhat';
      local max=_result(6);
      drop if `yhat'>$ul;
      drop `yhat';
    };
  };
end;
