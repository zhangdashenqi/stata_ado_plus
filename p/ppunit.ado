*! ppunit -- Phillips-Perron test for a unit root.
*! version 3.0.0     Sean Becketti     April 1992
*  keep S_X_unit and S_X_date for new lag, SRB 10/11/94
program define ppunit
	version 3.0
	local varlist "req ex min(1) max(1)"
	local if "opt"
	local in "opt"
	local options "Lags(int 4) Trend *"
	parse "`*'"
        if (`lags'<0) {
                di in red "lags() must be >= 0"
                error 99
        }
/*
        Save the input data set, then drop the unwanted observations.
        This procedure guarantees that unwanted observations do not
        creep into the lags.
*/
	local sfn "$S_FN"
	tempfile user
	quietly save `user'
	capture {
        	cap keep `in'
        	cap keep `if'
        	local y "`varlist'"
		keep `y' $S_X_unit $S_D_date	/* Drop all other variables */
/*
	Prune the data set of missing observations, and generate a
	trend if one is requested.
*/
		lag 1 `y', suffix(y)
		drop if `y'==. | L.y==.
		local ift "no trend"
		if "`trend'"!="" {
			local ift "trend"
			tempvar t
			gen int t = _n
			local trend "t"
		}
/*
	Run the Phillips-Perron regression and start calculating
	the components needed to produce the test statistic.
*/
		reg `y'
		local T = _result(1)
		local mfac = _result(4)/`T'^2
		if "`trend'"!="" {
			local mbaryy = `mfac'
			sum `y'
			local my = _result(3)/sqrt(`T')
			tempvar ysq ty   
			gen double ysq = `y'^2
			gen double ty = _n*`y'
			sum ysq
			local myy = _result(3)/`T'
			sum ty
			local mty = _result(3)/(sqrt(`T')^3)
			local T1 = 1/`T'
			local T2 = 1/`T'^2
			local mfac = (1-`T2')*`myy' - 12*`mty'^2 /*
*/				    + 12*(1+`T1')*`mty'*`my'     /*
*/				    - (4 + 6*`T1' + 2*`T2')*`my'^2
		}
		reg `y' L.y `trend'
		local alpha = _b[L.y]
		local sse = _result(4)/`T'
		local ser = sqrt(`sse')
*		local ser = _result(5)*_result(9)/`T'
* 		local ser = _result(9)
		tempvar resid
		predict `resid', resid
                local sign = sign(_b[L.y]-1)
                test L.y = 1
                local tau = `sign'*sqrt(_result(6))	/* t-statistic */
        	noi di in gr _new "(obs=`T', `ift')"
	        noi di in gr "  Lags  Z(alpha)  Z(t)"
       		noi di in gr "----------------------"
		local lag = 0
		local stl2 = `sse'
		local lambda = (`stl2'-`ser'^2)/2
		local za = `T'*(`alpha'-1) - `lambda'/`mfac'
		local ztau = `ser'*`tau'/sqrt(`stl2') /*
*/			    - `lambda'/sqrt(`stl2'*`mfac')
                noi di in ye %5.0g `lag' _skip(4) %5.0g `za' _skip(3) %5.0g `ztau'
		local za0 "`za'"
		local zt0 "`ztau'"
		if (`lags' > 0) {
			tempvar acov
			gen `acov' = .
		}
		while (`lag'<`lags') {
			local lag = `lag' + 1
			local j = 0
			local sum = 0
			while (`j' < `lag') {
				local j = `j' + 1
				replace `acov' = sum(`resid'*`resid'[_n-`j'])
				local sum = `sum' /*
*/					+ (1-`j'/(`lag'+1))*`acov'[_N]
			}
			local stl2 = `sse' + 2*`sum'/`T'
			local lambda = (`stl2'-`ser'^2)/2
			local za = `T'*(`alpha'-1) - `lambda'/`mfac'
			local ztau = `ser'*`tau'/sqrt(`stl2') /*
*/			    	    - `lambda'/sqrt(`stl2'*`mfac')
                	noi di in ye %5.0g `lag' _skip(4) %5.0g `za' _skip(3) %5.0g `ztau'
			local za`lag' "`za'"
			local zt`lag' "`ztau'"
        	}
/*
        Cleanup.
*/
	}
	local rc=_rc
	quietly use `user', clear
	mac def S_FN "`sfn'"
	erase `user'
	error `rc'
	mac def S_1 "`lags'"
	local i = 1
	local lag = 0
	while (`lag' <= `lags') {
		local i = `i' + 1
		mac def S_`i' "`za`lag''"
		local i = `i' + 1
		mac def S_`i' "`zt`lag''"
		local lag = `lag' + 1
	}
end
