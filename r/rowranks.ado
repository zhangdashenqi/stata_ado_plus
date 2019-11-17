*! NJC 2.0.0 30 January 2009 
* NJC 1.1.0 11 May 2005
* NJC 1.0.0 4 October 2000 
program rowranks
	version 9 
	syntax varlist [if] [in], Generate(str) ///
	[ Descending HIGHmissing MISSing METHod(str)] 

	capture confirm numeric var `varlist' 
	if _rc == 0 local numeric = 1 
	else { 
		capture confirm string var `varlist' 
		if _rc { 
			di as err "varlist must be all numeric or all string" 
			exit 7 
		}
		else local numeric = 0 
	}

	local mylist `varlist' 
	local nvars : word count `varlist'

	local 0 `generate' 
	syntax newvarlist
	local generate `varlist' 
	local ngen : word count `generate' 
	if `nvars' != `ngen' { 
		di as err "`nvars' variables, but `ngen' new " ///
		plural(`ngen', "name") 
		exit 198 
	} 

	quietly {
		marksample touse, novarlist 
		count if `touse' 
		if r(N) == 0 error 2000 

		if `nvars' == 1 { 
			gen `generate' = ///
cond("`missing'" != "", 1, cond(missing(`mylist'), ., 1)) if `touse' 
			exit 0 
		} 

		local method = lower("`method'") 
		local lm = length("`method'") 
		if `lm' { 
			if substr("low", 1, `lm') == "`method'" { 
				local how = 2 
			}
			else if substr("high", 1, `lm') == "`method'" { 
				local how = 3 
			}
			else if substr("mean", 1, `lm') == "`method'" { 
				local how = 4 
			}
			else { 
				di as err "invalid method()" 
				exit 498 
			} 
		} 
		else local how = 1 

		local dir = cond("`descending'" == "", 1, -1) 
		local miss = "`missing'" != "" 
		local high = "`highmissing'" != ""    

if `numeric' { 
	mata : ///
row_ranks("`mylist'", "`touse'", "`generate'", `dir', `miss', `how', `high') 
}
else { 
	mata : ///
row_sranks("`mylist'", "`touse'", "`generate'", `dir', `miss', `how', `high') 
}

		compress `generate' 
	}
end 	
	
mata : 

void row_ranks(string scalar varnames, 
		string scalar tousename,
		string scalar newnames, 
		real scalar dir, 
		real scalar miss, 
		real scalar how,  
		real scalar high)
{
	real matrix y 
	real scalar i

	y = st_data(., tokens(varnames), tousename) 
	
	for(i = 1; i <= rows(y); i++) { 
		y[i,] = ranks(y[i,]', dir, miss, how, high)' 
        }

	(void) st_addvar("float", tokens(newnames)) 
	st_store(., tokens(newnames), tousename, y) 
}

real colvector function ranks(
	real colvector y, 
	real scalar dir, 
	real scalar miss, 
	real scalar how, 
	real scalar high) 
{
real matrix work 
real scalar n, i, nmiss 

n = rows(y) 
nmiss = missing(y) 
work = sort((y, (1::n)) , (dir, 2)), (1::n) 

if(dir == -1 & high & nmiss & nmiss < n) { 
	work[,(1,2)] = work[((nmiss + 1::n) \ (1::nmiss)), (1,2)] 
	work[,3] = 1::n 
} 

if (how == 1) { // unique ranks, stable sort 
	// do nothing 
} 
else if (how == 2) { // low ranks 
	for(i = 2; i <= n; i++) { 
		if (work[i, 1] == work[i-1, 1]) work[i, 3] = work[i-1, 3] 
	} 
}
else if (how == 3) { // high ranks  
	for(i = n-1; i >= 1; i--) { 
		if (work[i, 1] == work[i+1, 1]) work[i, 3] = work[i+1, 3] 
	}
}
else if (how == 4) { // mean ranks 
	for(i = 2; i <= n; i++) { 
		if (work[i, 1] == work[i-1, 1]) work[i, 3] = work[i-1, 3] 
	}
	work = work, (1::n) 
 	for(i = n-1; i >= 1; i--) { 
		if (work[i, 1] == work[i+1, 1]) work[i, 4] = work[i+1, 4] 
	}
	work[,3] = (work[,3] + work[,4]) / 2 
}

if (miss == 0 & nmiss) {
	if (dir == 1 | high) work[|n - nmiss + 1, 3 \ n, 3|] = J(nmiss, 1, .) 
	else work[|1, 3 \ nmiss, 3|] = J(nmiss, 1, .) 
} 	
	
_sort(work, 2)
return(work[,3]) 
} 

void row_sranks(string scalar varnames, 
		string scalar tousename,
		string scalar newnames, 
		real scalar dir, 
		real scalar miss, 
		real scalar how,  
		real scalar high)
{
	string matrix y 
	real matrix ranks 
	real scalar i

	st_sview(y, ., tokens(varnames), tousename) 
	ranks = J(rows(y), cols(y), .) 

	for(i = 1; i <= rows(y); i++) { 
		ranks[i,] = sranks(y[i,]', dir, miss, how, high)' 
        }

	(void) st_addvar("float", tokens(newnames)) 
	st_store(., tokens(newnames), tousename, ranks) 
}

real colvector function sranks(
	string colvector y, 
	real scalar dir, 
	real scalar miss, 
	real scalar how, 
	real scalar high) 
{
string matrix work
string colvector strindices 
real scalar n, len, i, nmiss 

// we are going to sort string versions of the indices 1 to n, 
// but to ensure correct order we need to prefix with leading "0"; 
// thus 1 to 10 will be sorted as "01" to "10" 

n = rows(y) 
len = strlen(strofreal(n)) 
strindices = strofreal(1::n) 
strindices = (len :- strlen(strindices)) :* "0" :+ strindices 
nmiss = sum(y :== "") 

work = sort((y, strindices) , (dir, 2)), strindices

if(dir == 1 & high & nmiss & nmiss < n) { 
	work[,(1,2)] = work[((nmiss + 1::n) \ (1::nmiss)), (1,2)] 
	work[,3] = strindices 
} 

if (how == 1) { // unique ranks, stable sort 
	// do nothing 
} 
else if (how == 2) { // low ranks 
	for(i = 2; i <= n; i++) { 
		if (work[i, 1] == work[i-1, 1]) work[i, 3] = work[i-1, 3] 
	} 
}
else if (how == 3) { // high ranks  
	for(i = n-1; i >= 1; i--) { 
		if (work[i, 1] == work[i+1, 1]) work[i, 3] = work[i+1, 3] 
	}
}
else if (how == 4) { // mean ranks 
	for(i = 2; i <= n; i++) { 
		if (work[i, 1] == work[i-1, 1]) work[i, 3] = work[i-1, 3] 
	}
	work = work, strindices 
 	for(i = n-1; i >= 1; i--) { 
		if (work[i, 1] == work[i+1, 1]) work[i, 4] = work[i+1, 4] 
	}
}

if (miss == 0 & nmiss) {
	if (dir == -1 | high) work[|n - nmiss + 1, 3 \ n, 3|] = J(nmiss, 1, "")
	else work[|1, 3 \ nmiss, 3|] = J(nmiss, 1, "") 
} 	
	
_sort(work, 2)

if (how == 4) return((strtoreal(work[,3]) + strtoreal(work[,4])) / 2) 
else return(strtoreal(work[,3])) 
} 

end 

