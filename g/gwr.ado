/* v1.2 28may98	  STB-46 sg95 */

pro def gwr
	vers 5.0
	loc varlist "req ex"
	loc if "opt"
	loc in "opt"
	#d ;
	loc options "LINK(str) FAMily(str) EAST(str) NORTH(str) BANDWidth(real 0)
	SAVing(str)  REPS(int 1000)  DOTS REPLACE  DOUBle EFORM OFFset(str) TEST 	NOCONStant  NOLOg ITERate(int 50) INIt(str) LNOffset(str) SCALE(str) DISP(real 1) 	OUTfile(str) COMma WIDE SAMPle(real 100) MCSAVE(str)" ;
	#d cr	
	par "`*'"
	par "`varlist'", par(" ")
	loc i=0
	while "`1'" != ""{
		loc vn`i' "`1'"
		loc i=`i'+1
		ma s
	}
	loc nv=`i'-1
	if "`noconst'"=="" {
		loc tnv=`i'
		loc cons "cons"
		loc bcons "_b[_cons]"
	}
	else {
		loc tnv=`nv'
		loc cons ""
		loc bcons ""
	}
	cap keep `if'
	if "`east'"=="" | "`north'"=="" {
		di in red "Variables east() and north() need to be specified"
		e 100
	}

	if "`dots'"==""{
		loc dots "*"
	}
	else loc dots "n"

	if "`nolog'"=="" {
		loc nolog "n"
	}
	else loc nolog "*"

	if "`link'"=="" {
		loc link " "
	}
	else loc link "l("`link'")"

	if "`init'"=="" {
		loc init ""
	}
	else loc init "ini("`init'")"

	if "`family'"=="" {
		loc fam " "
	}
	else loc fam "f("`family'")"

	if "`offset'"=="" {
		loc off " "
		if "`lnoffse'"=="" {
			loc lnoff " "
		}
		else loc lnoff "lno("`lnoffse'")"
	}
	else loc off "o("`offset'")"

	if "`scale'"=="" {
		loc scale ""
	}
	else loc scale "s("`scale'")"

	if "`link'"==" " & "`fam'"==" " & "`off'"==" " & "`lnoff'"==" " {
		loc gm "regress"
		loc gpt " `noconst' "
		loc pred "pred"
	}
	else {
		loc gm  "glm"
	loc gpt "`link' `fam' nolo `eform' `scale' `lnoff' `off' `noconst'  `init' disp(`disp') "
		loc pred "glmpred"
	}
	if "`saving'"=="" {
		tempfile saving
		loc sv "*"
	}	
	else loc sv " "
	if "`mcsave'"=="" {
		tempfile mcsave
		loc msv "*"
	}
	else loc msv " "
	tempvar id w disti id2 mceast mcnorth p
	qui {
		g `id'=uniform()
		sort `id'
		replace `id'=_n
* Fit global model
		n di in y "Global Model"
		n `gm' `varlist', `gpt' 
		loc i=1
		loc plist " "
		loc mclist " "
		loc olist " "
		loc sdlist " "
		while `i'<=`nv' {
			loc plist "`plist' var`i'"
			loc mclist "`mclist' mcsd`i'"
			loc olist "`olist' ib`i'"
			loc sdlist "`sdlist' sdev`i'"
			loc i=`i'+1
		}
		g `id2'=.
		g `mceast'=.
		g `mcnorth'=.
		g `disti'=.
		g `w'=.
	tempname b1 b2 rho lwr upr zed b3 bw sc5 b4 sc6 sc obsbw sdcons mc_res mocarlo gwr_res
		sca `rho'=(1+sqrt(5))/2
		sca `lwr'=(`rho'-1)/`rho'
		sca `upr'=1/`rho'
		sca `zed'=0.000001
*Calibrate bandwidth
		su `east'
		loc maxid=_result(1)	
		loc erange=_result(6)-_result(5)
		su `north'
		loc nrange=_result(6)-_result(5)
		loc a= `maxid'*(`sample'/100)
		if `bandwid'==0 {
			sca `b2'=min(`erange',`nrange')
			sca `b1'=`b2'/1000
			loc bi=1
			loc tloop=1
			while `bi'<=`iterate'+1 {
				if `bi'==`iterate'+1 {
					di in r "Convergence not achieved"
					e 430
				}
				sca `sc'=0
				if `tloop'==1 {
					sca `b3'=`lwr'*(`b2'-`b1')+`b1'
					loc i=1
					if `b3'>0 {
						sca `bw' = `b3'
					}
					else sca `bw'=-1
					
					while `i'<=`a' {	
						su `east' if `id'==`i'
						loc easti=_result(6)
						su `north' if `id'==`i'
					replace `disti'=((`east'-`easti')^2)+((`north'-_result(6))^2)
						replace `w'=exp((-`disti')/(`bw'^2))
						`gm' `varlist' [iw=`w'] if `id'!=`i', `gpt'
						`pred' `p'
						su `p' if `id'==`i'
						loc py =_result(6)
						drop  `p'
						su $S_E_depv if `id'==`i'
						sca `sc'=`sc'+ ((_result(6)-`py')^2)
						loc i=`i'+1
					}
					sca `sc5'=sqrt(`sc'/`a')
					if `sc5'==. {
						loc bi=`iterate'+1
					}
		`nolog' di  _n in g "Bandwidth = " in y `bw' _col(40) in g "Score = " in y `sc5'
				}
				sca `b4'=`upr'*(`b2'-`b1')+`b1'
				if `b4'>0 {
					sca `bw' = `b4'
				}
				else sca `bw'=-1
				sca `sc'=0
				loc i=1
				while `i'<=`a' {	
					su `east' if `id'==`i'
					loc easti=_result(6)
					su `north' if `id'==`i'
					replace `disti'=((`east'-`easti')^2)+((`north'-_result(6))^2)
					replace `w'=exp((-`disti')/(`bw'^2))
					`gm' `varlist' [iw=`w'] if `id'!=`i', `gpt' 
					`pred' `p'
					su `p' if `id'==`i'
					loc py =_result(6)
					drop  `p'
					su $S_E_depv if `id'==`i'
					sca `sc'=`sc'+((_result(6)-`py')^2)
					loc i=`i'+1
				}
				sca `sc6'=sqrt(`sc'/`a')
				if `sc6'==. {
					loc bi=`iterate'+1
					}
		`nolog' di  _n in g "Bandwidth = " in y `bw' _col(40) in g "Score = " in y `sc6'
				if `sc5'<`sc6' {
					sca `sc6'=`sc5'
					sca `b2'=`b4'
					sca `b4'=`b3'
					if (abs(`b1'-`b2')-`zed')<=0 {
						local bi=`iterate'+2
					}
					else loc bi=`bi'+1
				}
				else if `sc5'>`sc6' {
					sca `sc5'=`sc6'
					sca `b1'=`b3'
					sca `b3'=`b4'
					if (abs(`b1'-`b2')-`zed')<=0 {
						local bi=`iterate'+2
					}
					else {
						loc tloop=0
						loc bi=`bi'+1
					}
				}
				else local bi=`iterate'+2	
			}
			sca `bw'=0.5*(`b1'+`b2')
			n di in g "Convergence : Bandwidth = " in y `bw'
		}
		else sca `bw'=`bandwid'
		sca `obsbw'=`bw'
* GWR using calibrated or inputted bandwidth
		preserve
		postfile `gwr_res' east north `plist'  `cons' using "`saving'", `replace' `double'
		loc i=1
		while `i'<=`maxid' {	
			su `east' if `id'==`i'
			loc easti=_result(6)
			su `north' if `id'==`i'
			loc northi=_result(6)
			replace `disti'=((`east'-`easti')^2)+((`north'-_result(6))^2)
			replace `w'=exp((-`disti')/(`bw'^2))
			cap `gm' `varlist' [iw=`w'] , `gpt'
			if _rc!=0 {
				n di "Failed at `i'"
				local i=`i'+1
			}
			else {
				mat coefs=get(_b)
				svmat double coefs
				loc j=1 
				while `j'<=`nv' {
					su coefs`j'
					scal ib`j'=_result(6) 
					loc j=`j'+1
				}
				drop coefs1-coefs`tnv'
				post `gwr_res' `easti' `northi' `olist' `bcons'
				loc i=`i'+1
			}
		}
		postclose `gwr_res'
* Get s.d's of estimates
		use "`saving'", clear
		if "`outfile'"!="" {
			ou using "`outfile'", `comma' `replace' `wide'
		}	
		loc i=1
		while `i'<=`nv' {
			su var`i'	
			sca sdev`i'=sqrt(_result(4))
			rename var`i' `vn`i''
			loc i=`i'+1
		}
		`sv' save, replace
		if "`noconst'"=="" {
		su cons
		sca `sdcons'=sqrt(_result(4))
		}
		restore, pres
*Monte Carlo
		`dots' di in y  _n  "Running Monte Carlo simulation"
		if "`test'"!="" {
			loc mcb "mcb"
		}
		else {loc mcb ""}
		postfile `mocarlo'  `plist' `cons' `mcb' using `mcsave', replace d  
		loc mci=1 
		while `mci'<=`reps' {
			`dots' di in g "." _c
* Randomly distribute the locations
			restore, pres
			replace `id2'=uniform()
			sort `id2'
			replace `id2'=_n
			loc j=1        
			while `j'<=`maxid' {                                                            
				su `east' if `id2'==`j'                                               
				replace `mceast'=_result(6) if `id'==`j'                                       
				su `north' if `id2'==`j'                                              
				replace `mcnorth'=_result(6) if `id'==`j'                                        
				loc j=`j'+1                                                              
			}
			if "`test'"!="" {	
				sca `b2'=min(`erange',`nrange')
				sca `b1'=`b2'/1000
				loc bi=1
				loc tloop=1
				loc nocv=0
				while `bi'<=`iterate' +1 {
					loc ncv=0
					if `bi'==`iterate'+1 {
						loc nocv=`nocv'+1
						loc ncv=1
						local bi=`iterate'+2
					}
					sca `sc'=0
					if `tloop'==1 {
						sca `b3'=`lwr'*(`b2'-`b1')+`b1'
						loc i=1
						if `b3'>0 {
							sca `bw' = `b3'
						}
						else sca `bw'=-1
						while `i'<=`a' {	
							su `mceast' if `id'==`i'
							loc easti=_result(6)
							su `mcnorth' if `id'==`i'
				replace `disti'=((`mceast'-`easti')^2)+((`mcnorth'-_result(6))^2)
						replace `w'=exp((-`disti')/(`bw'^2))
						`gm' `varlist' [iw=`w'] if `id'!=`i', `gpt'
							`pred' `p'
							su `p' if `id'==`i'
							loc py =_result(6)
							drop  `p'
							su $S_E_depv if `id'==`i'
							sca `sc'=`sc'+((_result(6)-`py')^2)
							loc i=`i'+1
						}
						sca `sc5'=sqrt(`sc'/`maxid')
						if `sc5'==. {
							loc bi=`iterate'+1
						}
					}
					sca `b4'=`upr'*(`b2'-`b1')+`b1'
					if `b4'>0 {
						sca `bw' = `b4'
					}
					else sca `bw'=-1
					sca `sc'=0
					loc i=1
					while `i'<=`a' {	
						su `mceast' if `id'==`i'
						loc easti=_result(6)
						su `mcnorth' if `id'==`i'
				replace `disti'=((`mceast'-`easti')^2)+((`mcnorth'-_result(6))^2)
						replace `w'=exp((-`disti')/(`bw'^2))
						`gm' `varlist' [iw=`w'] if `id'!=`i', `gpt'
						`pred' `p'
						su `p' if `id'==`i'
						loc py =_result(6)
						drop  `p'
						su $S_E_depv if `id'==`i'
						sca `sc'=`sc'+((_result(6)-`py')^2)
						loc i=`i'+1
					}
					sca `sc6'=sqrt(`sc'/`maxid')
					if `sc6'==. | `sc5'==. {
						loc bi =  `iterate' +1
					}
					if `sc5'<`sc6' {
						sca `sc6'=`sc5'
						sca `b2'=`b4'
						sca `b4'=`b3'
						if (abs(`b1'-`b2')-`zed')<=0 {
							loc bi=`iterate'+2
						}
						else loc bi=`bi'+1
					}
					else if `sc5'>`sc6' {
						sca `sc5'=`sc6'
						sca `b1'=`b3'
						sca `b3'=`b4'
						if (abs(`b1'-`b2')-`zed')<=0 {
							local bi=`iterate'+2
						}
						else {
							loc tloop=0
							loc bi=`bi'+1
						}
					}
					else loc bi=`iterate'+2
				}				
			if `ncv'==1 {
				loc mcbw=-99.99
			}
			else  loc mcbw=0.5*(`b1'+`b2')
		}	
*Use observed bandwidth 
			postfile `mc_res'  `plist' `cons' using st_0_0_1, replace d
			loc i=1
			while `i'<=`maxid' {	
				su `mceast' if `id'==`i'
				loc easti=_result(6)
				su `mcnorth' if `id'==`i'
				replace `disti'=((`mceast'-`easti')^2)+((`mcnorth'-_result(6))^2)
				replace `w'=exp(-`disti' /(`obsbw'^2))
				`gm' `varlist' [iw=`w'] , `gpt'
				mat coefs=get(_b)
				svmat double coefs
				loc j=1 
				while `j'<=`nv' {
					su coefs`j'
					sca ib`j'=_result(6) 
					loc j=`j'+1
				}
				drop coefs1-coefs`tnv'
				post `mc_res' `olist' `bcons'
				loc i=`i'+1
			}
			postclose `mc_res'
* Go to MC file and calculate s.d.'s	
			use st_0_0_1, clear
			loc m=1
			while `m'<=`nv' {
				su var`m'
				sca mcsd`m'=sqrt(_result(4)) 
				loc m=`m'+1
			}
			if "`noconst'"=="" {
				su cons
				loc mcsdcon=sqrt(_result(4))
				if "`test'" !="" {
					post `mocarlo' `mclist' `mcsdcon' `mcbw'
				}
				else post `mocarlo' `mclist' `mcsdcon'
			}
			else  {
				if "`test'" !="" {
					post `mocarlo' `mclist' `mcsdcon' `mcbw'
				}
				else {post `mocarlo' `mclist' `mcsdcon' }
			}
		loc mci=`mci'+1
		}
		postclose `mocarlo'
* Compare sim with obs
		use `mcsave', clear
	}
	di in g _n _n "Geographically Weighted Regression"
	if "`test'"!="" {	
		if `nocv'>0 {
		di in r" WARNING" in g "Convergence not achieved " `nocv' " times"
		}
		di in g _n "Significance Test for Bandwidth"
		di in g _n _dup(40) "-"
		di in g  "Observed" _col(20) "P-Value"
		di in g  _dup(40) "-"		
		qui count if  mcb<`obsbw' & mcb!=-99.99
		di in y %5.4f `obsbw' _col(20) %5.3f _result(1)/(`reps'-`nocv')
		di in g _dup(40) "-"
		}					
	di in g _n _n "Significance Tests for Non-Stationarity"
	di in g _n _dup(79) "-"
	di in g "Variable" _col(20) "Si" _col(40) "P-Value"
	di in g _dup(79) "-" 
	if "`noconst'"=="" {
		qui cou if cons>`sdcons'
		di in g "Constant" _col(20) in y %5.4f `sdcons' _col(40) in y %5.3f  _result(1)/`reps'
	}
	loc i=1
	while `i'<=`nv' {
		qui cou if var`i'>=sdev`i' 
		di in g "`vn`i''" _col(20) in y %5.4f sdev`i' _col(40) in y %5.3f _result(1)/`reps'
		rename var`i' `vn`i''
		loc i=`i'+1
	}
	di in g _dup(79) "-"
	`msv' save, replace
	erase st_0_0_1.dta
	gl S_1 =`maxid'
	gl S_2 = `obsbw'
end
