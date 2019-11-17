*! tauprob - calculate MacKinnon's p-values for tau test for a unit root
*! version 1.0.0     Craig Hakkio     October 1993      sts6: STB-17
program define tauprob	/* tauprob model-type vars tau */
	version 3.1
	global S_1 = .
	if "`4'"!="" { error 198 }
	local type = "`1'"
       	local vars = `2'
	local tau = `3'
/*
	type is either 0, 1, or 2 (literal) or "c", "ct", "ctt" (literal).
*/
	cap conf integer n `type'
	if _rc {			/* not an integer */
		local stype = lower("`type'")
		if "`stype'"=="c" { local type 0 }
		else if "`stype'"=="ct" { local type 1 }
		else if "`stype'"=="ctt" { local type 2 }
		else error 198
	}
	else if (`type'<0) | (`type'>2) { error 198 }
	conf integer n `vars'
	if (`vars'<1) | (`vars'>6) { error 198 }
/*
	Assign the appropriate constants.  The mapping from our macro
	names to MacKinnon's parameter names is as follows:

		Us	MacKinnon
		--	---------
		tau	tau
		min	tau(min)
		max	tau(max)
		g0	gamma(0)
		g1	gamma(1)
		g2	gamma(2)
		g3	gamma(3)
*/
	local g3=0
        local min=.
	local max=.
	if `type'==0 {	/* no trend */
		if `vars'==1 {
			if `tau'>-1.586 {
#d ;
local min=-6.07 ; local max=1.73 ; local g0=1.7325 ; local g1=0.8898 ; local g2=-0.1836 ; local g3=-0.02820 ;
#d cr
			}
			else {
#d ;
local min=-18.83 ; local g0=2.1659 ; local g1=1.4412 ; local g2=0.03827 ;
#d cr
			}
		} /* vars==1 */
		else if `vars'==2 {
			if `tau'>-2.285 {
#d ;
local min=-5.74 ; local max=1.03 ; local g0=2.2092 ; local g1=0.6808 ; local g2=-0.2705 ; local g3=-0.03833 ;
#d cr
			}
			else {
#d ;
local min=-18.86 ; local g0=2.9200 ; local g1=1.5012 ; local g2=0.03980 ;
#d cr
			}
		} /* vars==2 */
		else if `vars'==3 {
			if `tau'>-2.877 {
#d ;
local min=-6.30 ; local max=1.09 ; local g0=2.7246 ; local g1=0.6720 ; local g2=-0.2545 ; local g3=-0.03256 ;
#d cr
			}
			else {
#d ;
local min=-23.48 ; local g0=3.4699 ; local g1=1.4856 ; local g2=0.03164 ;
#d cr
			}
		} /* vars==3 */
		else if `vars'==4 {
			if `tau'>-3.330 {
#d ;
local min=-7.09 ; local max=1.47 ; local g0=3.2776 ; local g1=0.7667 ; local g2=-0.2066 ; local g3=-0.02452 ;
#d cr
			}
			else {
#d ;
local min=-28.07 ; local g0=3.9673 ; local g1=1.4777 ; local g2=0.02632 ;
#d cr
			}
		} /* vars==4 */
		else if `vars'==5 {
			if `tau'>-3.399 {
#d ;
local min=-7.96 ; local max=2.02 ; local g0=3.8227 ; local g1=0.8783 ; local g2=-0.1617 ; local g3=-0.01817 ;
#d cr
			}
			else {
#d ;
local min=-25.96 ; local g0=4.5509 ; local g1=1.5338 ; local g2=0.02954 ;
#d cr
			}
		} /* vars==5 */
		else if `vars'==6 {
			if `tau'>-3.498 {
#d ;
local min=-8.70 ; local max=2.50 ; local g0=4.3062 ; local g1=0.9499 ; local g2=-0.1353 ; local g3=-0.01455 ;
#d cr
			}
			else {
#d ;
local min=-23.27 ; local g0=5.1399 ; local g1=1.6036 ; local g2=0.03445 ;
#d cr
			}
		} /* vars==6 */
	} /* type==0 */
	else if `type'==1 {	/* linear trend */
		if `vars'==1 {
			if `tau'>-2.657 {
#d ;
local min=-5.51 ; local max=1.11 ; local g0=2.6130 ; local g1=0.7831 ; local g2=-0.2828 ; local g3=-0.04285 ;
#d cr
			}
			else {
#d ;
local min=-16.18 ; local g0=3.2512 ; local g1=1.6047 ; local g2=0.04959 ;
#d cr
			}
		} /* vars==1 */
		else if `vars'==2 {
			if `tau'>-2.998 {
#d ;
local min=-6.31 ; local max=1.37 ; local g0=3.0348 ; local g1=0.8084 ; local g2=-0.2317 ; local g3=-0.03125 ;
#d cr
			}
			else {
#d ;
local min=-21.15 ; local g0=3.6646 ; local g1=1.5419 ; local g2=0.03645 ;
#d cr
			}
		} /* vars==2 */
		else if `vars'==3 {
			if `tau'>-3.372 {
#d ;
local min=-7.19 ; local max=1.79 ; local g0=3.4954 ; local g1=0.8754 ; local g2=-0.1840 ; local g3=-0.02271 ;
#d cr
			}
			else {
#d ;
local min=-25.37 ; local g0=4.0983 ; local g1=1.5173 ; local g2=0.02990 ;
#d cr
			}
		} /* vars==3 */
		else if `vars'==4 {
			if `tau'>-3.447 {
#d ;
local min=-8.11 ; local max=2.42 ; local g0=3.9904 ; local g1=0.9717 ; local g2=-0.1408 ; local g3=-0.01650 ;
#d cr
			}
			else {
#d ;
local min=-26.63 ; local g0=4.5844 ; local g1=1.5338 ; local g2=0.02880 ;
#d cr
			}
		} /* vars==4 */
		else if `vars'==5 {
			if `tau'>-3.510 {
#d ;
local min=-8.90 ; local max=2.91 ; local g0=4.4318 ; local g1=1.0233 ; local g2=-0.1183 ; local g3=-0.01317 ;
#d cr
			}
			else {
#d ;
local min=-26.53 ; local g0=5.0722 ; local g1=1.5634 ; local g2=0.02947 ;
#d cr
			}
		} /* vars==5 */
		else if `vars'==6 {
			if `tau'>-3.763 {
#d ;
local min=-9.63 ; local max=3.44 ; local g0=4.8639 ; local g1=1.0739 ; local g2=-0.1005 ; local g3=-0.01082 ;
#d cr
			}
			else {
#d ;
local min=-26.18 ; local g0=5.5300 ; local g1=1.5914 ; local g2=0.03039 ;
#d cr
			}
		} /* vars==6 */
	} /* type==1 */
	else if `type'==2 {	/* quadratic trend */
		if `vars'==1 {
			if `tau'>-3.034 {
#d ;
local min=-6.24 ; local max=1.55 ; local g0=3.3784 ; local g1=0.9197 ; local g2=-0.2238 ; local g3=-0.03180 ;
#d cr
			}
			else {
#d ;
local min=-17.17 ; local g0=4.0002 ; local g1=1.6580 ; local g2=0.04829 ;
#d cr
			}
		} /* vars==1 */
		else if `vars'==2 {
			if `tau'>-3.275 {
#d ;
local min=-7.23 ; local max=2.20 ; local g0=3.8109 ; local g1=1.0131 ; local g2=-0.1605 ; local g3=-0.02126 ;
#d cr
			}
			else {
#d ;
local min=-21.10 ; local g0=4.3534 ; local g1=1.6016 ; local g2=0.03795 ;
#d cr
			}
		} /* vars==2 */
		else if `vars'==3 {
			if `tau'>-3.582 {
#d ;
local min=-8.21 ; local max=2.86 ; local g0=4.2292 ; local g1=1.0763 ; local g2=-0.1225 ; local g3=-0.01526 ;
#d cr
			}
			else {
#d ;
local min=-24.33 ; local g0=4.7343 ; local g1=1.5768 ; local g2=0.03240 ;
#d cr
			}
		} /* vars==3 */
		else if `vars'==4 {
			if `tau'>-3.436 {
#d ;
local min=-9.12 ; local max=3.55 ; local g0=4.6461 ; local g1=1.1291 ; local g2=-0.0973 ; local g3=-0.01163 ;
#d cr
			}
			else {
#d ;
local min=-24.03 ; local g0=5.2140 ; local g1=1.6077 ; local g2=0.03345 ;
#d cr
			}
		} /* vars==4 */
		else if `vars'==5 {
			if `tau'>-2.760 {
#d ;
local min=-9.86 ; local max=4.03 ; local g0=5.0308 ; local g1=1.1549 ; local g2=-0.0848 ; local g3=-0.00970 ;
#d cr
			}
			else {
#d ;
local min=-24.33 ; local g0=5.6481 ; local g1=1.6274 ; local g2=0.03345 ;
#d cr
			}
		} /* vars==5 */
		else if `vars'==6 {
			if `tau'>-4.343 {
#d ;
local min=-10.55 ; local max=4.57 ; local g0=5.4153 ; local g1=1.1863 ; local g2=-0.0736 ; local g3=-0.00820 ;
#d cr
			}
			else {
#d ;
local min=-28.22 ; local g0=5.9296 ; local g1=1.5929 ; local g2=0.02822 ;
#d cr
			}
		} /* vars==6 */
	} /* type==2 */
/*
	Now apply the approximation formula.
*/
	local h = `g0' + `g1'*`tau' + `g2'*`tau'^2 + `g3'*`tau'^3
	local p = cond(`tau'<`min',0,cond(`tau'>`max',1,normprob(`h')))
	global S_1 = `p'
end
