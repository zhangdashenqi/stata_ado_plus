*! mnm updated graph to version 8, 1/11/05
*! version 1.0.0 --  6/30/00
program define hadiplot 
	version 6.0
	if e(cmd)~="regress" { error 301 }
	tempvar pf rf p e d2 
	quietly {
		predict `p', leverage
		predict `e', resid 
		gen `d2'=(`e'*`e')/`e(rss)'
		generate `pf' =  `p'/(1-`p')
	    generate `rf' = ((`e(df_m)'+1)/(1-`p'))*(`d2'/(1-`d2')) 
	    label variable `rf' "Residual"
	    label variable `pf' "Potential"
	    version 8.2: graph twoway scatter `pf' `rf' 
end
