* version 1.0.5 8oct2002  MER  version 7   (SJ2-4: st0025)
capture program drop roctg
program define roctg, rclass
	version 7.0


*************
* Syntax help
*************

	 if "`1'" == "" {
		di _n in gr "  Syntax is:" _n
		di    in wh "     roctg" in gr " var_reftest var_newtest [if] [in] , " 	_c
		di    in gr "[" in wh " cb" in gr "and " 				_c
		di    in wh "op" in gr "timal"  			 		_c
                di    in wh " sm" in gr "ooth " 					
		di    in wh _col(12)  "lo" in gr "wess " 				_c
		di    in wh "bw" in gr "idth("  in wh "#" in gr ") "         	 	_c
		di    in wh "ab" in gr "normal(" in wh "min/max"  in gr ") " 		_c			
		di    in wh "co" in gr "nt "						_c		
		di    in wh "int" in gr "erval(" in wh "numlist" in gr ") " 		
		di    in wh _col(12) "d" in gr "isplay " 				_c	
		di    in wh "nor" in gr "ank "    					_c
 		di    in wh "nog" in gr "raph " 					_c
		di    in wh "sa" in gr "ving(" in wh "filename" in gr ") "		_c
		di    in gr "replace "							_c
		di    in wh "le" in gr "vel(" in wh "#" in gr ") " 			
		di    in wh _col(12) "sy" in gr "mbol(" in wh "symb" in gr ") "		_c 
		di    in wh "xlab" in gr "el(" in wh "numlist" in gr ") " 		_c
		di    in wh "ylab" in gr "el(" in wh "numlist" in gr ") "		_c	 
 		di    in gr "] "

	   exit
	 }



*******
* Setup
*******
	version 7.0
	syntax varlist(max=2 min=2) [if] [in] [ , Display NORank SMooth LOwess ABnormal(str)  	/* 
*/			BWidth(numlist) SYmbol(str) CBand Level(integer $S_level) OPtimal  	/* 
*/			SAving(str) replace NOGraph XLABel(str) YLABel(str) COnt INTerval(numlist)]

	marksample touse
	tokenize `varlist'
	local gold = `"`1'"'
	local T = `"`2'"'

    	preserve

    	if ("`if'"!="") {
       		keep `if'
    	} 
    	if ("`in'"!="") {
       		keep `in'
    	}



*****************
* Setting default
*****************

	local bwmark `bwidth'
	if "`bwidth'" == "" {local bwidth = 0.2}

	local abn `abnormal'
	if "`abnormal'" == "" {local abn "max"}

	tempvar Tgr
	qui egen `Tgr'=group(`T')
	qui tab `Tgr'
	local intden = `r(r)'

	if `intden' > 50 { local intden 50 }
	
	tempvar dummy
	qui gen `dummy' = `gold'+`T'
	qui tab `dummy'
	local ssize `r(N)'
	local hss = `ssize'/2
 
	if `ssize' < 100 { local intden `hss' }
 
	qui sum `T'
	if "`interval'" == "" {
		if "`cont'" ~= "" {
			local interval = ((`r(max)'-`r(min)')/`intden')
		}
		if "`cont'" == "" {
			local interval 1
		}
	}
 
	if `interval' <= 0 {
		di in bl "Zero or negative interval number is inappropriate."
		di in bl "Value set to default."
		if "`cont'" ~= "" {
			local interval = ((`r(max)'-`r(min)')/`intden')  
		}
		if "`cont'" == "" {
			local interval 1
		}
	} 

	qui sum `T'
	local maxint `r(max)'
	if `interval' >= `maxint' {
		di in bl "Interval number is too high given the range of `T' values"
		di in bl "Value set to default"
		if "`cont'" ~= "" {
			local interval = ((`r(max)'-`r(min)')/`intden')  
		}
		if "`cont'" == "" {
			local interval 1
		}
	} 

	if "`cont'" ~= "" { local form %3.2f }
	if "`cont'" == "" { 
		if `interval' == 1 {
			local form %3.0f 
		}
		if `interval' ~= 1 {
			local form %3.2f 
		}
	}
 

****************
* Exit situation
****************

	cap assert `gold'==0 | `gold'==1 if `touse'
	if _rc~=0 {
	 	noi di in red "true status variable `gold' must be 0 or 1"
		exit
 	}

	if `level'<10 | `level'>99 {
		di in red "level() invalid"
		exit 198
	}

	qui summ `gold' if `touse', meanonly
	if r(min) == r(max) {
		di in red "Outcome does not vary"
		exit 198
	}

	if ("`abn'" ~= "min")  {
		if ("`abn'" ~= "max") {
			di in red "Option abnormal() requires either min or max"
			exit 198
		}
	}


*************
* Starting...
*************


	qui sum `T'
	local nmin `r(min)'
	local nmax `r(max)'
	local xmin `nmin'
	local xmax `nmax'

	local sc `nmin' 
	if `sc' == 0 {local sc -0}  	/* for loop  */ 
	local nmax `nmax'

	if "`abn'" == "min" {local ab "<"}
	if "`abn'" == "max" {local ab ">"}


********* Extra exit and warning  *************************************

	local cutoff = (`nmax'-`nmin')/`interval'

	if `cutoff' < 5 {
		di in re "Current specifications imply less than 5 cutoff points for"  
		di in re "variable `T'. Options cont and/or int() must be changed." 
	exit
	}

	if `cutoff' > 100 {
		di in bl "Warning: Current specifications imply " in ye %5.0f `cutoff' 	_c
		di in gr " cutoff points for variable"  
		di in bl _column(10) "`T'. Consider breaking and controlling options "	_c
		di in wh  "cont " in gr "and " 
		di in wh _column(10) "int() " in gr "to improve efficiency "		_c
		di in gr "... or wait ..." 						_n
	}

**********************************************************************

	tempname seVSsp
	cap postfile `seVSsp' score sens sens_l sens_u spec spec_l spec_u using seVSsp, replace
	quietly {
		forvalues i = `sc'(`interval')`nmax' {
		tempvar T_``sc'' se_``sc'' sel_``sc'' seu_``sc'' sp_``sc'' spl_``sc'' spu_``sc''

			gen `T_``sc'''=0
			replace `T_``sc'''=1 if `T' `ab' `sc'
			replace `T_``sc'''=. if `T'==.

			qui diagt `gold' `T_``sc''', level(`level')

			gen `se_``sc'''=`r(sens)'
			replace `se_``sc'''=0 if `se_``sc'''==.
			replace `se_``sc'''=. if `T_``sc'''==. | `gold'==.

			gen `sel_``sc'''=`r(sens_lb)'
			replace `sel_``sc'''=0 if `sel_``sc'''==.
			replace `sel_``sc'''=0 if `sel_``sc'''<0 
			replace `sel_``sc'''=. if `T_``sc'''==. | `gold'==.

			gen `seu_``sc'''=`r(sens_ub)'
			replace `seu_``sc'''=0 if `seu_``sc'''==.
			replace `sel_``sc'''=100 if `sel_``sc'''>100 
			replace `seu_``sc'''=. if `T_``sc'''==. | `gold'==.


			gen `sp_``sc'''=`r(spec)'
			replace `sp_``sc'''=0 if `sp_``sc'''==.
			replace `sp_``sc'''=. if `T_``sc'''==. | `gold'==.

			gen `spl_``sc'''=`r(spec_lb)'
			replace `spl_``sc'''=0 if `spl_``sc'''==.
			replace `spl_``sc'''=0 if `spl_``sc'''<0 
			replace `spl_``sc'''=. if `T_``sc'''==. | `gold'==.

			gen `spu_``sc'''=`r(spec_ub)'
			replace `spu_``sc'''=0 if `spu_``sc'''==.
			replace `spl_``sc'''=100 if `spl_``sc'''>100 
			replace `spu_``sc'''=. if `T_``sc'''==. | `gold'==.

       			post `seVSsp' (`sc') (`se_``sc''') (`sel_``sc''') (`seu_``sc''') 	/*
*/			              (`sp_``sc''') (`spl_``sc''') (`spu_``sc''')

			local sc = `sc' + `interval'
		}
	}
	postclose `seVSsp'


***********************
* Preparing output ...
***********************

	set textsize 80

	use seVSsp.dta, clear
	label var score "Score of variable `T'"
	qui drop if score > `nmax'

	tempvar difsq difsq_l difsq_u mark mark_l mark_u obs

	qui gen `obs'=_n
	qui sum `obs'
	local maxobs r(max)
	local minobs r(min)


	if "`abn'" == "max" {
		local Semax = sens[`maxobs'-1]
		local Semax_l = sens_l[`maxobs'-1]
		local Semax_u = sens_u[`maxobs'-1]
		local Spmax = spec[`maxobs'-1]
		local Spmax_l = spec_l[`maxobs'-1]
		local Spmax_u = spec_u[`maxobs'-1]

		qui replace sens=`Semax' if `obs'==`maxobs'
		qui replace sens_l=`Semax_l' if `obs'==`maxobs'
		qui replace sens_u=`Semax_u' if `obs'==`maxobs'
		qui replace spec=`Spmax' if `obs'==`maxobs'
		qui replace spec_l=`Spmax_l' if `obs'==`maxobs'
		qui replace spec_u=`Spmax_u' if `obs'==`maxobs'
	}

	if "`abn'" == "min" {
		local Semin = sens[`minobs'+1]
		local Semin_l = sens_l[`minobs'+1]
		local Semin_u = sens_u[`minobs'+1]
		local Spmin = spec[`minobs'+1]
		local Spmin_l = spec_l[`minobs'+1]
		local Spmin_u = spec_u[`minobs'+1]

		qui replace sens=`Semin' if `obs'==`minobs'
		qui replace sens_l=`Semin_l' if `obs'==`minobs'
		qui replace sens_u=`Semin_u' if `obs'==`minobs'
		qui replace spec=`Spmin' if `obs'==`minobs'
		qui replace spec_l=`Spmin_l' if `obs'==`minobs'
		qui replace spec_u=`Spmin_u' if `obs'==`minobs'
	}
	

	local N _N
	local bwrank=3/`N'

	qui ksm sens score, bwidth(`bwrank') gen(smse) nograph
	qui ksm spec score, bwidth(`bwrank') gen(smsp) nograph
	qui gen `difsq' = (smse-smsp)^2
	qui drop smse smsp
	sort `difsq'
	qui gen rank=_n
	sort score
	qui gen `mark'=score if rank==1
	qui sum `mark'
	local maxsco = r(min)

	qui ksm sens_l score, bwidth(`bwrank') gen(smse_l) nograph
	qui ksm spec_l score, bwidth(`bwrank') gen(smsp_l) nograph
	qui gen `difsq_l' = (smse_l-smsp_l)^2
	qui drop smse_l smsp_l
	sort `difsq_l'
	qui gen rank_l=_n
	sort score
	qui gen `mark_l'=score if rank_l==1
	qui sum `mark_l'
	local maxsco_l = r(min)

	qui ksm sens_u score, bwidth(`bwrank') gen(smse_u) nograph
	qui ksm spec_u score, bwidth(`bwrank') gen(smsp_u) nograph
	qui gen `difsq_u' = (smse_u-smsp_u)^2
	qui drop smse_u smsp_u
	sort `difsq_u'
	qui gen rank_u=_n
	drop `difsq_u'
	sort score
	qui gen `mark_u'=score if rank_u==1
	qui sum `mark_u'
	local maxsco_u = r(min)

	tempvar scor maxsens maxsensl maxsensu maxspec maxspecl maxspecu

	qui gen `scor'=score if rank==1
	qui sum `scor'
	local scor1 = r(min)
	qui gen `maxsens'=sens if rank==1
	qui sum `maxsens'
	local maxsens = r(min)
	qui gen `maxsensl'=sens_l if rank==1
	qui replace `maxsensl'=0 if `maxsensl'<0
	qui sum `maxsensl'
	local maxsel = r(min)
	qui gen `maxsensu'=sens_u if rank==1
	qui replace `maxsensu'=100 if `maxsensu'>100
	qui sum `maxsensu'
	local maxseu = r(min)

	qui gen `maxspec'=spec if rank==1
	qui sum `maxspec'
	local maxspec = r(min)
	qui gen `maxspecl'=spec_l if rank==1
	qui replace `maxspecl'=0 if `maxspecl'<0
	qui sum `maxspecl'
	local maxspl = r(min)
	qui gen `maxspecu'=spec_u if rank==1
	qui replace `maxspecu'=100 if `maxspecu'>100
	qui sum `maxspecu'
	local maxspu = r(min)


**********************
* Another warning ...
**********************

  	if "`smooth'" ~= "smooth" & "`bwmark'" ~= "" {
		di _n in wh "bwidth() " in bl "has been ignored since "	_c
		di    in wh "smooth " in bl "has not been requested" 	_n
 
	}


**********************************
* Handling graph and order options
**********************************

	if "`optimal'"=="" { local op "" } 
	else local op "xline(`maxsco')"

	if "`lowess'"=="" { local lo "" } 
	if "`lowess'"~="" { local lo "lowess" }

	local bw "bwidth(`bwidth') nograph" 

	if "`cband'" == ""      & `"`symbol'"' == `"`symbol'"'  {local sy "sy(`symbol'`symbol'i)" }	
	if "`cband'" == ""      & `"`symbol'"' == "" 	 { local sy `"s(iii)"' }

	if "`cband'" == "cband" & `"`symbol'"' == `"`symbol'"' { local sy "sy(i`symbol'ii`symbol'ii)" }
	if "`cband'" == "cband" & `"`symbol'"' == "" 	 { local sy `"sy(iiiiiii)"' }

	if "`smooth'" == "smooth" & "`cband'" == ""  		{
		local varlst "smsens smspec score" 
	} 
	if "`smooth'" == "smooth" & "`cband'" == "cband" 	{
		local varlst "smsens_l smsens smsens_u smspec_l smspec smspec_u score" 
	} 
	if "`smooth'" == "" & "`cband'" == ""        		{
		local varlst "sens spec score" 
	} 
	if "`smooth'" == "" & "`cband'" == "cband"      	{
		local varlst "sens_l sens sens_u spec_l spec spec_u score" 
	} 

	if "`cband'" == ""      { local cnct "c(ll)" }
	if "`cband'" == "cband" { local cnct "c(l[-]ll[-]l[-]ll[-])" } 

	if `"`xlabel'"' == `"`xlabel'"'  {
		if "`optimal'"=="" { local xlab "xlab(`xlabel')" }
		if "`optimal'"~="" { local xlab "xlab(`xlabel' `maxsco')" }
	if `"`xlabel'"' == ""  {
		if "`optimal'"=="" { local xlab "xlab(`xmin' `xmax')"}
		if "`optimal'"~="" { local xlab "xlab(`xmin' `maxsco' `xmax')" }
	}

	if `"`ylabel'"' == `"`ylabel'"'  {local ylab "ylab(`ylabel')"}	
	if `"`ylabel'"' == ""  {local ylab "ylab(0 10 20 30 40 50 60 70 80 90 100)"}

	local key1 "key1(c(l[l]) p(2) "Specificity")"
	local key2 "key2(c(l[l]) p(5) "Sensitivity")"

	if "`cband'" == ""  { local key3 "" } 	
	if "`cband'" ~= ""  { local key3  "key3("`level'% confidence bands are shown")" }

	if "`smooth'" == "" { local key4 "" } 	
	if "`smooth'" ~= "" & "`lowess'"=="" { local key4 "key4("Smoothing with bw =`bwidth'")" }
	if "`smooth'" ~= "" & "`lowess'"~="" { local key4 "key4("Smoothing (lowess) with bw =`bwidth'")" }

	if "`cband'" == ""  { local pn "pen(52)" } 	
	if "`cband'" ~= ""  { local pn "pen(555222)" }	

	local b1tit b1title("             Sensitivity and specificity curves")
	local b2tit "b2title("Score of variable `T' (Reference Test is `gold')")"

   	if "`smooth'" == "smooth" {
		qui ksm sens score, `bw' `lo' gen(smsens)
		qui ksm sens_l score, `bw' `lo'  gen(smsens_l)
		qui ksm sens_u score, `bw' `lo' gen(smsens_u)
		qui ksm spec score, `bw' `lo' gen(smspec)
		qui ksm spec_l score, `bw' `lo' gen(smspec_l)
		qui ksm spec_u score, `bw' `lo' gen(smspec_u)

		local keeplst "score rank sens sens_l sens_u spec spec_l spec_u smsens smsens_l smsens_u smspec smspec_l smspec_u"
	}
   	if "`smooth'" == "" {
		local keeplst "score rank sens sens_l sens_u spec spec_l spec_u"
	}


******************************************
* Displaying graph (according to nograph) 
******************************************

	if "`nograph'" == "" {

		gr `varlst', `op' `cb' `xlab' `ylab' `cnct' `sy' `key1' `key2' /*
*/                           `key3' `key4' `pn' `b1tit' `b2tit' `options'
	}

	if "`nograph'" == "nograph" & "`saving'" == "" {
		if "`display'" ~= "display" & "`rank'" ~= "rank" {
			di in bl " "
			di in wh "nograph " in bl "has been ignored since neither "	_c
			di in wh "display " in gr "nor " in wh "rank " 			
			di in bl "nor " in wh "saving() " in gr "have been requested" 	_n

		gr `varlst', `op' `cb' `xlab' `ylab' `cnct' `sy' `key1' `key2' 	/*
*/                           `key3' `key4' `pn' `b1tit' `b2tit'
		}
	}




*****************************
* Preparing if norank is off
*****************************

	if "`smooth'" == "smooth" {

	local j = 1
	quietly {
		while `j' <= 5 {
		tempvar scor scor`j' sse`j' sse`j'l sse`j'u ssp`j' ssp`j'l ssp`j'u

		qui gen `scor`j''=score if rank==`j'
		qui sum `scor`j''
		local scor`j' = r(min)

		qui gen `sse`j''=smsens if rank==`j'
		qui sum `sse`j''
		local sse`j' = r(min)
		qui gen `sse`j'l'=smsens_l if rank==`j'
		qui replace `sse`j'l'=0 if `sse`j'l'<0
		qui sum `sse`j'l'
		local sse`j'l = r(min)
		qui gen `sse`j'u'=smsens_u if rank==`j'
		qui replace `sse`j'u'=100 if `sse`j'u'>100
		qui sum `sse`j'u'
		local sse`j'u = r(min)

		qui gen `ssp`j''=smspec if rank==`j'
		qui sum `ssp`j''
		local ssp`j' = r(min)
		qui gen `ssp`j'l'=smspec_l if rank==`j'
		qui replace `ssp`j'l'=0 if `ssp`j'l'<0
		qui sum `ssp`j'l'
		local ssp`j'l = r(min)
		qui gen `ssp`j'u'=smspec_u if rank==`j'
		qui replace `ssp`j'u'=100 if `ssp`j'u'>100
		qui sum `ssp`j'u'
		local ssp`j'u = r(min)

		local j = `j' + 1
		}
	}

	}

*******************		
* Display if d on
*******************

   	if "`display'" == "display" { 
  
	    di in gr _col(60) "  n = " in ye `ssize'                                    
	    di in gr "---------------------------------------------------------------------"	                           
 	    di in gr "  Given reference test " in ye "`gold'" in gr ", for variable "          	_c
	    di in ye "`T'" in gr ", curves cross at "					                                        
	    di in gr "  score " in ye `form' `maxsco' in gr " and values (" in ye `level'     	_c
	    di in ye "%" in gr " CI):"                                                      	_n
	    di in gr "     Sensitivity (obs) = " in ye %5.2f `maxsens' in ye "%" in gr " ("   	_c
	    di in ye %5.2f `maxsel' "% - " %5.2f `maxseu' "%" in gr")"                      	  
	    di in gr "     Specificity (obs) = " in ye %5.2f `maxspec' in ye "%" in gr " ("     _c
            di in ye %5.2f `maxspl' "%" in gr" - " in ye %5.2f `maxspu' "%" in gr")"        	 
 	    di in gr "---------------------------------------------------------------------" 	_n 						

		di in gr "Note: score value and results dependent on interval size (" 	 	_c
		di in ye %3.2f `interval'  in gr "), "	
		di in gr _col(7) "which entails" in ye %4.0f `cutoff' in gr " cutoff points for "	_c
		di in gr "variable `T'." 


	  if "`norank'" == "" {
   	    if "`smooth'" == "smooth" {

	    di in gr " "                                   
	    di in gr "-------------------------------------------------------------------------"                                   
 	    di in gr "  Rank   Score     Sensitivity (sm)              Specificity (sm)"                 
	    di in gr "-------------------------------------------------------------------------"   	  
 
	    di in gr "  1      " in ye `form' `scor1' _col(20) %5.2f `sse1' in gr " (" in ye %5.2f `sse1l'   _c
	    di in ye "%" in gr " - " in ye %5.2f `sse1u' "%" in gr ")"                                  _c
            di in ye _col(50) %5.2f `ssp1' in gr " (" in ye %5.2f `ssp1l' "%" in gr " - "           	_c
            di in ye %5.2f `ssp1u' "%" in gr ")"                                                        
                                                        
	    di in gr "  2      " in ye `form' `scor2' _col(20) %5.2f `sse2' in gr " (" in ye %5.2f `sse2l'   _c
            di in ye "%" in gr " - " in ye %5.2f `sse2u' "%" in gr ")"                                  _c
            di in ye _col(50) %5.2f `ssp2' in gr " (" in ye %5.2f `ssp2l' "%" in gr " - "           	_c
	    di in ye %5.2f `ssp2u' "%" in gr ")"                                                        

	    di in gr "  3      " in ye `form' `scor3' _col(20) %5.2f `sse3' in gr " (" in ye %5.2f `sse3l'   _c
	    di in ye "%" in gr " - " in ye %5.2f `sse3u' "%" in gr ")"                                  _c
            di in ye _col(50) %5.2f `ssp3' in gr " (" in ye %5.2f `ssp3l' "%" in gr " - "           	_c
            di in ye %5.2f `ssp3u' "%" in gr ")"                                                        

	    di in gr "  4      " in ye `form' `scor4' _col(20) %5.2f `sse4' in gr " (" in ye %5.2f `sse4l'   _c
            di in ye "%" in gr " - " in ye %5.2f `sse4u' "%" in gr ")"                                  _c
            di in ye _col(50) %5.2f `ssp4' in gr " (" in ye %5.2f `ssp4l' "%" in gr " - "           	_c
            di in ye %5.2f `ssp4u' "%" in gr ")"                                                        

	    di in gr "  5      " in ye `form' `scor5' _col(20) %5.2f `sse5' in gr " (" in ye %5.2f `sse5l'   _c
            di in ye "%" in gr " - " in ye %5.2f `sse5u' "%" in gr ")"                                  _c
            di in ye _col(50) %5.2f `ssp5' in gr " (" in ye %5.2f `ssp5l' "%" in gr " - "           	_c
            di in ye %5.2f `ssp5u' "%" in gr ")"                                                        

 	    di in gr "-------------------------------------------------------------------------"        
 	    di in gr "   Note: estimates are smoothed"       _n

	    }
	  }
	}


*********************************************************
* Dropping or keeping vars for further use and/or saving
*********************************************************

   	if "`saving'" ~= "" {
		
		label data "Se & Sp by score: `gold' by `T' (`level'% CI) / $S_FNDATE "
		cap keep `keeplst'
		cap order `keeplst'
		cap label var rank "Score rank"
		cap label var sens "Sensitivity"
		cap label var sens_l "Sensitivity, lower CI"
		cap label var sens_u "Sensitivity, upper CI"
		cap label var spec "Specificity"
		cap label var spec_l "Specificity, lower CI"
		cap label var spec_u "Specificity, upper CI"
		cap label var smsens "Smoothed sensitivity"
		cap label var smsens_l "Smoothed sensitivity, lower CI"
		cap label var smsens_u "Smoothed sensitivity, upper CI"
		cap label var smspec "Smoothed specificity"
		cap label var smspec_l "Smoothed specificity, lower CI"
		cap label var smspec_u "Smoothed specificity, upper CI"

		sort score
   		if "`replace'" == "" {
			qui cap save "`saving'.dta"
			if _rc==602 {
				di "   "
				di in re "Warning: File `saving'.dta already exists and has not been  
				di in re "         overwritten! Use option replace or change the"
				di in re "         filename."
			}
			if _rc~=602 {
				di in gr "    "                                   
 	    			di in gr "Sensitivity and specificity values dumped" 
                		di in gr "to " in wh "`saving'.dta " in gr "on " in wh "$S_FNDATE"  _n

				erase seVSsp.dta
			}
		}

   		if "`replace'" ~= "" {
			qui save "`saving'.dta", replace
			di in gr "    "                                   
 	    		di in gr "Sensitivity and specificity values dumped" 
                	di in gr "to " in wh "`saving'.dta " in gr "on " in wh "$S_FNDATE"  _n

			erase seVSsp.dta	
		}

	} 


   	if "`saving'" == "" {
		erase seVSsp.dta
	}


	set textsize 100


* Cleaning up

	macro drop S_G1 S_G2 S_3 S_4 S_5 S_6


* return list  / globals

	return scalar   int = `interval'    
	return scalar   numb_cp = `cutoff'
   	if "`smooth'" == "smooth" {
   		return scalar   spec_sm = `ssp1'
   		return scalar   sens_sm = `sse1'
	}
   	return scalar   spec = `maxspec'
   	return scalar   sens = `maxsens'
   	return scalar   score = `maxsco'

   	global S_1  `gold'
   	global S_2  `T'

end
