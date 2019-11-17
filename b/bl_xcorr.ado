*! version 6.0.0	29dec1998	(www.stata.com/users/becketti/tslib)
*! bl_xcorr, xcorr -- Cross correlations with p-values.     STB-13: sts3
* version 1.0.0     Sean Becketti     April 11, 1993
program define bl_xcorr
	version 3.0
	local varlist "req ex min(2) max(2)"
	local if "opt"
	local in "opt"
        local options "Kendall Lags(int 0) Pearson Spearman"
	parse "`*'"
        if (`lags'<=0) {
                qui period
                if ($S_1>1) {local lags = $S_1}
                else {local lags = 4}
        }
	local corr "pearson"
	if ("`spearma'"!="") {local corr "spear"}
	if ("`kendall'"!="") {local corr "ktau"}
	local sfn "$S_FN"
	tempfile user
	quietly save `user'
	capture {
		mac def S_1
		mac def S_2
		mac def S_3
		parse "`varlist'", parse(" ")
		count if `1'!=. & `2'!=.
		if (_result(1)<2+`lags') {
			noi di in re "Not enough observations"
			error 99
		}
                noi di in gr _col(12) "lags of" _col(31) "lags of"
                noi di in ye _col(12) "`1'" _col(31) "`2'"
                noi di in gr "Lag" _col(10) "r" _col(15) "p-value" _col(29) "r" _col(34) "p-value"
                noi di in gr "---" _col(8) "-----" _col(15) "-------" _col(27) "-----" _col(34) "-------"
		`corr' `1' `2' `if' `in'
		local r0 = $S_4
		local p0 = $S_5
		noi di in ye " 0" _col(8) %5.2f =`r0' _col(16)  %5.2f =`p0'
		lag `lags' `1'
		lag `lags' `2'
		local lagx "`1'"
		local lagy "`2'"
		local i=0
		while (`i'<`lags') {
		 	local i=`i'+1
			_addl `lagx'
			local lagx "$S_1"
			_addl `lagy'
			local lagy "$S_1"
			local j=2*`i' - 1
			`corr' `2' `lagx' `if' `in'
			local r`j' = $S_4
			local p`j' = $S_5
			local k=`j'+1
			`corr' `1' `lagy' `if' `in'
			local r`k' = $S_4
			local p`k' = $S_5
			noi di in ye %2.0f =`i' _col(8) %5.2f =`r`j'' _col(16)  %5.2f =`p`j'' _col(27) %5.2f =`r`k'' _col(35) %5.2f =`p`k''
		}
	}
	local rc = _rc
	quietly use `user', clear
	erase `user'
	mac def S_FN "`sfn'"
	error `rc'
        mac def S_1 "`r0'"
        mac def S_2 "`p0'"
        local i=0
        while (`i'<`lags') {
		local i=`i'+1
                local j=4*(`i'-1)+3
                local k=2*(`i'-1)+1
                mac def S_`j' "`r`k''"
                local j=`j'+1
                mac def S_`j' "`p`k''"
                local k=`k'+1
                local j=`j'+1
                mac def S_`j' "`r`k''"
                local j=`j'+1
                mac def S_`j' "`p`k''"
        }
end
