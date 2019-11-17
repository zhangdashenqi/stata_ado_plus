*! version 2.0.0  22dec1998
* modified by Jeroen Weesie
* option -compact- displays only the parameters of the working correlation matrix.
program define xtcorr2
	version 6.0

	if `"`e(cmd)'"' != "xtgee" {
		error 301
	}
	syntax [, Compact]
	if "`compact'" == "" {
		DispR
	}
	else {
		tempname r
		matrix `r' = e(R)

		if "`e(corr)'" == "independence" {
			di _n in gr "Error structure: " in ye "`e(corr)'"
			di in gr "The within-`e(ivar)' correlation R is the Identity matrix"
		}

		else if "`e(corr)'" == "exchangeable" {
			di _n in gr "Error structure: " in ye "`e(corr)'"
			di in gr "Estimated within-`e(ivar)' correlation: " in ye %6.4f `r'[2,1]
		}

		else if substr("`e(corr)'",1,2) == "AR" {
			di _n in gr "Error structure: " in ye "`e(corr)'"
			local k = substr("`e(corr)'",4,length("`e(corr)'")-4)
			if `k' == 1 {
				di in gr "Estimated within-`e(ivar)' autocorrelation: " in ye %6.4f `r'[2,1]
			}
			else {
				di in gr "Estimated within-`e(ivar)' correlations"
				local i 1
				while `i' <= `k' {
					di _col(11) in gr "lag `i' : " in ye %6.4f `r'[`i'+1,1]
					local i = `i'+1
				}
				if `k' < colsof(`r')-1 {
					di in gr _col(11) "lag>`k' : " in ye 0
				}
			}
		}

		else if substr("`e(corr)'",1,10) == "stationary" {
			di _n in gr "Error structure: " in ye "`e(corr)'"
			local k = substr("`e(corr)'",12,length("`e(corr)'")-12)
			di in gr "Estimated within-`e(ivar)' correlations "
			local i 1
			while `i' <= `k' {
				di _col(11) in gr "lag `i' : " in ye %6.4f `r'[`i'+1,1]
				local i = `i'+1
			}
			if `k' < colsof(`r')-1 {
				di in gr _col(11) "lag>`k' : " in ye 0
			}
		}

		else {
			* no suitable compact format
			DispR
		}
end

program define DispR
	di _n in gr "Estimated within-`e(ivar)' correlation matrix R:"
	mat list e(R), format(%6.4f) noheader
end
exit
