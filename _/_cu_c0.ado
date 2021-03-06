*! _cu_c0 - 5 percent intercept for CUSUM of squares significance bands.
*! version 1.0.0     Sean Becketti     November 1993
*
*	This program is coded from Table C, pp. 364-365 of Harvey's
*		"The Econometric Analysis of Time Series"
*
program define _cu_c0	/* _cu_c0 T K */
quietly {
	version 3.1
	global S_1 = .
	if "`3'"!="" { error 198 }
	local T = "`1'"
       	local K = `2'
	conf integer n `T'
	conf integer n `K'
	local n = int(-1 + (`T'-`K')/2)
	tempvar c0
	gen double `c0' = `n' in f
	if `n' < 11 {
recode `c0' min/1=.475 2=.50855 3=.46702 4=.44641 5=.42174 6=.40045 7=.38294 8=.36697 9=.35277 10=.34022 in f
	}
	else if `n' < 21 {
recode `c0' 11=.32894 12=.31869 13=.30935 14=.30081 15=.29296 16=.28570 17=.27897 18=.2727 19=.26685 20=.26137 in f
	}
	else if `n' < 31 {
recode `c0' 21=.25622 22=.25136 23=.24679 24=.24245 25=.23835 26=.23445 27=.23074 28=.22721 29=.22383 30=.22061 in f
	}
	else if `n' < 41 {
recode `c0' 31=.21752 32=.21457 33=.21173 34=.20901 35=.20639 36=.20387 37=.20144 38=.1991 39=.19684 40=.19465 in f
	}
	else if `n' < 51 {
recode `c0' 41=.19254 42=.1905 43=.18852 44=.18661 45=.18475 46=.18295 47=.18120 48=.1795 49=.17785 50=.17624 in f
	}
	else if `n' < 61 {
recode `c0' 51=.17468 52=.17316 53=.17168 54=.17024 55=.16884 56=.16746 57=.16613 58=.16482 59=.16355 60=.1623 in f
	}
	else if `n' < 71 {
recode `c0' 61 62=.1599 63 64=.1576 65 66=.1554 67 68=.15329 69 70=.15127 in f
	}
	else if `n' < 81 {
recode `c0' 71 72=.14932 73 74=.14745 75 76=.14565 77 78=.14392 79 80=.14224 in f
	}
	else if `n' < 91 {
recode `c0' 81 82=.14063 83 84=.13907 85 86=.13756 87 88=.13610 89 90=.13468 in f
	}
	else {
recode `c0' 91 92=.13331 93 94=.13198 95 96=.1307 97 98=.12944 99/max=.12823 in f
	}
	global S_1 = `c0' in f
}	/* end quietly */
end
