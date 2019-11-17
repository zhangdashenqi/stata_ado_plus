#delim ;
prog def bmjcip;
version 9.0;
/*
  Replace a list of numeric variables,
  containing estimates, confidence limits and (optionally) P-values,
  with a list of corresponding string variables,
  containing estimates, confidence limits and (optionally) P-values,
  formatted in a way that might be approved
  by the British Medical Journal (BMJ) and other medical journals
  for use in tables.
*!Author: Roger Newson
*!Date: 09 November 2007
*/

syntax varlist(min=3 max=4) [, CFormat(string) ];
local estimate: word 1 of `varlist';
local cimin: word 2 of `varlist';
local cimax: word 3 of `varlist';
local pvalue: word 4 of `varlist';

if "`cformat'"=="" {;
  local cformat: format `estimate';
};

qui {;
  sdecode `estimate' if !missing(`estimate'), format(`cformat') replace;
  sdecode `cimin' if !missing(`cimin'), format(`cformat') prefix("(") suffix(",") replace;
  sdecode `cimax' if !missing(`cimax'), format(`cformat') suffix(")") replace;
  if "`pvalue'"!="" {;
    sdecode `pvalue' if !missing(`pvalue'), format(%-10.2g) replace;
    replace `pvalue'=trim(`pvalue');
    replace `pvalue'=subinstr(`pvalue',"e-0","e-",1);
    replace `pvalue'=subinstr(`pvalue',"e-0","e-",1);
    replace `pvalue'=subinstr(`pvalue',"e-","x10-",1);  
    format `pvalue' %-10s;
  };
};
end;;
