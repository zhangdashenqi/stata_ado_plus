*! Version 1.0 - 29 January 2001 STB-60 sg162
*! -spatgsa- Measures of global spatial autocorrelation                        
*! Author: Maurizio Pisati                                                     
*! Department of Sociology and Social Research                                 
*! University of Milano Bicocca (Italy)                                        
*! maurizio.pisati@galactica.it                                                
*!                                                                             




*  ----------------------------------------------------------------------------
*  1. Define program                                                           
*  ----------------------------------------------------------------------------

program define spatgsa, rclass
version 7.0




*  ----------------------------------------------------------------------------
*  2. Define syntax                                                            
*  ----------------------------------------------------------------------------

syntax varlist, Weights(string) [Moran Geary GO TWOtail]




*  ----------------------------------------------------------------------------
*  3. Check syntax                                                             
*  ----------------------------------------------------------------------------

capture qui matrix list `weights'
if _rc==111 {
	di as err "Matrix `weights' does not exist"
	exit
}

local ROWNAME : rownames(`weights')
local COLNAME : colnames(`weights')
local WTYPE : word 1 of `ROWNAME'
local WBINA : word 2 of `ROWNAME'
local WSTAN : word 3 of `ROWNAME'
local LOW1 : word 1 of `COLNAME'
local LOW2 : word 2 of `COLNAME'
local LOWER "`LOW1'.`LOW2'"
local UPP1 : word 3 of `COLNAME'
local UPP2 : word 4 of `COLNAME'
local UPPER "`UPP1'.`UPP2'"
if "`WTYPE'"!="SWMImpo" & "`WTYPE'"!="SWMDist" {
	di as err "Matrix `weights' has not been created by -spatwmat-."
	di as err "To run -spatgsa-, create weights matrix with -spatwmat-"
	exit
}

local N=_N
local DIM=rowsof(`weights')
if `DIM'!=`N' {
	di as err "Matrix `weights' is `DIM'x`DIM', the dataset in use has `N' obs."
	di as err "To run -spatgsa- weights matrix dimension must equal N. of obs"
	exit
}

if "`moran'"=="" & "`geary'"=="" & "`go'"=="" {
	di as err "You must specify one or more of the following options:"
	di as err "{bf:{ul:m}oran}: Moran's I"
	di as err "{bf:{ul:g}eary}: Geary's c"
	di as err "{bf:{ul:go}}   : Getis and Ord's G"
	exit
}

if "`go'"!="" & "`WSTAN'"=="Yes" {
	di as err "Matrix `weights' is row-standardized."
	di as err "To compute Getis and Ord's G you must use a"
	di as err "non-standardized binary weights matrix"
	exit
}

if "`go'"!="" & "`WBINA'"=="No" {
	di as err "Spatial weights in matrix `weights' are not binary."
	di as err "To compute Getis and Ord's G you must use a"
	di as err "non-standardized binary weights matrix"
	exit
}




*  ----------------------------------------------------------------------------
*  4. Define basic quantities                                                  
*  ----------------------------------------------------------------------------

/* Weights matrix */
local W="`weights'"


/* N. of variables */
local NVAR : word count `varlist'


/* p-value multiplier and label */
local MULT=("`twotail'"!="")+1
local PVL "*`MULT'-tail test"


/* Display labels */
if "`WTYPE'"=="SWMImpo" & "`WBINA'"=="Yes" {
	local LBLTYPE "Imported (binary)"
}
if "`WTYPE'"=="SWMImpo" & "`WBINA'"=="No" {
	local LBLTYPE "Imported (non-binary)"
}
if "`WTYPE'"=="SWMDist" & "`WBINA'"=="Yes" {
	local LBLTYPE "Distance-based (binary)"
	local LBLBAND "`LOWER' < d <= `UPPER'"
}
if "`WTYPE'"=="SWMDist" & "`WBINA'"=="No" {
	local LBLTYPE "Distance-based (inverse distance)"
	local LBLBAND "`LOWER' < d <= `UPPER'"
}


/* Z m2 m4 b2 matrices */
preserve
tempname m2 m4 b2 M
matrix `m2'=J(`NVAR',1,0)
matrix `m4'=J(`NVAR',1,0)
matrix `b2'=J(`NVAR',1,0)
matrix `M'=J(`NVAR',4,0)
local k=1
while `k'<=`NVAR' {
	local VAR : word `k' of `varlist'
	local j=1
	while `j'<=4 {
		tempvar TEMP
	   qui generate `TEMP'=`VAR'^`j'
	   qui summ `TEMP', mean
	   matrix `M'[`k',`j']=r(sum)
		local j=`j'+1
	}
	qui summ `VAR', mean
	local MEAN=r(mean)
	qui replace `VAR'=`VAR'-`MEAN'
	tempvar Vm2 Vm4
	qui generate `Vm2'=`VAR'^2
	qui summ `Vm2', mean
   matrix `m2'[`k',1]=r(mean)	
	local m2k=r(mean)
	qui generate `Vm4'=`VAR'^4
	qui summ `Vm4', mean
   matrix `m4'[`k',1]=r(mean)	
	local m4k=r(mean)
   matrix `b2'[`k',1]=`m4k'/(`m2k'^2)	
	local k=`k'+1
}
tempname Z
mkmat `varlist', matrix(`Z')
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
*  5. Moran's I                                                                
*  ----------------------------------------------------------------------------

if "`moran'"!="" {


/* Define results matrix */
tempname MORAN
matrix `MORAN'=J(`NVAR',5,0)
matrix rownames `MORAN'=`varlist'
matrix colnames `MORAN'=stat mean sd z p-value

/* Start loop */
local k=1
while `k'<=`NVAR' {
	local m2k=`m2'[`k',1]
	local b2k=`b2'[`k',1]
	
	/* stat */
	tempname Zk
	matrix `Zk'=`Z'[1...,`k']
	matrix `Zk'=`Zk''*`W'*`Zk'
	local stat=`Zk'[1,1]/(`S0'*`m2k')
	matrix `MORAN'[`k',1]=`stat'
	
	/* E(stat) */
	local E=-1/(`N'-1)
	matrix `MORAN'[`k',2]=`E'
	
	/* sd(stat) */
	local NUM1=`N'*( (`N'^2-3*`N'+3)*`S1' - (`N'*`S2') + (3*`S0'^2) )
	local NUM2=`b2k'*( (`N'^2-`N')*`S1' - (2*`N'*`S2') + (6*`S0'^2) )
	local DEN=(`N'-1)*(`N'-2)*(`N'-3)*(`S0'^2)
	local sd=(`NUM1'-`NUM2')/`DEN' - (1/(`N'-1))^2
	local sd=sqrt(`sd')
	matrix `MORAN'[`k',3]=`sd'

	/* z */
	local z=(`stat'-`E')/`sd'
	matrix `MORAN'[`k',4]=`z'
	
	/* p-value */
   local pval=(1-normprob(abs(`z')))*`MULT'
	matrix `MORAN'[`k',5]=`pval'
	
	/* End loop */
	local k=`k'+1
}


}




*  ----------------------------------------------------------------------------
*  6. Geary's c                                                                
*  ----------------------------------------------------------------------------

if "`geary'"!="" {


/* Define results matrix */
tempname GEARY
matrix `GEARY'=J(`NVAR',5,0)
matrix rownames `GEARY'=`varlist'
matrix colnames `GEARY'=stat mean sd z p-value

/* Start loop */
local k=1
while `k'<=`NVAR' {
	local m2k=`m2'[`k',1]
	local b2k=`b2'[`k',1]
	
	/* stat */
	tempname Zk
	matrix `Zk'=`Z'[1...,`k']
	local SUM=0
	local i=1
	while `i'<=`N' {
		local j=1
		while `j'<=`N' {
			local SUM=`SUM'+`W'[`i',`j']*(`Zk'[`i',1]-`Zk'[`j',1])^2
			local j=`j'+1
		}
		local i=`i'+1
	}
	local stat=((`N'-1)*`SUM')/(2*`N'*`S0'*`m2k')
	matrix `GEARY'[`k',1]=`stat'
	
	/* E(stat) */
	local E=1
	matrix `GEARY'[`k',2]=`E'
	
	/* sd(stat) */
	local NUM1=(`N'-1) * `S1' * (`N'^2 - 3*`N' + 3 - (`N'-1)*`b2k')
	local NUM2=(1/4) * (`N'-1) * `S2' * (`N'^2 + 3*`N' - 6 - (`N'^2-`N'+2)*`b2k')
	local NUM3=(`S0'^2) * (`N'^2 - 3 - ((`N'-1)^2)*`b2k')
	local DEN=(`N')*(`N'-2)*(`N'-3)*(`S0'^2)
	local sd=(`NUM1'-`NUM2'+`NUM3')/`DEN'
	local sd=sqrt(`sd')
	matrix `GEARY'[`k',3]=`sd'

	/* z */
	local z=(`stat'-`E')/`sd'
	matrix `GEARY'[`k',4]=`z'
	
	/* p-value */
   local pval=(1-normprob(abs(`z')))*`MULT'
	matrix `GEARY'[`k',5]=`pval'
	
	/* End loop */
	local k=`k'+1
}


}




*  ----------------------------------------------------------------------------
*  7. Getis and Ord's G                                                        
*  ----------------------------------------------------------------------------

if "`go'"!="" {


/* Define results matrix */
tempname GETORD
matrix `GETORD'=J(`NVAR',5,0)
matrix rownames `GETORD'=`varlist'
matrix colnames `GETORD'=stat mean sd z p-value

/* Define X matrix */
tempname X
mkmat `varlist', matrix(`X')

/* B0 B1 B2 B3 B4 */
local B0=((`N'^2)-3*`N'+3)*`S1' - `N'*`S2' + 3*(`S0'^2)
local B1=-( ((`N'^2)-`N')*`S1' - 2*`N'*`S2' + 6*(`S0'^2) )
local B2=-( 2*`N'*`S1' - (`N'+3)*`S2' + 6*(`S0'^2) )
local B3=4*(`N'-1)*`S1' - 2*(`N'+1)*`S2' + 8*(`S0'^2)
local B4=`S1' - `S2' + (`S0'^2)

/* Start loop */
local k=1
while `k'<=`NVAR' {
	local m1k=`M'[`k',1]
	local m2k=`M'[`k',2]
	local m3k=`M'[`k',3]
	local m4k=`M'[`k',4]
	
	/* stat */
	tempname Xk NUM
	matrix `Xk'=`X'[1...,`k']
	matrix `NUM'=`Xk''*`W'*`Xk'
	local DEN=0
	local i=1
	while `i'<=`N' {
		local j=1
		while `j'<=`N' {
			if `i'!=`j' {
				local DEN=`DEN'+`Xk'[`i',1]*`Xk'[`j',1]
			}
			local j=`j'+1
		}
		local i=`i'+1
	}
	local stat=`NUM'[1,1]/`DEN'
	matrix `GETORD'[`k',1]=`stat'
	
	/* E(stat) */
	local E=`S0'/(`N'*(`N'-1))
	matrix `GETORD'[`k',2]=`E'
	
	/* sd(stat) */
	local NUM=(`B0'*(`m2k'^2)) + (`B1'*`m4k') + (`B2'*(`m1k'^2)*`m2k')
	local NUM=`NUM' + (`B3'*`m1k'*`m3k') + (`B4'*(`m1k'^4))
	local DEN=(((`m1k'^2)-`m2k')^2)*`N'*(`N'-1)*(`N'-2)*(`N'-3)
	local sd=(`NUM'/`DEN') - ((`E')^2)
	local sd=sqrt(`sd')
	matrix `GETORD'[`k',3]=`sd'

	/* z */
	local z=(`stat'-`E')/`sd'
	matrix `GETORD'[`k',4]=`z'
	
	/* p-value */
   local pval=(1-normprob(abs(`z')))*`MULT'
	matrix `GETORD'[`k',5]=`pval'
	
	/* End loop */
	local k=`k'+1
}


}




*  ----------------------------------------------------------------------------
*  8. Display results                                                          
*  ----------------------------------------------------------------------------

di _newline
di as txt "{title:Measures of global spatial autocorrelation}"
di _newline
di as txt "Weights matrix"
di as txt "{hline 62}"
di as txt "Name: " as res "`W'"
di as txt "Type: " as res "`LBLTYPE'"
if "`WTYPE'"=="SWMDist" {
	di as txt "Distance band: " as res "`LBLBAND'"
}
di as txt "Row-standardized: " as res "`WSTAN'"
di as txt "{hline 62}"

if "`moran'"!="" {
   di ""
	_disp "`MORAN'" "Moran's I" "I"
   return matrix Moran `MORAN'
}

if "`geary'"!="" {
   di ""
	_disp "`GEARY'" "Geary's c" "c"
   return matrix Geary `GEARY'
}

if "`go'"!="" {
   di ""
	_disp "`GETORD'" "Getis & Ord's G" "G"
   return matrix GetisOrd `GETORD'
}
di as txt "`PVL'"
di _newline




*  ----------------------------------------------------------------------------
*  9. End program                                                              
*  ----------------------------------------------------------------------------

end








*  ----------------------------------------------------------------------------
*  A1. Subprogram _disp                                                        
*  ----------------------------------------------------------------------------

program define _disp
version 7.0
args MAT TITLE L

local LIST : rownames(`MAT')
local NVAR : word count `LIST'
di as txt "`TITLE'"
di as txt "{hline 20}{c TT}{hline 41}"
di as txt _col(11) "Variables {c |}" _col(26) "`L'" _col(33) "E(`L')"   /*
     */   _col(40) "sd(`L')" _col(50) "z" _col(55) "p-value*"
di as txt "{hline 20}{c +}{hline 41}"
local k=1
while `k'<=`NVAR' {
	local VAR : word `k' of `LIST'
	local VAR=abbrev("`VAR'",19)
	di as txt _col(1)  %19s "`VAR'" " {c |}"   /*
	*/ as res _col(22) %7.3f `MAT'[`k',1]      /*
	*/ as res _col(30) %7.3f `MAT'[`k',2]      /*
	*/ as res _col(38) %7.3f `MAT'[`k',3]      /*
	*/ as res _col(46) %7.3f `MAT'[`k',4]      /*
	*/ as res _col(56) %5.3f `MAT'[`k',5]
	local k=`k'+1
}
di as txt "{hline 20}{c BT}{hline 41}"

end



