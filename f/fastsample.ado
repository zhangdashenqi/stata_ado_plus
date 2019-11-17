cap program drop fastsample
program define fastsample
version 13.0
	syntax anything(name=n) [if] [in], [count]
	
	/*
	rather than mark, which requires generating a new variable, the below
	code will run instantaneously if if/in were not specified
	*/
	if `"`in'"' != `""' keep `in'
	if `"`if'"' != `""' keep `if'
	
	if "`count'" == "" {
		cap assert (`n' <= 100) & (`n' > 0)
		if _rc != 0 {
			di as error "n must be percentage greater than 0 and less than or equal to 100"
			error 9
		}
		local n = ceil(_N*`n'/100)
	}
	cap assert _N != 0
	if _rc != 0 {
		di as error "cannot sample empty dataset"
		error 9
	}
	cap assert ((`n'-ceil(`n')==0) & (`n' > 0) & (`n' <= _N))
	if _rc != 0 {
		di as error "n must be a positive integer and may not be greater than the size of the touse dataset"
		error 9
	}
	
	mata: fastsample(`n')
	
end

mata

void fastsample(real scalar N)
// faster alternative to stata's sample.
// 1.6s vs 58.9s in one test
{
	
	real scalar origN, L, n, i
	real vector allnum, allstr, obstokeep
	
	// check for errors
	L = st_nobs()
	if ((N-ceil(N)!=0) | (N <= 0)) _error(9,"N must be a positive integer")
	if (L < N) _error(9,"cannot sample more observations than entire dataset")
	
	// initialize index	
	I = J(L,1,0) // index of rows to keep
	i = 0

	// first try - there could be collisions (the same row being called twice)
	obstokeep = ceil(L*runiform(N,1))
	I[obstokeep] = J(N,1,1)

	// iterate until we have a sample of N index values of L
	while (n!=0) {
		R = selectindex(!I) // remaining indices that may be chosen
		l = length(R) // total subindices
		n = N - (L-l) // remaining obs to get

		obstokeep = R[ceil(l*runiform(n,1))]
		I[obstokeep] = J(n,1,1)
		i++
	}
	printf("total iterations: %f\n", i)

	obstokeep = selectindex(I)
	st_keepobsin(obstokeep)
		
}

end
