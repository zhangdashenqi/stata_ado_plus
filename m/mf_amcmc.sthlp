{smcl}
{* 19feb2013}{...}
{cmd:help amcmc}
{hline}

{title:Title}

{p 4 4 2}
{bf:amcmc -- Mata Functions and Structures for Adaptive Markov Chain Monte Carlo sampling from distributions}

{title:Introduction}

{p 4 4 2}
{bf:amcmc} refers to a collection of Mata tools for performing adaptive Markov chain Monte Carlo (MCMC) sampling from distributions. Algorithms are
described in Baker (2013) and rely on Markov chain Monte Carlo sampling using a continually adapted multivariate normal proposal 
distribution. Using the commands and functions, a user can perform adaptive MCMC using either the function {bf:amcmc()}
 or by setting up an adaptive MCMC
problem using the suite of commands {bf:amcmc_*()}. The function {bf:amcmc()} is described below under the heading
of {bf:{help mf_amcmc##amcmc_fun: the function amcmc()}}. Setting up a structured object for performing {bf:amcmc_*()} 
is discussed under the heading {bf: {help mf_amcmc##amcmc_struct:using amcmc_*() commands}}.

{marker amcmc_fun}{...}
{title:The function amcmc()}

{title:Syntax}

{p 8 40 2}
{it:real matrix}{bind:        }
{cmd:amcmc(}{it:alginfo}{cmd:,} 
{it:lnf}{cmd:,}    
{it:xinit}{cmd:,} 
{it:Vinit}{cmd:,} 
{it:draws}{cmd:,}
{it:burn}{cmd:,} 
{it:damper}{cmd:,} 
{it:aopt}{cmd:,}
{it:arate}{cmd:,}
{it:vals}{cmd:,}
{it:lam}{cmd:,}
{it:blocks} [{cmd:,}
{it:M}{cmd:,}
{it:noisy}]{cmd:)}

{p 4 4 2}
where inputs are 

{p2colset 9 33 35 2}{...}
{p2col 7 33 35 2: {it:alginfo}:  {it:string rowvector}}{p_end}
{p2col 11 33 35 2: {it:lnf}:  {it:pointer (real scalar function) scalar f}}{p_end}
{p2col 9 33 35 2: {it:xinit}:  {it:real colvector}}{p_end}
{p2col 9 33 35 2: {it:Vinit}:  {it:real matrixvector}}{p_end}
{p2col 9 33 35 2: {it:draws}:  {it:real scalar}}{p_end}
{p2col 10 33 35 2: {it:burn}:  {it:real scalar}}{p_end}
{p2col 9 33 35 2: {it:delta}:  {it:real scalar}}{p_end}
{p2col 10 33 35 2: {it:aopt}:  {it:real scalar}}{p_end}
{p2col 9 33 35 2: {it:arate}:  {it:transmorphic}}{p_end}
{p2col 10 33 35 2: {it:vals}:  {it:transmorphic}}{p_end}
{p2col 11 33 35 2: {it:lam}:  {it:transmorphic}}{p_end}
{p2col 8 33 35 2: {it:blocks}:  {it:real matrix}}{p_end}
{p2col 13 33 35 2: {it:M}:  {it:transmorphic}}{p_end}
{p2col 9 33 35 2: {it:noisy}:  {it:string scalar}}{p_end}

{title:Description}

{p 4 4 2}
{bf:amcmc()} performs adaptive MCMC sampling using a multivariate normal proposal distribution. MCMC methods work through 
acceptance-rejection sampling; an MCMC algorithm with adaptation is continually 
tuned as the algorithm runs so as to achieve a targeted acceptance rate. The degree of tuning 
recedes as the algorithm proceeds so as
to achieve an eventually stationary proposal distribution. For a full description of the Mata implementation, see Baker (2013),
which follows the more detailed descriptions of adaptive MCMC algorithms in Andrieu and Thoms (2008).  
The draws from the target distribution are returned as a matrix, with each row representing a draw. 

{p 4 4 2} 
Discussion of {it:alginfo}, the first argument, is postponed until other arguments have been discussed.

{p 4 4 2}
The (pointer) function {it:lnf} specifies the target distribution from which the user wishes to draw. The function describing the target
distribution must be written in log form, so that the (typically, but not always scalar) log-value of the distribution is returned by the function. 

{p 4 4 2}
The initial values used in drawing are specified in the argument {it:xinit}, and an initial covariance matrix for the 
proposal distribution is specified in {it:Vinit}. {it:draws} tells 
the algorithm how many draws to perform, while {it:burn} instructs {bf:amcmc()} to drop the first {it:burn} draws as a burn-in period;
 accordingly, 
{bf:amcmc()} returns only the last {it:draws-burn} draws from the distribution {it:lnf}. 

{p 4 4 2}
{it:delta} is an adjustment parameter telling the algorithm how agressively or conservatively to adapt the proposal distribution to achieve the
acceptance rate specified by the user in {it:aopt}. {it:delta} should lie between zero and one, with values closer to zero corresponding 
with slower adaptation, and values closer to one corresponding to more rapid adaptation to the proposal history. 
{it:aopt} is the acceptance rate desired by the user; typically lying in the range .2 to .44, as 
it has been shown that optimal acceptance rates for univariate problems are around .44, while for large-dimensional problems 
optimal rates are around .234. See Andrieu and Thoms (2008) for further discussion.

{p 4 4 2}
{it:arate}, {it:vals}, and {it:lam} are arguments that can be initialized as missing or as anything else by the user, as they are overwritten. 
{it:arate} is overwritten with acceptance rates of the algorithm. 
{it:vals} is overwritten with the values of the target distribution corresponding with each draw. 
{it:lam} is a set of scaling parameters which are tuned as the algorithm proceeds. These parameters
scale the proposal covariance matrix to direct the algorithm towards the desired acceptance rate, with 
aggressiveness captured by {it:delta}. In
global, all-at-once sampling, {it:lam} is returned as a scalar, 
while if metropolis-within-gibbs sampling is specified (so that each component of the
target distribution is drawn sequentially), {it:lam} returns a vector
of lambda values equal in dimension to the target distribution. Finally, if block sampling is specified, {it:lam} returns a vector of lambda values
equal in dimension to the number of blocks. For further description of how different types are specified, see the description of {it:alginfo} below
and the examples. In block sampling or in metropolis-within-gibbs sampling, the dimension of {it:arate} matches that of sampler. 

{p 4 4 2}
{it:blocks} is a matrix of zeros and ones which describes how the algorithm is to proceed if the user wishes to draw from the target distribution 
not all-at-once but in a sequence of (Gibbs) steps. Values that are to be drawn together are marked by rows of {it:blocks} containing ones and zeros
elsewhere. 

{p 4 4 2}
{it:M} can be used to relay additional information to the algorithm. In cases in which the user has assembled a 
model statement using {bf:{help mf_moptimize:moptimize()}} or {bf:{help mf_optimize:optimize()}}, this model can be passed to {bf: amcmc()} using {it:M}. The idea is to 
save the user the need to respecify things such as missing values, arguments of the function embedded in the model, etc. when switching or using {bf:amcmc()}. 
In cases in which the user does not have a model, but has a function requiring additional arguments, {it:M} can be a pointer holding additional arguments
of the target distribution; up to ten additional arguments can be passed to {bf:amcmc()} in this fashion. For example, if the target distribution is characterized by 
some function {it:lnf(x,Y,Z)} where {it:x} are to be drawn, but {it:Y} and
{it:Z} are also arguments, the user would define a pointer {it:M} containing {it:Y} and {it:Z}. 
{it:M} is optional and does not require specification. 

{p 4 4 2}
{it:noisy} is a string scalar that can be specified as {bf:"noisy"} or as something else. If {it:noisy=}{bf:"noisy"}, the algorithm produces 
feedback - each time the target distribution is evaluated, it produces a {bf:.} as output, while after 50 calls, it produces the value of the target 
distribution after the last call of {it:lnf}.

{p 4 4 2}
Last but not least, the first argument of the function is {it:alginfo}, which is a string scalar specifying the drawing 
scheme desired by the user, what sort of target distribution
evaluator the user has passed to the function when the target is part of a previously specified model statement,
 and perhaps some other things about how the algorithm is to be executed. While the examples present
more details, a user may assemble a string row vector composed of one entry from each of the following:

{col 12}{it:Sampling information}{...}
{col 36}{bf:mwg, global, block}
{col 12}{it:Model definition}{...}
{col 36}{bf:moptimize, optimize, standalone}
{col 12}{it:Model evaluator type}{...}
{col 36}{bf:d*, q*, e*, g*, v*}
{col 12}{it:Other information}{...}
{col 36}{bf:fast}

{p 4 4 2}
Thus, if the user wishes to perform Metropolis-within-Gibbs sampling (each component of {it:lnf} sampled alone and in order), and has previously
modeled the target distribution as part of a structure using {bf:{help mf_moptimize:moptimize()}} and a type {bf:d0} evaluator, 
the user would specify 
(in any order) {it:alginfo=}{bf:"moptimize","d0","mwg"}. Note that each component of {it:alginfo} should be a separate 
string entry in a string row vector, so {it:alginfo=}{bf:"moptimize,d0,mwg"} will not work. The final option,
 {bf:"fast"}, is somewhat experimental
and should be used with caution. In large problems, global, all-at-once samplers require Cholesky decomposition of the proposal covariance matrix.
This can be slow and time consuming. The option {bf:"fast"} avoids Cholesky decomposition by working with a diagonal proposal covariance matrix that 
is continually adjusted as the algorithm proceeds. {bf:"fast"} sometimes works if the target distribution has many independent random variates and
if the proposal distribution is close to the target distribution. See the examples for other possibilities. 

{p 4 4 2}
If the user wishes to use a block sampler (which is somewhere between a one-at-a-time, Metropolis-within-Gibbs sampler,
 the user must also submit a block matrix to communicate to {cmd:amcmc()} which values are to be drawn together.

{title:Further Options}

{p 4 4 2}
While the function {bf:amcmc()} is designed to perform adaptive MCMC, adaptation can be turned off by the user. This feature is often useful if
a previous set of draws from a target distribution has already been performed and the distribution is well-tuned. In this case, the user can set
{it:damper} equal to missing, i.e., {it:damper=.}, and no adaptation will occur. In this case, the user must also specify a set of conformable values
for {it:lam}. 

{title:Examples}

{pstd}{it:Example 1:} Sampling from a univariate normal mixture - with probability 1/2 the mean is -1 or 1
with standard deviation 1 in each case. While this is probably not the most efficient way to sample
from a mixture distribution, it serves to illustrate basic ideas. Initial values for
drawing are set to 0, with initial variance matrix for proposals set at 1. 
1000 draws are taken with the first 100 discarded. A value of {it: delta}=1/2 is a 
fairly conservative choice. A type of sampler has not been specified, which means a global sampler will be used as a default:

	{com}:real scalar mixnorm(X)
	>{
	>val=1/2*normalden(x,1,1)+1/2*normalden(x,-1,1)
	>return(ln(val))
	>}
	{res}
	{com}:alginfo="standalone"
	{res}
	{com}:X=amcmc(alginfo,&mixnorm(),0,1,1000,100,1/2,.44,arate=.,vals=.,lam=.,.)
    {res}{txt}

{pstd}{it:Example 2:} Sampling from a bivariate normal mixture with dimension 2, where with probability {it:p} 
the mean is {it:m}, and with probability {it:p} the mean is {it:-m}. {it:p}, {it:m} and {it:Sig} - the covariance matrix of the distribution - 
are passed to {bf:amcmc()} as additional arguments of the function. A vector of zeros and an identity matrix are used as the starting values for the proposal 
distribution:

	{com}real scalar mixnorm2(x,p,m1,m2,Sig)
	>{
	>dSig=1/sqrt(det(Sig))
	>Siginv=invsym(Sig)
	>val1=1/2*dSig*exp(-(x-m1)*Siginv*(x-m1)')
	>val2=1/2*dSig*exp(-(x-m2)*Siginv*(x-m2)')
	>return(ln(p*val1+(1-p)*val2))
	>}
	{res}
	{com}:p=1/2
	{res}
	{com}:m1=1,1
	{res}
	{com}:m2=-1,-1
	{res}
	{com}:Sig=I(2):+.1
	{res}
	{com}:Args=J(4,1,NULL)
	{res}
	{com}:Args[1]=&p
	{res}
	{com}:Args[2]=&m1
	{res}
	{com}:Args[3]=&m2
	{res}
	{com}:Args[4]=&Sig
	{res}
	{com}:alginfo="standalone","global"
	{res}
	{com}:X=amcmc(alginfo,&mixnorm2(),J(1,2,0),I(2),100000,10000,1,.34,arate=.,vals=.,lam=.,.,Args)
	{res}{txt}

{pstd}{it:Example 3:} "Estimating" a negative-binomial count model by simulation. The premise behind the example
is that one can view a likelihood function as a distribution for
parameters conditional on data. The idea is superficially Bayesian; the model is isomorphic to a typical Bayesian 
analysis with uninformative prior distributions for parameters, but can be applied more generally; see Chernozukov and Hong (2003).
Sampling from the parameters' distribution is a sometimes useful method for analyzing models applied to 
small samples, as results do not depend upon asymptotics as
they do in the typical Bayesian analysis. While in a more complete analysis, one might "thin" the resulting draws out,
check for convergence, etc. this is not done in the example, which is really used to illustrate how a model statement is
passed to {cmd:amcmc()}. The results can be contrasted with those obtained from
 estimation via application of {bf:{help nbreg}}. 

	{com}. clear all
	{res}
	{com}. use http://www.stata-press.com/data/lf2/couart2, clear
	{res}{txt}(Academic Biochemists / S Long)
	{res}
	{com}. set seed 5150
	{res}
	{com}. mata: 
	{res}{txt}{hline 20} mata (type {bf:end} to exit) {hline 20}
	{com}:void nb_d0(M,todo,b,lnf,g,H)
	>{
	>y=moptimize_util_depvar(M,1)
	>mu=exp(moptimize_util_xb(M,b,1))
	>a=exp(moptimize_util_xb(M,b,2))
	>lnfi=lngamma(y:+1/a):-lngamma(1/a):-
	>    lnfactorial(y):-(y:+1/a):*ln(1:+a*mu):+
	>    y*ln(a):+y:*ln(mu)
	>lnf=colsum(lnfi)
	>}
	{res}
	{com}:M=moptimize_init()
	{res}
	{com}:moptimize_init_evaluator(M,&nb_d0())
	{res}
	{com}:moptimize_init_evaluatortype(M,"d0")
	{res}
	{com}:moptimize_init_depvar(M,1,"art")
	{res}
	{com}:moptimize_init_eq_indepvars(M,1,"fem mar kid5 phd ment")
	{res}
	{com}:moptimize_init_eq_indepvars(M,2,"")
	{res}
	{com}:moptimize_evaluate(M)
	{res}
	{com}:alginfo="global","moptimize","d0"
	{res}
	{com}:X=amcmc(alginfo,&nb_d0(),J(1,7,0),I(7),20000,10000,3/4,.234,arate=.,vals=.,lam=.,.,M){txt}
	{res}
	{com}:mean(X)'
	{res}       {txt}              1      
		  {c   TLC}{hline 15}{c TRC}
		1 {c |}  {res}-.2200206506 {c |}  
		2 {c |}  {res}  .148970965 {c |}
		3 {c |}  {res}-.1774053762 {c |}  
		4 {c |}  {res} .0173632397 {c |}
		5 {c |}  {res} .0290353224 {c |}  
		6 {c |}  {res}  .253103149 {c |}
		7 {c |}  {res}-.7998843153 {c |}  
		  {c   BLC}{hline 15}{c BRC}
	{res}{txt}

{marker amcmc_struct}{...}
{title: Using amcmc_*() commands}

{title:Syntax}

{p 4 4 2}
Syntax is discussed in a three steps, which include:

        {help mf_amcmc##syn_step1:Step 1:  Initialization}
        {help mf_amcmc##syn_step2:Step 2:  Problem definition}
        {help mf_amcmc##syn_step3:Step 3:  Obtaining results}

{marker syn_step1}{...}
    {title:Step 1:  Initialization}

{p 4 4 2}
To initialize a problem, the user first issues an initialize command: 	
	
{p2col 7 33 35 2: {it:A = }    {cmd:amcmc_init()}}{p_end}

{p 4 4 2} {cmd:amcmc_init()} sets up an adaptive MCMC problem with the following defaults: 
the number of draws is set to one, the burn period is set to zero, and the optimal acceptance rate is set to .234. 

{marker syn_step2}{...}
    {title:Step 2: Problem definition}

{p 4 4 2}
Problem definition fills in the arguments described under {bf:{help mf_amcmc##amcmc_fun:the function amcmc()}}, so it might
first help the user to peruse that material, in addition to having a look at Baker (2013) and/or Andrieu and Thoms (2008). The user has to
relay information about the target distribution, initial values, how many draws are desired, any additional information about the function or
how drawing should go, and how adaptation of the proposal should occur. 

{p 8 40 2}
{cmd:amcmc_lnf(}{it:A}{cmd:,} {it:pointer (real scalar function) scalar lnf}{cmd:)}

{p 12 12 2}
{it:Use:} sets the target distribution as the function {it:lnf}. Note that {it:lnf} must be in log form.

{p 8 40 2}
{cmd:amcmc_args(}{it:A}{cmd:,} {it:pointer matrix Args}{cmd:)}

{p 12 12 2}
{it: Use:} sets any additional arguments of the function {it:lnf}. Note that this option can only be used with a stand-alone target
distribution. That is,
if the user is sampling from a problem with details constructed using {bf:{help mf_moptimize:moptimize()}} or {bf:{help mf_optimize:optimize()}}, the user should
pass any arguments of the function {it:lnf} through those routines. 

{p 8 40 2}
{cmd:amcmc_xinit(}{it:A}{cmd:,} {it:real rowvector xinit}{cmd:)}

{p 12 12 2}
{it:Use:} sets initial values for the proposal distribution.

{p 8 40 2}
{cmd:amcmc_Vinit(}{it:A}{cmd:,} {it:real matrix Vinit}{cmd:)}

{p 12 12 2}
{it:Use:} sets initial values of the proposal covariance matrix. If the matrix submitted is not positive definite, by default a conformable identity
matrix is used. 

{p 8 40 2}
{cmd:amcmc_aopt(}{it:A}{cmd:,} {it:real scalar aopt}{cmd:)}

{p 12 12 2}
{it:Use:} sets desired acceptance rate, typically in the range .234 to .45 or so. 

{p 8 40 2}
{cmd:amcmc_damper(}{it:A}{cmd:,} {it:real scalar delta}{cmd:)}

{p 12 12 2}
{it:Use:} Specifies the parameter determining how tuning of the algorithm is to occur; the value should be between zero and one.
Values close to zero mean less aggressive tuning of the proposal distribution, while values closer to one mean more aggressive tuning. One can
also specify a missing value for {it:damper} here; i.e., {cmd:amcmc_damper(A,.)}. In this case, no adaptation of the proposal distribution occurs,
and the user must specify scaling parameters using the command {cmd:amcmc_lambda(}{it:A}{cmd:,} {it:real rowvector lambda}{cmd:)}. 

{p 8 40 2}
{cmd:amcmc_lambda(}{it:A}{cmd:,} {it:real rowvector lambda}{cmd:)}

{p 12 12 2}
{it:Use:} Specifies the scaling parameters for the proposal covariance matrix. That is, when a draw is performed using covariance matrix {it:W},
draws use {it:lambda*W} to make the draws. This option should only be set if {it:damper} (discussed above under the heading
 {cmd:amcmc_damper(}{it:A}{cmd:,)} is set to missing so that no adaptation of the proposal distribution is to occur.  

{p 8 40 2}
{cmd:amcmc_burn(}{it:A}{cmd:,} {it:real scalar burn}{cmd:)}

{p 12 40 2}
{it:Use:} sets the length of the burn-in period, for which information about draws is discarded. 

{p 8 40 2}
{cmd:amcmc_draws(}{it:A}{cmd:,} {it:real scalar draws}{cmd:)}

{p 12 40 2}
{it:Use:} Number of draws to be performed. 

{p 8 40 2}
{cmd:amcmc_noisy(}{it:A}{cmd:,} {it:string scalar noisy}{cmd:)}

{p 12 12 2}
{it:Use:} If {it:noisy}={bf:"noisy"}, a dot is produced each time {it:lnf} is called; every 50 calls the function value at the last draw is also
produced.

{p 8 40 2}
{cmd:amcmc_model(}{it:A}{cmd:,} {it:transmorphic M}{cmd:)}

{p 12 12 2}
{it:Use:} Can be used to append the drawing problem with a previously assembled model statement 
formulated using either {bf:{help mf_moptimize:moptimize()}} or {bf:{help mf_optimize:optimize()}}.

{p 8 40 2}
{cmd:amcmc_blocks(}{it:A}{cmd:,} {it:real matrix blocks}{cmd:)}

{p 12 12 2}
{it:Use:} In conjunction with block samplers. The matrix {it:blocks} contains information about the sequence of draws.

{p 8 40 2}
{cmd:amcmc_alginfo(}{it:A}{cmd:,} {it:string rowvector alginfo}{cmd:)}

{p 12 12 2}
{it:Use:} A sequence of strings that contain information about how drawing is to proceed, what type of sampler to use, if and how models are specified,
etc. Available options are:

{col 12}{it:Sampling information}{...}
{col 36}{bf:mwg, global, block}
{col 12}{it:Model definition}{...}
{col 36}{bf:moptimize, optimize, standalone}
{col 12}{it:Model evaluator type}{...}
{col 36}{bf:d*, q*, e*, g*, v*}
{col 12}{it:Other information}{...}
{col 36}{bf:fast}

{p 12 12 2}
Thus, if the user is sampling from a previously formed model statement using optimize with a type {bf:d0} evaluator, and wished to sample in blocks the user
would specify {cmd:amcmc_alginfo(A,("block","optimize","d0"))}. 

{p 8 40 2}
{cmd:amcmc_draw(}{it:A}{cmd:)}

{p 12 12 2}
{it:Use:} Execute the sampler.
	
{p 4 4 2}
Setting up a problem as a structured object has advantages in 
situations in which the user is interested in executing adaptive MCMC as a step in a larger algorithm, or in which the user must set up 
a sequence of similar adaptive MCMC problems (or both). An additional set of commands which do not directly analogize with the use of the 
function {bf:amcmc()} follow:

{p 8 40 2}
{cmd:amcmc_append(}{it:A}{cmd:,} {it:string scalar append}{cmd:)}

{p 12 12 2}
{it:Use:} In the event that the user executes the command {cmd:amcmc_draw(A)} multiple times in sequence, by specifying {it:append}={bf:"append"}, 
the results of the draw will be attached to the information on previous calls of {cmd:amcmc_draw(A)}. Acceptance rates, the proposal distribution, etc.
are all updating accordingly. This is the default setting; unless the user specifies {it:append}={bf:"overwrite"}, all information about previous
draws will be retained. Specifying {it:append}={bf:"overwrite"} does not restart the draw; everything is updated using past draws, but only the
most recent set of draws is retained. This is useful in large problems in which a sampler is used as a step in a larger sampling algorithm.

{p 8 40 2}
{cmd:amcmc_reeval(}{it:A}{cmd:,} {it:string scalar reeval}{cmd:)}

{p 12 12 2}
{it:Use:} In the event that the user executes the command {cmd:amcmc_draw(A)} as a step in larger algorithm,
the parameters that have been passed to the problem might change. It is then necessary for the algorithm to reevaluate the function
using the last drawn values with the new parameter values before proceeding. If the user wishes to do this, the user may simply
set {it:reeval="reeval"}. 

{marker syn_step3}{...}
    {title:Step 3:  Results}

{p 4 4 2}
Once a run has been executed using {cmd:amcmc_draw()}, the user can access information about the draws, and also recover some information about 
initial settings. 

{p 8 40 2}
{it:real matrix}        {cmd:amcmc_results_draws(}{it:A}{cmd:)}

{p 12 12 2}
{it:Use:} Returns the draws in a matrix form; each row represents a draw.

{p 8 40 2}
{it:real colvector}     {cmd:amcmc_results_vals(}{it:A}{cmd:)}

{p 12 12 2}
{it:Use:} Returns the values of the proposal distribution corresponding with each draw.

{p 8 40 2}
{it:real rowvector}     {cmd:amcmc_results_arate(}{it:A}{cmd:)}

{p 12 12 2}
{it:Use:} Returns acceptance rates; if a global scheme is used, this is a single value; otherwise, acceptance rates conform with the number of blocks
(for a block sampler) or the dimension of the target distribution (for a metropolis-within-gibbs sampler).

{p 8 40 2}
{it:real scalar}        {cmd:amcmc_results_passes(}{it:A}{cmd:)}

{p 12 12 2}
{it:Use:} Returns the number of times the {cmd:amcmc_draw()} command has been issued.

{p 8 40 2}
{it:real scalar}     {cmd:amcmc_results_totaldraws(}{it:A}{cmd:)}

{p 12 12 2}
{it:Use:} Returns the total number of draws.

{p 8 40 2}
{it:real colvector}     {cmd:amcmc_results_vals(}{it:A}{cmd:)}

{p 12 12 2}
{it:Use:} Returns the values of the proposal distribution corresponding with each draw.
 
{p 8 40 2}
{it:real matrix}     {cmd:amcmc_results_acceptances(}{it:A}{cmd:)}

{p 12 12 2}
{it:Use:} Returns a matrix of zeros and ones conformable with the sampling scheme, where a one marks whether or not a particular draw was
accepted, and a zero marks whether or not a draw was rejected. In short, the function returns the acceptance history of the draw. 

{p 8 40 2}
{it:real rowvector}     {cmd:amcmc_results_propmean(}{it:A}{cmd:)}

{p 12 12 2}
{it:Use:} Returns the mean of the proposal distribution at the end of the run.

{p 8 40 2}
{it:real matrix}     {cmd:amcmc_results_propvar(}{it:A}{cmd:)}

{p 12 12 2}
{it:Use:} Returns the covariance matrix of the proposal distribution at the end of the run.

{p 8 40 2}
{it:real rowvector}     {cmd:amcmc_results_lastdraw(}{it:A}{cmd:)}

{p 12 12 2}
{it:Use:} Returns only the last draw.

{p 8 40 2}
{it:void}     {cmd:amcmc_results_report(}{it:A}{cmd:)}

{p 12 12 2}
{it:Use:} Produces a quick summary of a run, which includes the total passes, 
draws per pass, the total number of draws, the average value of the target distribution,
the last value of the target distribution, the acceptance rate (average), and the burn-in period.

{p 4 4 2}
Additionally, one can obtain the values that the user specified by using {cmd: amcmc_results_*()}, where {cmd:*} can be any one of:
{bf:alginfo, noisy, blocks, damper, xinit, Vinit,} or {bf:lambda}. 

{title: Examples}

{pstd}{it:Example 1:} This example recasts example 2 above. To recap, the 
interest lies in sampling from a multivariate normal mixture with dimension 2, where with probability {it:p} 
the mean is {it:m}, and with probability {it:p} the mean is {it:-m}. {it:p}, {it:m} and {it:Sigma} - the covariance matrix of the distribution - 
are passed as additional arguments of the function. A vector of zeros and an identity matrix are used as the starting values for the proposal 
distribution:

	{com}real scalar mixnorm2(x,p,m1,m2,Sig)
	>{
	>dSig=1/sqrt(det(Sig))
	>Siginv=invsym(Sig)
	>val1=1/2*dSig*exp(-(x-m1)*Siginv*(x-m1)')
	>val2=1/2*dSig*exp(-(x-m2)*Siginv*(x-m2)')
	>return(ln(p*val1+(1-p)*val2))
	>}
	{res}
	{com}:p=1/2
	{res}
	{com}:m1=1,1
	{res}
	{com}:m2=-1,-1
	{res}
	{com}:Sig=I(2):+.1
	{res}
	{com}:Args=J(4,1,NULL)
	{res}
	{com}:Args[1]=&p
	{res}
	{com}:Args[2]=&m1
	{res}
	{com}:Args[3]=&m2
	{res}
	{com}:Args[4]=&Sig
	{res}
	{com}:alginfo="standalone","global"
	{res}
	{com}:A=amcmc_init()
	{res}
	{com}:amcmc_alginfo(A,alginfo)
	{res}
	{com}:amcmc_lnf(A,&mixnorm2())
	{res}
	{com}:amcmc_draws(A,100000)
	{res}
	{com}:amcmc_burn(A,10000)
	{res}
	{com}:amcmc_args(A,Args)
	{res}
	{com}:amcmc_xinit(A,J(1,2,0))
	{res}
	{com}:amcmc_Vinit(A,I(2))
	{res}
	{com}:amcmc_aopt(A,.34)
	{res}
	{com}:amcmc_damper(A,1)
	{res}
	{com}:amcmc_draw(A){txt}

{pstd}{it: Example 2:} Bayesian estimation of a mixed logit model. The ideas behind this example follow Chapter 12 of Train (2009).
The user is interested in estimating a logit model, but where parameters vary about a distribution at some group level. 
There are three set of parameters: 1) beta_n,  the values of the group parameters for each group, 2) b, the mean of the group
level parameters across groups, and 3) W, the covariance matrix of the group-level parameters. 

{pstd} Following the setup described in Train (2009), suppose that the prior distribution 
for b is normal with arbitrarily large variance, while the prior on W is inverted
Wishart with K (the dimension of b) degrees of freedom and identity scale matrix. Under these conditions:

{pstd} 1. The distribution of b given beta_n and W is normal with mean=mean(beta_n), and covariance matrix W/N, 
where N is the number of groups.

{pstd} 2. The distribution of W given b and beta_n is an inverted Wishart. 

{pstd} 3. The distribution of beta_n given b and W is the product of a normal density 
capturing the likelihood of the group's parameters given the mean and variance of group parameters across the sample, 
and the likelihood of the individual's choices given beta_n. 

{pstd} The example begins by setting up the data, which is {bf:bangladesh.dta}. The data set has information on 
the use of contraceptives for individuals in different districts. The user posits that the coefficients vary 
randomly by district in accordance with the model. Reading data into Mata: 

	{com}. clear all
	{res}
	{com}. webuse bangladesh
	{res}{txt}(NLS Women 14-24 in 1968)
	{res}
	{com}. set seed 90210
	{res}
	{com}. mata: 
	{res}{txt}{hline 20} mata (type {bf:end} to exit) {hline 20}
	{com}: st_view(X=.,.,"urban age child1 child2 child3")
	{res}
	{com}: st_view(y=.,.,"c_use")
	{res}
	{com}: st_view(id=.,.,"district")
	{res}
	{com}: X=X,J(rows(X),1,1)
	{res}
	{com}: m=panelsetup(id,1){txt}

{pstd} Mata now contains contraceptive use information in the vector {it:y}, explanatory variables (and a constant) in the vector {it:X}, 
and an id code which is organized into a panel using {bf:{help mf_panelsetup:panelsetup()}}. The next step is to code the functions 
following Train's (2009) descriptions. For steps 1 and 2, a function producing draws from the
 respective distributions is needed; step 3 will be set up to work with {bf:amcmc_*()}, so
this function does not produce draws, but instead returns the log value of the parameter density conditional on data, choices, b, and W. 
The notational convention in the necessary functions are that the mean and variance of group-level parameters are denoted by {bf:b} and
{bf:W}, the (matrix of) group-level parameters is denoted {bf:beta}, while a set (really, a rowvector) of group-level parameters
are denoted by {bf:beta_n}. The three required functions are:

	{com}: real matrix drawb_betaW(beta,W) {
	>return(mean(beta)+rnormal(1,cols(beta),0,1)*cholesky(W)')
	>}
	{res}
	{com}: real matrix drawW_bbeta(beta,b) 
	>{
	>v=rnormal(cols(b)+rows(beta),cols(b),0,1)
	>S1=variance(beta:-b)
	>S=invsym((cols(b)*I(cols(b))+rows(beta)*S1)/(cols(b)+rows(beta)))
	>L=cholesky(S)
	>R=(L*v')*(L*v')'/(cols(b)+rows(beta))
	>return(invsym(R))
	>}
	{res}
	{com}: real scalar lnchoiceprob(beta_n,b,W,yn,Xn)
	>{
	>mus=rowsum(Xn:*beta_n)
	>lnp=yn:*mus:-ln(1:+exp(mus))
	>lnprior=-1/2*(beta_n-b)*invsym(W)*(beta_n-b)'-
	>        1/2*ln(det(W))-cols(b)/2*ln(2*pi())
	>return(sum(lnp)+lnprior)
	>}
	{res}
	{com}:{txt}

{pstd} The next step is setting up a series of adaptive MCMC problems - one for each individual, using {bf: amcmc_*()} and Mata's 
{help mata J():J()} function, which allows easy duplication of a single problem. 

	{com}: Ap=amcmc_init()
	{res}
	{com}: amcmc_damper(Ap,1)
	{res}
	{com}: amcmc_arate(Ap,.4)
	{res}
	{com}: amcmc_alginfo(Ap,("standalone","global"))
	{res}
	{com}: amcmc_lnf(Ap,&lnchoiceprob())
	{res}
	{com}: amcmc_draws(Ap,1)
	{res}
	{com}: amcmc_append(Ap,"overwrite")
	{res}
	{com}: amcmc_reeval(Ap,"reeval")
	{res}
	{com}: A=J(rows(m),1,Ap)
	{res}
	{com}:{txt}
	
{pstd} Each problem is set up as a global drawing problem, where one draw is taken. In passing, the author's 
experience is that it is sometimes helpful to 
let each individual problem run a bit by specifying 5 or 10 draws, say, in this step for better mixing in the early stages of the 
algorithm. The option {bf:"overwrite"} specifies that 
information on each draw is not to be stored as the algorithm proceeds. The option {bf:"reeval"} specifies that 
it is necessary to reevaluate the function, as the two arguments {it:b} and {it:W} are changed as the 
algorithm proceeds. After some (pretty poor) starting values are
specified, an initial draw of the individual-level parameters is taken.
A loop can now be run to fill in the arguments. This is done by
setting up a pointer matrix, each row of which points to explanatory values and the mean and variance of the distribution. Now, initial
values for parameters are specified, and then all the separate {bf:amcmc} problems are initiated in a loop.

	{com}: b=J(1,6,0)
	{res}
	{com}: W=I(6)*6
	{res}
	{com}:beta=b:+rnormal(rows(m),cols(X),0,1)*cholesky(W)'
	{res}
	{com}: Args=J(rows(m),4,NULL)
	{res}
	{com}: for (i=1;i<=rows(m);i++) {
	>Args[i,1]=&b
	>Args[i,2]=&W
	>Args[i,3]=&panelsubmatrix(y,i,m)
	>Args[i,4]=&panelsubmatrix(X,i,m)
	>amcmc_args(A[i],Args[i,])
	>amcmc_xinit(A[i],b)
	>amcmc_Vinit(A[i],W)
	>} 
	{res}
	{com}:{txt}
	
{pstd} The algorithm is now implemented as follows (with 10000 total draws, and an initial value of individual 
level parameters taken as a draw
from the normal distribution. The matrices {bf: bvals} and {bf: Wvals} are used to hold the draws of the mean and the covariance matrix:

	{com}: its=10000
	{res}
	{com}: bvals=J(0,cols(beta),.)
	{res}
	{com}: Wvals=J(0,cols(rowshape(W,1)),.)
	{res}
	{com}: for (i=1;i<=its;i++) {
	>b=drawb_betaW(beta,W/rows(m))
	>W=drawW_bbeta(beta,b)
	>bvals=bvals\b
	>Wvals=Wvals\rowshape(W,1)
	>for (j=1;j<=rows(m);j++) {
	>amcmc_draw(A[j])
	>beta[j,]=amcmc_results_lastdraw(A[j])
	>}
	>} 
	{res}
	{com:}{txt}

{pstd} While in a typical application, one usually discards some number of initial values and thins results so as to
eliminate the autcorrelation inherent in MCMC sampling, here we just summarize the draws
for the mean of the parameter vector and the covariance matrix:

	{com}:mean(bvals)'
	{res}       {txt}              1      
		  {c   TLC}{hline 15}{c TRC}
		1 {c |}  {res} .9653859143 {c |}  
		2 {c |}  {res}-.0363394328 {c |}
		3 {c |}  {res} 1.399463261 {c |}  
		4 {c |}  {res} 1.696209143 {c |}
		5 {c |}  {res} 1.656005711 {c |}
		6 {c |}  {res}-2.121194287 {c |}
		  {c BLC}{hline 15}{c BRC}
	{res}
	{com}:rowshape(mean(Wvals),6)
	{txt}[symmetric]
		{res}      {txt}        1              2              3              4			  5			   6
		  {c TLC}{hline 85}{c TRC}{txt}
		1 {c |} {res} 1.692919191                                                                        {c |}{txt}
		2 {c |} {res}-.0236467397    .1201797953                                                         {c |}{txt}
		3 {c |} {res} .7638987195   -.0098907509    1.356704652                                          {c |}{txt}
		4 {c |} {res} .5181705857   -.0080073073    .6239961521   1.122827391                            {c |}{txt}
		5 {c |} {res} 1.087957638   -.0416998767    1.023219879   .6940770407   1.978052313              {c |}{txt}
		6 {c |} {res}-1.317031389    .0337024609   -1.044189251   -.812652926  -1.535208409  2.077123236 {c |}{txt}
		  {c BLC}{hline 85}{c BRC}
 
 The example is in fact a fairly complete description as to how the user-written command {cmd: bayesmlogit} works. 
 For more information, type {cmd:findit net bayesmlogit} at the Stata command prompt. Further examples can be found in Baker (2013).

{title:Additional Notes}

{p 4 4 2}
{bf:amcmc()} or {bf:amcmc_*()} requires that the user install Ben Jann's {cmd:help moremata} set of commands. 

{title:Author}

{p 4 4 2} Matthew J. Baker, Hunter College and the Graduate Center, CUNY, matthew.baker@hunter.cuny.edu. Comments and suggestions are appreciated.

{title: References}

{p 8 8 2}
	Andrieu, Christophe, and Johannes Thoms. 2008. A tutorial on adaptive MCMC. Statistics and Computing 18: 343-73.

{p 8 8 2}
    Baker, Matthew J. 2013. Adaptive Markov chain Monte Carlo in Mata. {browse " http://EconPapers.repec.org/RePEc:htr:hcecon:440":Hunter College working paper 440}. 
	
{p 8 8 2}
	Chernozukov, Victor, and Han Hong. 2003. An MCMC approach to classical estimation. Journal of Econometrics, 115(2): 293-346.
	
{p 8 8 2}
    Train, Kenneth E. 2009. Discrete choice methods with simulation, 2nd. ed. Cambridge and New york: Cambridge University Press.
	
{title:Also see}

{p 4 13 2}
Online:  help for {bf:{help mata}}
