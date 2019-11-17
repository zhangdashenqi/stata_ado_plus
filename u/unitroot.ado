*! unitroot -- unit root tests
*! version 1.0.0     Sean Becketti     5/5/92
program define unitroot
	version 3.0
	local varlist "req ex min(1) max(1)"
	local options "Lags(int 4) Trend"
	parse "`*'"
	if (`lags' < 0) {
		di in red "lags() must be >= 0"
		error 99
	}
	quietly dickey `varlist', lags(`lags') `trend' nof
	local l = -1
	while (`l' < `lags') {
		local l = `l' + 1
		local j = `l' + 1
		local df`l' = ${S_`j'}
	}
	quietly ppunit `varlist', lags(`lags') `trend'
	di in gr _new "  Lags   tau   Z(alpha)  Z(t)"
	di in gr "-----------------------------"
	local l = -1
	while (`l' < `lags') {
		local l = `l' + 1
		local i = 2 + 2*`l'
		local j = 3 + 2*`l'
		di in ye %5.0g `l' _skip(3) %5.0g `df`l'' _skip(3)  /*
*/			 %5.0g ${S_`i'} _skip(3) %5.0g ${S_`j'}
	}
end
