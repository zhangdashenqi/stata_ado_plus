*! extreme 1.0.0 17 January 2015
*! Copyright (C) 2015 David Roodman

*    This program is free software: you can redistribute it and/or modify
*    it under the terms of the GNU General Public License as published by
*    the Free Software Foundation, either version 3 of the License, or
*    (at your option) any later version.

*    This program is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU General Public License for more details.

*    You should have received a copy of the GNU General Public License
*    along with this program. If not, see <http://www.gnu.org/licenses/>.

mata
mata clear
mata set matastrict on
mata set mataoptimize on
mata set matalnum off

// similar to selectindex(), introduced in Stata 13
real vector _selectindex(real vector v) {
	real colvector i; real matrix w
	pragma unset i; pragma unset w
	maxindex((v \ 0), 1, i, w)
	return (rows(i)>length(v)? J(0, 1, 0) : i)
}

real matrix extreme_clone(real matrix X) {
	real matrix Y
	return(Y = X)
}

// Mata interface for estimator: one-time set-up. Returns moptimize() estimation object
transmorphic extreme_init(real scalar N, real scalar GEV, | string scalar wttype, real colvector wt) {
	transmorphic M
	M = moptimize_init()
	moptimize_init_evaluator(M, &extreme_lf2())
	moptimize_init_evaluatortype(M, "lf2")
	moptimize_init_depvar(M, 1, J(N,0,0)) // cue moptimize() about sample size
	if (GEV) moptimize_init_eq_name(M, 1, "mu")
	moptimize_init_eq_name(M, 1+GEV, "lnsig")
	moptimize_init_eq_name(M, 2+GEV, "xi")
	moptimize_init_search(M, "off")
	moptimize_init_userinfo(M, 1, GEV)
	if (wttype!="") {
		moptimize_init_weight(M, wt)
		moptimize_init_weighttype(M, wttype)
	}
	return (M)
}

// shift available order stats so lowest in rightmost col, for programming convenience in extreme_lf2()
// modifies argument and returns the max order available by observation (scalar if constant)
real matrix extreme_est_prep(real matrix Z) {
	real colvector r; real scalar i
	if (cols(Z)>1 & hasmissing(Z)) {
		r = cols(Z) :- rowmax((Z:==.) :* (cols(Z)..1))
		if (isview(Z)) Z = extreme_clone(Z)
		for (i=rows(Z); i; i--)
			if (r[i]<cols(Z))
				Z[i,] = J(1,cols(Z)-r[i],.), Z[|i,1\i,r[i]|]
	} else
		r = cols(Z)
	return (r)
}

// fit model. X_mu and X_mu_1 must be included for GPD, but are ignored. X_mu, X_lnsig, X_xi must have N rows but can have 0 cols
real scalar extreme_est(transmorphic M, real matrix Z, real matrix X_mu, real matrix X_lnsig, real matrix X_xi, real scalar X_mu_1, real scalar X_lnsig_1, real scalar X_xi_1, | pointer(real rowvector) vector init) {
	real colvector r, i; real scalar GEV
	GEV = moptimize_init_userinfo(M, 1)
	r = extreme_est_prep(Z)
	moptimize_init_userinfo(M, 2, Z)
	moptimize_init_userinfo(M, 3, r)
	if (GEV) {
		moptimize_init_eq_cons(M, 1, X_mu_1? "on" : "off")
		moptimize_init_eq_indepvars(M, 1, X_mu)
	}
	moptimize_init_eq_cons(M, 1+GEV, X_lnsig_1? "on" : "off")
	moptimize_init_eq_indepvars(M, 1+GEV, X_lnsig)
	moptimize_init_eq_cons(M, 2+GEV, X_xi_1? "on" : "off")
	moptimize_init_eq_indepvars(M, 2+GEV, X_xi)
	for (i=length(init); i; i--) moptimize_init_eq_coefs(M, i, *init[i])
	(void) _moptimize(M)
	return (moptimize_result_converged(M))
}

function extreme_lf2(transmorphic M, real scalar todo, real rowvector b, real colvector lng, real matrix S, real matrix H) {
	real matrix x,  y, lny, xgumbel; real colvector sig, xi, mu, lng_mu, f, inv_xi, gumbel, f_x, r; real scalar GEV, R

	GEV =  moptimize_util_userinfo(M, 1)

	sig = exp(moptimize_util_xb(M, b, 1+GEV))
	xi  =     moptimize_util_xb(M, b, 2+GEV)
	if (GEV) {
		mu = moptimize_util_xb(M, b, 1)
		x = moptimize_util_userinfo(M, 2) :- mu
		R = cols(x)
		x = x :/ sig
		r =  moptimize_util_userinfo(M, 3)
	} else {
		x = moptimize_util_userinfo(M, 2) :/ sig
		r = R = 1
	}
	gumbel  = rows(xi)>1? _selectindex(abs(xi):<1e-10) : (abs(xi):<1e-10? 1::rows(x) : J(0,0,0) )
	if (rows(gumbel)) xgumbel=x[gumbel,]
	inv_xi = 1:/xi
	lny = ln(y = 1:+xi:*x)

	if (GEV) {
		f = (R>1? y[,R] : y):^-inv_xi
		if (rows(gumbel)) f[gumbel] = exp(-(R>1? xgumbel[,R] : xgumbel))
	}

	if (todo) {
		real colvector neg_lny_x, neg_lny_xi, lnf_x, lnf_xi, lng_x, lng_xi, lng_lnsig, inv_sig, neg_inv_sig
		
		lnf_x = (-1):/y

		neg_lny_x  = xi:*lnf_x
		neg_lny_xi = x :*lnf_x
		
		lnf_xi = inv_xi:*(inv_xi:*lny+neg_lny_xi)
		if (rows(gumbel)) lnf_xi[gumbel,] = 0.5*xgumbel:*xgumbel

		lng_x  = lnf_x  + neg_lny_x 
		lng_xi = lnf_xi + neg_lny_xi; if (R>1) lng_xi    = quadrowsum(lng_xi)
		lng_lnsig = x :* lng_x      ; if (R>1) lng_lnsig = quadrowsum(lng_lnsig) 
		if (GEV) {
			f_x  =            f :* (R>1? lnf_x [,R] : lnf_x )
			lng_xi = lng_xi - f :* (R>1? lnf_xi[,R] : lnf_xi)
			neg_inv_sig = -(inv_sig = 1:/sig)
			lng_mu  = neg_inv_sig :* ((R>1? quadrowsum(lng_x):lng_x) - f_x)
			lng_lnsig = lng_lnsig - (R>1? x[,R] : x) :*f_x
		}

		S = -r:-lng_lnsig, lng_xi; if (GEV) S = lng_mu, S
		if (todo==2) {
			real colvector neg_lny_xx, neg_lny_xixi, lnf_xx, lnf_xxi, lnf_xixi, lng_xx, lng_xxi, lng_xixi, sig_lng_mulnsig, lny_xxi, t
			real matrix d2lnsiglnsig, d2lnsigxi, d2xixi, d2mumu, d2mulnsig, d2muxi
			real scalar v; v = 1
			
			neg_lny_xx   =  neg_lny_x:*neg_lny_x
			    lny_xxi  =      lnf_x:*lnf_x
			neg_lny_xixi = neg_lny_xi:*neg_lny_xi

			lnf_xx   =  xi:*lny_xxi
			lnf_xxi  =  x :*lny_xxi
			lnf_xixi = inv_xi:*(neg_lny_xixi-2*lnf_xi)
			if (rows(gumbel)) lnf_xixi[gumbel,] = (-1.3333333333333333)*lnf_xi[gumbel,]:*xgumbel

			lng_xx   = lnf_xx   + neg_lny_xx
			lng_xxi  = lnf_xxi  - lny_xxi
			lng_xixi = lnf_xixi + neg_lny_xixi

			if (GEV) {
				lng_xx  [,R] = lng_xx  [,R] - f:*lnf_xx  [,R] -    f:*lny_xxi[,R]        
				lng_xxi [,R] = lng_xxi [,R] - f:*lnf_xxi [,R] - (t=f:*lnf_xi [,R]):*lnf_x [,R] 
				lng_xixi[,R] = lng_xixi[,R] - f:*lnf_xixi[,R] -  t                :*lnf_xi[,R]
			}

			sig_lng_mulnsig = lng_x + x:*lng_xx; if (GEV) sig_lng_mulnsig[,R]=sig_lng_mulnsig[,R]-f_x
			d2lnsigxi    = -moptimize_util_matsum(M, 1+GEV, 2+GEV, quadrowsum(x :* lng_xxi        ), v)
			d2lnsiglnsig =  moptimize_util_matsum(M, 1+GEV, 1+GEV, quadrowsum(x :* sig_lng_mulnsig), v)
			d2xixi       =  moptimize_util_matsum(M, 2+GEV, 2+GEV, quadrowsum(lng_xixi            ), v)
			if (GEV) {
				if (rows(sig)==1) {
					d2mumu    = moptimize_util_matsum(M, 1, 1, quadrowsum(lng_xx         ), v)/(sig*sig)
					d2mulnsig = moptimize_util_matsum(M, 1, 2, quadrowsum(sig_lng_mulnsig), v)/sig
					d2muxi    = moptimize_util_matsum(M, 1, 3, quadrowsum(lng_xxi        ), v)/(-sig)
				} else {
					d2mumu    = moptimize_util_matsum(M, 1, 1, quadrowsum(lng_xx          :*neg_inv_sig:*neg_inv_sig), v)
					d2mulnsig = moptimize_util_matsum(M, 1, 2, quadrowsum(sig_lng_mulnsig :*inv_sig                 ), v)
					d2muxi    = moptimize_util_matsum(M, 1, 3, quadrowsum(lng_xxi         :*neg_inv_sig             ), v)
				}
				H = d2mumu,d2mulnsig,d2muxi \ d2mulnsig',d2lnsiglnsig,d2lnsigxi \ d2muxi',d2lnsigxi',d2xixi
			} else
				H = d2lnsiglnsig,d2lnsigxi  \ d2lnsigxi',d2xixi
		}
	}

	if (R>1) {
		_editmissing(x, 0)  // should only be missing in cells representing missing statistics of order>1. Editing to 0 results in 0 contribution to likelihood.
		_editmissing(xgumbel, 0) // ...or if sig overflowed, in which case lng will become missing below
		lny = ln(1:+xi:*x)
	}
	lng = quadrowsum((inv_xi:+1):*lny, 1)
	if (rows(gumbel)) lng[gumbel] = quadrowsum(xgumbel)
	lng = -r*ln(sig) :- lng
	if (GEV)
		lng = lng - f
}

// parameterize GEV or GPD by (mu,) z_p, xi, where z_p=return level for probability p
function extreme_return_lf(transmorphic M, real rowvector b, real colvector lng) {
	real colvector x, zp, sig, xi, mu, y, gumbel; real scalar GEV
	GEV = moptimize_util_userinfo(M, 1)
	zp = moptimize_util_xb(M, b, 1+GEV)
	xi = moptimize_util_xb(M, b, 2+GEV)
	mu = GEV? moptimize_util_xb(M, b, 1) : 0
	gumbel = abs(xi):<1e-10
	sig = gumbel? ln(moptimize_util_userinfo(M, 3)) : (moptimize_util_userinfo(M, 3)^xi-1) / xi
	sig = (zp - mu) / sig
	x = (GEV? (moptimize_util_userinfo(M, 2) :- mu) : moptimize_util_userinfo(M, 2)) / sig
	lng = -ln(sig) :- (gumbel? x : (1+1/xi)*ln(y = 1:+xi*x))
	if (GEV) lng = lng - (gumbel? exp(-x) : y:^-(1/xi))
}

// represents sum of terms of form C * xi^a * sig^b * f^l * (ln f)^d * x^n / y^m
class poly {
	real scalar len // number of terms
	real matrix coef // one col for each poly, one row (if more than one) for each obs
	real matrix powers // one row for each term's a, b, l, f, n, m 6-tuple

	static pointer (real colvector function) scalar pfnPi // expectation function to be used for all polys
	static pointer (real colvector) scalar pxi, psig, pwt // xi & sig values, observation weights
	static real colvector gumbel // rows of xi near zero
	static real scalar tol // tolerance defining "near"
	static real scalar N // number of obs represented in calculations--1 if no covariates

	static class poly scalar term()
	void  _C(), _xi(), _sig(), debug()
	class poly scalar C(), x(), f(), lnf(), dxi(), sig()
	static class poly scalar sum()
	static class poly rowvector times()
	void set_xi_sig_wt_fnPi()
	void cleanup(), equals()
	real matrix E()
	protected real colvector _E()
	void new()
}

void poly::new() {
	len = 0
	coef = J(0,1,0)
	powers = J(0,6,0)
  if (pfnPi==NULL) pfnPi = &Pi_GEV()
	if (pwt==NULL) pwt = pxi = &J(0,1,0)
}

void poly::debug() {
	"coef,powers"
	coef,powers
	"gumbel"
	gumbel
}

void poly::set_xi_sig_wt_fnPi(real colvector xi, real scalar tol, real colvector sig, real colvector wt, pointer (real colvector function) scalar pPi) {
	pxi = &xi; pwt = &wt;	psig = &sig;	pfnPi = pPi; this.tol = tol
	N = max((rows(xi), rows(wt), rows(sig)))
	gumbel = _selectindex(abs(xi):<tol)
}

// copy one poly into another
void poly::equals(class poly scalar p) {
	len = p.len
	coef = p.coef
	powers = p.powers
}

// create a new monomial: xi^a * f^l * (ln f)^d * x^n / y^m
class poly scalar poly::term(real scalar C, real scalar a, real scalar l, real scalar d, real scalar n, real scalar m) {
	class poly scalar retval
	retval.len = 1
	retval.coef = C
	retval.powers = a,0,l,d,n,m
	return(retval)
}
class poly scalar term(real colvector C, real scalar a, real scalar l, real scalar d, real scalar n, real scalar m)
	return(poly::term(C,a,l,d,n,m))

// multiply a poly by a constant not containing xi or sig, producing a new poly. Constant can vary over observations.
class poly scalar poly::C(real colvector C) {
	class poly scalar retval
	retval = this
	retval.coef = C * retval.coef
	return(retval)
}

// multiply a poly by a constant not containing xi or sig, in place. Constant can vary over observations.
void poly::_C(real colvector C) {
	coef = C * coef
}

// multiply a poly by a power of x, default = 1st power
class poly scalar poly::x(| real scalar n) {
	class poly scalar retval; real scalar i
	if (n==.) n = 1
	retval = this
	for (i=len; i; i--)
		retval.powers[i,5] = retval.powers[i,5] + n
	return(retval)
}

// multiply a poly by a power of xi, in place; default = 1st power
void poly::_xi(| real scalar n) {
	real scalar i
	if (n==.) n = 1
	for (i=len; i; i--)
		powers[i,1] = powers[i,1] + n
}

// multiply a poly by a power of sig, in place; default = 1st power
void poly::_sig(| real scalar n) {
	real scalar i
	if (n==.) n = 1
	for (i=len; i; i--)
		powers[i,2] = powers[i,2] + n
}

// multiply a poly by f; default = 1st power
class poly scalar poly::f(| real scalar n) {
	class poly scalar retval; real scalar i
	if (n==.) n = 1
	retval = this
	for (i=len; i; i--)
		retval.powers[i,3] = retval.powers[i,3] + n
	return(retval)
}

// multiply a poly by ln f
class poly scalar poly::lnf() {
	class poly scalar retval; real scalar i
	retval = this
	for (i=len; i; i--)
		retval.powers[i,4] = retval.powers[i,4] + 1
	return(retval)
}

// multiply a poly by a power of sig; default = 1st power
class poly scalar poly::sig(| real scalar n) {
	class poly scalar retval
	if (n==.) n = 1
	retval = this
	retval._sig(n)
	return(retval)
}

// combine a rowvector of poly's by summing
class poly scalar poly::sum(class poly rowvector t) {
	class poly scalar retval; real scalar i
	retval = t[1]
	for (i=2; i<=cols(t); i++) {
		retval.coef   = retval.coef   \ t[i].coef
		retval.powers = retval.powers \ t[i].powers
	}
	retval.cleanup()
	return(retval)
}

// tensor product of two poly rowvectors
class poly rowvector poly::times(class poly rowvector t1, class poly rowvector t2) {
	real scalar i1, i2, k; class poly rowvector retval
	retval = poly(k=cols(t1)*cols(t2))
	for (i1=cols(t1); i1; i1--)
		for (i2=cols(t2); i2; i2--) {
			retval[k].coef = t1.coef # t2.coef
			retval[k].powers = t1.powers#J(t2.len,1,1) + J(t1.len,1,1)#t2.powers
			retval[k--].cleanup()
		}
	return(retval)
}

// simplify by combining like terms and assure len member is set correctly
void poly::cleanup() {
	real colvector p
	if (rows(coef)) {
		if (rows(coef)>1) {
			p = order(powers, -1..-6) // put high negative powers of xi at bottom so backward loop in E() evaluates most potentially explosive terms first
			coef = coef[p,]
			_collate(powers,p)
			p = 1 \ rowsum(powers[|2,.\.,.|] :!= powers[|.,.\rows(coef)-1,.|]):!=0 // rows for new term types
			powers = powers[_selectindex(p),]
			coef = designmatrix(runningsum(p)) ' coef
		}
		p = _selectindex(rowsum(coef:!=0):>0)
		coef = coef[p,]
		powers = powers[p,]
	}
	len = rows(coef)
}

// differentiate a poly wrt xi--in sense that E[result]=dE[argument]/dxi
class poly scalar poly::dxi() {
	class poly scalar t1, t2, t3, t4, retval
	t1 = this
	t1.coef = t1.coef :* -t1.powers[,5] // -n * f^l * (ln f)^d * x^n / y^m
	t2 = t1.lnf().x(-1)  // // -n * f^l * (ln f)^(d+1) * x^(n-1) / y^m
	retval = poly::sum((t1,t2)); retval._xi(-1) // (t1+t2)/xi
	t3 = this.lnf(); t3.coef = t3.coef :* (t3.powers[,6]-t3.powers[,5]) // (m-n) * [f^l * (ln f)^(d+1) * x^n / y^m]
	t4 = this; t4.coef = coef :* powers[,1]; t4.powers[,1] = t4.powers[,1] :- 1 // Dxi^a = a*xi^(a-1)
	retval = poly::sum((retval, t3, t4)) // dxipoly_dxi * [f^l*(ln f)^d*x^n/y^m] + xipoly * {-n/xi*([f^l*(ln f)^d*x^n/y^m] + [f^l*(ln f)^(d+1)*x^(n-1)/y^m]) + (m-n)*[f^l*(ln f)^(d+1)*x^n/y^m] }
	retval.cleanup()
	return(retval)
}

// expectations of a poly, optionally restricted to observations p. gumbel holds indexes of small xi *after* any restriction by p
real colvector poly::_E(real colvector xi, | real colvector p) {
	real scalar i; real colvector E
	pointer (real matrix) scalar _psig; pointer (real colvector) _pxi
	_psig = rows(p) & rows(*psig)>1? &((*psig)[p,]) : psig
	_pxi  = rows(p) & rows(xi )>1? &(    xi [p,]) : &xi
	E = J(N, 1, 0)
	for (i=len; i; i--)
		E = E + quadrowsum((*_pxi):^powers[i,1] :* (*_psig):^powers[i,2] :* coef[i] :* (-1):^powers[i,5] :* BackDiff(powers[i,3],powers[i,4],powers[i,5],powers[i,6], xi, pfnPi))
	return (E)
}

// weighted, observation-wise expectations of a rowvector of polys
real matrix poly::E(class poly rowvector p) {
	real scalar i; real matrix retval
	retval = J(N, cols(p), 0)
	for (i=cols(p); i; i--) {
		if (rows(*pxi)==rows(gumbel))
			retval[,i] = ((tol:-*pxi):* p[i]._E(-tol, gumbel) + (tol:+*pxi):* p[i]._E(tol, gumbel))/(2*tol)
		else {
			retval[,i] = p[i]._E(*pxi)
			if (rows(gumbel)) retval[gumbel,i] = ((tol:-(*pxi)[gumbel]):* p[i]._E(-tol, gumbel) + (tol:+(*pxi)[gumbel]):* p[i]._E(tol, gumbel))/(2*tol)
		}
	}
	return(retval :* *pwt)
}

// hold pre-computed values of gamma(), digamma(), and trigamma() of a+b*xi, a and b certain integers, for speed
class gammastore {
	static transmorphic _gamma, _digamma, _trigamma
	static real scalar amin, amax, bmin_gamma, bmin_digamma, bmin_trigamma, bmax_gamma, bmax_digamma, bmax_trigamma
	static pointer(real colvector) scalar pxi
	void init()
	real matrix gamma(), digamma(), trigamma()
}

// precompute gamma(), digamma(), trigamma() of a+b*xi, for pre-set ranges of a,b and given colvector xi, as well a+b*(+/- tol)
// associative array indexed by a and i, where i=-1 means -tol, i=0 means xi, and i=1 means +tol
void gammastore::init(real colvector xi, real scalar tol, real scalar R) {
	real scalar a, i; pointer(real colvector) rowvector p
	amin = 1
	amax = 9+R
	bmin_gamma = 0
	bmin_digamma = 0
	bmin_trigamma = 0
	bmax_gamma = 3
	bmax_digamma = 2
	bmax_trigamma = 1
	pxi = &xi
	_gamma    = asarray_create("real", 2)
	_digamma  = asarray_create("real", 2)
	_trigamma = asarray_create("real", 2)
	p = &(-tol), &xi, &tol
	for (i=3; i; i--)
		for (a=amin; a<=amax; a++) {
			asarray(   _gamma, (a,i-2), ::gamma   (a:+*p[i]*(   bmin_gamma..   bmax_gamma)))
			asarray( _digamma, (a,i-2), ::digamma (a:+*p[i]*( bmin_digamma.. bmax_digamma)))
			asarray(_trigamma, (a,i-2), ::trigamma(a:+*p[i]*(bmin_trigamma..bmax_trigamma)))
		}
}

real matrix gammastore::gamma   (real scalar a, real rowvector b, real colvector xi) return (asarray(_gamma,    (a,(&xi==pxi? 0 : sign(xi))))[b==0?1:.,b:-(bmin_gamma   -1)])
real matrix gammastore::digamma (real scalar a, real rowvector b, real colvector xi) return (asarray(_digamma,  (a,(&xi==pxi? 0 : sign(xi))))[b==0?1:.,b:-(bmin_digamma -1)])
real matrix gammastore::trigamma(real scalar a, real rowvector b, real colvector xi) return (asarray(_trigamma, (a,(&xi==pxi? 0 : sign(xi))))[b==0?1:.,b:-(bmin_trigamma-1)])

// for positive integers
real scalar tetragamma(x) return (x==1? -2.4041138063191885707995 :   -2.4041138063191885707995 +   2*sum((1::x-1):^-3))

//real scalar polygamma(m, x) return (-(-1)^m*factorial(m)*sum((x..x+100000):^(-m-1)))

// dth derivative of 1/(.) at a+bx
real matrix Pi_GPD(real scalar d, real scalar a, real rowvector b, real colvector x)
	return ((-1)^d*factorial(d)*(1:/(a:+x*b)):^(d+1))

// nth derivative of gamma(), not lngamma(), at a+bx, where x prestored in gammastore class. For n>2, only works for a=1,2,b=0, in which case returns a scalar.
// xi=+/-1: evaluate at xi=+/-tol. xi==0: evaluate at preset xi
real matrix Pi_GEV(real scalar d, real scalar a, real rowvector b, real colvector xi) return(dgamma(d, a, b, xi))
real matrix dgamma(real scalar d, real scalar a, real rowvector b, real colvector xi) {
	class gammastore scalar _gammastore
	if (!d  ) return(_gammastore.gamma(a,b,xi))
	if (d==1) return(dgamma(0,a,b,xi):*_gammastore.digamma(a,b,xi))
	if (d==2) return(dgamma(1,a,b,xi):*_gammastore.digamma(a,b,xi) +   dgamma(0,a,b,xi):*_gammastore.trigamma(a,b,xi))
	          return(dgamma(2,a,b,xi):*_gammastore.digamma(a,b,xi) + 2*dgamma(1,a,b,xi):*_gammastore.trigamma(a,b,xi) + dgamma(0,a,b,xi)*tetragamma(a))
}

// compute 1/xi^n * backdiff_n of Pi^(d)(1+l+m*xi)
real colvector BackDiff(real scalar l, real scalar d, real scalar n, real scalar m, real colvector xi, pointer (real scalar function) pfnPi) {
	real rowvector k
	if (n) {
		k = 0..n
		return (quadrowsum((-1):^k:*comb(n,k):*(*pfnPi)(d,1+l,m:-k,xi)):/xi:^n)
	}
	return ((*pfnPi)(d,1+l,m,xi))
}

// do the bulk of the Cox-Snell bias-correction work, returning A & K as a pointer pair
pointer(real matrix) rowvector extreme_CSByR(real scalar GEV, real scalar R, real colvector lnsig, real colvector xi, real colvector wt, real matrix X_mu, real matrix X_lnsig, real matrix X_xi, real scalar X_mu_1, real scalar X_lnsig_1, real scalar X_xi_1) {
	class poly scalar E, lny_x, lnf_x, lnf_xi, f_x, lng_x, lny_xx, lny_xxi, lny_xixi, lnf_xx, lnf_xxi, lnf_xixi, f_xx, f_xxi, f_xixi, lng_xx, lng_xxi, lng_xixi, lny_xxx, lny_xxxi, lny_xxixi, 
		lny_xixixi, lnf_xxx, lnf_xxxi, lnf_xxixi, lnf_xixixi, f_xxx, f_xxxi, f_xxixi, f_xixixi, lng_xxx, lng_xxxi, lng_xxixi, lng_xixixi, xlng_x, xlng_xx, x2lng_xx, xlng_xxi, lng_mumu, lng_mulnsig, 
		lng_lnsiglnsig, lng_muxi, lng_lnsigxi, lng_mumumu, lng_mumulnsig, lng_mulnsiglnsig, lng_lnsiglnsiglnsig, lng_mumuxi, lng_mulnsigxi, 
		lng_muxixi, lng_lnsiglnsigxi, lng_lnsigxixi, lng_xx_xi, lng_xxi_xi, xlng_xxi_xi, f_xxi_xi, f_xixi_xi, xf_xxi_xi, 
		lng_xixi_xi, lng_mumu_xi, lng_mulnsig_xi, lng_muxi_xi, lng_lnsigxi_xi
	class poly scalar lng_lnsiglnsig_xi
	class poly rowvector D2lng, D3lng, D2lng_xi
	real rowvector E_D2lng, E_D3lng
	real scalar sig, i, k
	real matrix K, A, _E_D2lng, _E_D3lng, D, L, Q
	pointer (real scalar function) pfnPi
	class gammastore scalar _gammastore

	sig = exp(lnsig)
	pfnPi = GEV? &Pi_GEV() : &Pi_GPD()
	if (rows(xi)==1 & rows(lnsig)==1) wt = sum(wt)
	E.set_xi_sig_wt_fnPi(xi, .01, sig, wt, pfnPi)
	if (GEV) _gammastore.init(xi, .01, R)

	lny_x = term( 1,1,0,0,0,1) // xi/y
	lnf_x = term(-1,0,0,0,0,1) // -1/y
	lnf_xi = poly::sum((term(-1,-1,0,1,0,0),term(-1,-1,0,0,1,1))) // -1/xi*x/y-1/xi*ln(f)
	lng_x = poly::sum((lny_x. C(-1),lnf_x)) // -lny_x  + lnf_x 

	lny_xx   = term(-1,2,0,0,0,2) // -xi^2/y^2
	lny_xxi  = term(1,0,0,0,0,2)      // 1/y^2
	lny_xixi = term(-1,0,0,0,2,2)     //-x^2/y^2
	lnf_xx   = term(1,1,0,0,0,2) // xi/y^2
	lnf_xxi  = term(1,0,0,0,1,2)  // x/y^2
	lnf_xixi = poly::sum((term(1,-1,0,0,2,2),term(2,-2,0,1,0,0),term(2,-2,0,0,1,1))) // 1/xi*x^2/y^2+2/xi^2*ln(f)+2/xi^2*x/y

	lng_xx   = poly::sum((lny_xx.  C(-1),lnf_xx  )) // -lny_xx   + lnf_xx
	lng_xxi  = poly::sum((lny_xxi. C(-1),lnf_xxi )) // -lny_xxi  + lnf_xxi 
	lng_xixi = poly::sum((lny_xixi.C(-1),lnf_xixi)) // -lny_xixi + lnf_xixi

	lny_xxx    = term( 2,3,0,0,0,3) //  2*xi^3/y^3
	lny_xxxi   = term(-2,1,0,0,0,3) // -2*xi/y^3
	lny_xxixi  = term(-2,0,0,0,1,3) // -2*x/y^3
	lny_xixixi = term( 2,0,0,0,3,3) //  2*x^3/y^3
	lnf_xxx    = term(-2,2,0,0,0,3)                  // -2*xi^2/y^3
	lnf_xxxi   = poly::sum((term(2,0,0,0,0,3),term(-1,0,0,0,0,2))) //  2/y^3-1/y^2
	lnf_xxixi  = term(-2,0,0,0,2,3)                       // -2*x^2/y^3
	lnf_xixixi = poly::sum((term(-6,-3,0,0,1,1),term(-3,-2,0,0,2,2),term(-2,-1,0,0,3,3),term(-6,-3,0,1,0,0))) // -6/xi^3*x/y-3/xi^2*x^2/y^2-2/xi*x^3/y^3-6/xi^3*ln(f)
	lng_xxx    = poly::sum((lny_xxx.   C(-1),lnf_xxx   )) // -lny_xxx    +lnf_xxx   
	lng_xxxi   = poly::sum((lny_xxxi.  C(-1),lnf_xxxi  )) // -lny_xxxi   +lnf_xxxi  
	lng_xxixi  = poly::sum((lny_xxixi. C(-1),lnf_xxixi )) // -lny_xxixi  +lnf_xxixi 
	lng_xixixi = poly::sum((lny_xixixi.C(-1),lnf_xixixi)) // -lny_xixixi +lnf_xixixi

	if (GEV) {
		class poly scalar lnf_x_lnf_x, lnf_x_lnf_xi, lnf_xi_lnf_xi
		lnf_x_lnf_x          = poly::times(lnf_x,  lnf_x)
		lnf_x_lnf_xi         = poly::times(lnf_x,  lnf_xi)
		lnf_xi_lnf_xi        = poly::times(lnf_xi, lnf_xi)
		
		f_x  = lnf_x.f() // f:*lnf_x

		f_xx   = (poly::sum((lnf_x_lnf_x  , lnf_xx  ))).f() // f:*lnf_x :*lnf_x  + f:*lnf_xx
		f_xxi  = (poly::sum((lnf_x_lnf_xi , lnf_xxi ))).f()
		f_xixi = (poly::sum((lnf_xi_lnf_xi, lnf_xixi))).f()

		f_xxx    = (poly::sum((poly::times(lnf_x ,lnf_x_lnf_x  ), (poly::times(lnf_x , lnf_xx  )).C(3),                               lnf_xxx   ))).f()
		f_xxxi   = (poly::sum((poly::times(lnf_x ,lnf_x_lnf_xi ), (poly::times(lnf_x , lnf_xxi )).C(2),poly::times(lnf_xi, lnf_xx  ), lnf_xxxi  ))).f()
		f_xxixi  = (poly::sum((poly::times(lnf_x ,lnf_xi_lnf_xi), (poly::times(lnf_xi, lnf_xxi )).C(2),poly::times(lnf_x,  lnf_xixi), lnf_xxixi ))).f()
		f_xixixi = (poly::sum((poly::times(lnf_xi,lnf_xi_lnf_xi), (poly::times(lnf_xi, lnf_xixi)).C(3),                               lnf_xixixi))).f()

		f_xxi_xi  = f_xxi.    dxi()
		f_xixi_xi = f_xixi.   dxi()
		xf_xxi_xi = f_xxi.x().dxi()

		if (R>1) {
			pointer(class poly scalar) rowvector p; class poly rowvector t; real scalar r
			p = &lng_x, &lng_xx, &lng_xxi, &lng_xixi, &lng_xxx, &lng_xxxi, &lng_xxixi, &lng_xixixi
			for (i=cols(p); i; i--) {
				t = *p[i]
				for (r=2; r<=R; r++)
					t = t, (t[r-1]).C(1/(r-1)).f() // create sum_r {1/gamma(r)* C * xi^a * sig^b * f^(l+r-1) * (ln f)^d * x^n / y^m}
				*p[i] = poly::sum(t)
			}
			p = &f_x, &f_xx, &f_xxi, &f_xixi, &f_xxx, &f_xxxi, &f_xxixi, &f_xixixi, &f_xxi_xi, &f_xixi_xi, &xf_xxi_xi
			for (i=cols(p); i; i--)
				*p[i] = (*p[i]).C(1/gamma(R)).f(R-1)
		}
	}

	xlng_xxi = lng_xxi.x()
	 lng_xxi_xi =  lng_xxi.dxi()
	lng_xixi_xi = lng_xixi.dxi()
	xlng_xxi_xi = xlng_xxi.dxi()

	if (GEV) {
		 lng_x    = poly::sum((lng_x   ,f_x.      C(-1))) // -lny_x  + lnf_x  - f_x

		 lng_xx   = poly::sum((lng_xx  ,f_xx.     C(-1))) // -lny_xx   + lnf_xx   - f_xx  
		 lng_xxi  = poly::sum((lng_xxi ,f_xxi.    C(-1))) // -lny_xxi  + lnf_xxi  - f_xxi 

		xlng_xxi  = poly::sum((xlng_xxi,f_xxi.x().C(-1)))
		 lng_xixi = poly::sum((lng_xixi,f_xixi.   C(-1))) // -lny_xixi + lnf_xixi - f_xixi

		 lng_xxi_xi  = poly::sum(( lng_xxi_xi, f_xxi_xi.C(-1)))
		xlng_xxi_xi  = poly::sum((xlng_xxi_xi,xf_xxi_xi.C(-1)))
		 lng_xixi_xi = poly::sum((lng_xixi_xi,f_xixi_xi.C(-1)))

		lng_xxx    = poly::sum((lng_xxx   ,f_xxx.   C(-1))) // -lny_xxx    +lnf_xxx    - f_xxx
		lng_xxxi   = poly::sum((lng_xxxi  ,f_xxxi.  C(-1))) // -lny_xxxi   +lnf_xxxi   - f_xxxi
		lng_xxixi  = poly::sum((lng_xxixi ,f_xxixi. C(-1))) // -lny_xxixi  +lnf_xxixi  - f_xxixi
		lng_xixixi = poly::sum((lng_xixixi,f_xixixi.C(-1))) // -lny_xixixi +lnf_xixixi - f_xixixi
	}

	lng_xx_xi  = lng_xx.dxi()
	xlng_x = lng_x.x()
	x2lng_xx = lng_xx.x(2)

	lng_lnsiglnsig = poly::sum((xlng_x, x2lng_xx))
	lng_lnsigxi = xlng_xxi.C(-1)
	lng_lnsiglnsig_xi = x2lng_xx.dxi()
	lng_lnsigxi_xi = xlng_xxi_xi.C(-1)
	lng_lnsiglnsiglnsig = poly::sum((xlng_x.C(-1), x2lng_xx.C(-3), lng_xxx.x(3).C(-1)))
	lng_lnsiglnsigxi = poly::sum((xlng_xxi, lng_xxxi.x(2)))
	lng_lnsigxixi = lng_xxixi.x().C(-1)

	if (GEV) {
		xlng_xx = lng_xx.x()

		lng_mumu    = lng_xx.sig(-2) // lng_xx/sig^2
		lng_mulnsig = poly::sum((lng_x, xlng_xx)); lng_mulnsig._sig(-1) // lng_x/sig + xlng_xx/sig
		lng_muxi = lng_xxi.sig(-1).C(-1) // -lng_xxi/sig

		lng_mumu_xi = lng_xx_xi.sig(-2)
		lng_mulnsig_xi = xlng_xx.dxi().sig(-1)
		lng_muxi_xi = lng_xxi_xi.sig(-1).C(-1)

		lng_mumumu = lng_xxx.sig(-3).C(-1) // -lng_xxx/sig^3
		lng_mumulnsig =  poly::sum((lng_xx.C(2), lng_xxx.x())); lng_mumulnsig._sig(-2); lng_mumulnsig._C(-1) // -1/sig^2(2lng_xx+xlng_xxx)
		lng_mulnsiglnsig = poly::sum((lng_x, xlng_xx.C(3), lng_xxx.x(2))); lng_mulnsiglnsig._C(-1); lng_mulnsiglnsig._sig(-1) // -1/sig*(lng_x+3xlng_xx+xxlng_xxx)
		lng_mumuxi = lng_xxxi.sig(-2) // lng_xxxi/sig^2
		lng_mulnsigxi = poly::sum((lng_xxi, lng_xxxi.x())); lng_mulnsigxi._sig(-1) // 1/sig*(lng_xxi+xlng_xxxi)
		lng_muxixi = lng_xxixi.C(-1); lng_muxixi._sig(-1) // -lng_xxixi/sig

		D2lng    = lng_mumu     , lng_mulnsig     , lng_muxi     , lng_lnsiglnsig     , lng_lnsigxi     , lng_xixi     
		D2lng_xi = lng_mumu_xi  , lng_mulnsig_xi  , lng_muxi_xi  , lng_lnsiglnsig_xi  , lng_lnsigxi_xi  , lng_xixi_xi
		D3lng    = lng_mumumu   , lng_mumulnsig   , lng_mumuxi   , lng_mulnsiglnsig   , lng_mulnsigxi   , lng_muxixi   ,
		           lng_mumulnsig, lng_mulnsiglnsig, lng_mulnsigxi, lng_lnsiglnsiglnsig, lng_lnsiglnsigxi, lng_lnsigxixi,
		           lng_mumuxi   , lng_mulnsigxi   , lng_muxixi   , lng_lnsiglnsigxi   , lng_lnsigxixi   , lng_xixixi
	} else {
		D2lng    = lng_lnsiglnsig     , lng_lnsigxi     , lng_xixi
		D2lng_xi = lng_lnsiglnsig_xi  , lng_lnsigxi_xi  , lng_xixi_xi
		D3lng    = lng_lnsiglnsiglnsig, lng_lnsiglnsigxi, lng_lnsigxixi, 
		           lng_lnsiglnsigxi   , lng_lnsigxixi   , lng_xixixi
	}

	// expand expectations to derivatives w.r.t. coeficients of linear determinants of mu, lnsig, xi
	k = X_mu_1+X_lnsig_1+X_xi_1 + cols(X_mu)+cols(X_lnsig)+cols(X_xi)
	E_D2lng = J(1,k^2,0); E_D3lng = J(1,k^3, 0)
	D = Dmatrix(2+GEV)' 
	L = Lmatrix(k)'
	K = E.E(D2lng)
	_E_D2lng = K * D
	_E_D3lng = (( (GEV? (J(rows(K),6,0), -2*K[,1],-K[|.,2\.,3|],J(rows(K),3,0)) : J(rows(K),3,0)), E.E(D2lng_xi)) - E.E(D3lng)/2) * I(2+GEV)#D
	for (i=rows(_E_D2lng); i; i--) {
		Q = blockdiag((X_lnsig[i,],J(1,X_lnsig_1,1)), (X_xi[i,],J(1,X_xi_1,1)))
		if (GEV) Q = blockdiag((X_mu[i,],J(1,X_mu_1,1)), Q)
		E_D2lng = E_D2lng + _E_D2lng[i,] * Q#Q
		E_D3lng = E_D3lng + _E_D3lng[i,] * Q#Q#Q
	}
	E_D2lng = E_D2lng * L
	E_D3lng = E_D3lng * I(k)#L
	E_D3lng = colshape(E_D3lng, cols(E_D2lng))'
	A = J(k,0,0); for (i=k; i; i--) A = invvech(E_D3lng[,i]), A
	return(&E_D2lng, &A)
}

real rowvector extreme_CS(transmorphic M) {
	real scalar i, N, GEV, X_mu_1, X_lnsig_1, X_xi_1, k_mu_covar, k_lnsig_covar, k_xi_covar
	real matrix t, A, K, invK, X_mu, X_lnsig, X_xi
	pointer(real matrix) rowvector pt
	real rowvector b_ML
	real colvector subsample, r, ur, lnsig, xi, wt

	GEV =  moptimize_util_userinfo(M, 1)
	N = st_numscalar("e(N)")
	r = moptimize_init_userinfo(M, 3)
	b_ML = moptimize_result_coefs(M) // ML estimate

	X_lnsig_1   = moptimize_init_eq_cons(M, 1+GEV)=="on"
	X_xi_1      = moptimize_init_eq_cons(M, 2+GEV)=="on"
	X_mu_1 = GEV? moptimize_init_eq_cons(M, 1    )=="on" : 0

					 t = moptimize_util_eq_indices(M, 1+GEV); k_lnsig_covar = t[2,2]-t[1,2]-X_lnsig_1+1 // number of non-constant covariates
					 t = moptimize_util_eq_indices(M, 2+GEV); k_xi_covar    = t[2,2]-t[1,2]-X_xi_1+1
	if (GEV) t = moptimize_util_eq_indices(M, 1    ); k_mu_covar    = t[2,2]-t[1,2]-X_mu_1+1

	xi    = k_xi_covar   ? moptimize_util_xb(M, b_ML, 2+GEV) : moptimize_result_eq_coefs(M, 2+GEV)
	lnsig = k_lnsig_covar? moptimize_util_xb(M, b_ML, 1+GEV) : moptimize_result_eq_coefs(M, 1+GEV)

					 X_lnsig    = k_lnsig_covar? moptimize_init_eq_indepvars(M, 1+GEV) : J(N,0,0)
					 X_xi       = k_xi_covar?    moptimize_init_eq_indepvars(M, 2+GEV) : J(N,0,0)
	if (GEV) X_mu       = k_mu_covar?    moptimize_init_eq_indepvars(M, 1    ) : J(N,0,0)
	
	wt = moptimize_init_weight(M)
	if (rows(wt)>1) {
		if (moptimize_init_weighttype(M)!="fweight")
			wt = wt * (N/sum(wt))
	} else
		wt = cols(X_lnsig) | cols(X_xi)? J(rows(wt), 1, 1) : N
	wt = wt :* (xi:>=-.2)
	
	ur = uniqrows(r)
	for (i=1; i<=rows(ur); i++) {
		subsample = _selectindex(r:==ur[i])
		pt = extreme_CSByR(GEV, ur[i], (rows(lnsig)>1? lnsig  [subsample,] : lnsig  ), 
															 (rows(xi   )>1? xi     [subsample,] : xi     ), 
															 (rows(wt   )>1? wt     [subsample,] : wt     ), 
															 (cols(X_mu   )? X_mu   [subsample,] : X_mu   ), 
															 (cols(X_lnsig)? X_lnsig[subsample,] : X_lnsig), 
															 (cols(X_xi   )? X_xi   [subsample,] : X_xi   ), X_mu_1, X_lnsig_1, X_xi_1)
		if (i==1) {
			K =*pt[1]
			A =*pt[2]
		} else {
			K = K + *pt[1]
			A = A + *pt[2]
		}
	}
	invK = invsym(invvech(-K'))
	return((invK * A * vec(invK))')
}

real rowvector extreme_BS(transmorphic M, real scalar reps, real matrix V) {
	real scalar i, k, R, GEV, N,  X_mu_1, X_lnsig_1, X_xi_1, k_mu_covar, k_lnsig_covar, k_xi_covar
	real colvector r, mu, lnsig, xi, sig, gumbel
	real matrix x, x2, bhat, C, t
	real rowvector mean, b_ML
	
	GEV =  moptimize_util_userinfo(M, 1)
	N = st_numscalar("e(N)")
	r = moptimize_init_userinfo(M, 3)
	b_ML = moptimize_result_coefs(M) // ML estimate

	X_lnsig_1   = moptimize_init_eq_cons(M, 1+GEV)=="on"
	X_xi_1      = moptimize_init_eq_cons(M, 2+GEV)=="on"
	X_mu_1 = GEV? moptimize_init_eq_cons(M, 1    )=="on" : 0

	         t = moptimize_util_eq_indices(M, 1+GEV); k_lnsig_covar = t[2,2]-t[1,2]-X_lnsig_1+1 // number of non-constant covariates
	         t = moptimize_util_eq_indices(M, 2+GEV); k_xi_covar    = t[2,2]-t[1,2]-X_xi_1+1
	if (GEV) t = moptimize_util_eq_indices(M, 1    ); k_mu_covar    = t[2,2]-t[1,2]-X_mu_1+1

	xi    = k_xi_covar   ? moptimize_util_xb(M, b_ML, 2+GEV) : moptimize_result_eq_coefs(M, 2+GEV)
	lnsig = k_lnsig_covar? moptimize_util_xb(M, b_ML, 1+GEV) : moptimize_result_eq_coefs(M, 1+GEV)
	if (GEV) mu = k_mu_covar? moptimize_util_xb(M, b_ML, 1) : moptimize_result_eq_coefs(M, 1)

	sig = exp(lnsig)
	R = colmax(r)
	C = uppertriangle(J(R,R,-1))
	if (rows(xi)>1) gumbel = _selectindex(abs(xi):<.001)
	bhat = J(reps, moptimize_util_eq_indices(M, moptimize_init_eq_n(M))[2,2], .) // width is K, number of coefs
	moptimize_init_tracelevel(M, "none")
	moptimize_init_verbose(M, "off")

	for (i=reps; i; i--) {
		x = 1:-runiform(N,R)
		if (GEV) x = ln(x)*C
		if (rows(xi)==1)
			x2 = abs(xi)<.001? -ln(x) : (x:^-xi:-1):/xi
		else {
			x2 = (x:^-xi:-1):/xi
			if (rows(gumbel)) x2[gumbel] = -ln(x[gumbel])
		}
		x2 = x2 * sig; if (GEV) x2 = x2 :+ mu
		if (rows(r)>1) // for multiple-order stat models with missing values, copy missingness pattern, moving available order stats to right
			for (k=N; k; k--)
				if (r[k]<R)
					x2[k,] = J(1,R-r[k],.), x2[|k,1\k,r[k]|]
		moptimize_init_userinfo(M, 2, x2)
		(void) _moptimize(M)
		if (moptimize_result_converged(M))
			bhat[i,] = moptimize_result_coefs(M)
	}
	mean = mean(bhat)
	V = quadcrossdev(bhat,mean,bhat,mean) / (colnonmissing(bhat)[1]-1)
	return (mean - b_ML)
}

// Bias correction for EVT models
// reps = 0 for Cox-Snell, otherwise number of replications for parametric bootstrap
void extreme_small(transmorphic M, real scalar reps) {
	real rowvector bias; real matrix V; pragma unset V

	if (reps) {
		bias = extreme_BS(M, reps, V)
		st_matrix(st_local("Vsmall"), V)
	} else
		bias = extreme_CS(M)

	st_matrix         (st_local("bsmall"), moptimize_result_coefs(M) - bias)
	st_matrixcolstripe(st_local("bsmall"), moptimize_result_colstripe(M))
}

// helper function for profile plots
// takes moptimize() model, index in full param vector of param to be varied, name of string numlist of evaluation points, eq of result to be extracted (eq=0=>log likelihood)
real matrix extreme_profile(transmorphic M, real scalar paramindex, string scalar paramname, real rowvector numlist, real scalar eq) {
	real matrix Cns, t; real scalar i
	(t = J(1, moptimize_util_eq_indices(M, moptimize_init_eq_n(M))[2,2]+1, 0))[paramindex] = 1 // moptimize_util_eq_indices(M, moptimize_init_eq_n(M))[2,2] is just K, number of coefs
	Cns = moptimize_init_constraints(M)
	Cns = rows(Cns)? Cns \ t : t
	moptimize_init_constraints(M, Cns)
	moptimize_init_tracelevel(M, "none")
	moptimize_init_verbose(M, "off")
	t = J(0, 2, 0)
	for (i=1; i<=cols(numlist); i++) {
		Cns[rows(Cns),cols(Cns)] = numlist[i]
		moptimize_init_constraints(M, Cns)
		if (_moptimize(M))
			printf("Unable to maximize profile likelihood for %s = %f.\n", paramname, numlist[i])
		else	
			t = t \ (numlist[i], (eq?  moptimize_result_eq_coefs(M,eq) : moptimize_result_value(M)))
	}
	return(t) 
}

// helper function for MRL plot--fast computation of mean exceedence at each data point, and standard error thereof
// assumes X is sorted ascending
/*real matrix extreme_mrl(string scalar Xname, string scalar wtname) {
	real colvector X, wt, mu, se; real scalar N, i, t, dmu
	st_view(X, ., Xname)
	st_view(wt, ., wtname)
	wt = wt / sum(wt)
	mu = se = J(N=rows(X), 1, 0)
	mu[N] = X[N]
	for (i=N-1; i; i--) {
		t = X[i] - mu[i+1]
		mu[i] = mu[i+1] + (dmu = (X[i]-mu[i+1])/(N-i+1))
		se[i] = se[i+1] + dmu*dmu*(N-i) + t*t
	}
	return (mu-X, sqrt(se):/(N-1::0))
}*/

mata mlib create lextreme, dir(PLUS) replace
mata mlib add lextreme *(), dir(PLUS)
mata mlib index
end
