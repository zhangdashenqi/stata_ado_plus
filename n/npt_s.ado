*! version 1.1.4  27/09/96 (STB-33: snp12)
program define npt_s
version 3.1
local varlist "req ex max(1)"
local if "opt"
local in "opt"
local options "By(string) noDetail Ordinal Midrank SCore(string) STrata(string)"
parse "`*'"
if "`score'"!="" {
	di in y "Score " in r "option is no longer supported.  Use" /*
	*/ in y " by " in r "instead."
	exit 198
}
if "`by'"=="" {
	di in red "You must specify the grouping variable"
	exit 198
}
_crcunab `by'
local by "$S_1"
local wcnt : word count `by'
if `wcnt' > 1 {
	di in red "Only one by() variable allowed"
	exit 198
}
if "`strata'"!="" {
	_crcunab `strata'
	local strata "$S_1"
	local bystr "by `strata':" 
	local bys "by(`strata')" 
}
quietly {
/*
	Is the grouping variable a string variable? It should not be -- 
		how is it ordered?
*/                         
	cap conf string var `by'
	if _rc { local byvar "`by'" }
	else {
		noisily di "By-varaible must be numeric"
		exit 
	}
/*
	Mark usable observations before sorting
*/
	tempvar usable
	gen byte `usable' = 1 `if' `in'
	markout `usable' `varlist' `byvar'
	if "`strata'" !="" {
		local nsv : word count `strata'
		local j = 1
		while `j'<=`nsv' {
			local str : word `j' of `strata'
			capture confirm string var `str'
			if _rc {
				markout `usable' `str'
			}
			else	replace `usable'=. if `str'=="" 
			local j = `j'+1
		}
	}
	replace `usable'=. if `usable'==0
/*
	Create score.
*/
	tempvar score
	if "`ordinal'"!="" {
		sort `usable' `byvar'
		gen `score'=sum(`byvar'!=`byvar'[_n-1]) if `usable'!=.
	}
	else if "`midrank'"!="" {
		egen `score' = rank(`byvar') if `usable'!=. 
	}
	else    gen `score' = `byvar'
	sort `byvar' `usable'
	by `byvar' :replace `score'=`score'[1]
/*
	Generate the rank sums.
*/
	tempvar ranksum tie nstrat T ET VT
	egen `ranksum' = srank `varlist' if `usable'!=. ,`bys'
	sort `strata' `ranksum'
	`bystr' gen `T' = sum(`ranksum'*`score')
	egen long `nstrat'  = count(`usable') ,`bys'
	sort `strata' `ranksum'
	`bystr' gen `ET'= sum(`score')
	by `strata' `ranksum': gen int `tie'=_N if _n==_N & `usable'!=.
	`bystr' replace `tie'=sum(`tie'*(`tie'^2-1))/(`nstrat'*(`nstrat'^2-1))
	`bystr' gen `VT'=sum(`score'^2)
	`bystr' replace `VT'=  /*
		*/ (1-`tie')*((`nstrat'+1)/12)*(`nstrat'*`VT'-(`ET')^2)
	`bystr' replace `ET'= cond(_n==`nstrat' &  /*
		*/ `usable'!=. , (`nstrat'+1)*`ET'/2,.) 
	replace `VT'=. if `ET'==.
	replace `T'=. if `ET'==.
/*
	Calculate the test statistic and p-value.
*/
	sum `T'
	local O = _result(1)*_result(3)
	sum `ET'
	local E = _result(1)*_result(3)
	sum `VT'
	local V = _result(1)*_result(3)
	local z = (`O'-`E')/sqrt(`V')
	local pval = 2*( 1-normprob(abs(`z')))
}
/*
	Display the rank sums for each group if no strata option.
*/
local byname : var lab `by'
if "`detail'"=="" & "`strata'"=="" {
	di
	tempvar obs
	sort `byvar'
	qui by `byvar': gen `obs'=cond(_n==_N,sum(`ranksum'!=.),.)
	qui by `byvar': replace `ranksum'=cond(_n==_N,sum(`ranksum'),.)
	qui replace `usable' = cond((`obs'!=. & `obs'!=0),1,.)
	sort `usable' `score'
	local scol = 11 - length("`by'")
	local bylab : val lab `by'
	if "`bylab'"!="" {
		tempvar BY
		decode `by',gen(`BY')
	}
	else { local BY "`by'" }
	di in gr _col(`scol') "`by'" /*
	   */ _col(16) "score"  _col(28) "obs" _col(37) "sum of ranks"
	local i=1
	while `i'<_N  & `usable'[`i']!=.{
	    di in ye _col(2) %8.1g `BY'[`i'] _col(11) %10.1g `score'[`i'] /*
		    */ %10.0g `obs'[`i'] "    " %10.1g `ranksum'[`i']
	    local i = `i'+1
	}
	local i
	di
}
/*
	Display the O,E,V for each strata.
*/
if "`detail'"=="" {
	di
	qui replace `usable' = cond(`ET'!=0,`ET'/`ET',1)
	sort `usable' `strata'
	local scol = max(0,15 - length("`strata'"))
	noi di in gr _col(`scol') "`strata'" _col(26) "Obs" /*
			*/ _col(38) "Exp" _col(50) "Var"
	if "`strata'" !="" {
		local nsv : word count `strata'
		local j = 1
		while `j'<=`nsv' {
			local str : word `j' of `strata'
			local strlab : val lab `str'
			if "`strlab'"!="" {
				tempvar str`j'
				decode `str',gen(`str`j'')
				local str "`str`j''"
			}
			local STRATA "`STRATA' `str'"
			local j = `j'+1
		}
	}
	local i = 1
	while `i'<=_N  & `usable'[`i']!=.{
		if "`strata'" !="" {
			local stratum 
			local j = 1
			while `j'<=`nsv' {
				local str : word `j' of `STRATA'
				local stratum "`stratum' _skip(1) `str'[`i']"
				local j = `j'+1
			}
		}
		noi di in ye _col(7) `stratum' _col(20) %10.1g  `T'[`i'] /*
		    */ _col(32) %10.1g `ET'[`i'] _col(45) %10.0g `VT'[`i'] 
		local i = `i'+1
	}
	if `i'>2 {
	   local dd "    ------"
	   di in ye _col(5)"`dd'" _col(20)"`dd'" _col(32)"`dd'" _col(45) "`dd'" 
	   di in ye _col(10) "Total" _col(20) %10.1g  `O' _col(32) %10.1g `E' /*
		    */  _col(45) %10.0g `V' 
	}
	di 
}
local varname : var lab `varlist'
if "`varname'"=="" {local varname "`varlist'"}
local byname : var lab `by'
if "`byname'"=="" {local byname "`by'"}
if "`strata'"!=""{ local str_str ", stratified by `strata'"}
di in gr "Nonparametric test for trend in `varname' with `byname'`str_str'"
di in gr "     z  = " in ye %5.2f `z' /*
 */in gr ",  chi-squared(1) = " in ye %6.2f `z'^2
di in gr "  P>|z| = " in ye %6.4f `pval'
global S_1 = `O' - `E'
global S_2 = `V'
global S_3 = `z'
global S_4 = `pval'
end

