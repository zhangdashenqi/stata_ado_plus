capture program drop escftest
* Stata Journal review 
* set tab to 8 spaces for alignment 
program escftest, rclass sortpreserve byable(recall)
	version 9.2
	syntax varname(numeric) [if] [in], Group(varname) ///
	[t1(real 0.4) t2(real 0.8)]

	marksample touse
	markout `touse' `group', strok 

	quietly {
		count if `touse' 
		if r(N) == 0 error 2000 
		local n = r(N) 

		tempvar g 
		bysort `touse' `group' : gen `g' = (_n == 1) * `touse' 
		replace `g' = sum(`g') 
		local ng = `g'[_N] 
      		if `ng' == 1 {
			di as err "1 group found, 2 required"
			exit 499
		}
		else if `ng' > 2 { 
			di as err "`ng' groups found, 2 required" 
			exit 499 
		}	

		count if `g' == 1 & `touse'
		local n1 = r(N)
		count if `g' == 2  & `touse'
		local n2 = r(N)
		local group1 = `group'[_N - `n2']
		local group2 = `group'[_N]
	}

	mata: ///
	EppsSingleton("`varlist'", "`g'", "`touse'", `n1', `n2', `t1', `t2')

	local where = length(`"`group' = `group1':"')
	local where = 15 + max(`where', length(`"`group' = `group2':"'))  

	di _n as txt ///
	"Epps-Singleton Two-Sample Empirical Characteristic Function test"
	di _n as txt "Sample sizes: " _c 
	di as txt `"{col 15}`group' = `group1'"'  ///
	          "{col `where'}" as res %12.0f `n1'
	di as txt `"{col 15}`group' = `group2'"' /// 
	          "{col `where'}" as res %12.0f `n2'
	di as txt "{col 15}total{col `where'}" as res %12.0f `n'
	di as txt "t1 {col `where'}" as res %12.3f `t1'
	di as txt "t2 {col `where'}" as res %12.3f `t2'
	di _n as txt "Critical value for W2 at 10%" as res %10.3f r(crit_val_10) 
	di as txt    "                          5%" as res %10.3f r(crit_val_5) 
	di as txt    "                          1%" as res %10.3f r(crit_val_1) 
	di as txt    "Test statistic W2           " as res %10.3f r(W2)         

	di _n as txt "Ho: distributions are identical" 
	di    as txt "P-value" as res "{col `where'}" %12.5f r(p_value)
	if r(correction) != 1 {
		di _n as txt "{p}Note: a small sample correction factor of " /// 
		"C(" as res "`n1'" as txt "," as res "`n2'" as txt ") = " ///
		as res %7.5f r(correction) as txt " has been applied to W2.{p_end}"
	}

	return scalar crit_val_1  = r(crit_val_1) 
	return scalar crit_val_5  = r(crit_val_5) 
	return scalar crit_val_10 = r(crit_val_10) 
	return scalar p_val       = r(p_value)   
	return scalar correction  = r(correction) 
	return scalar W2          = r(W2)       
	return scalar t2          = `t2'
	return scalar t1          = `t1'
	return local group2       `"`group2'"' 
	return local group1       `"`group1'"'
end

mata: 
void EppsSingleton(
string scalar varname, 
string scalar groupname, 
string scalar tousename, 
real scalar n1,
real scalar n2,
real scalar t1,
real scalar t2
) 

{
real matrix sample, g_xm, g_x1m, g_x2m 
real rowvector t_hat, s1h, s2h, omega_hat, gs2 
real scalar n, sigma_hat, W2, rg, corrfac 

sample = st_data(., (varname, groupname), tousename)
n = rows(sample)

sample = sort(sample, 1)
sigma_hat = 0.25 * (sample[floor(n * 0.25), 1] + 
                    sample[floor(n * 0.25) + 1, 1] +  
                    sample[floor(n * 0.75), 1] + 
		    sample[floor(n * 0.75) - 1, 1])
t_hat = (t1, t2) / sigma_hat

sample = sort(sample, 2)
g_xm = J(n, 4, .)
g_xm[., 1] = cos(t_hat[1] :* sample[, 1])
g_xm[., 3] = cos(t_hat[2] :* sample[, 1])
g_xm[., 2] = sin(t_hat[1] :* sample[, 1])
g_xm[., 4] = sin(t_hat[2] :* sample[, 1])
g_x1m = g_xm[1..n1,] 
g_x2m = g_xm[n1 + 1..n,] 

s1h = variance(g_x1m) * ((n1 - 1) / n1)
s2h = variance(g_x2m) * ((n2 - 1) / n2)
omega_hat = (n / n1) * s1h + (n / n2) * s2h
gs2 = mean(g_x1m) - mean(g_x2m)
W2 = n * gs2 * luinv(omega_hat) * gs2' 
rg  = rank(omega_hat)
corrfac = 
(n1 < 25 & n2 < 25) ? (1 / (1 + (n1 + n2)^-.45 + 10.1 * (n1^-1.7 + n2^-1.7))) : 1 
W2 = W2 * corrfac 

st_numscalar("r(correction)", corrfac) 
st_numscalar("r(W2)",  W2) 
st_numscalar("r(p_value)", 1 - chi2(rg, W2)) 
st_numscalar("r(crit_val_10)", invchi2(rg, 0.9))
st_numscalar("r(crit_val_5)", invchi2(rg, 0.95))
st_numscalar("r(crit_val_1)", invchi2(rg, 0.99))

}

end 
