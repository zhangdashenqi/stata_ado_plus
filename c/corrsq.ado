*! version 1.0 -- pbe -- 2/28/08
program corrsq
version 10.0
syntax [, Matrix(string)]
tempvar cor

if "`matrix'"=="" {
  mat `cor' = r(C)
}
else {
  mat `cor' = `matrix'
}
if `cor'[1,1]!=1 {
  di as err "not a correlation matrix"
		exit 198
}
local nrows=rowsof(`cor')
forvalues i=1/`nrows' {
  forvalues j=1/`nrows' {
  mat `cor'[`i',`j']=`cor'[`i',`j']^2
}
}

display 
display as txt "Squared Correlation Coefficients"
mat list `cor', noheader
end
