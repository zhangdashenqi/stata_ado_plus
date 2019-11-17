*! $Id$
*! meantab.ado example

program define meantab_example 
	version 9.2
	
	di _n as txt "-> " as input "preserve" 
	preserve
	
	di _n as txt "-> " as input "sysuse census, clear"
	sysuse census, clear
	
	// (Scatter dataset with missing values)
	di _n as txt "-> " as input "foreach var of varlist region  medage death marriage divorce {" _n "     quietly replace `var' = . if uniform() < .15   // (Scatter dataset with missing values)" _n "     }"
	foreach var of varlist region  medage death marriage divorce  {
		quietly replace `var' = . if uniform() < .15   
		}
	
	di _n as txt "-> " as input `"meantab  medage death marriage divorce , over(region) tstat"'
	meantab  medage death marriage divorce , over(region) tstat 
	
	qui {
		cap {
			findfile meantab_example.ado
			local file_loc_name = subinstr((substr(r(fn),1,(length(r(fn))-4))),"/","\",100)
			local file_full_name `"`file_loc_name'.csv"'
			
			noisily di _n as txt "-> " as input `"mat2txt2 e(table) e(_m) using "`file_full_name'", matnames replace "'
			noisily mat2txt2 e(table) e(_m) using "`file_full_name'", matnames replace 
			}
		if _rc !=0    di as err "You must first install mat2txt.ado"
	} // end quiet
	
	di _n as txt "-> " as input `"meantab  medage death marriage divorce if (region==1 | region==3), over(region) diff "'
	meantab  medage death marriage divorce if (region==1 | region==3) , over(region) diff 
	
	
	di _n as txt "-> " as input `"restore"'
	restore 

	
end 
