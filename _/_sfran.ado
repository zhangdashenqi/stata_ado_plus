*! version 2.0.1  09/25/91  same as sfrancia, but uses egen trank()
*  Original written by P. Royston, updated by CRC
*  updated 9/93 by SRB to use egen rather than genrank
*               this fix improves treatment of sorting "in range"
program define _sfran
	version 3.1
	local varlist "req ex"
	local if "opt"
	local in "opt"
	parse "`*'"
	parse "`varlist'", parse(" ")
	#delimit ; 
	di in gr _n _col(16) "Shapiro-Francia W' test for normal data" _n
		" Variable |    Obs" _col(29) "W'"
		_col(39) "V'"
		_col(51) "z    Pr>z" _n 
		" ---------+" _dup(49) "-"
	;
	#delimit cr
	tempvar WD1
	while "`1'"~="" { 
		/*
			Calculate ranks
		*/
		capture drop `WD1'
/*		quietly genrank `WD1' = `1' `if' `in' */
		quietly egen `WD1' = trank(`1') `if' `in'
		/*
			Calculate number of good values
		*/
		local skip = 9 - length("`1'") 
		quietly summarize `WD1'
		local G=_result(1)
		if _result(1)<5 { 
			local R . 
			local w . 
			local Z .
			local sig .
			mac def S_5 . 
		}
		else {
			quietly replace `WD1'=invnorm((`WD1'-0.375)/(`G'+0.25))
			quietly corr `1' `WD1'
			local X=log(`G')-5
			local L=-0.0480157+`X'*(0.01971964-0.0119065*`X'*`X')
			local M=-exp(1.6930674+`X'*(0.1441647 /*
				*/	+`X'*(-0.01849276  /*
				*/	+`X'*(0.031074485+`X'*0.0055717663))))
			local S=exp(-0.510725+`X'*(-0.1160364 /*
				*/	+`X'*(-0.006702098 /*
				*/ 	+`X'*(0.054465944+`X'*0.0087397329))))
			local Y=(((1-(_result(4))^2)^`L')-1)/`L'
			local Z=(`Y'-`M')/`S'
			local R=(_result(4))^2
			local w=(1-`R')/( (`L'*`M'+1)^(1/`L') )
			mac def S_5 = normprob(-`Z')
			local sig=max($S_5,.00001)
		}
		#delimit ;
		di in gr _skip(`skip') "`1' |" in ye
			%7.0f `G' "    "
			%8.5f `R' "  "
			%8.3f `w' "   "
			%8.3f `Z' "  "
			%7.5f `sig'
		;
		#delimit cr
		mac shift 
	}
	mac def S_1 `G'		/* # observations		*/
	mac def S_2 `R'		/* W'				*/
	mac def S_3 `w'		/* V'				*/
	mac def S_4 `Z'		/* z				*/
	/* mac def S_5 */	/* P				*/
end
