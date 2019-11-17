*! version 6.0.0	29dec1998	(www.stata.com/users/becketti/tslib)
*! _ts_flag -- findlag utility
*! Sean Becketti, April 1991.
*  lags synonym for nlags added 6/16/92 by SRB.
program define _ts_flag
	version 3.0
	local varlist "req ex min(1)"
	local weight "aweight fweight"
	local options "Lags(int 0) Nlags(int 4) Reg(str) Ifcons(int 0) Detail Zero *"
	parse "`*'"
	local lags=cond(`lags',`lags',`nlags')		/* SRB, 6/16/92 */
	parse "`varlist'", parse(" ")
        local yvar "`1'"
        mac shift 
        local xvars "`*'"
        local l 0
        if "`zero'"~="" { local l -1 }
	tempvar order
        gen long `order' = _n
        local bLrmse .
        local bLAIC .
        local bLPC .
        local bLSC .
        local brmse .
        local bAIC .
        local bPC .
        local bSC .
	local weight "[`weight'`exp']"
        while (`l'<`lags') {
                local l = `l'+1
                local ll `l'
                if (`l'==0) {
                        qui `reg' `yvar' `xvars' `weight', `options'
                }
                else if (`l'==1) {
                        qui `reg' `yvar' `xvars' L_y `weight', `options'
                        local ll
                }
		else {
                        qui `reg' `yvar' `xvars' L_y-L`l'_y `weight', `options'
                }
                local T = _result(1)
                local K = _result(3) + `ifcons'   /* Correct K for intercept */
                local rmse = _result(9)
                local s2ml = _result(9)^2 * (`T'-`K')/`T'
                local AIC = log(`s2ml') + 2*`K'/`T'
                local PC = `rmse'^2 * (1 + `K'/`T')
                local SC = log(`s2ml') + log(`T')*`K'/`T'
                local bLrmse = cond(`rmse'<`brmse',`l',`bLrmse')
                local brmse = min(`brmse',`rmse')
                local bLAIC = cond(`AIC'<`bAIC',`l',`bLAIC')
                local bAIC = min(`bAIC',`AIC')
                local bLPC = cond(`PC'<`bPC',`l',`bLPC')
                local bPC = min(`bPC',`PC')
                local bLSC = cond(`SC'<`bSC',`l',`bLSC')
                local bSC = min(`bSC',`SC')
                capture test L`ll'_y
                local ndf = _result(3)
                local ddf = _result(5)
                local F = _result(6)
                local lastp = fprob(`ndf',`ddf',`F')
                if (`l'==0) { local allp .  }
                else if (`l'==1) { local allp `lastp' }
		else {
                        capture test L_y
                        local j 1
                        while (`j'<`l') {
                                local j = `j' + 1
                                capture test L`l'_y, accum
                        }
                        local ndf = _result(3)
                        local ddf = _result(5)
                        local F = _result(6)
                        local allp = fprob(`ndf',`ddf',`F')
                }
                if "`detail'"~="" {
                        di in ye %3.0f `l' _skip(3) %4.0g `K' _skip(4) /* 
*/                       %7.0g `rmse' _skip(4) %7.0g `AIC' _skip(4)   /*
*/                       %7.0g `PC' _skip(4) %7.0g `SC' _skip(4)   /*
*/                       %5.3f `allp' _skip(4) %5.3f `lastp'
                }
                if (`l'==`lags') {
                        if "`detail'"~="" {
				di in gr _dup(74) "-"
                                di in ye "Best" _skip(10) %4.0g `bLrmse' /*
*/                              _skip(7) %4.0g `bLAIC' _skip(7) %4.0g /*
*/                              `bLPC' _skip(7) %4.0g `bLSC'
                        }
			else {
                                di in ye %4.0g `bLrmse' /*
*/                              _skip(2) %4.0g `bLAIC' _skip(1) %4.0g /*
*/                              `bLPC' _skip(2) %4.0g `bLSC'
                        }
                }
        }
        sort `order'
end
