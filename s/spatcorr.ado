*! Version 1.0 - 29 January 2001 STB-60 sg162
*! -spatcorr- Moran's I and Geary's c spatial correlogram                      
*! Author: Maurizio Pisati                                                     
*! Department of Sociology and Social Research                                 
*! University of Milano Bicocca (Italy)                                        
*! maurizio.pisati@galactica.it                                                
*!                                                                             




*  ----------------------------------------------------------------------------
*  1. Define program                                                           
*  ----------------------------------------------------------------------------

program define spatcorr, rclass
version 7.0




*  ----------------------------------------------------------------------------
*  2. Define syntax                                                            
*  ----------------------------------------------------------------------------

syntax varname, Bands(numlist min=3 >=0 sort)   /*   
           */   Xcoord(varname numeric)         /*
           */   Ycoord(varname numeric)         /*
           */   [Geary]                         /*
           */   [Cumulative]                    /*
           */   [TWOtail]                       /*
           */   [GRaph]                         /*
           */   [Needle]                        /*
           */   [SAVegraph(string)]




*  ----------------------------------------------------------------------------
*  3. Check syntax                                                             
*  ----------------------------------------------------------------------------

capture qui assert `xcoord'!=.
if _rc!=0 {
 	di as err "Variable `xcoord' has missing values"
  	exit
}
capture qui assert `ycoord'!=.
   if _rc!=0 {
  	di as err "Variable `ycoord' has missing values"
  	exit
}




*  ----------------------------------------------------------------------------
*  4. Define basic quantities                                                  
*  ----------------------------------------------------------------------------

local VAR "`varlist'"

local NDIST : word count `bands'
local NBANDS=`NDIST'-1

tempname RESULTS
matrix `RESULTS'=J(`NBANDS',7,0)
matrix colnames `RESULTS'=lower upper stat mean sd z p-value

local MULT=("`twotail'"!="")+1
local PVL "*`MULT'-tail test"




*  ----------------------------------------------------------------------------
*  5. Start loop                                                               
*  ----------------------------------------------------------------------------

local b=1
while `b'<=`NBANDS' {




*  ----------------------------------------------------------------------------
*  6. Create spatial weights matrix                                            
*  ----------------------------------------------------------------------------

/* Define distance band */
if "`cumulative'"=="" {
	local l1=`b'
	local l2=`b'+1
}
if "`cumulative'"!="" {
	local l1=1
	local l2=`b'+1
}
local LOWER : word `l1' of `bands'
local UPPER : word `l2' of `bands'
matrix `RESULTS'[`b',1]=`LOWER'
matrix `RESULTS'[`b',2]=`UPPER'

/* Create binary weights matrix */
local N=_N
matrix _W=J(`N',`N',0)
local i=1
while `i'<=`N' {
	local j=`i'+1
	while `j'<=`N' {
		local A=(`xcoord'[`i']-`xcoord'[`j'])^2
		local B=(`ycoord'[`i']-`ycoord'[`j'])^2
		local DIST=sqrt(`A'+`B')
		if `DIST'>`LOWER' & `DIST'<=`UPPER' {
			matrix _W[`i',`j']=1
			matrix _W[`j',`i']=1
		}
	   local j=`j'+1
	}
   local i=`i'+1
}

/* Row-standardize weights matrix */                                           
preserve
qui drop _all
qui svmat _W
qui egen ROWSUM=rsum(_W*)
qui for varlist _W* : replace X=X/ROWSUM if ROWSUM!=0
qui mkmat _W*, matrix(_WS)
restore




*  ----------------------------------------------------------------------------
*  7. Create common quantities                                                 
*  ----------------------------------------------------------------------------

/* Weights matrix */
local W="_WS"

/* Z m2 m4 b2 */
preserve
qui summ `VAR', mean
local MEAN=r(mean)
qui replace `VAR'=`VAR'-`MEAN'
tempvar Vm2 Vm4
qui generate `Vm2'=`VAR'^2
qui summ `Vm2', mean
local m2=r(mean)	
qui generate `Vm4'=`VAR'^4
qui summ `Vm4', mean
local m4=r(mean)
local b2=`m4'/(`m2'^2)
tempname Z
mkmat `VAR', matrix(`Z')
restore

/* S0 S1 S2*/
local S0=0
local S1=0
local S2=0
local i=1
while `i'<=`N' {
	local wi=0
	local wj=0
	local j=1
	while `j'<=`N' {
		local S0=`S0'+`W'[`i',`j']
		local S1=`S1'+(`W'[`i',`j']+`W'[`j',`i'])^2
		local wi=`wi'+`W'[`i',`j']
		local wj=`wj'+`W'[`j',`i']
		local j=`j'+1
	}
	local S2=`S2'+(`wi'+`wj')^2
	local i=`i'+1
}
local S1=`S1'/2




*  ----------------------------------------------------------------------------
*  8. Moran's I                                                                
*  ----------------------------------------------------------------------------

if "`geary'"=="" {


/* Labels */
local TITLE "Moran's I spatial correlogram"
local L "I"
local RET "Moran"
local YLINE=0

/* stat */
tempname Zk
matrix `Zk'=`Z''*`W'*`Z'
local stat=`Zk'[1,1]/(`S0'*`m2')
matrix `RESULTS'[`b',3]=`stat'

/* E(stat) */
local E=-1/(`N'-1)
matrix `RESULTS'[`b',4]=`E'

/* sd(stat) */
local NUM1=`N'*( (`N'^2-3*`N'+3)*`S1' - (`N'*`S2') + (3*`S0'^2) )
local NUM2=`b2'*( (`N'^2-`N')*`S1' - (2*`N'*`S2') + (6*`S0'^2) )
local DEN=(`N'-1)*(`N'-2)*(`N'-3)*(`S0'^2)
local sd=(`NUM1'-`NUM2')/`DEN' - (1/(`N'-1))^2
local sd=sqrt(`sd')
matrix `RESULTS'[`b',5]=`sd'

/* z */
local z=(`stat'-`E')/`sd'
matrix `RESULTS'[`b',6]=`z'
	
/* p-value */
local pval=(1-normprob(abs(`z')))*`MULT'
matrix `RESULTS'[`b',7]=`pval'

	
}




*  ----------------------------------------------------------------------------
*  9. Geary's c                                                                
*  ----------------------------------------------------------------------------

if "`geary'"!="" {


/* Labels */
local TITLE "Geary's c spatial correlogram"
local L "c"
local RET "Geary"
local YLINE=1

/* stat */
local SUM=0
local i=1
while `i'<=`N' {
	local j=1
	while `j'<=`N' {
		local SUM=`SUM'+`W'[`i',`j']*(`Z'[`i',1]-`Z'[`j',1])^2
		local j=`j'+1
	}
	local i=`i'+1
}
local stat=((`N'-1)*`SUM')/(2*`N'*`S0'*`m2')
matrix `RESULTS'[`b',3]=`stat'

/* E(stat) */
local E=1
matrix `RESULTS'[`b',4]=`E'
	
/* sd(stat) */
local NUM1=(`N'-1) * `S1' * (`N'^2 - 3*`N' + 3 - (`N'-1)*`b2')
local NUM2=(1/4) * (`N'-1) * `S2' * (`N'^2 + 3*`N' - 6 - (`N'^2-`N'+2)*`b2')
local NUM3=(`S0'^2) * (`N'^2 - 3 - ((`N'-1)^2)*`b2')
local DEN=(`N')*(`N'-2)*(`N'-3)*(`S0'^2)
local sd=(`NUM1'-`NUM2'+`NUM3')/`DEN'
local sd=sqrt(`sd')
matrix `RESULTS'[`b',5]=`sd'

/* z */
local z=(`stat'-`E')/`sd'
matrix `RESULTS'[`b',6]=`z'
	
/* p-value */
local pval=(1-normprob(abs(`z')))*`MULT'
matrix `RESULTS'[`b',7]=`pval'
	

}



	
*  ----------------------------------------------------------------------------
*  10. End loop                                                                
*  ----------------------------------------------------------------------------

	local b=`b'+1
}




*  ----------------------------------------------------------------------------
*  11. Display results                                                         
*  ----------------------------------------------------------------------------

di _newline
di as txt "{title:`TITLE'}"
di _newline

local VARLBL : variable label `VAR'
if "`VARLBL'"!="" {
   local VARLBL=substr("`VARLBL'",1,62)
}
else {
   local VARLBL="`VAR'"
}
di as res "`VARLBL'"
di as txt "{hline 20}{c TT}{hline 41}"
di as txt "   Distance bands   {c |}" _col(26) "`L'" _col(33) "E(`L')"   /*
     */   _col(40) "sd(`L')" _col(50) "z" _col(55) "p-value*"
di as txt "{hline 20}{c +}{hline 41}"
local b=1
while `b'<=`NBANDS' {
	local LO=`RESULTS'[`b',1]
	local UP=`RESULTS'[`b',2]
	local BAND "(`LO'-`UP']"
	di as txt _col(1)  %~20s "`BAND'" "{c |}"   /*
	*/ as res _col(22) %7.3f `RESULTS'[`b',3]   /*
	*/ as res _col(30) %7.3f `RESULTS'[`b',4]   /*
	*/ as res _col(38) %7.3f `RESULTS'[`b',5]   /*
	*/ as res _col(46) %7.3f `RESULTS'[`b',6]   /*
	*/ as res _col(56) %5.3f `RESULTS'[`b',7]
	local b=`b'+1
}
di as txt "{hline 20}{c BT}{hline 41}"
di as txt "`PVL'"
di _newline




*  ----------------------------------------------------------------------------
*  12. Plot correlogram                                                        
*  ----------------------------------------------------------------------------

if "`graph'"!="" {
	

/* Preserve data */
preserve

/* Extract variable label */
local VARLBL : variable label `varlist'
if "`VARLBL'"!="" {
   local VARLBL=substr("`VARLBL'",1,78)
}
else {
   local VARLBL="`varlist'"
}

/* Create x and y */
if `N'<`NBANDS' {
	qui set obs `NBANDS'
}
tempvar YLINVAR x y
qui gen `YLINVAR'=`YLINE' in 1/`NBANDS'
qui gen `x'=_n in 1/`NBANDS'
qui gen `y'=.
local VALLBL ""
local b=1
while `b'<=`NBANDS' {
	local LO=`RESULTS'[`b',1]
	local UP=`RESULTS'[`b',2]
	local VALLBL `"`VALLBL' `b' "`LO'-`UP'""'
	qui replace `y'=`RESULTS'[`b',3] in `b'
	local b=`b'+1
}
lab def _temp `VALLBL'
lab val `x' _temp
format `y' %04.2f

/* Define graph arguments and options */
if "`needle'"=="" {
	local args "`y' `YLINVAR' `x'"
	local conn "c(ll[-])"
	local symb "sy(oi)"
	local pens "pen(21)"
	local yline ""
}
if "`needle'"!="" {
	local args "`y' `y' `YLINVAR' `x'"
	local conn "c(.||)"
	local symb "sy(oii)"
	local pens "pen(222)"
	local yline "yline(`YLINE')"
}

/* Make graph */
graph `args' in 1/`NBANDS', sort `conn' `symb' `pens' `yline' ylab   /*
                       */   xlab(1(1)`NBANDS')                       /*
                       */   t1(`TITLE') t2(`VARLBL') l1(`L')         /*
                       */   b2(Distance bands)
                     
/* Save graph */
if "`savegraph'"!="" {
  	translate @Graph `savegraph'
}

/* Restore data */
restore


}




*  ----------------------------------------------------------------------------
*  13. End program                                                             
*  ----------------------------------------------------------------------------

return matrix `RET' `RESULTS'
matrix drop _W
matrix drop _WS
end



