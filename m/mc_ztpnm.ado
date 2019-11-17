*global logpath "D:\Arbeit\AAA-ztpnm\latex"
*sjlog using "$logpath\mcztpnm", replace
program define mc_ztpnm, rclass
	syntax ,COMmand(string) [obs(integer 3000) Beta(real 0.5) CONStant(real 0.5) SIGma(real 0.7) options(string)] 
	qui {
	drop _all
	set obs `obs'
	gen x = invnormal(runiform())
	gen e = invnormal(runiform())*`sigma'
	gen xb = `constant' + `beta'*x + e
	gen z = runiform()
	gen double fy_cdf=0
	gen y=.
	forvalues k=1/200 {
		gen double fy`k' = (exp(xb)^`k'*exp(-exp(xb)))/((1-exp(-exp(xb)))*exp(lnfactorial(`k')))
		replace fy_cdf = fy_cdf + fy`k'
		replace y=`k' if fy_cdf - fy`k'<z & fy_cdf>z
	}
	}
	`command' y x, robust `options'
end
*cap sjlog close, replace
