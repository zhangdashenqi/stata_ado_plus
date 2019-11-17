*! dotplot -- Version 3.1.4,   8-Mar-94.      (STB19: gr14)
program define dotplot
	version 3.1
	local varlist "req ex min(1)"
	local in "opt"
	local if "opt"
	#delimit ;
	local options "BY(string) NX(int -1) NY(int 35) EXact_y 
		CEntre AVerage(string) Bar Symbol(string) Pen(string) 
		T1title(string) L1title(string) B2title(string) *" ;
	#delimit cr
	parse "`*'"
	local centre = "`centre'"!=""
	parse "`options'", parse(" ")
	local wcnt : word count `by'
	if `wcnt' > 1  {
	    di in red "only one by() variable allowed"
	    exit 198
	}
	if "`by'" != ""  {
		local wcnt : word count `varlist'
		if `wcnt' > 1 {
		    di in red "only 1 variable may be plotted with by()"
		    exit 198
		}
		confirm variable `by'
	}
	while "`1'"!="" {
		if (substr("`1'", 1, 3)=="xla") {
			local XLAB 1
			local 1 ""
		}
		else mac shift
	}
	while "`2'"!="" {mac shift}
/*
	Put names of y-variables and integers 1, 2, ... into xdef
*/
	parse "`varlist'", parse(" ")
	local nyvars 0
	while "`1'"!="" {
		local nyvars = `nyvars'+1
		local yname : var lab `1'
		if "`yname'"=="" {local yname "`1'"}
		local xdef "`xdef' `nyvars' "`yname'""
		local xunique "`xunique',`nyvars'"
		mac shift
	}
	tempvar x y xc yc 
	tempname xlbl
	local small 1e-6
	capture { 
		if "`by'"!="" {
			gen `y' = `varlist' `if' `in'
			gen `x' = `by' if `y'!=.
			replace `y' = . if `x'==.
			local sort :sortedby
			sort `x'
			gen `xc'= -(`x'!=`x'[_n-1])  if `x'!=.
			count if `xc'==-1
			local cols=_result(1)
			if "`XLAB'"=="" {
			   sort `xc'
			   local xunique
			   local j 1
			   while `j' > 0 {
				local xj=`x'[`j']
				local xunique "`xunique',`xj'"
				local j=`j'+1
				if `xc'[`j']==0 {local j 0}
			   }
			}
			replace `xc'=.
			_crcslbl `xc' `by'
			local xlbl : value label `by'
		}
		else {
			if `nyvars'>1 {
				if substr("`symbol'",1,1)=="[" {
				   noisily di /*
*/				   "symbol([varname]) not allowed with varlist"
				   local symbol 
				}
				preserve
				keep `varlist' 
				capture keep `if' `in'
				desc,short
				local maxobs =_result(4)
				local reqobs=`nyvars'*(_result(1) + 100)
				if `maxobs'<`reqobs' {
					tempfile user
					save `user'
					drop _all
					set maxobs `reqobs'
					use `user'
					erase `user'
				}
				stack `varlist' , into(`y') clear
				gen int `x' = _stack if `y'!=.
				drop _stack
			}
			else {
				gen `y' = `varlist' `if' `in'
				gen int `x' = 0 if `y'!=.
			}
			gen `xc' = .
			label var `xc' " " /* ??? */
			label define `xlbl' `xdef'
			local cols `nyvars' /* no. of columns to be plotted */
		}
		label values `xc' `xlbl'
		sum `x'
		local min = _result(5)
		local max = _result(6)
		local xrange = `max'-`min'
		if abs(`xrange')<`small' { local xrange 1 }
/*
	xoffset expands the plotting range for the x-axis by .5 of an x unit.
*/
		local xoffset =0.5*(`xrange'/`cols')
		local x0 = `min'-`xoffset'*(1+`centre')
		local x1 = `max'+`xoffset'*2
		sort `y'
		if "`exact_y'"!=""{ gen `yc'=`y' }
		else { 
			sum `y'
			local min = _result(5)
			local max = _result(6)
			local yprec 0
			gen `yc'=`y'-`y'[_n-1]
			sum `yc' if `yc'>0
			if _result(5)!=. { local yprec=_result(5) }
			local yprec=round((`max'-`min')/`ny',`yprec')
			replace `yc'=round(`y',`yprec')
		}
		if "`average'"!="" {
			tempvar me
			capture egen `me'=`average'(`y'),by(`x')
			if _rc!=0 {
				noisily di "`average' not valid with average" 
				local average ""
			}
			else {
				local ym "`me'"
				local st p
				local pa 4
			}
		}
		if "`bar'"!="" {
			tempvar yb1 yb2 dash 
			tempname dash
			if substr("`average'",1,3)=="mea"{
				egen `yb1'=sd(`y'),by(`x')
				gen `yb2'=`ym'+`yb1'
				replace `yb1'=`ym'-`yb1'
			}
			else {
				egen `yb1'=pctile(`y'), p(25) by(`x')
				egen `yb2'=pctile(`y'), p(75) by(`x')
			}
			gen byte `dash'=1
			lab def `dash' 1 "_"
			lab val `dash' `dash'
			local yb "`yb1' `yb2'"
			local da "[`dash'][`dash']"
			local pb 44
		}
		sort `x' `yc'
		if `centre' {
			by `x' `yc': replace `xc' = (_n-(_N+1)/2)
		}
		else {
			by `x' `yc': replace `xc' = (_n-1)
		}
		if `nx'==-1 {
			sum `xc' if  `x'!=. & `yc'!=.
			local nx=int(`cols'* /*
				*/    ((1+`centre')*_result(6)+`cols'^.3))
		}
		global S_1 `nx'
		local nx = `nx'/`xrange'
		replace `xc'=`x'+`xc'/`nx'
		local xunique =substr("`xunique'",2,.)
		local xlab1 "xlab(`xunique')"
		if  !`centre' & (`cols'==1) {
			local xlab1 "xlab "
			by `x' `yc': replace `xc' = _n
			local b2t "Frequency"
			local x0 0
			local x1 `nx'
		}
		local l1t " "  
		if ("`by'"!="" | `cols'==1)  {local l1t "`yname'"}
		if "`t1title'"=="" { local t1title " " }
		if "`l1title'"=="" { local l1title "`l1t'" }
		if "`b2title'"=="" { local b2title "`b2t'" }
		if "`symbol'"=="" { local symbol "o" }
		local symbol "`symbol'`st'`da'"
		if "`pen'"=="" { local pen "2`pa'`pb'" }
		if "`XLAB'"=="1" { local xlab1  }
		noisily gr `yc'  `ym' `yb' `xc', s(`symbol') pen(`pen') /*
 	   	 */ `xlab1' xscale(`x0',`x1')  `options' /*
	  	 */ l1("`l1title'") t1("`t1title'") b2("`b2title'") 
		global S_2 `ny'
	}
	if "`by'"==""	& `nyvars'>1 {
		if `maxobs'<`reqobs' {
			drop _all
			quietly set maxobs `maxobs'
		}
	}
	if "`sort'"!=""{ 
		if "$S_NOFKEY"=="" {  mac def F4 "sort `sort';"
			di in gr "Type <F4> to restore sort order"}
        	else { di in gr "Type" di in red " sort `sort'" /*
		*/	di in gr " to restore sort order" }
	}
end
