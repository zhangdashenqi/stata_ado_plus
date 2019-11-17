cap program drop fastbsample
program define fastbsample
version 13.0
	syntax anything(name=n) [if] [in], [count]
	
	/*
	rather than mark, which requires generating a new variable, the below
	code will run instantaneously if if/in were not specified
	*/
	if `"`in'"' != `""' keep `in'
	if `"`if'"' != `""' keep `if'
	
	cap assert _N != 0
	if _rc != 0 {
		di as error "cannot sample empty dataset"
		error 9
	}
	cap assert ((`n'-ceil(`n')==0) & (`n' > 0))
	if _rc != 0 {
		di as error "n must be a positive integer"
		error 9
	}
		
	mata: fastbsample(`n')
	
end

mata

void fastbsample(real scalar n)
// faster alternative to stata's bsample.
// .2s vs 55.6s in one test
{
	
	real scalar origN
	real vector allnum, allstr
	
	// check for errors
	if ((n-ceil(n)!=0) | (n <= 0)) _error(9,"n must be a positive integer")
	if (st_nobs() == 0) _error(9,"cannot sample empty dataset")
	
	// declare objects
	allnum = J(1,0,.)
	allstr = J(1,0,.)
	v = st_nvar()

	// separate string and numeric variables
	for (i=1;i<=v;i++) if (st_isnumvar(i)==1) allnum = allnum, i; else allstr = allstr, i;
	
	st_view(Nvars=.,.,allnum)
	st_sview(Svars=.,.,allstr)
	
	origN = rows(Nvars)
	
	// manually add extra obs if origN < n
	if (origN < n) {
		st_addobs(n - origN,1)
		st_view(Nvars=.,.,allnum)
		st_sview(Svars=.,.,allstr)
	}

	/*
	Below: slightly less efficient to store vector obstokeep than direct
	subscripting. We only have to if Nvars and Svars are both nonempty
	*/
	if (cols(allstr) == 0) Nvars[|1,.\n,.|] = Nvars[ceil(origN*runiform(n,1)),.]
	else if (cols(allnum) == 0) Svars[|1,.\n,.|] = Svars[ceil(origN*runiform(n,1)),.]
	else {
		real vector obstokeep
		obstokeep = ceil(origN*runiform(n,1))
		Nvars[|1,.\n,.|] = Nvars[obstokeep,.]
		Svars[|1,.\n,.|] = Svars[obstokeep,.]
	}

	st_keepobsin((1,n))
	
}

end
