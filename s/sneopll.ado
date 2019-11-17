*! Version 1.3.3 June 19 2003 Mark Stewart
program define sneopll
	version 7
	args lnf xb
	tempname cut1 theta mu0 mu1
	scalar `cut1'=$Cut1
	local n1 = $Ncat-1
	macro shift 2
	forvalues i=2(1)`n1' {
	local cut`i' `"`1'"'
	macro shift
	}
	local b0 = 1
	forvalues i=1(1)$K {
	local b`i' `"`1'"'
	macro shift
	}
	scalar `theta' = 0
	local K2 = $K*2
	scalar `mu0' = 1
	scalar `mu1' = 0
	forvalues j=0(1)`K2' {
		local j2 = `j'-2
		tempname c`j'
		scalar `c`j'' = 0
		local ulim = min($K,`j')
		local llim = max(`j'-$K,0)
		forvalues i=`llim'(1)`ulim' {
			local ji = `j'-`i'
			scalar `c`j'' = `c`j'' + (`b`i''*`b`ji'')
		}
		if `j'>1 {
			tempname mu`j'
			scalar `mu`j'' = (`j'-1)*`mu`j2''
		}
		scalar `theta' = `theta' + (`c`j''*`mu`j'')
	}
	tempvar A AL1 AL2 F1 A0 A0L1 A0L2 F0
	gen double `F1' = `c1'
	gen double `AL2' = 0
	gen double `AL1' = 1
	gen double `A' = 0
	gen double `F0' = `c1'
	gen double `A0L2' = 0
	gen double `A0L1' = 1
	gen double `A0' = 0
* Cases with $ML_y1=1
	forvalues j=2(1)`K2' {
		quietly replace `A' = ((`j'-1)*`AL2') + ((`cut1'-`xb')^(`j'-1)) if $ML_y1==1
		quietly replace `AL2' = `AL1' if $ML_y1==1
		quietly replace `AL1' = `A' if $ML_y1==1
		quietly replace `F1' = `F1' + (`c`j''*`A') if $ML_y1==1
	}
	quietly replace `lnf' = ln(norm(`cut1'-`xb') - (`F1'*(normden(`cut1'-`xb'))/`theta')) if $ML_y1==1
* Cases with $ML_y1=2 to $Ncat-1
	forvalues gp=2(1)`n1'{
	local gp1 = `gp'-1
	forvalues j=2(1)`K2' {
		quietly replace `A' = ((`j'-1)*`AL2') + ((`cut`gp''-`xb')^(`j'-1)) if $ML_y1==`gp'
		quietly replace `AL2' = `AL1' if $ML_y1==`gp'
		quietly replace `AL1' = `A' if $ML_y1==`gp'
		quietly replace `F1' = `F1' + (`c`j''*`A') if $ML_y1==`gp'
		quietly replace `A0' = ((`j'-1)*`A0L2') + ((`cut`gp1''-`xb')^(`j'-1)) if $ML_y1==`gp'
		quietly replace `A0L2' = `A0L1' if $ML_y1==`gp'
		quietly replace `A0L1' = `A0' if $ML_y1==`gp'
		quietly replace `F0' = `F0' + (`c`j''*`A0') if $ML_y1==`gp'
	}
	quietly replace `lnf' = ln(norm(`cut`gp''-`xb') - (`F1'*(normden(`cut`gp''-`xb'))/`theta') /*
		*/ - norm(`cut`gp1''-`xb') + (`F0'*(normden(`cut`gp1''-`xb'))/`theta')) if $ML_y1==`gp'
	}
* Cases with $ML_y1=$Ncat
	forvalues j =2(1)`K2' {
		quietly replace `A0' = ((`j'-1)*`A0L2') + ((`cut`n1''-`xb')^(`j'-1)) if $ML_y1==$Ncat
		quietly replace `A0L2' = `A0L1' if $ML_y1==$Ncat
		quietly replace `A0L1' = `A0' if $ML_y1==$Ncat
		quietly replace `F0' = `F0' + (`c`j''*`A0') if $ML_y1==$Ncat
	}
	quietly replace `lnf' = ln(norm(`xb'-`cut`n1'') + (`F0'*(normden(`cut`n1''-`xb'))/`theta')) if $ML_y1==$Ncat
end
