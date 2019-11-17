*! version 1.3.0  10 July 1996 (STB-33: sg57)
* N.J. Cox, University of Durham
* several major and minor improvements suggested by W.W. Gould
* adjusted residuals added July 1996
program define tab2i
	version 4.0
	parse "`*'", parse(",\ ")

	local r 1
	local c 1
	local cols .
	while ("`1'"!="" & "`1'"!=",") {
		if "`1'"=="\" {
			local r = `r' + 1
			if `cols'==. {
				if (`c'<=2) {
					di in red "too few columns"
					exit 198
				}
				local cols `c'
			}
			else {
				if (`c'!=`cols') { error 198 }
			}
			local c 1
		}
		else {
			conf integer num `1'
			if `1'<0 { error 411 }
			local n`r'`c' `1'
			local c = `c' + 1
		}
		mac shift
	}
	if (`c'!=`cols') { error 198 }
	local cols = `cols' - 1
	local rows = `r'

	local options "REPLACE"
	parse "`*'"
    quietly {
        if "`replace'"!="" {
            drop _all
        }
        preserve
        drop _all
        local obs 1
        set obs 1
        gen byte row = .
        gen byte col = .
        gen long observed = .
        local r 1
        while (`r'<=`rows') {
            local c 1
            while (`c'<=`cols') {
                set obs `obs'
                replace row = `r' in l
                replace col = `c' in l
                replace observed = `n`r'`c'' in l
                local obs = `obs' + 1
                local c = `c' + 1
            }
            local r = `r' + 1
        }
        sort col
        by col: gen double colsum = sum(observed)
        by col: replace colsum = colsum[_N]
        sort row col
        by row: gen double rowsum = sum(observed)
        by row: replace rowsum = rowsum[_N]
        su observed
        local tabsum = _result(1)*_result(3)
        gen double expected = (rowsum * colsum)/`tabsum'
        gen double Pearson = (observed - exp)/sqrt(exp)
        gen double adjusted = Pearson / sqrt((1 - rowsum/`tabsum')      /*
        */                                          *(1 - colsum/`tabsum'))
        format exp Pear adj %10.3f
        drop rowsum colsum
        label var observed "observed frequency"
        label var expected "expected frequency"
        label var Pearson "Pearson residual"
        label var adjusted "adjusted residual"
        noisily di _n in g _dup(53) " " "residuals" _c
        noisily l, noobs
        tabulate row col [fw=obs], chi2
        local df = (`rows' - 1)*(`cols' - 1)
        noisily di _n in g _dup(10) " " "Pearson chi2(" in y "`df'"   /*
        */ in g ") = " in y %8.4f _result(4) in g "   Pr = "          /*
        */ in y %5.3f _result(5)
        if "`replace'"!="" {
            restore, not
        }
    }
end

