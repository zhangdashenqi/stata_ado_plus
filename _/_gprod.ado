*! version 1.0.0                    [STB51: dm71]
*! Calculate the product of observations
*! extension to egen
*! Philip Ryan  August 6 1999  v1.3.4
*! with coding suggestions by Michael Blasnik 
program define _gprod
version 6
#delimit ;
syntax newvarname = /exp [if] [in] [, BY(varlist) PMiss(string)];
if "`pmiss'" == "" {;
local pmiss "ignore";
};
if "`pmiss'" != "missing" & "`pmiss'" != "1" & "`pmiss'" != "ignore" {;
displ in re "Syntax error: specify " in wh "pmiss(missing)" in re " or "
in wh "pmiss(1)"  in re " or " in wh "pmiss(ignore)";
exit 198;
};
marksample touse, novarlist;
tempvar absvar oldsrt sumlog negsign;
quietly{;
local sortby: sortedby;
gen long `oldsrt' = _n;
gen double `absvar' = abs(`exp');
sort `touse' `by' `absvar';
gen double `sumlog' = log(`absvar') if `touse';
by `touse' `by': replace `sumlog'=sum(`sumlog') if `touse';
replace `sumlog'=exp(`sumlog');
by `touse' `by': gen `negsign' = sum(`exp'<0) if `touse';
by `touse' `by': replace `sumlog'=`sumlog'[_N]*
                 cond(mod(`negsign'[_N],2)==0,1,-1)*
                 (`absvar'[1]>0 );
if "`pmiss'" == "ignore" {;
by `touse' `by': replace `sumlog'= . if `absvar'[1]==.;
};
if "`pmiss'" == "missing" {;
by `touse' `by': replace `sumlog'= . if `absvar'[_N]==.;
};

rename `sumlog' `varlist' ;
sort `sortby' `oldsrt';
};
#delimit cr
end
exit
