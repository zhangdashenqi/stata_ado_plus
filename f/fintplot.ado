* forestplot version 1.4 SB 13Sept2003

* program to calculate table for interaction and produce forest plots

program define fintplot

syntax varlist [if] [in], [by(varname) strata(varname)] logistic(numlist) logscale(numlist)

if `logistic'==0 {
	fintplotcox `0'
}
else {
	fintplotlog `0'
}

end

exit


