*** program for NB2 with multinomial endogeneity           ***
*** ml for joint mmlogit & nb2                             ***
***                                                        ***
*** author: Partha Deb                                     ***
*** written: January 16, 2006                              ***
*** modified: February 26, 2006                             ***

program mtreatnb_lf
	version 9.1
	args todo b lnf g negH $MTREATNB_g

	tempname lnL gi
	tempname xb11 xb12 xb13 xb14 xb15 xb16 xb17 xb18 xb19 xb2
	tempname lnalpha alpha lam1 lam2 lam3 lam4 lam5 lam6 lam7 lam8 lam9
	tempname $MTREATNB_gr

	scalar neq=$MMLOGIT_neq
	scalar neqall=$MTREATNB_neq

	qui gen double `lnL'=.

	forvalues i=1/$MMLOGIT_neq {
		mleval `xb1`i'' = `b', eq(`i')
	}

	local i = $MMLOGIT_neq+1
	mleval `xb2' = `b', eq(`i')
	local i = $MMLOGIT_neq+2
	mleval `lnalpha' = `b', eq(`i')

	forvalues i=1/$MMLOGIT_neq {
		mleval `lam`i'' = `b', eq(`=$MMLOGIT_neq+2+`i'')
	}

	qui gen double `alpha'=exp(`lnalpha')

	forvalues i=`=$MMLOGIT_neq+1'/9 {
		qui gen double `xb1`i''=.
	}

	forvalues i=`=$MMLOGIT_neq+1'/9 {
		qui gen double `lam`i''=.
	}

	forvalues i=`=$MMLOGIT_neq+1'/9 {
		qui gen double `g`i''=.
	}

	forvalues i=`=$MMLOGIT_neq+12'/20 {
		qui gen double `g`i''=.
	}

	mata: mtreatnb_lf("`lnL'",_mtreatnb_rmat,"neq","neqall","nobs","sim" ///
		,"`xb11'","`xb12'","`xb13'","`xb14'","`xb15'","`xb16'","`xb17'","`xb18'" ///
		,"`xb19'","`xb2'","`alpha'" ///
		,"`lam1'","`lam2'","`lam3'","`lam4'","`lam5'","`lam6'","`lam7'","`lam8'" ///
		,"`lam9'" ///
		,"`g1'","`g2'","`g3'","`g4'","`g5'","`g6'","`g7'","`g8'","`g9'" ///
		,"`g10'","`g11'","`g12'","`g13'","`g14'","`g15'","`g16'","`g17'" ///
		,"`g18'","`g19'","`g20'","H")

	mlsum `lnf' = `lnL'

	local k = colsof(`b')
	local c 1
	matrix `g' = J(1,`k',0)

	forvalues i = 1/$MMLOGIT_neq {
		mlvecsum `lnf' `gi' = `g`i'', eq(`i')
		matrix `g'[1,`c'] = `gi'
		local c = `c' + colsof(`gi')
	}

	local e 10
	forvalues i = `=$MMLOGIT_neq+1'/$MTREATNB_neq {
		mlvecsum `lnf' `gi' = `g`e'', eq(`i')
		matrix `g'[1,`c'] = `gi'
		local c = `c' + colsof(`gi')
		local e = `e' + 1
	}

	mat `negH' = -H

end
