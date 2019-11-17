program define mylog
// Program to create a log transformation of a single variable
version 12.1
syntax varlist(min=1 numeric), gen(string) [ replace ]
capture confirm var `gen'
if c(rc) != 0 {
	// `gen' does not exist; it's safe to create it and finish
	generate `gen' = ln(`varlist')
	exit
}
// `gen' does exist; it must be handled correctly
if "`replace'" == "replace" {
	replace `gen' = ln(`varlist')
}
else {
	display as error "`gen' already defined"
	error 110
}
end
