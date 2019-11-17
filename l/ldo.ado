*! version 0.3 Januar 31, 2013 @ 10:25:35 UK
*! Clickable list of .mata files

* 0.1 Initial version
* 0.2 User string is search pattern

program ldo, rclass
version 10.0

syntax [name] [, Erase]
local names: dir `"`c(pwd)'"' files "*`namelist'*.do"
local names: list sort names

if "$MYEDITOR" == "" global MYEDITOR doedit

foreach name of local names {
	if "`erase'" != "" 					/// 
	  local eitem `"[{stata `"erase "`name'""':{err}erase}]"'
	display 							///  
	  `"{txt}`eitem'"' 	///  
	  `" [{stata `"view "`name'""':view}]"'   ///
	  `" [{stata `"$MYEDITOR "`name'""':edit}]"' ///
	  `" [{stata `"do "`name'""':do}]"' 	///
	  `" {res} `name' "'
}

display _n `"{txt}Click [{stata `"ldir"':here}] for other links"'

return local files `"`names'"' 
end

exit

Author: Ulrich Kohler
	Tel +49 (0)30 25491 361
	Fax +49 (0)30 25491 360
	Email kohler@wzb.eu


