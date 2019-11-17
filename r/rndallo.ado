*! version 6.0.0   03apr2001
program def rndallo
	version 6.0
	gettoken nsub  0 : 0 , parse(" ,")
	gettoken narms 0 : 0 , parse(" ,")
	gettoken nblk  0 : 0 , parse(" ,")
	gettoken 4: 0 , parse(" ,")

	if "`nsub'"=="" | "`narms'"=="" | "`nblk'"=="" /*
	*/ | "`nsub'"=="," | "`narms'"=="," | "`nblk'"=="," {
		di in red "must specify the number of sujects, the number of treatments"
		di in red" and the block size" 
		exit 198
	}
	
	cap confirm integer number `nsub'
	if _rc~=0 {
		noi di in red "number of sujects must be an integer"
		exit 198
	}
	cap confirm integer number `narms'
	if _rc~=0 {
		noi di in red "number of treatment arms must be an integer"
		exit 198
	}
	cap confirm integer  number `nblk'
	if _rc~=0 {
		noi di in red "number of blocks must be an integer"
		exit 198
	}
	if mod(`nblk',`narms')!=0 {  
		noi di in red "Block size must be a multiple of number of treatment arms"
		exit 198
	}

	if  "`4'"=="," {
		syntax [, Label(string) Title(string) seed(string) OUTfile(string) replace] 
	}
	
	qui {
		local total =`narms' * `nblk'
 		if `total'!=`nsub' {
			local total=(int(`nsub'/`nblk')+1)*`nblk'
		}
		noi di 
		if "`title'"~="" {
			noi di _col(5) in gr `"`title'"'
		}
		if "`seed'"~="" {
			noi di in gr _col(5) "             seed: " in ye `"`seed'"'
		}
			noi di in gr _col(5) "       Block size: " in ye `nblk'
	 		noi di in gr _col(5) "Final Sample size: " in ye `total'
		if "`replace'"=="" {
			preserve
		}
		drop _all
		set obs `total'
		gen int subject=_n
		gen block=_n/`nblk' if mod(_n,`nblk')==0
		gsort -subject
		replace block=block[_n-1] if block==.
		gen int txgroup=.
		if "`seed'"~="" {
			set seed `seed'
		}
		tempvar rand
		gen double `rand'=uniform()
		
		sort block `rand'
		local obs 1
		local j 1
		while `j'<=`total' {
			local i 1
			while `i'<= `narms' {
				replace txgroup=`i' in `obs'
				local obs=`obs'+1
				local i=`i'+1
				local j=`j'+1
			}
		}
		parse "`label'", parse(" ,")
		
		gen str20 desc=""
		local i 1
		while `i'<= `narms' {
			replace desc="`1'" if txgroup==`i'
			if "`1'"~="," {			
				local i=`i'+1
			}
			mac shift

		}
		replace desc="." if desc==""
		sort subject
		if "`log'"~="" {
			log using `log'
		}
		if "`label'"=="" {
	 		noi di  "" _n                
			noi di in gr "                 Treatment"           
			noi di in gr "     Subject       Group  "           
			noi di in gr "     -------     ----------  " _n
			local i 1
			while `i'<= `total' {
				noi di in ye _col(9) subject[`i'] _col(22) txgroup[`i']  
				local i=`i'+1
			}
			label var txgroup "Treatment Group"
			label var block "Block Number"
			noi tab  block txgroup
		}
		else {
			noi di  "" _n                
			noi di in gr "                 Treatment            Treatment
			noi di in gr "     Subject       Group             Description"
			noi di in gr "     -------     ----------   --------------------------" _n
			local i 1
			while `i'<= `total' {
				noi di in ye _col(9) subject[`i'] _col(22) txgroup[`i'] /* 
				*/ _col(39) desc[`i'] 
				local i=`i'+1
		  	}
			label var desc "Treatment Group"
			label var block "Block Number"
			noi tab  block desc
		}
		if "`outfile'"~="" {
			qui keep subject block   txgroup desc
			tokenize "`outfile'", parse(",")
			qui save "`1'" `2' `3'
        	}
	}
end
	
