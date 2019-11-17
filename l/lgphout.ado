*! version 0.1 Mai 15, 2009 @ 10:38:15 UK
*! Subprogram for lgph
program lgphout
version 10.0

syntax anything [, export print]

if "`export'" == "export" {
	graph use `anything'
	local fname = subinstr(`anything',".gph","",1)
	quietly graph export "`fname'.eps", replace
	display 							///  
	  `" {res} `fname'.eps {txt}created "' ///
	  `" [{browse `"`fname'.eps"':browse}]"'  

}

if "`print'" == "print" {
	graph use `anything'
	graph print 
}


end
exit

Author: Ulrich Kohler
	Tel +49 (0)30 25491 361
	Fax +49 (0)30 25491 360
	Email kohler@wzb.eu



