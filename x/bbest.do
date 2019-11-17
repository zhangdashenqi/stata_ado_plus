* Program to reproduce the some results from Blundell-Bond 1998, as revised in "bbest1.out" in http://www.doornik.com/download/dpdox121.zip.
clear all
set mem 32m
set matsize 800
use "http://www.stata-press.com/data/r7/abdata.dta"

* Make variables whose first differences are year dummies and the constant term.
* These are not necessary in general, but is needed to exactly imitate DPD because it enters time dummies
* and the constant term directly, undifferenced, in difference GMM.
forvalues y = 1979/1984 {
	gen yr`y'c = year>=`y'
}
gen cons = year

capture local version = c(stata_version)
if _rc == 0 {
	* Replicate one-step difference GMM with xtabond. This only works in Stata 8.
	query born
	if $S_1 < d(18may2004) {
		xtabond n yr*c, lags(1) pre(w k, lags(1,.) end) robust small
	}
	else {
		xtabond n yr*c, lags(1) pre(w k, lags(1,.)) robust small		
	}
}

* Now replicate difference GMM runs with xtabond2
xtabond2 n L.n L(0/1).(w k) yr*c cons, gmm(L.(w k n)) iv(yr*c cons) noleveleq noconstant robust small
xtabond2 n L.n L(0/1).(w k) yr*c cons, gmm(L.(w k n)) iv(yr*c cons) noleveleq robust twostep small

* Now replicate system GMM runs with xtabond2.
* eq(level) option is also not necessary in general, but needed for perfect imitation.
* Similarly, dpds2 is an undocumented option that simulates what appears to be a bug in DPD in one-step GMM
* that doubles the point estimate of the variance of the errors (sig2) and affects the Sargan and AR() statistics.
* dpds2 is only for demonstrating the capacity of xtabond2 to match DPD perfectly.
xtabond2 n L.n L(0/1).(w k) yr1978-yr1984, gmm(L.(w k n)) iv(yr1978-yr1984, eq(level)) h(2) dpds2 robust small
xtabond2 n L.n L(0/1).(w k) yr1978-yr1984, gmm(L.(w k n)) iv(yr1978-yr1984, eq(level)) h(2) robust twostep small
