*! version 2.0.0, 9/4/92 (STB-10: sg12)
program define xtab
/* Written by:
	D.H. Judson
	1013 James St.
	Newberg, OR 97132
	(503) 537-0660
	Program code enhancements and suggestions are welcome at the above address.
	This program calls ado files: 
		etab.ado.
	STATA version: 3.0 */
version 3.0
#delimit ;
local varlist "req ex";
local options "BY(string) *";
local in "opt";
local if "opt";
local weight "opt fweight noprefix";
parse "`*'";
local lftside `varlist';
local rtside `by';
if "`by'"=="" { ;
	di in red "No BY(" in ye "varlist" in red ") option specified.";
	error 198;
};
parse "`lftside'", parse(" ");
while "`1'"~="" { ;
	etab `1' `rtside' `in' `if' `weight', `options';
	mac shift;
};
#delimit cr ;
end
