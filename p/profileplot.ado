*! version 1.2 -- 22nov11, 19may08, 2nov07, 31oct07 -- pbe
program define profileplot
version 8.2
syntax varlist [if] [in] [pweight], by(varname) [ MEDian XLabel(string) ///
        XTitle(string) MSYMbol(string) ANGle(integer 0) LEGend(string) *]

 preserve
 
 if "`if'"~="" | "`in'"~="" {
   keep `if' `in'
 }
 local pvar = substr("`exp'",3,.)
 keep `varlist' `pvar' `by' 
 
 local type "mean"
 if "`median'"~="" {
   local type "median"
 }
 
 local kvars : word count `varlist'  /* get number of variables */
 local q=char(34)
 local label ""
 local i=0
 foreach V of varlist `varlist' {
   local i=`i' + 1
   local label = `"`label'"' + " " + `"`i'"' + " " + `"`q'"' + "`V'" + `"`q'"'
   rename `V' value`i'
 }
 
 /* restructure data prior to plotting */
 collapse (`type') value* [`weight' `exp'], by(`by')
 quietly reshape long value, i(`by') j(Variables)

 local htitle ""
 if "`xtitle'"~="" {
    local htitle "ttitle(`xtitle')"
 }
 if "`xlabel'"~="" {
   local label=`"`xlabel'"'
 }
 label def var `label'
 label values Variables var
 label var value "`type'"
 if "`msymbol'"=="" {
   local msymbol "O"
 }

 * use xtline to draw profiles
 quietly xtset `by' Variables
 xtline value, overlay tlabel(#`kvars', valuelabels) /// 
        addplot(scatter value Variables, msymbol("`msymbol'") ///
        legend(`legend') ) ///
        `htitle' `options'  xlabel(,angle(`angle'))
end
