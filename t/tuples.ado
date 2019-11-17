*! 3.0.1 NJC 1 July 2013
*! 3.0.0 Joseph N. Luchman & NJC 22 June 2013
* 2.1.0 NJC 26 January 2011 
* 2.0.0 NJC 3 December 2006 
* 1.0.0 NJC 10 February 2003 
* all subsets of 1 ... k distinct selections from a list of k items 
program tuples
	version 8 
	syntax anything [, max(numlist max=1 int >0) asis DIsplay VARlist noMata] 

	if "`varlist'" != "" & "`asis'" != "" { 
		di as err "varlist and asis options may not be combined"
		exit 198 
	}	

	if "`varlist'" == "" { 
		local capture "capture" 
	}	
	
	if "`asis'" == "" { 
		`capture' unab anything : `anything' 
	} 
	
	tokenize `"`anything'"'  
	local n : word count `anything' 

	if "`max'" == "" local max = `n' 
	else if `max' > `n' { 
		di "{p}{txt}maximum reset to number of items {res}`n'" 
		local max = `n' 
	} 
	
	if "`display'" == "" local qui "*" 
	local imax = 2^`n' - 1   
	if "`mata'"!="" {
		local k = 0 
		forval I = 1/`max' { 
			forval i = 1/`imax' { 
				qui inbase 2 `i'
				local which `r(base)' 
				local nzeros = `n' - `: length local which' 
				local zeros : di _dup(`nzeros') "0" 
				local which `zeros'`which'  
				local which : subinstr local which "1" "1", ///
					all count(local n1) 
				if `n1' == `I' {
					local previous "`out'"  
					local out 
					forval j = 1 / `n' { 
						local char = substr("`which'",`j',1) 
						if `char' local out `out' ``j''  
					}
					c_local tuple`++k' `"`out'"'
					`qui' di as res "tuple`k': " as txt `"`out'"'  
				}	
			} 	
		}
		c_local ntuples `k'
	}
	else mata: fasttuples("`anything'", `max', "`display'")		
	 
end 

//mata-based implementation of tuples macro generation

version 10 
mata:

void fasttuples(string scalar list, real scalar max, string scalar display)
{
string scalar invtuple 
string colvector toklist
string rowvector tuple
real scalar n, k

t = tokeninit()
tokenset(t, list)
toklist = tokengetall(t)'
for(x = 1; x <= rows(toklist); x++) {
	if (substr(toklist[x],1,1) == `"""') {
		toklist[x] = substr(toklist[x], 2, strlen(toklist[x]) - 2)
	}
}
n = rows(toklist)
k = 0

for(x = 1; x <= max; x++) {
		base = J(x, 1, 1)
		base = (base \ J(n-x, 1, 0))
		basis = cvpermutesetup(base)
		for(y = 1; y <= comb(n, x); y++) {
			combin = cvpermute(basis)
			tuple = (toklist :* combin)'
			invtuple = strtrim(stritrim(invtokens(tuple)))
			k++
			stata("c_local tuple" + strofreal(k) + " " + invtuple)
			if(display != "") printf("{res}tuple%f: {txt}%s\n", k, invtuple)
		}		
	}
	stata("c_local ntuples " + strofreal(k))
}
end
