*! version 1.0.0 cagregory 3 19 14
program define switch_oprobit_p

	
	tempname cuts1 cuts0
	local cutpts = e(cuts)
	mat `cuts0' = J(1,`cutpts',0)
	mat `cuts1' = J(1,`cutpts',0)
	forv i = 1/`cutpts' {
		mat `cuts0'[1,`i']=_b[cut_0`i':_cons]
		mat `cuts1'[1,`i']=_b[cut_1`i':_cons]
		}
	
 
 	local nchoices=`cutpts'+1 
	 
 	local PFX
		forv i = 1/`nchoices'{
			local PFX "`PFX' P1`i' P0`i' TE`i' TT`i' SETE`i'"
		 	}
	
		
	local myopts PTR XBOUT0 XBOUT1 `PFX'
	
	_pred_se "`myopts'" `0'	
	if (`s(done)') { 
		exit 
	}
	local vtyp  `s(typ)'
	local varn `s(varn)'
	local 0 `"`s(rest)'"'

	syntax [if] [in] [, `myopts' noOFFset ]

	marksample touse
	
	
	
	local pfx
	forv i = 1/`nchoices'{
		local pfx "`pfx'`p1`i''`p0`i''`te`i''`tt`i''`sete`i''"
	 	}
	local type "`ptr'`xbout0'`xbout1'`pfx'"
	
	
	local ytr : word 1 of `e(depvar)'
   	local yout0 : word 2 of `e(depvar)'
 	local yout1 : word 3 of `e(depvar)'
 	local s = strlen("`yout0'")
 	local ss = `s'-1
 	local treatvar = substr("`yout0'",1,`ss')
   tempvar zbp xb0 xb1
   qui _predict double `zbp' if `touse', xb eq(#1) 
   qui _predict double `xb0' if `touse', xb eq(#2) 
	qui _predict double `xb1' if `touse', xb eq(#3)
     tempvar psel 
     qui g double `psel' = normal(`zbp')
	tempname cutmat_tr cutmat_out0 cutmat_out1 rho0 rho1 
	local neginf = minfloat()
	local posinf = maxfloat()
	mat `cutmat_tr' = `neginf',0,`posinf'
	mat `cutmat_out0'= `neginf',`cuts0', `posinf'
	mat `cutmat_out1'= `neginf',`cuts1', `posinf'
	local `rho0' = tanh(_b[atanh_rho0:_cons])
	local `rho1' = tanh(_b[atanh_rho1:_cons])
	tempvar xb1_0
	local xvec `e(rhsout)'
	qui g double `xb1_0'=0
	foreach x of local xvec {
		qui replace `xb1_0'=`x'*_b[`yout0':`x'] if `touse' & `ytr==1'
	} 
	
	
   if (missing("`type'") | "`type'" == "p11") {
           if missing("`type'") noisily display as text "(option p11 assumed; Pr(`ytr'=1, `yout1'=1)"
			  local cut_ltr = `cutmat_tr'[1,2]
			  local cut_htr = `cutmat_tr'[1,3]
			  local cut_lout = `cutmat_out1'[1,1]
			  local cut_hout = `cutmat_out1'[1,2]
			  //di `cut_hout'
           generate `vtyp' `varn' = binorm(`cut_htr'-`zbp',`cut_hout'-`xb1', ``rho1'')-  ///
			  		                     binorm(`cut_ltr'-`zbp', `cut_hout'-`xb1', ``rho1'')- ///
												binorm(`cut_htr'-`zbp', `cut_lout'-`xb1',``rho1'')+  ///
					                     binorm(`cut_ltr'-`zbp', `cut_lout'-`xb1',``rho1'') if `touse'
           label variable `varn' "Pr(`ytr'=1,`yout'=1)"
        
	}
	
	forv i = 2/`nchoices' {
		if "`type'"=="p1`i'" {
				local k = `i'+1
		  		local cut_ltr = `cutmat_tr'[1,2]
		  		local cut_htr = `cutmat_tr'[1,3]
		 		local cut_lout = `cutmat_out1'[1,`i']
		  		local cut_hout = `cutmat_out1'[1,`k']
            generate `vtyp' `varn' = binorm(`cut_htr'-`zbp',`cut_hout'-`xb1', ``rho1'')- ///
 			  		                     binorm(`cut_ltr'-`zbp', `cut_hout'-`xb1', ``rho1'')- ///
 												binorm(`cut_htr'-`zbp', `cut_lout'-`xb1',``rho1'')+  ///
 					                     binorm(`cut_ltr'-`zbp', `cut_lout'-`xb1',``rho1'') if `touse'
            label variable `varn' "Pr(`ytr'=1,`yout'=`i')"
		}
	}
	forv i = 1/`nchoices' {
		if "`type'"=="p0`i'" {
			local k = `i'+1
	  		local cut_ltr = `cutmat_tr'[1,1]
	  		local cut_htr = `cutmat_tr'[1,2]
	 		local cut_lout = `cutmat_out0'[1,`i']
	  		local cut_hout = `cutmat_out0'[1,`k']
         generate `vtyp' `varn' = binorm(`cut_htr'-`zbp',`cut_hout'-`xb0', ``rho0'')- ///
		  		                     binorm(`cut_ltr'-`zbp', `cut_hout'-`xb0', ``rho0'')- ///
											binorm(`cut_htr'-`zbp', `cut_lout'-`xb0',``rho0'')+  ///
				                     binorm(`cut_ltr'-`zbp', `cut_lout'-`xb0',``rho0'') if `touse'
		
		    label variable `varn' "Pr(`ytr'=0,`yout'=`i')"
		}
		
	if "`type'"=="te`i'" {
		local k = `i'+1
		local cut_ltr = `cutmat_tr'[1,2]
		local cut_htr = `cutmat_tr'[1,3]
 		local cut_lout1 = `cutmat_out1'[1,`i']
  		local cut_hout1 = `cutmat_out1'[1,`k']
		local cut_lout0 = `cutmat_out0'[1,`i']
		local cut_hout0 = `cutmat_out0'[1,`k']
		generate `vtyp' `varn' = normal(`cut_hout1'-`xb1')-normal(`cut_lout1'-`xb1')- ///
									 normal(`cut_hout0'-`xb0')+normal(`cut_lout0'-`xb0') if `touse'	
			label variable `varn' "MFX of `ytr' on P(`yout1'=`i')"
		}
		
	if "`type'"=="sete`i'" {
		local out = `i'
		tempname W d e f g h C t sehat
		local `t'=`cutpts'
		local treatvars `e(treatx)'
		local tcount: word count `treatvars'
		local treatvec = `tcount'+1
		local xvars `e(rhsout)' 
		local wcount: word count `xvars'
		local wfirst: word 1 of `xvars'
		local wlast: word `wcount' of `xvars'
		mat `W' = e(V)
		mat `d' = `W'["`yout0':`wfirst'" . . "`yout1':`wlast'", "`yout0':`wfirst'" . . "`yout1':`wlast'"]
		mat `g' = `W'["cut_01:" . . "cut_1``t'':", "cut_01:" . . "cut_1``t'':"]
		mat `e' = `W'["`yout0':", "cut_01:" . . "cut_1``t'':"]
		mat `f' = `W'["`yout1':", "cut_01:" . . "cut_1``t'':"]
		mat `h' = `e' \ `f'
		mat `C' = `W'  //`d', `h' \ `h'', `g'
		//mat list `C'
		local k = `i'+1
		local cut_ltr = `cutmat_tr'[1,2]
		local cut_htr = `cutmat_tr'[1,3]
 		local cut_lout1 = `cutmat_out1'[1,`i']
  		local cut_hout1 = `cutmat_out1'[1,`k']
		local cut_lout0 = `cutmat_out0'[1,`i']
		local cut_hout0 = `cutmat_out0'[1,`k']
		qui g `sehat' = .
		mata: mata_switchoprobit_sete_predict("`sehat'","`xvars'", "`C'", "`cut_hout1'", "`cut_lout1'", ///
			"`cut_hout0'", "`cut_lout0'", "`xb1'", "`xb0'", "`ytr'", "`cutpts'", "`treatvec'", "`out'")
		generate `vtyp' `varn' = `sehat' if `touse'	
			label variable `varn' "Standard Error of MFX of `ytr' on P(`yout1'=`i')"
		
	
	}
}


	forv i = 1/`nchoices' {
		if "`type'"=="tt`i'" {
		local k = `i'+1
		local cut_ltr = `cutmat_tr'[1,2]
		local cut_htr = `cutmat_tr'[1,3]
 		local cut_lout1 = `cutmat_out1'[1,`i']
  		local cut_hout1 = `cutmat_out1'[1,`k']
  		local cut_lout0 = `cutmat_out0'[1,`i']
		local cut_hout0 = `cutmat_out0'[1,`k']
		tempvar zx1 zx0
		qui g double `zx1' = binorm(`cut_htr'-`zbp', `cut_hout1'-`xb1', ``rho1'')- ///
 			                 binorm(`cut_ltr'-`zbp', `cut_hout1'-`xb1', ``rho1'')- ///
 							 binorm(`cut_htr'-`zbp', `cut_lout1'-`xb1',``rho1'')+  ///
 					         binorm(`cut_ltr'-`zbp', `cut_lout1'-`xb1',``rho1'') if `touse'
 		qui g double `zx0' = binorm(`cut_htr'-`zbp', `cut_hout0'-`xb0', ``rho0'')- ///
		  		             binorm(`cut_ltr'-`zbp', `cut_hout0'-`xb0', ``rho0'')- ///
							 binorm(`cut_htr'-`zbp', `cut_lout0'-`xb0',``rho0'')+  ///
				             binorm(`cut_ltr'-`zbp', `cut_lout0'-`xb0',``rho0'') if `touse'
		generate `vtyp' `varn' = (`zx1'-`zx0')/`psel' if `touse' & `ytr'==1		             
		/*generate `vtyp' `varn' = normal(`cut_hout'-`xb1')-normal(`cut_lout'-`xb1')- ///
									 normal(`cut_hout0'-`xb1_0')+normal(`cut_lout0'-`xb1_0') if `touse' & `ytr'==1*/
		label variable `varn' "Effect of `ytr' on P(`treatvar'=`i') for the treated"		 				 
		}
	}
	if "`type'" =="ptr" {
		generate `vtyp' `varn' = normal(`zbp') if `touse'
		label variable `varn' "Probability of selection into `ytr'"
		}
	
	if "`type'" =="xbout1" {
			generate `vtyp' `varn' = `xb1' if `touse'
			label variable `varn' "Outcome index, treated group"
	}
	if "`type'" =="xbout0" {
			generate `vtyp' `varn' = `xb0' if `touse'
			label variable `varn' "Outcome index, untreated group"
	}
	
end
	
/*mata: mata_switchoprobit_sete_predict("`sehat'", "`xvars'", "`C'", "`cut_hout1'", "`cut_lout1'", ///
			"`cut_hout0'", "`cut_lout0'", "`xb1'", "`xb0'", "`ytr'") */				
mata:
function mata_switchoprobit_sete_predict(string scalar new_se, string scalar xvars, string scalar Mat, string scalar chi1, string scalar clo1, ///
	 string scalar chi0, string scalar clo0, string scalar xb_1, string scalar xb_0, string scalar tvar, ///
	 string scalar cuts, string scalar tvec, string scalar out)	
		
		{
		n=st_nobs()	
		st_view(xb1,.,xb_1)
		st_view(xb0,.,xb_0)
		st_view(Y,.,tvar)
		khi1 = strtoreal(chi1)
		klo1 = strtoreal(clo1)
		khi0 = strtoreal(chi0)
		klo0 = strtoreal(clo0)
		tcols = strtoreal(tvec)
		cutpts = strtoreal(cuts)
		outr = strtoreal(out)
		nchoices = cutpts+1
		JMat = st_matrix(Mat)
		st_view(X,.,tokens(xvars))
		kx = cols(X)
		c = kx+cutpts
		newvar = J(n,1,.)
		tzero = J(n,tcols,0)
		kappa1 = J(n,cutpts, 0)
		delta1 = J(n, kx, 0)
		kappa0 = J(n, cutpts, 0)
		delta0 = J(n, kx, 0)
		rho = J(n,2,0)
		for (i=1;i<=kx;i++) {
				delta0[.,i] =  -1:*(normalden(khi0:-xb0[.,1]):-normalden(klo0:-xb0[.,1])):*X[.,i] 
				delta1[.,i] = (normalden(khi1:-xb1[.,1]):-normalden(klo1:-xb1[.,1])):*X[.,i] ///
							
				}
		if (outr==1){
				kappa0[.,1] = -1:*(normalden(khi0:-xb0[.,1]))
				kappa1[.,1] = (normalden(khi1:-xb1[.,1]))
		}
		if (outr==nchoices){
				kappa0[.,cutpts] = (normalden(klo0:-xb0[.,1]))
				kappa1[.,cutpts] = -1:*(normalden(klo1:-xb1[.,1]))
		}
		if (outr>1 & outr<nchoices){
				k = outr-1
				kappa0[.,outr] = (-1:*(normalden(khi0:-xb0[.,1]))) 
				kappa1[.,outr] = ((normalden(khi1:-xb1[.,1])))
				kappa0[.,k] = ((normalden(klo0:-xb0[.,1])))
				kappa1[.,k] = (-1:*(normalden(klo1:-xb1[.,1])))
		}
				
		delta = tzero, delta0, delta1, rho, kappa0, kappa1
		f = cols(delta)	
		for (i=1;i<=n;i++) {
			jacobmat = delta[i,.]
			newvar[i] = sqrt(jacobmat*JMat*jacobmat')
		}
		st_store(.,new_se,newvar)
	}	


end








