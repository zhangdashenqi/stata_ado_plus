*! version 0.1 Mai 15, 2009 @ 10:38:18 UK
*! Subprogram for lsmcl
program ltrans
version 10.0

syntax anything [, txt ps]

local fname = subinstr(`anything',".smcl","",1)

if "`txt'" == "txt" {
	quietly translate "`fname'.smcl" "`fname'.txt", translator(smcl2txt) replace
	display 							///  
	  `" {res} `fname'.txt {txt}created "' ///
	  `" {txt} [{stata `"view "`fname'.txt""':view}]"'   ///
	  `" [{stata `"doedit "`fname'.txt""':edit}]"'   ///
	  `" [{browse `"`fname'.txt"':browse}]"'  
}


if "`ps'" == "ps" {
	quietly translate "`fname'.smcl" "`fname'.ps", translator(smcl2ps) replace
	display 							///  
	  `" {res} `fname'.ps {txt}created "' ///
	  `" [{browse `"`fname'.ps"':browse}]"'  
}


end
exit

Author: Ulrich Kohler
	Tel +49 (0)30 25491 361
	Fax +49 (0)30 25491 360
	Email kohler@wzb.eu



