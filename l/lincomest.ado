#delim ;
prog def lincomest,eclass;
version 7.0;
/*
 Call lincom, saving estimation results,
 and optionally holding the existing ones in a specified holdname.
*! Author: Roger Newson
*! Date: 21 January 2003
*/

*
 Extract formula and leave command line ready to be syntaxed
*;
gettoken token 0 : 0, parse(",= ");
while `"`token'"'!="" & `"`token'"'!="," {;
  if `"`token'"' == "=" {;
    di in red _quote "=" _quote " not allowed in expression";
    exit 198;
  };
  local formula `"`formula'`token'"';
  gettoken token 0 : 0, parse(",= ");
};
local 0 `",`0'"';

*
 Replay if -formula- is empty
 otherwise input -formula- to lincom
 and store the result in estimation results
*;
if `"`formula'"'=="" {;
  * Beginning of replay section *;
  if "`e(cmd)'"!="lincomest" {;error 301;};
  syntax [, EForm(passthru) Level(integer $S_level) ];
  * End of replay section *;
};
else{;
  *
   Beginning of non-replay section
  *;

  *
   Extract options *;
  *;
  syntax [ , HOldname(string) EForm(passthru) Level(integer $S_level) ];

  * Check that -holdname- is valid *;
  if `"`holdname'"'!="" {;
    cap confirm names `holdname';
    local retcode=_rc;
    if `retcode'!=0 {;
      disp as error "Invalid holdname:" _n `"`holdname'"';
      error 198;
    };
  };

  *
   Call lincom in non-eform mode
   to extract non-eform estimate and SE
  *;
  qui lincom `formula', level(`level');

  * Extract estimation output *;
  local depname `"`e(depvar)'"';
  tempvar esample;
  local obs=e(N);
  local dof=e(df_r);
  gene byte `esample'=e(sample);

  * Extract output to lincom *;
  tempname estimate se vari;
  scal `estimate'=r(estimate);
  scal `se'=r(se);
  scal `vari'=`se'*`se';

  * Create estimation and covariance matrices *;
  tempname beta vcov;
  matr def `beta'=J(1,1,0);
  matr def `vcov'=J(1,1,0);
  matr def `beta'=`estimate';
  matr def `vcov'=`vari';
  matr rownames `beta'="y1";
  matr colnames `beta'="(1)";
  matr rownames `vcov'="(1)";
  matr colnames `vcov'="(1)";

  * Replace estimates *;
  nobreak {;
    if "`holdname'"!="" {;
      estimates hold `holdname';
    };
    if missing(`obs') {;local obsopt "";};else{;local obsopt "obs(`obs')";};
    if missing(`dof') {;local dofopt "";};else{;local dofopt "dof(`dof')";};
    esti post `beta' `vcov',depname(`depname') `obsopt' `dofopt' esample(`esample');
    esti local cmd "lincomest";
    esti local depvar "`depname'";
    esti local predict "lincomest_p";
    esti local formula `"`formula'"';
    esti local holdname "`holdname'";
    if !missing(`dof') {;esti scalar df_r=`dof';};
  };

  *
   End of non-replay section
  *;
};

*
 Check level
*;
if (`level'<10)|(`level'>99) {;
  disp as err "level() must be between 10 and 99 inclusive";
  exit 198;
};

* Display estimates *;
local eformopt="";
disp as text "Confidence interval for formula:" _n as result "`e(formula)'" _n;
esti disp, `eform' level(`level');

end;
