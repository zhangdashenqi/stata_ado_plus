*!  Version 1.0   (STB-54: sbe32)
**INITIAL NEGATIVE BINOMIAL REGRESSION MODEL**

cap program drop funver1
program define funver1
version 5.0

tempvar mui mufi var s1 s2 s3
local lnf "`1'"
local xbeta "`2'"

qui {
	gen double `mui'=exp(`xbeta')
	gen double `var'=[($S_mldepn-`mui')^2]/`mui'
	sum `var' 
	global fi=_result(18)/32
	gen double `mufi'=`mui'/($fi-1)
	gen double `s1'=lngamma($S_mldepn+`mufi')-lngamma($S_mldepn+1)
	gen double `s2'=lngamma(`mufi')+`mufi'*ln($fi)
	gen double `s3'=$S_mldepn*ln($fi)-$S_mldepn*ln($fi-1)
	replace `lnf'=`s1'-`s2'-`s3'
}
end


