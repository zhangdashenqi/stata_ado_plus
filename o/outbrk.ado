*!  Version 1.0    (STB-54: sbe32)
version 5.0

cap program drop outbrk
program define outbrk

qui save, replace
local archivo="$S_FN" 
local semana=`1'
local ano=`2'
	
qui {
	tempvar grupo
	encode $texto, gen(`grupo')
	sum `grupo'
	local k=_result(6)+1                  /* k-1=Nº of organisms */ 
	local i=1                             /* i=organism indicator */
	while `i'<`k'{
		datos `i' `semana' `ano' `archivo'           /* Historical data selection */
		tempfile provis
		save `provis'
		local bfinal="umbral"
		sum casos if id~=1
		local yo=_result(6)
		if `yo'==0 {                    /* End: no outbreak */
			local c=0
			bfinal `semana' `ano' `c' ``bfinal''
		}
		else {
			count if casos==0
			local m=_result(1)
			if `m'>30 {               /* End: rare organism */
				local c=0
				bfinal `semana' `ano' `c' ``bfinal''
			}
			else {
				carchivo `provis'
				rho
				modelos `provis' R
				local c=1
				bfinal `semana' `ano' `c' ``bfinal''
			}
		}
		tempfile umbral
		save `umbral'
		local i=`i'+1
	}
	
**CALCULATING THE THRESHOLD VALUE**
	tempvar gamma varmu
	gen double sup=.
	label var sup "Threshold"
	local v1=invnorm(0.995)
	gen double `gamma'=fi+(varmu/mucero)
	gen double `varmu'=(4*`gamma'*(mucero^(1/3)))/9
	replace sup=(mucero^(2/3)+`v1'*sqrt(`varmu'))^(3/2)
	format sup %6.2g
	gen str6 alerta="-   "
	replace alerta="Warning" if casos>0 & sup==.
	replace alerta="Warning" if casos>sup & sup~=.
	label var alerta "Warning"
	label var texto "Organism"
	label var casos "Reports"
}

**FINAL TABLE**
di "YEAR `2'; WEEK `1'"
tabdisp texto, cellvar(casos sup alerta)

qui use `archivo', clear

end


**THIS PROGRAM SELECT THE HISTORICAL DATA**
cap program drop datos
program define datos
use `4', clear
cap drop grupo
encode $texto, gen(grupo)
keep if grupo==`1'
sort $ano $semana
tempvar id1 id2 col
gen `id1'=_n
sum `id1' if $ano==`3' & $semana==`2'
local a=_result(6)
gen `id2'=.
replace `id2'=0 if $ano==`3' & $semana==`2'
gen `col'=.
replace `col'=4 if $ano==`3' & $semana==`2' 
local ns=0
local i=1
while `i'<6 {
	count if $ano==`3'-`i'
	local ns=`ns'+_result(1)
	local r1=`a'-`ns'-3
	local r2=`r1'+6
	replace `id2'=1 in `r1'/`r2'
	local j=0
	while `j'<7 {
		local r3=`r1'+`j'
		replace `col'=`j'+1 in `r3'
		local j=`j'+1
		}
	local i=`i'+1
	}
keep if `id2'==0 | `id2'==1

cap drop col orden id
gen col=`col'
gen id=`id2'
recode id 0=.
sum `id1'
local k=_result(5)-1
gen orden=`id1'-`k'

cap ren $casos casos
cap ren $semana semana
cap ren $ano ano
cap ren $nhosp nhosp
cap ren $texto texto

end


**TEMPORARY FILE FOR THRESHOLD CALCULATION**
cap program drop bfinal
program define bfinal
keep texto grupo ano semana nhosp casos
if `3'==0 { 
	keep in 36
	global mucero="."
	global varmu="."
	global fi="."
}
else {
	keep in 1
	replace semana=`1'
	replace ano=`2'
	replace casos=$yo
	replace nhosp=$no
}
gen double mucero=$mucero
gen double varmu=$varmu
gen double fi=$fi
sum grupo
local g=_result(6)
if `g'~=1 {
	tempfile provisi
	save `provisi'
	use `4', clear
	append using `provisi' 
}
end


**DATA SELECTION TO CALCULATE THE CORRELATION MATRIX R
cap program drop carchivo
program define carchivo
local i=1
while `i'<8 {
	use `1', clear
	keep if id==1
	keep if col==`i'
	sort ano
	gen n=_n
	ren casos casos`i'
	keep n casos`i'
	sort n
	if `i'==1 {
		tempfile correl
		save `correl'
	}
	else {
		tempfile provisi
		save `provisi'
		use `correl', clear
		sort n
		merge n using `provisi'
		drop _merge
		save, replace
	}
	local i=`i'+1
}
end


**PROGRAM TO CALCULATE THE CORRELATION MATRIX R
cap program drop rho
program define rho
matrix R=J(7,7,1)
local i=1
while `i'<7 {
	local j=`i'+1
	while `j'<8 {
		qui sum casos`i'
		local m1=_result(4)
		qui sum casos`j'
		local m2=_result(4)
		if `m1'==0 | `m2'==0 {
			 matrix R[`i',`j']=0
			 matrix R[`j',`i']=0
		}	
		else {
			correlate casos`i' casos`j'
			matrix R[`i',`j']=_result(4)
			matrix R[`j',`i']=_result(4)
		}
		local j=`j'+1
	}
	local i=`i'+1
}
end

