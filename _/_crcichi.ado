*! version 1.0.0  10/28/92  STB-11 smv6
program define _crcichi /* p df */
	version 3.0
	local p `1'
	local df `2'
	if (`p'>.5) { 
		local xlo 0
		local flo 1
		local xhi `df'
		local fhi=chiprob(`df',`xhi')
		local x=(`xlo'+`xhi')/2
		local f=chiprob(`df',`x')
		while abs(`p'-`f') > 1e-3 { 
			if `f'>`p' { 
				local xlo `x'
				local flo `f'
			}
			else {
				local xhi `x'
				local fhi `f'
			}
			local x=(`xlo'+`xhi')/2
			local f=chiprob(`df',`x')
			* di "x=`x' f=`f'"
		}
		mac def S_1 `x'
		exit
	}


	local x = `df' 
	local x0 . 
	while abs(`x' - `x0') > 1e-3 { 
		local x0 = `x'
		local f = chiprob(`df', `x0') - `p'
		local fp= (chiprob(`df',`x0'+.01)-`p'-`f')/.01
		local x = `x' - `f'/`fp'
		* di "x=`x'  diff = " `x' - `x0'
	}
	mac def S_1 `x'
end
