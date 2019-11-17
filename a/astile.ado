*! 3.0.0  :  1Apr2017 , Added speed efficiency
*! Author : Attaullah Shah: attaullah.shah@imsciences.edu.pk
* In this current version, I have added more speed efficiency
* Also, this version fixes bugs related to [IF] and [IN] options when used with by(varlist)
* Verion 	2.0.0 	12Mar2017
*! Version 	1.0.0	 27Jun2015

cap prog drop astile
prog astile, byable(onecall) sortpreserve
syntax namelist=/exp [if] [in] [, Nquantiles(string) by(varlist) ]
marksample touse
	if "`nquantiles'" == "" {
		local nquantiles 2
	}
if "`by'"!=""{
	local _byvars "`by'"
}
if "`_byvars'"!="" {
tempvar numby n first
		gen `n'=_n
		qui bysort `_byvars' (`n'): gen  `first' = _n == 1 
		qui gen `numby'=sum(`first')  
		drop `first' `n'
}	


mata: fastile4("`exp'", "`_byvars'", "`numby'", "`namelist'",`nquantiles',  "`touse'") 
label var `namelist' "`nquantiles' quantiles of `exp'"

end
