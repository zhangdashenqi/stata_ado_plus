* forestplotk version 1.0 SB 21Apr2004

* program to calculate table for interaction and produce forest plots for 2*k

program define fintplotk

syntax varlist [if] [in], [strata(varname)] logistic(numlist) logscale(numlist)

if `logistic'==0 {
	fintplotkcox `0'
}
else {
	fintplotklog `0'
}

end

exit


