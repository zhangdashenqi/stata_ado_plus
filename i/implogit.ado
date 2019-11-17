*! version 1.2 STB-45 sg92
***FUNCTIONING PROTOTYPE***
***PERFORMS LOGISITIC REGRESSIONS ON DATA WITH MULTIPLE IMPUTATIONS***
*** SEE .hlp FILE FOR DETAILS *****
***********************************
***Christopher Paul, RAND.  Version 1.0 (Beta) 3/12/97 *****
*** rev to Version 1.1 on 2/24/98 adding log liklihoods ****

program define implogit
version 5.0
#delimit ;

local varlist "required existing" ;
local weight "fw pw";
local if "optional" ;
local in "optional" ;
local nothing "" ;

local options "IMPVARS(integer 1) IMPNO(integer 10) Level(real 95) Robust
CLuster(string) OR ";

* Note, and note in dox: YOU CANNOT CLUSTER ON AN IMPUTED VARIABLE!     ;
* this is for program reasons, as well as statistical impropriety.;


parse  "`*'" ;


local trunopt = "level(`level')" ;
if "`robust'" == "robust"  {local trunopt  `trunopt' `robust'} else { } ;

if "`cluster'" ~= "`nothing'" { local trunopt = "`trunopt'" + " " + "cluster(`cluster')"}
else { } ;

unabbrev `varlist' ;

local novars "$S_2" ;
local nut " ";

local icount = `impvars';

local trunv =  " ";
local n : word count `varlist';
local n = `n' - `icount' ;
local c = 1 ;
while `c' <= `n' { ;
local temp : word `c' of `varlist';
local trunv   `trunv' `temp';

local c   = `c' +1 ;
}   ;


local n : word count `varlist';
local c = `n' - `icount' + 1 ;
while `c' <= `n' { ;
local temp : word `c' of `varlist';
local ivars  `ivars' `temp';

local c   = `c' +1 ;
}   ;

local varist `trunv';

local I  = 1  ;

while `I' <= `impno' {    ;


if `I' < 10 {   ;
local api "_0`I'" } ;
else  {  ;
local api  "_`I'" };


parse "`ivars'", parse (" ");


local imp = 1;
local imptemp = "" ;

while `imp' <= `impvars' {   ;
local lng =length("``imp''")  ;

local lng = `lng' - 3  ;



local subst = substr("``imp''",1,`lng');
local that = "`subst'"  +"`api'" ;

local imptemp  `imptemp' `that' ;
local imp = `imp' + 1    };

local ivars = "`imptemp'" ;


quietly logistic `varist' `ivars' `if' `in' [`weight'] , `trunopt';


local ll`I' = _result(2) ;

local allvar " `varist' `ivars'";
parse "`allvar'", parse(" ");
local n : word count `allvar';

*detour: ;
local U `I';
while `U' < 2 {   ;
local count  2 ;
local det  `n';
while `count' <= `det'   {   ;
local worder : word `count' of `allvar'  ;
local preds  `preds' `worder' ;
local count = `count' + 1 ;
local U = `U'+1  };

local q = `n' -1 ;
matrix b =J(1,`q',0) ;
matrix V =J(`q',`q',0);
matrix colnames b = `preds' ;
matrix colnames V = `preds' ;
matrix rownames V = `preds' ;
		   } ;
* end detour;

while `n' > 1  {   ;


local b`n'`I' =  _b[``n''] ;
local se`n'`I' = _se[``n''] ;


local n = `n' - 1;
}   ;
di "Iteration no. `I' complete.";


local I = `I' + 1;
 } ;



local n : word count `allvar' ;
while `n' > 1 {  ;
local mib`n' = 0 ;
local mise`n' = 0;
local bdiff`n' = 0;



local K = 1;
while `K' <= `impno' {  ;
local mib`n' = `mib`n'' + `b`n'`K'';


local K = `K' +1 } ;
***^ this is the tail of the _b loop ;

local mib`n' = (`mib`n'' /`impno')    ;

local I  = 1  ;
while `I' <= `impno' {    ;

local mise`n' = ( `mise`n'' + ( (1/`impno') * ((`se`n'`I'')^2 ))) ;

local bdiff`n' = ((`bdiff`n'') + ((`b`n'`I''-`mib`n'')^2)) ;

local I = `I' + 1 };
local mise`n' = (`mise`n'') + ((( `impno'+1)/`impno')*(`bdiff`n''/(`impno'-1)));

local mise`n' = sqrt(`mise`n'') ;

local q = `n' -1 ;

matrix b[1,`q'] = `mib`n'' ;
matrix V[`q',`q'] = `mise`n''^2 ;


local n = `n' - 1   }  ;
*** ^ this is the tail end of the s.e. loop.;



parse "`allvar'", parse(" ");
local depvar : word 1 of `allvar';

local ntot $S_E_nobs ;
local dof $S_E_mdf ;


matrix post  b   V  , depname(`depvar') obs(`ntot') dof(`dof')  ;

**** assignment of global macros:  ;
global S_E_vl "`varist' `ivars'"      ;
global S_E_if "`if'" ;
global S_E_in "`in'";
global S_E_wgt "`weight'";
global S_E_cmd "implogit";
global S_E_depv "`depvar'";
global S_E_nobs "`ntot'";
global S_E_mdf "`dof'";



di "";
di "Logistic Regression using imputed values.";
di " Coefficients and Standard Errors Corrected";
di "N = $S_E_nobs ";

local  I  = 1;
while   `I' <= `impno' { ;
di "Log Likelihood for component regression no." `I' "= " `ll`I'' "." ;
local I = `I' + 1   };


if "`or'"=="or"  {  ;

matrix mlout, eform(Odds) level(`level')    }  ;

else { matrix mlout, level(`level') };

end;



