*! $Id: personal/n/normdiff_example.ado, by Keith Kranker <keith.kranker@gmail.com> on 2011/04/19 20:56:24 (revision b8ba72488bca by user keith) $
*! Create a table to compare two groups, including normalized differences.
* Example for help file.

*! By Keith Kranker
*! $Date$

program define normdiff_example 
	version 9.2
	
	di _n as txt "-> " as input "preserve" 
	preserve
	
	di _n as txt "-> " as input "sysuse lifeexp, clear"
	sysuse lifeexp, clear
	
	di _n as txt "-> " as input "gen regionSA = (region == 3)"
	gen regionSA = (region == 3)
	
	di _n as txt "-> " as input `"normdiff popgrowth lexp if region!=2, over(regionSA)"'
	normdiff popgrowth lexp if region!=2, over(regionSA)

	di _n as txt "-> " as input `"normdiff popgrowth lexp gnppc safewater, over(regionSA) diff tstat n(below) f(%16.4gc)"'
	normdiff popgrowth lexp gnppc safewater, over(regionSA) diff tstat n(below) f(%16.4gc)

	qui {
		cap {
			findfile normdiff_example.ado
			local file_loc_name = subinstr((substr(r(fn),1,(length(r(fn))-4))),"/","\",100)
			local file_full_name `"`file_loc_name'.csv"'
			
			noisily di _n as txt "-> " as input `"mat2txt2 e(table) e(_n) using "`file_full_name'", matnames replace "'
			noisily mat2txt2 e(table) e(_n) using "`file_full_name'", matnames replace 
			}
		if _rc !=0    di as err "You must first install mat2txt.ado"
	} // end quiet
	
	di _n as txt "-> " as input `"restore"'
	restore 

	
end 
