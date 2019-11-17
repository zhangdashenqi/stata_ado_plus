*! 1.2.1  24mar2000  Jeroen Weesie/ICS
*  code was modelled after -cond- in Matlab 4.0
program define matcond, rclass
	version 6.0

	* scratch
	tempname A U w V maxw minw

	* parse input
	gettoken A0 0: 0, parse(",")
	mat `A' = `A0'  /* may trigger error msg */
	local nrA = rowsof(`A')
	local ncA = colsof(`A')

	syntax [, Cond(str) Display Format(str) ]

	* Stata's "mat svd" requires #rows >= #cols !!!!
	if rowsof(`A') < colsof(`A') {
		mat `A' = `A''
	}
	mat svd `U' `w' `V' = `A'

	* condition number is ratio of largest to smallest singular value
	local nw = colsof(`w')
	scalar `maxw' = 0
	scalar `minw' = 1E32
	local i 1
	while `i' <= `nw' {
		scalar `maxw' = max(`maxw', `w'[1,`i'])
		scalar `minw' = min(`minw', `w'[1,`i'])
		local i = `i'+1
	}

	if `minw' > 0 {
		return scalar cond = `maxw' / `minw'
	}
	else return scalar cond = .

	*  output
	if "`display'" != "" | "`cond'" == ""  {
		if "`format'" == "" {
			local format "%10.2g"
		}
		di in gr "condition number of `A0' [`nrA',`ncA'] = " /*
			*/ in ye `format' return(cond)
	}
	else scalar `cond' = return(cond)

	* other return values
	return matrix singval `w'
end

exit
For future version :

		* matrix name or expression? transpose is left with name
		gettoken token1 token2 : A0, parse(" +*([")
		if `"`token2'"' ~= "" {
			di in gr "matrix expression: ANS = " in ye `"`A0'"'
			local ans "ANS"
		}
		else local ans `A0'

		di in gr "condition number of `ans'[`nrA',`ncA'] = " /*
			*/ in ye `format' return(cond)

