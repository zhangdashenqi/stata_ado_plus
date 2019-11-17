capture program drop xpost
program define xpost, rclass
version 6.0

* V1.08 Done -- 5/15/00, by Simon Cheng
* V1.08 add ologit, 5/15/00
* V1.07 add mlogit, 5/14/00
* V1.06 add poisson and nbreg - xpostg, 5/13/00
* V1.05 add probit, 5/13/00
* V1.04 add ologit, 5/11/00
* V1.02 for logit, 5/10/00, sc
* V1.01 for logit, incomplete, 5/10/00, sc

*Vraibles for All Models, unless specified
*	di "comaand"		= `cmd'
*	di "y-name" 		= `lhsnm'"
*	di "x-name" 		= `rhsnam'"
*	di "# of x" 		= `rhsnum'"
*	di "Cat Name" 	= `cnames'"
*	di "# of cat" 	= `ncats'"
*	di "# of rows"	= `rown'" --- gologit only --- equal (rhsnum + 1)*(ncats - 1)
*	mat "Mean of X"	= `mnnoy'
*	mat "std of X"  = `sdnoy'
*	mat "Min of X"  = `minnoy'
*	mat "Max of X"	= `maxnoy'
*	sca "Mean of Y"	= `ymn'
*	sca "std of Y"	= `ysd'
*	sca "Min of Y"	= `ymin'
*	sca "Max of Y"	= `ymax'
*	mat "b no cons" = `bnoc' -- logit probit ologit poisson nbreg-- 
*	mat "z no cons" = `znoc' -- logit probit ologit poisson nbreg-- 
*	mat "b matrix"	= `b'	 -- gologit mlogit b matrix, with con on the top
*	sca "Bconstant" = `bcon' -- logit probit poisson nbreg --  
*	sca "Zconstant" = `zcon' -- logit probit poisson nbreg --
*	mat "cutpoints" = `ycut' -- ologit --

*Command Conditions
    local cmd "`e(cmd)'"
    if "`cmd'" != "logit" & "`cmd'" != "probit" & "`cmd'" != "ologit" /*
	*/ & "`cmd'" != "gologit" & "`cmd'" != "mlogit" /* 
	*/ & "`cmd'" != "poisson" & "`cmd'" != "nbreg"  {
    	di in r "  -xpost- must be run after logit, probit, ologit, gologit, /*
		*/ mlogit, poisson, or nbreg.  "
        exit
	}
    di
    di in g " -The output is generated to be directly pasted to Excel XPOST- "
    
*Grab name of y
    local lhsnm "`e(depvar)'"

*Information on x
    _perhs
    local rhsnam "`r(rhsnms)'"
    local rhsnum "`r(nrhs)'"

*Information of categories
    if "`cmd'" != "gologit" {
    	_pecats
    	local ncats = r(numcats)
    	local cnames = r(catnms)
    	di
    	local rfnm = r(refnm)
    }
    if "`cmd'" == "gologit" {
		tempname gv  /* gv is the v matrix of gologit */
    	mat `gv' = e(V)
    	local rown = rowsof(`gv')
    	local df = e(df_m)
    	local ncats = `rown' - `df' + 1
		quietly ologit `lhsnm' `rhsnam'
		_pecats
    	local cnames = r(catnms)
		quietly gologit `lhsnm' `rhsnam'
    }

*Grab mean sd min max; determine var type
    if "`cmd'" == "gologit" {
		quietly ologit `lhsnm' `rhsnam'
	}
    tempname mn sd min max vtype
    tempname mnnoy sdnoy minnoy maxnoy
    tempname ymn ysd ymin ymax
    _pesum  if e(sample)==1 /*-if e(sample)==1- works when missing present"*/
    mat `mn' = r(Smean)
    mat `sd' = r(Ssd)
    mat `min' = r(Smin)
    mat `max' = r(Smax)
    _pesum if e(sample)==1, dummy /* Determine Var Type */
    mat `vtype' = r(Sdummy)
    mat `mnnoy' = `mn'[1,2...] /* trim off _y */
    mat `sdnoy' = `sd'[1,2...]
    mat `minnoy' = `min'[1,2...]
    mat `maxnoy' = `max'[1,2...]
    mat `mnnoy' = `mnnoy'' /* transpose to be a column vector */
    mat `sdnoy' = `sdnoy'' 
    mat `minnoy' =`minnoy''
    mat `maxnoy' =`maxnoy''
    scalar `ymn' = `mn'[1,1]
	scalar `ysd' = `sd'[1,1]
    scalar `ymin' = `min'[1,1]
    scalar `ymax' = `max'[1,1]
    if "`cmd'" == "gologit" {
		quietly gologit `lhsnm' `rhsnam'
	}

*Grab b bnoc their std and compute z 
* -------------------------------------
* --logit probit ologit poisson nbreg-- 
* -------------------------------------
* | bnoc and znoc |
* -----------------
    if "`cmd'"=="logit" | "`cmd'"=="probit" | "`cmd'"=="ologit" /*
	*/ | "`cmd'"=="poisson" | "`cmd'"=="nbreg" { 
    	tempname b bnoc sdb sdbnoc znoc
	    mat `b' = e(b)
	    mat `bnoc' = `b'[1,1..`rhsnum'] /* trim off _con */
    	mat `bnoc'=`bnoc''
    	mat `sdb' = e(V)
    	mat `sdb' = vecdiag(`sdb')
    	mat `sdbnoc' = `sdb'[1,1..`rhsnum'] /* trim off _con */
    	mat `sdbnoc' = `sdbnoc''
        mat `znoc' = `bnoc'
        local nbnoc = rowsof(`bnoc')
		local i = 1
        while `i' <= `nbnoc' {
            mat `znoc'[`i',1] = `bnoc'[`i',1] / sqrt(`sdbnoc'[`i',1])
            local i = `i' + 1
      	}
	}
* ------------------------------
* --logit probit poisson nbreg-- 
* ------------------------------
* | bnoc and znoc |
* -----------------
    if "`cmd'"=="logit" | "`cmd'"=="probit" /*
	*/ | "`cmd'"=="poisson" | "`cmd'"=="nbreg" {
		tempname bcon zcon
		scalar `bcon' = `b'[1,`rhsnum'+1]
        scalar `zcon' = `b'[1,`rhsnum'+1] / sqrt(`sdb'[1,`rhsnum'+1])
    }
* ------------
* -- ologit -- 
* ------------
* | cutpoint |
* ------------
	if  "`cmd'"=="ologit" {
	    tempname ycut
    	mat `ycut' = `b'[1,`rhsnum'+1..`rhsnum'+`ncats'-1]
		mat `ycut' = (`ycut')'
	}
* ----------------------------------------------------
* --gologit mlogit-- get b matrix, including constant
* ----------------------------------------------------
    if "`cmd'"=="gologit" {
		tempname b bmat
		mat `bmat' = e(b)
		local numeq = `ncats' - 1
		local eqnum = 1
		local rhsnum1 = `rhsnum' + 1
		local icount = 0
		mat `b' = J(`rhsnum1',`numeq',-999)
		while `eqnum' <= `numeq' {
			local varnum = 1
			while `varnum' <= `rhsnum1' {
				local icount = `icount' + 1
				mat `b'[`varnum',`eqnum'] = `bmat'[1,`icount']    
				local varnum = `varnum' + 1
	            } /* varnum */
			local eqnum = `eqnum' + 1
	        } /* eqnum loop */
        *put con on top row
		mat `bmat' = `b'
        mat `b' = J(`rhsnum1',`numeq',-999)
        local icol = 1
        while `icol' <= `numeq' {
            mat `b'[1,`icol'] = `bmat'[`rhsnum1',`icol']
            local icol = `icol' + 1
        }
        local irow = 1
        while `irow' <= `rhsnum' {
            local icol = 1
            while `icol' <= `numeq' {
                mat `b'[`irow'+1,`icol'] = `bmat'[`irow',`icol']
                local icol = `icol' + 1
            }
            local irow = `irow' + 1
        }
    }
    if "`cmd'" == "mlogit" {
        tempname b bnoc bcon
        version 5.0
        mat `b' =get(_b)
        version 6.0
        mat `bnoc' = `b'[1..`ncats'-1,1..`rhsnum']
        mat `bcon' = `b'[1..`ncats'-1,`rhsnum'+1]
        mat `b' = `bcon', `bnoc'
        mat `b'=`b''
    }

* Print Output
*=========================
* Table 1.  Y Information
*=========================
* ALL MODELS
*============
    tempname t1
    mat `t1'=[`ymn', `ysd', `ymin', `ymax']
    mat colnames `t1' =  mean std min max
    mat rownames `t1' = `lhsnm'
    di
    di in g "---------------------------------"
    di in g " Table 1: Input of Y Information "
    di in g "---------------------------------"
    mat list `t1', f(%5.0g) noh
    if "`cmd'" == "mlogit" {
		di
    	di "Reference Category  =  `rfnm'"
	}
*=========
* Table 2
*==============
* logit probit
*==============
	tempname t2
    di  
	local i = 10
    local c1 "10"
    local c2 "20"
    local c3 "30"
    local c4 "40"
    local c5 "50"
    local c6 "60"
    local c7 "70"
    if "`cmd'" == "logit" | "`cmd'" == "probit" {
		mat `t2' = `bnoc', `znoc', `mnnoy', `sdnoy', `minnoy', `maxnoy'
    	di
    	di in g "--------------------------------"
    	di in g " Table 2: Input of X Information"
    	di in g "--------------------------------"
	    di  
	    di "                 b        z       mean       std      min" /*
		*/ "       max    VType"
	    di "Constant" _col(`c1') %9.5f `bcon' _col(`c2') %8.2f `zcon' /*
        */ "        ---       ---      ---       ---     ---"
	    local i = 1
	    while `i' < `rhsnum' + 1 {
    		local vt`i' = "C"
			if `vtype'[1,`i'+1]==1 {
        		local vt`i' = "B"
			}
   			local vname : word `i' of `rhsnam'
    		di in y %8s "`vname'" /*
        	*/ _col(`c1') %9.5f `t2'[`i',1] /*
	        */ _col(`c2') %8.2f `t2'[`i',2] /*
	        */ _col(`c3') %9.5f `t2'[`i',3] /*
	        */ _col(`c4') %9.5f `t2'[`i',4] /*
	        */ _col(`c5') %8.2f `t2'[`i',5] /*
	        */ _col(`c6') %8.2f `t2'[`i',6] /*
	        */ _col(`c7') %5s   "`vt`i''"
	        local i = `i' + 1
		}
	}
*============
* T2: ologit 
*============
    if "`cmd'" == "ologit" {
    	di in g "--------------------------"
	    di in g " Table 2: Tau & Cat Names "
	    di in g "--------------------------"
		di
	    di "   A: Tau (1 to k)"
		di
	    local i = 1
	    while `i' < `ncats' {
		    di in y %9.5f _col(6) `ycut'[`i',1]
		    local i = `i' + 1
        }
		di
	    di "   B: Cat Names"
		di
		local i = 1
	    while `i' <= `ncats' {
	    	local vname : word `i' of `cnames'
		    di in y %10s "`vname'" 
			local i = `i' + 1
		}
    }
*=========================
* T2: poissin nbreg mlogit 
*=========================
    if "`cmd'" == "poisson" | "`cmd'" == "nbreg" | "`cmd'" == "mlogit" {
		mat `t2' = `mnnoy', `sdnoy', `minnoy', `maxnoy'
	    di
	    di in g "---------------------------------"
	    di in g " Table 2: Input of X Information "
	    di in g "---------------------------------"
		di  
		di "              mean       std      min       max    VType"
    	local i = 1
    	while `i' < `rhsnum' + 1 {
	    	local vt`i' = "C"
		    if `vtype'[1,`i'+1]==1 {
		        local vt`i' = "B"
	        }
	    	local vname : word `i' of `rhsnam'
		    di in y %8s "`vname'" /*
	        */ _col(`c1') %9.5f `t2'[`i',1] /*
	        */ _col(`c2') %9.5f `t2'[`i',2] /*
	        */ _col(`c3') %8.2f `t2'[`i',3] /*
	        */ _col(`c4') %8.2f `t2'[`i',4] /*
	        */ _col(`c5') %5s   "`vt`i''"
	        local i = `i' + 1
		}
		di
	}
*=============
* T2: gologit 
*=============
	if "`cmd'" == "gologit" {
    	di in g "--------------------"
	    di in g " Table 2: Cat Names "
	    di in g "--------------------"
		di
		local i = 3
        local icol = 1
        while `icol' <= `ncats' {
            local vname: word `icol' of `cnames'
            di %8s _col(`i') "`vname'" _c
            local icol = `icol' + 1
        }
	di
    }
*=========
* Table 3
*========
* ologit
*========
    if "`cmd'" == "ologit" {
		mat `t2' = `bnoc', `znoc', `mnnoy', `sdnoy', `minnoy', `maxnoy'
    	di
    	di in g "--------------------------------"
    	di in g " Table 3: Input of X Information"
    	di in g "--------------------------------"
	    di  
	    di "                 b        z       mean       std      min" /*
		*/ "       max    VType"
	    local i = 1
	    while `i' < `rhsnum' + 1 {
    		local vt`i' = "C"
			if `vtype'[1,`i'+1]==1 {
        		local vt`i' = "B"
			}
   			local vname : word `i' of `rhsnam'
    		di in y %8s "`vname'" /*
        	*/ _col(`c1') %9.5f `t2'[`i',1] /*
	        */ _col(`c2') %8.2f `t2'[`i',2] /*
	        */ _col(`c3') %9.5f `t2'[`i',3] /*
	        */ _col(`c4') %9.5f `t2'[`i',4] /*
	        */ _col(`c5') %8.2f `t2'[`i',5] /*
	        */ _col(`c6') %8.2f `t2'[`i',6] /*
	        */ _col(`c7') %5s   "`vt`i''"
	        local i = `i' + 1
		}
	}
*=============
* T3: Poisson
*=============
    if "`cmd'"=="poisson" {
		tempname t3
		mat `t3' = `bnoc', `znoc'
    	di in g "-------------------------------"
    	di in g " Table 3: Poisson Coefficients "
    	di in g "-------------------------------"
    	di  
    	di "                 b         z"
    	di _col(`c1') %9.5f `bcon' _col(`c2') %9.5f `zcon'
    	local i = 1
    	while `i' < `rhsnum' + 1 {
    		di in y _col(`c1') %9.5f `t3'[`i',1] /*
        	*/ _col(`c2') %9.5f `t3'[`i',2] 
        	local i = `i' + 1
        }
	}
*============
* T3: Mlogit
*============
    if "`cmd'" == "mlogit" {
		di
    	di in g "-------------------------------"
    	di in g " Table 3: Logit Coefficients "
    	di in g "-------------------------------"
		di
		local i = 4
        local icol = 1
        while `icol' < `ncats' {
            local vname: word `icol' of `cnames'
            di %9s _col(`i') "`vname'" _c
            local icol = `icol' + 1
        }
        di
		local irow = 1
		local icol = 1
        while `icol' < `ncats' {
			tempname b0
			local i = 4
			scalar `b0' = `b'[1,`icol']
			di _col(`i') %9.5f `b0' _c
			local icol = `icol' + 1
			local i = `i' + 4
		}
		di
		local irow = 1
        while `irow' < = `rhsnum' {
        	local icol = 1
        	while `icol' < `ncats' {
				local i = 4
            	scalar `b0' = `b'[`irow'+1,`icol']
            	di _col(`i') %9.5f `b0' _c
            	local icol = `icol' + 1
				local i = `i' + 4
        	}
        di
        local irow = `irow' + 1
    	}
	}
*=============
* T3: gologit
*=============
	if "`cmd'" == "gologit" {
		tempname t3
		mat `t3' = `mnnoy', `sdnoy', `minnoy', `maxnoy'
	    di
	    di in g "---------------------------------"
	    di in g " Table 3: Input of X Information "
	    di in g "---------------------------------"
		di  
		di "              mean       std      min       max    VType"
    	local i = 1
    	while `i' < `rhsnum' + 1 {
	    	local vt`i' = "C"
		    if `vtype'[1,`i'+1]==1 {
		        local vt`i' = "B"
	        }
	    	local vname : word `i' of `rhsnam'
		    di in y %8s "`vname'" /*
	        */ _col(`c1') %9.5f `t3'[`i',1] /*
	        */ _col(`c2') %9.5f `t3'[`i',2] /*
	        */ _col(`c3') %8.2f `t3'[`i',3] /*
	        */ _col(`c4') %8.2f `t3'[`i',4] /*
	        */ _col(`c5') %5s   "`vt`i''"
	        local i = `i' + 1
		}
	}
*===========
* T4: Nbreg
*===========
    if "`cmd'"=="nbreg" {
		tempname t4
		mat `t4' = `bnoc', `znoc'
    	di in g "-------------------------------"
    	di in g " Table 4: Nbreg Coefficients "
    	di in g "-------------------------------"
    	di  
    	di "                 b         z"
    	di _col(`c1') %9.5f `bcon' _col(`c2') %9.5f `zcon'
    	local i = 1
    	while `i' < `rhsnum' + 1 {
    		di in y _col(`c1') %9.5f `t4'[`i',1] /*
        	*/ _col(`c2') %9.5f `t4'[`i',2] 
        	local i = `i' + 1
        }
		di
	    di in y "Alpha = " _col(`c1') %9.5f e(alpha)
	}
*============
* T3: Mlogit
*============
    if "`cmd'" == "gologit" {
		di
    	di in g "-------------------------------"
    	di in g " Table 4: Logit Coefficients "
    	di in g "-------------------------------"
		di
		local i = 4
        local icol = 1
		local j = 1
        while `icol' < `ncats' {
			local eq`j' = "Equ `j'"
            di %9s _col(`i') "`eq`j''" _c
            local icol = `icol' + 1
			local j = `j' + 1
        }
        di
		local irow = 1
		local icol = 1
        while `icol' < `ncats' {
			tempname b0
			local i = 4
			scalar `b0' = `b'[1,`icol']
			di _col(`i') %9.5f `b0' _c
			local icol = `icol' + 1
			local i = `i' + 4
		}
		di
		local irow = 1
        while `irow' < = `rhsnum' {
        	local icol = 1
        	while `icol' < `ncats' {
				local i = 4
            	scalar `b0' = `b'[`irow'+1,`icol']
            	di _col(`i') %9.5f `b0' _c
            	local icol = `icol' + 1
				local i = `i' + 4
        	}
        di
        local irow = `irow' + 1
    	}
	}
*=====================
* T5: Poisson & Nbreg
*=====================
	di
    if "`cmd'"=="poisson" | "`cmd'"=="nbreg" {
    	di in g "------------------------------"
	    di in g " Table 5: Oberved Probability "
	    di in g "------------------------------"
	    di
	    di in y "       Counts       Obs Prob"
	    local i=0
	    version 5.0
	    while `i'<`ymax'+1 { /*2*/
	        quietly gen n`i'=1 if `lhsnm'==`i'
	        quietly recode n`i' 1=1 .=0
	        quietly sum n`i'
	        di _col(`c1') `i' _col(`c2') %9.5f _result(3)
	        local i = `i' + 1
		}
	}
end
