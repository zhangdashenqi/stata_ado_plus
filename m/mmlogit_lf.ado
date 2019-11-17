*** program for NB2 with multinomial endogeneity           ***
*** ml for mixed mlogit                                    ***
***                                                        ***
*** author: Partha Deb                                     ***
*** written: January 16, 2006                              ***
*** modified: February 26, 2006                             ***

program mmlogit_lf
	version 9.1
	args todo b lnf g negH $MMLOGIT_g

	tempname lnL gi
	tempname xb11 xb12 xb13 xb14 xb15 xb16 xb17 xb18 xb19
	tempname $MMLOGIT_gr

	qui gen double `lnL'=.

	forvalues i=1/$MMLOGIT_neq {
		mleval `xb1`i'' = `b', eq(`i')
	}

	forvalues i=`=$MMLOGIT_neq+1'/9 {
		qui gen double `xb1`i''=.
	}

	forvalues i=`=$MMLOGIT_neq+1'/9 {
		qui gen double `g`i''=.
	}

	scalar neq=$MMLOGIT_neq

	mata: mmlogit_lf("`lnL'",_mtreatnb_rmat,"neq","nobs","sim" ///
		,"`xb11'","`xb12'","`xb13'","`xb14'","`xb15'","`xb16'","`xb17'","`xb18'","`xb19'" ///
		,"`g1'","`g2'","`g3'","`g4'","`g5'","`g6'","`g7'","`g8'","`g9'","H")

	mlsum `lnf' = `lnL'

	local k = colsof(`b')
	local c 1
	matrix `g' = J(1,`k',0)
	
	forvalues i = 1/$MMLOGIT_neq {
		mlvecsum `lnf' `gi' = `g`i'', eq(`i')
		matrix `g'[1,`c'] = `gi'
		local c = `c' + colsof(`gi')
	}

	mat `negH' = -H

end

