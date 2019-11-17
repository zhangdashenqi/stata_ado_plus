*! version 1.2.0, 9/4/92 (STB-10: sg12)
program define etab
/* Written by:
   D.H. Judson
   1013 James St.
   Newberg, OR 97132
   (503) 537-0660
   Program code enhancements and suggestions are welcome at the above address.
   This program calls ado files: 
      none.
   STATA version: 3.0 */
version 3.0
#delimit ;
local varlist "req ex";
local options "*";
local in "opt";
local if "opt";
local weight "opt fweight noprefix";
parse "`*'";
parse "`varlist'", parse(" ");
local dv `1';
mac shift;
while "`1'"~="" { ;
        tab `dv' `1' `in' `if' `weight', `options';
        mac shift;
};
#delimit cr ;
end
