/* Calculate critical values for test of regime switching */

/* Code by Valerie Bostwick */

/* Last edited September 13, 2012 */



program define rscv

version 10.1

syntax [,ll(real -1) ul(real 1) r(real 100000) q(real 0.95)]

/*

ll = the lower limit for the grid of values

ul = the upper limit for the grid of values

r = the number of iterations

q = the quantile

*/

mata: genrscv(`ll', `ul', `r', `q')

end



version 10.1

mata:

real scalar genrscv(real scalar ll, real scalar ul, real scalar r, real scalar q)

{
maxeta=max(abs(ul)\abs(ll))				/*find max value of eta over interval H */

j=ceil(2*(maxeta^2))					/*set the number of expansion terms s.t. (maxeta^2)/j=1/2 */

if (j<4) j=4						/* minimum number of expansions is 4 */

if (j<=167) {						/* maximum number of expansions is 167 */

d=(3..j)						/*index of expansion terms*/

nH = floor((ul-ll)*100)+1				/*number of terms in the grid*/

eta=range(ll,ul,.01)'					/*grid of values at which to evaluate the process*/

stddev=1:/sqrt(factorial(d))				/*vector of 1/root(j!)*/

emat=rnormal(1,r,0, stddev')				/*matrix of simulated N(0,stddev^2) random variates

                                            			 # columns = r

                                           			 # rows = number of terms in expansion (d-2)*/  

etamat=J(j-2,1,eta):^J(1,nH,d')				/*create a matrix: 1 column for each value in the grid, 

								 1 row for each term in the expansion

                                            			 first column (eta(1)^3, eta(1)^4,...,eta(1)^d) where

                                            			 eta(1) is the first element of the grid */

s1 = etamat'*emat					/*matrix of sums, nh rows, nr columns (1,2): sum of 

								 eta(1)^j*e(j,rep 2) and (2,1) sum of eta(2)^j*e(j,rep 1)*/

sc = sqrt(exp(eta:^2):-1:-eta:^2:-eta:^4:/2)		/*scaling factor*/

cs = s1:/J(1,r,sc')					/*rescale matrix of sums by scaling factor*/

cs1=cs\J(1,r,0)						/*add row of zeros at end to insert the 0 for calculation 

								 of min(0,g(eta))*/

m2 = colmin(cs1):^2					/*take minimum of each column, which is min(0,g(eta)) for 

								 each replication and construct [min(0,g(eta))]^2*/

m1=colmax(emat[2,.]:*sqrt(gamma(5))\J(1,r,0)):^2

m=sort(colmax(m1\m2)',1)				/*max( [max(0,epsilon4)]^2, [min(0,g(eta))]^2 ), sorted in 

								 ascending order across replications*/

kcv = floor(q*r)					/*Calculate the value that corresponds to the q quantile 

								 of the replication vector*/

cv = m[kcv]  



return(cv) 

}

else {

printf("The requested interval, %f to %f, is too large. \n", ll, ul)

return(-1)

}
clear

}

end



