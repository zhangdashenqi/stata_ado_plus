{smcl}
{* 20aug2014}{...}
{cmd:help intsolver}
{hline}

{title:Title}

{p 4 4 2}
{bf:intsolver -- Mata Functions and Structures for finding all solutions to nonlinear systems of equations}

{hline}

{title:Introduction}

{p 4 4 2}
{bf:intsolver} is a collection of Mata routines for completely solving - finding all zeros - of nonlinear systems. {bf:intsolver} uses
interval methods for solving systems of equations. Interval methods for solving systems are fairly accessible to the novice, and 
are also numerically stable. Descriptions appear in Moore et. al. (1999), and Jaulin et al. (2001).

{p 4 4 2}
The specific method {bf:intsolver} uses to completely solve systems is a form of constraint 
propogation combined with a so-called Taylor inclusion for the function
of interest. The method is a simplified version of some of the methods described in Hentenryck et. al. (1997), and also bears resemblance to 
the equation-by-equation interval Gauss-Seidel method described in Moore et. al. (1999).

{p 4 4 2}
An extensive description of interval arithmetic is described in the package {help int_utils:int_utils}, which, 
along with the package {help rowmat_utils:rowmat_utils}, must be installed for {cmd: intsolver}
to work (along with {help moremata:moremata}). 

{p 4 4 2}
For a brief overview of the method, consider the problem of determining whether or not a 
zero of a function f(x) exists in some range [a,b]. Interval arithmetic uses outward rounding
to create a range of possible values for f(x) on [a,b], which in trade jargon is referred to as
 an interval extension of f(x): sometimes written as [f]([x]).  

{p 4 4 2}
In most cases, the interval extension [f]([x]) has two important properties. First, the bounds it generates 
are not sharp in that the true mininum (maximum) value of f(x) over the range [x] is greater (less than) the bounds
provided by [f]([x]). This phenomenon is referred to as pessimism. Second, it can be shown that as the size 
of the range [x] shrinks, it is the case that the bounds [f]([x]) 
imposes on the domain of f(x) shrink more rapidly towards the true domain of f(x) on [a,b].  
This convergence typically occurs at a rate >2 for a Taylor inclusion function, which is the type of inclusion 
function used by {cmd:intsolver}.

{p 4 4 2}
This latter feature of the problem forms the basis for algorithms in which intervals are continuously narrowed
via bisection or some other means. One maintains 
a list of potential intervals where a zero might
be located, and then tests the intervals to see if [f]([x]) brackets zero. 
If a tested interval contains zero, it can be shrunk by some method (perhaps bisection) into smaller intervals, which can 
then be retested. If a tested interval does not bracket zero, it is discarded. This method can 
be extended to multiple variables, and can also use different
sorts of information about the problem. The process terminates when all intervals remaining are of sufficiently small size. 
These remaining intervals can be resolved into point solutions
via some technique such as Newton Iteration.  

{p 4 4 2}
{cmd:intsolver} uses simple interval tests which are performed in parallel over sets of intervals, 
Consider f(x) to be a vector-valued function of the vector x. A first-order Taylor expansion about 
the point x0 can be written as f(x)~f(x0)+J(x0)(x-x0). Suppose [x] is an interval vector, with the first row containing
lower bounds and the second upper bounds (see {help int_utils:int_utils} for examples). 
In interval arithmetic, it can be shown that f([x]) is 
bounded by f(x0)+[J]([x])([x]-x0), where [J]([x]) is the interval Jacobian. 
This principal is simple and owes to the mean value theorem: the value of the function cannot be greater (smaller) than its greatest (smallest) 
value multiplied by the greatest (smallest) value of the derivative. The algorithm used by {cmd:intsolver} is a version of interval Gauss-Seidel
iteration (see, e.g., Moore et. al. 1999, p. 96).

{p 4 4 2}
There are other methods, but in applications it has been found by the author 
that using this interval function equation by equation and variable by variable
is a relatively efficient means of solving most problems. 

{hline}

{title:Usage}

{title:Syntax}

{p 4 4 2}
Syntax is discussed in three steps:

        {help intsolver##syn_step1:Step 1: Preliminaries}
        {help intsolver##syn_step2:Step 2: Initialization}
        {help intsolver##syn_step3:Step 3: Solving a problem}
        {help intsolver##syn_step4:Step 4: Refining and obtaining results}

{marker syn_step1}{...}
    {title:Step 1: Preliminaries}

{p 4 4 2}
Ideas are best motivated by example. Accordingly, consider the problem of finding all the 
zeros of the vector function f={1-2x1x2-3x1^2, f2=1-x1^2-3x2^2} 
where both x1 and y1 are restricted to the [-100,100] interval. While simple, this
function reflects one of the situations for which {bf:intsolver} was intended: Smaller 
nonlinear problems that are difficult to solve completely by hand, that have multiple real solutions. 
This function in fact has four roots in [-100,100]. 

{p 4 4 2}
To use {cmd:intsolver}, one must program four Mata functions: one that returns the value of a particular equation at a
set of points, one that returns an entry of the jacobian at a set of points, an interval representation of values, and
an interval representation of jacobian entries. The actual function arguments should be passed to the function
in a single matrix. Each row of the matrix is a sequence of points
at which the value of one of the component functions can be calculated. The first 
step is to program the two functions themselves. First, the function itself:

	{com}. mata:
	{hline 20} {txt}mata (type {bf:end} to exit) {hline 20} 
	{com}: real matrix fun(real matrix x,real scalar i)
	>{
	>if (i==1) return(1:-2*x[,1]:*x[,2]:-3*x[,1]:^2)
	>if (i==2) return(1:-x[,1]:^2:-3*x[,2]:^2)
	>}
	>: end{txt}
	{hline 65}
	
{p 4 4 2}
The function {com}fun(){txt} takes in two arguments. The first, a matrix, holds (x1,x2) combinations 
listed as its rows. The second argument is simply the equation number in the system.

{p 4 4 2}
The next step is programming the function providing values of the entries of the Jacobian. 
For the example, f11=-2x2-6x1, f12=-2x1, f21=-2x1, f22=-6x2. So:

	{com}. mata:
	{hline 20} {txt}mata (type {bf:end} to exit) {hline 20} 
	{com}: real matrix jac(real matrix x,real scalar i, real scalar j)
	>{
	>if (i==1 & j==1) return(-2*x[,2]:-6:*x[,1])	
	>if (i==1 & j==2) return(-2*x[,1])
	>if (i==2 & j==1) return(-2*x[,1]])	
	>if (i==2 & j==2) return(-6*x[,2])	
	>}
	: end{txt}
	{hline 65}

	
{p 4 4 2}
Next, one must program an interval version of {bf: fun()}. This is more challenging, 
but can be accomplished through application of {help int_utils:int_utils}. In
the author's experience, it is useful to break interval operations into steps. Some operations, 
like interval-scalar multiplication, can be 
treated on the fly, although one should exert care to avoid rounding errors, which are 
crucial to interval arithmetic. Treating a constant like an interval with equal upper and 
lower limits is helpful in avoiding these sorts of errors.
The arguments of the function once again are rows of an input matrix, but now the first 
two columns are the lower and upper bound of the first variable, columns 3 and 4 are the bounds of the
second variable, etc. Accordingly, the interval functions should be set up to take in a 
matrix as the first argument, a scalar indicating the equation number as the next argument, and a 
final argument (d in the functions below). This last argument is a tolerance for 
rounding that is used in interval computations. It is described further below and also the help entry 
for {help int_utils:int_utils}.

	{com}. mata:
	{hline 20} {txt}mata (type {bf:end} to exit) {hline 20} 
	{com}: real matrix fun_I(real matrix x,real scalar i, real scalar d)
	>{
	>X1=x[,1::2]
	>X2=x[,3::4]
	>if (i==1) {
	>	A=2*int_mult(X1,X2,d)
	>	I=J(rows(A),2,1)
	>	B=int_sub(I,A,d)
	>	C=3*int_mult(X1,X1,d)
	>	D=int_sub(B,C,d)
	>	return(D)
	>}
	>if (i==2) {
	>	A=int_mult(X1,X1,d)
	>	B=3*int_mult(X2,X2)
	>	I=J(rows(A),2,1)
	>	C=int_sub(I,A,d)
	>	D=int_sub(C,B,d)
	>	return(D)
	>}
	>}
	: end{txt}
	{hline 65}

{p 4 4 2}
Some tricks of the trade that allow programming interval versions of functions are employed 
in the above Mata program. The line {cmd:I=J(rows(A),2,1)} produces a two-column matrix of ones
that conforms with the arguments {cmd:X1} and {cmd:X2}. The next line, {cmd:int_sub(I,A,d)} is
thus a way of performing {help int_utils##int_sub:interval subtraction}, where one wishes to 
subtract an interval from a constant.  

{p 4 4 2}
The interval jacobian is programmed similarly:

	{com}. mata:
	{hline 20} {txt}mata (type {bf:end} to exit) {hline 20} 
	{com}: real matrix jac_I(real matrix x,real scalar i,real scalar j, real scalar d)
	>{
	>X1=x[,1::2]
	>X2=x[,3::4]
	>r=rows(X1)
	>if (i==1 & j==1) {
	>	A=int_mult(J(r,2,-2),X2,d)
	>	B=int_mult(J(r,2,-6),X1,d)
	>	C=int_add(A,B,d)
	>	return(C)  
	>}
	>if (i==1 & j==2) {
	>	A=int_mult(J(r,2,-2),X1,d)
	>	return(A)
	>}
	>if (i==2 & j==1) {
	>	A=int_mult(J(r,2,-2),X1,d)
	>	return(A)
	>if (i==2 & j==2) {
	>	A=J(rows(X1),2,-6)
	>	B=int_mult(A,X2,d)
	>	return(B)
	>}
	>}
	: end{txt}
	{hline 65}
	
{marker syn_step2}{...}
    {title:Step 2: Initiation}

{p 4 4 2}
Now that the basic problem has been defined, the user must describe several basic features of the problem. 
These include the interval within which {cmd:intsolver} is to search
for solutions and various sorts of tolerances. One starts by defining a problem using the mata 
function {bf: int_prob_init()}, then filling in the number of arguments using {bf:int_prob_args()}
and then passing the four required functions to the solver 
using {bf: int_prob_f()}, {bf:int_prob_jac()}, {bf:int_prob_f_Iform()}, and {bf:int_prob_jac_Iform()}.  Continuing the example:

	{com}. mata:
	{hline 20} {txt}mata (type {bf:end} to exit) {hline 30} 
	{com}: Prob=int_prob_init()
	: int_prob_args(Prob,2)
	: int_prob_f_Iform(Prob,&fun_I())
	: int_prob_jac_Iform(Prob,&jac_I())
	: int_prob_f(Prob,&fun())
	: int_prob_jac(Prob,&jac()){res}
	: end{txt}
	{hline}

{marker syn_step3}{...}
    {title:Step 3: Solving a problem}	
	
{p 4 4 2}
The next step is define the intervals within which to search for solutions and apply the solver: 
	
	{com}. mata:
	{hline 20} {txt}mata (type {bf:end} to exit) {hline} 
	{com}: Ival=(-100,100) \ (-100,100)
	: int_prob_ival(Prob,Ival)
	: int_solve(Prob)
	: end{txt}
	{hline}

{p 4 4 2}
The problem has been solved in interval form. One can view the solutions through use of 
the utility {bf:int_prob_ints_vals(Prob)}. Entering the command produces the following:

	{com}. mata:
	{hline 20} {txt}mata (type {bf:end} to exit) {hline} 
	{com}: int_prob_ints_vals(Prob)
	           {txt}    1          2           3           4 
            {c TLC}{hline 49}{c TRC}
          1 {c |}{com}  -.7249408   -.7249155    .3976849    .3976926  {c    |}
          {txt}2{com} {c |}{com}  -.7249408   -.7249155    .3976849    .3976926  {c    |}
          {txt}3{com} {c |}{com}  -.4291268   -.4291181   -.5214909   -.5214856  {c    |}
          {txt}4{com} {c |}{com}   .4291181    .4291268    .5214856    .5214909  {c    |}
          {txt}5{com} {c |}{com}   .7249155    .7249408   -.3977003   -.3976926  {c    |}
          {txt}6{com} {c |}{com}   .7249155    .7249408   -.3976926   -.3976849  {c    |}
            {c BLC}{hline 49}{c BRC}{txt}

{marker syn_step2}{...}
    {title:Step 4: Refining and obtaining results}			
			
{p 4 4 2}
In this particular case, {bf:intsolver} produces 6 intervals which potentially contain solutions. The user
might wish to refine these solutions, or get a more accurate count of the number of solutions to the system. 
To this end, one can refine the intervals into points using {bf: int_newton_iter()}, 
which operates on the principle that interval solutions
define a neighborhood of convergence and hence newton iteration will converge rapidly, a principle for which 
Pandian (1986) provides rigorous foundation. The
exact method used for newton iteration is discussed in the help entry {help rowmat_utils:rowmat_utils}. Suffice it to say 
here that {cmd:intsolver} uses {help rowmat_utils:rowmat_utils} to perform Newton iteration in parallel. To illustrate:

	{com}: int_newton_iter(Prob)
	{com}: int_prob_pts_vals(Prob)
	           {txt}    1          2            
            {c TLC}{hline 29}{c TRC}
          1{com} {c |}{com}  -.7249360956   .3976881766 {c    |}
          {txt}2{com} {c |}{com}  -.4291212844  -.5214898284 {c    |}
          {txt}3{com} {c |}{com}   .4291212844   .5214898284 {c    |}
          {txt}4{com} {c |}{com}   .7249360956  -.3976881766 {c    |}
            {c BLC}{hline 29}{c BRC}{txt}	
	
{p 4 4 2}
Thus, applying {bf:int_newton_iter()} pares down the solution set and renders 
the set of intervals into a set of points, so the equations have four solutions in the given range. In the accompanying .do file 
{cmd:IntsolverExamples.do}, an example using Powell's badly-scaled function is presented. This example produces approximately 115 separate
intervals where solutions might be. Newton iteration pares this set down to two actual solutions.

{title: Additional function arguments}

{p 4 4 2}
In the event that one wishes to use a function that has additional arguments or parameters, 
one should specify these in terms of a single argument (by, for example, collecting the additional arguments
in a pointer, matrix, vector, etc. and then unpacking the additional arguments 
inside the body of the function). If it were the case, for example, that {cmd:fun()} had additional arguments,
instead of programming

	{com}. mata:
	{hline 20} {txt}mata (type {bf:end} to exit) {hline 20} 
	{com}: real scalar fun(real matrix x, real scalar i)
	>{
	     
		 {it:<body of function>}
		 
	>}
	>: end{txt}
	{hline 65}
	
{p 4 4 2}
One would instead collect arguments in some vector, matrix, pointer, or some other object -  
{it:{bf:Z}}, say - and code a function of the form:

	{com}. mata:
	{hline 20} {txt}mata (type {bf:end} to exit) {hline 20} 
	{com}: real scalar fun(real matrix x, real scalar i, transmorphic Z)
	>{
	     
		 {it:<body of function>}
		 
	>}
	>: end{txt}
	{hline 65}	

{p 4 4 2}
Similarly, {bf:fun_I()}, {bf:jac()}, and {bf:jac_I()} should be programmed with an additional argument {bf:{it:Z}}:


	{com}. mata:
	{hline 20} {txt}mata (type {bf:end} to exit) {hline 20} 
	{com}: real scalar fun_I(real matrix x, real scalar i, real scalar d, transmorphic Z)
	>{
	     
		 {it:<body of function>}
		 
	>}
	>: end{txt}
	{hline 65}	

 
	{com}. mata:
	{hline 20} {txt}mata (type {bf:end} to exit) {hline 20} 
	{com}: real scalar jac(real matrix x, real scalar i, real scalar j, transmorphic Z)
	>{
	     
		 {it:<body of function>}
		 
	>}
	>: end{txt}
	{hline 65} 	
 

	{com}. mata:
	{hline 20} {txt}mata (type {bf:end} to exit) {hline 20} 
	{com}: real scalar jac_I(real matrix x, real scalar i, real scalar j, real scalar d, transmorphic Z)
	>{
	     
		 {it:<body of function>}
		 
	>}
	>: end{txt}
	{hline 65}	 
 
 {p 4 4 2}
 The final thing that needs to be done if additional arguments are to be 
 passed to the function is {cmd:intsolver} must be informed of the additional information
 needed to calculate the functions. This is done by using the function {bf:int_prob_addinfo()}. 

 {p 4 4 2}
 As an example, consider Diamond's (1982) model of search and unemployment. 
Diamond shows that the equations describing the model have
multiple solutions, and therefore in analysis of the model, one might like to 
be able to find all of the solutions. 
 
{p 4 4 2}
In the model, agents search for production opportunities. When an opportunity arises, 
the costs of executing it is drawn from a distribution G(c), and the agent must
decide whether or not to do the project. Agents engaged in projects are freed from 
projects at some rate. The measure of agents is normalized to one, and opportunities 
arrive at the rate a. Moreover, opportunities end at the rate b(e), where e 
is the employment rate and b'>0. Steady-state employment occurs when the flow out of 
opportunities equals the flow into opportunities:

{p 8 8 2}
a(1-e*)G(c*)-e*b(e*)=0 

{p 4 4 2}
In the above, c* is the threshold cost below which production opportunities are accepted, 
so G(c*) is the probability a given opportunity is accepted. Diamond shows 
that the cutoff cost c* is described by an equation which equates the flow value of the 
current opportunity with cost c* with the flow value of searching for another opportunity
given projects with costs greater than c* will not be undertaken. This equation can be written:

{p 8 8 2}
c*(r+b(e)+aG(c*))=b(e)y+a*E[c|c<c*]

{p 4 4 2}
In the previous equation r is the discount factor, and y is the flow output generated 
by a project. To parameterize the model, we will suppose that b(e)=be, where b is a constant, and
that G(c) is the pareto distribution with parameter alpha. Hence, G(c)=1-c^alpha. 
Therefore, the model of interest has five parameters: a,alpha,b,r, and y. 

{p 4 4 2}
The first step is to define the equilibrium conditions and the jacobian. The equilibrium conditions are:

	{com}. mata:
	{hline 20} {txt}mata (type {bf:end} to exit) {hline 20} 	
	{com}: real matrix eqconds(real matrix X, real scalar i, transmorphic Z)
	{
	>real scalar a,alpha,b,r
	>real matrix eq
	>a=Z[1]
	>alpha=Z[2]
	>b=Z[3]
	>r=Z[4]
	>y=Z[5]
	>
	>e=X[,1]
	>c=X[,2]
	>
	>Gc=1:-c:^alpha
	>if (i==1) {
	>	eq=a*(1:-e):*Gc:-e:*b*e				    /* Equilibrium employment */
	>}
	>if (i==2) {
	>	CE=(-alpha/(alpha+1)):*c:^(alpha+1)
	>	eq=c*r:+b:*e*r:+a*c:*Gc-b:*e*y:-a:*CE	/* Equilibrium project adoption */
	>}
	>return(eq)
	>}
	: end{txt}
	{hline 20}
	
{p 4 4 2}
While the Jacobian is:

	{com}. mata:
	{hline 20} {txt}mata (type {bf:end} to exit) {hline 20} 	
	{com}:
	: real matrix eqjac(real matrix X, real scalar i, real scalar j, transmorphic Z)
	>{
	>real scalar a,alpha,b,r
	>real matrix eq
	>a=Z[1]
	>alpha=Z[2]
	>b=Z[3]
	>r=Z[4]
	>y=Z[5]
	>
	>e=X[,1]
	>c=X[,2]
	>
	>if (i==1 & j==1) {
	>	Gc=1:-c:^alpha	
	>	eq=-a*Gc:-2*e:*b
	>}
	>if (i==1 & j==2) {
	>	dGc=-alpha*c:^(alpha-1)
	>	eq=a*(1:-e):*dGc
	>}	
	>if (i==2 & j==1) {
	>	eq=J(rows(X),1,b*r:-b*y)
	>}
	>if (i==2 & j==2) {
	>	Gc=1:-c:^alpha
	>	dGc=-alpha*c:^(alpha-1)
	>	dCE=-alpha:*c:^alpha	
	>	eq=r:+a*Gc:+a*c:*dGc:-a:*dCE
	>}
	>return(eq)
	>}
	: end{txt}
	{hline 65}

{pstd}
Note how the functions now take an additional argument, {bf:Z}, which contains the 
five parameters of the model. Next, the interval version of the equilibrium conditions should
be programmed: 

	{com}. mata:
	{hline 20} {txt}mata (type {bf:end} to exit) {hline 20}
 	{com}: real matrix eqconds_I(real matrix X, real scalar i, real scalar digits, transmorphic Z)
	>{
	>real scalar a,alpha,b,r
	>real matrix eq,Gc,A,B,C,D,CE,Alphas
	>
	>a=Z[1]
	>alpha=Z[2]
	>b=Z[3]
	>r=Z[4]
	>y=Z[5]
	>
	>e=X[,1::2]
	>c=X[,3::4]
	>	
	>Ones=J(rows(X),2,1)
	>A=int_pow(c,alpha,digits)
	>Gc=int_sub(Ones,A,digits)
	>if (i==1) {
	>	A=a*int_sub(Ones,e,digits)
	>	B=b*int_mult(e,e,digits)
	>	C=int_mult(A,Gc,digits)
	>	eq=int_sub(C,B)
	>}
	>else if (i==2) {
	>	Alphas=J(rows(X),2,-alpha/(alpha+1))
	>	CE=int_mult(Alphas,int_pow(c,alpha+1,digits),digits)
	>	A=r*int_add(c,b*e,digits)
	>	B=a*int_mult(c,Gc,digits)
	>	C=int_add(b*y*e,a*CE,digits)
	>	D=int_sub(B,C,digits)
	>	eq=int_add(A,D,digits)
	>}
	>return(eq)
	>}
	: end{txt}
	{hline 20}
	
{p 4 4 2}
The interval version of the jacobian must also be programmed:

	{com}. mata:
	{hline 20} {txt}mata (type {bf:end} to exit) {hline 20}
 	{com}: real matrix eqjac_I(real matrix X, real scalar i, real scalar j, real scalar digits, transmorphic Z)
	>{
	>real scalar a,alpha,b,r
	>real matrix eq
	>
	>a=Z[1]
	>alpha=Z[2]
	>b=Z[3]
	>r=Z[4]
	>y=Z[5]
	>
	>e=X[,1::2]
	>c=X[,3::4]
	>
	>Ones=J(rows(X),2,1)
	>A=int_pow(c,alpha,digits)
	>Gc=int_sub(Ones,A,digits)	
	>if (i==1 & j==1) {
	>	eq=int_sub(-a*Gc,2*e:*b,digits)
	>}
	>if (i==1 & j==2) {
	>	dGc=-alpha*int_pow(c,alpha-1,digits)
	>	eq=a*int_mult(int_sub(Ones,e),dGc,digits)
	>}	
	>if (i==2 & j==1) {
	>	eq=J(rows(X),2,b*r:-b*y)
	>}
	>if (i==2 & j==2) {
	>	dGc=-alpha*int_pow(c,alpha-1,digits)
	>	dCE=-alpha*int_pow(c,alpha,digits)	
	>	eq=r:+a*int_sub(int_add(Gc,int_mult(c,dGc,digits),digits),dCE,digits)
	>}
	>return(eq)
	>}
	: end{txt}
	{hline 65} 
 
 {pstd}
 Next, the problem is initialized and solved over a reasonable range, 
 bounded away from zero:

	{com}. mata:
	{hline 20} {txt}mata (type {bf:end} to exit) {hline 20}
	{com}: Diamond=int_prob_init()
	:int_prob_args(Diamond,2)
	:int_prob_f(Diamond,&eqconds())
	:int_prob_jac(Diamond,&eqjac())
	:int_prob_f_Iform(Diamond,&eqconds_I())
	:int_prob_jac_Iform(Diamond,&eqjac_I())
	:bounds=0.000001,1 \ 0.000001,10
	:int_prob_ival(Diamond,bounds)
	:Z=2,-.12,3,.4,2			/* Parameter values */
	:int_prob_addinfo(Diamond,Z)
	:int_solve(Diamond)
	:int_prob_ints_vals(Diamond)
	           {txt}    1          2           3           4 
            {c TLC}{hline 50}{c TRC}
          1 {c |}{com} .027320859  .027321329  1.009640757  1.009643518 {c    |}
          {txt}2 {c |}{com} .027320859  .027321329  1.009640757  1.009643518 {c    |}
          {txt}3 {c |}{com}  .24685418   .24685852  2.939442678  2.939458896 {c    |}
          {txt}4 {c |}{com}  .24685418   .24685852  2.939458895  2.939475113 {c    |}
	    {c BLC}{hline 50}{c BRC}{txt}	

	{com}:int_newton_iter(Diamond)
	:int_prob_pts_vals(Diamond)
	           {txt}    1          2  
            {c TLC}{hline 26}{c TRC}
          1 {c |}{com} .0273211682  1.009644396 {c    |}
          {txt}2 {c |}{com} .2468549652  2.939448548 {c    |}
	    {c BLC}{hline 26}{c BRC}{txt}	

	:end{txt}
	{hline 65}
	
{pstd}
One can see that the model, as parameterized by Z, has two equilibria. 
One is a low-employment equililbrium in which only very low-cost opportunities are undertaken, while
the other is a high-employment equilibrium, in which higher-cost opportunities are undertaken.
 
{title:Additional Notes}

{p 4 4 2}
If one has a problem that does not necessarily require that all solutions be found, 
one can just program the function and its jacobian.
Then, if a set (however large) of starting points, along with an initial range, are 
provided to {bf:intsolver} newton iteration can be performed in parallel on
the given points in the hopes that there will be some that are sufficiently close
 to the solutions that they will be found. In the author's experience, 
a little experimentation usually gives a good indication about how many starting 
points are needed, and most if not all solutions can be found this way quite rapidly. 

{p 4 4 2}
For example, suppose in the first example given above that only the functions 
and its jacobian had been programmed.
Then, a "scatter shot" approach might be used, where random points around a solution might be passed to {bf:intsolver} using {bf:int_prob_init_pts()}: 

	{com}. mata:
	{hline 20} {txt}mata (type {bf:end} to exit) {hline} 
	{com}: Prob=int_prob_init()
	: int_prob_args(Prob,2)
	: int_prob_f(Prob,&fun())
	: int_prob_jac(Prob,&jac()){res}
	: randpoints=-1:+2*runiform(10,2)
	: int_prob_init_pts(Prob,randpoints)
	: int_prob_method(Prob2,"newton")
	: int_newton_iter(Prob)
	: int_prob_pts_vals(Prob){txt}

{p 4 4 2}
This produces the same results as the complete solution method described above. {bf:int_newton_iter()} does not 
return as solutions as many points as it is given to start;
it automatically detects and lumps together answers that it deems to be the same. 
How different points must be to be considered numerically different
can be controlled by the user. In applications, the user can calibrate the number of random points so that
seemingly all solutions are found. 

{title:Options}

{p 4 4 2}
There are several things that the user may specify to control the solution process
 that may greatly influence the speed at which 
solutions are found. In terms of interval arithmetic, two important tolerances 
are the tolerance used for outward rounding
in interval arithmetic, and the minimum width of a box. In terms of newton 
iterations, the important numerical ideas are the convergence
tolerance and the maximum number of iterations to undergo. These four things may be set with the options:

{p 4 4 2}
{bf:int_prob_mbwidth({it: real scalar w})} 

{p 8 8 2}
Can be used to set the minimum box width. The default is {it:1e-4}. Note that the box width
cannot be smaller than the number of digits used for outward rounding; otherwise 
{bf:intsolver} rounding down and up will always create
intervals bigger than the smallest box. Once all intervals are are reduced to 
the specified size or smaller, {bf:intsolver} stops bisection.
In practice, one can often get a sequence of intervals that are wide rather 
quickly and then use the midpoints of these intervals in Newton iteration. 

{p 4 4 2}
{bf:int_prob_digits({it: real scalar d})} 

{p 8 8 2}
Can be used to set the digits for outward rounding. The default is {it:1e-8}. As an example,
when presented with an interval [.11223344556677,.11223344557788], if {bf:{it:d=1e-8}, the interval is rounded to
[.1122334,.1122335]. Interval arithmetic uses this "outward rounding" to avoid dropping potential solutions via rounding. 

{p 4 4 2}
{bf:int_prob_maxit({it:real scalar its})} 

{p 8 8 2}
Can be used to set the maximum number of iterations performed by {bf:int_newton_iter()}. The default
is 50. 

{p 4 4 2}
{bf:int_prob_tol({it:real scalar tol}} 

{p 8 8 2}
Can be used to set convergence criterion for the Newton iteration process. The default is 1e-12. This can
in practice be tuned much lower. 

{p 4 4 2}
{bf: int_prob_tolsols({it:real scalar tolsols})} 

{p 8 8 2}
Can be used to lump solutions together. When newton iteration 
produces multiple solutions, one would like to know if results
are in fact "the same" or not. If solutions lie within {it:tolsols} of one another, 
then are deemed the same and one is dropped. The default
is 1e-2. 

{title:Test Problems and Examples}

The supporting -.do file {bf:intsolver_examples.do} contains an assortment of examples and test problems.  

{title:Further requirements}

{p 4 4 2}
{bf:intsolver} requires that the user install Ben Jann's {cmd:help moremata} set of commands, and also that the user install the
mata packages {bf:rowmat_utils} and {bf:int_utils}. 

{title:Author}

{p 4 4 2} Matthew J. Baker, Hunter College and the Graduate Center, CUNY, matthew.baker@hunter.cuny.edu. 

{p 4 4 2} {it:Note from the author}: Comments and suggestions are greatly appreciated, as usual. But I will also add that
if you are interested in using {cmd:intsolver} and need help setting
up your problem, please do not hesitate to contact me. I am hoping to build a larger library of examples, and also would like to know what sorts
of applications users have for the package. 

{title: References}

{p 8 8 2}
	Diamond, Peter. 1982. Aggregate demand management in search equilibrium. {it:Journal of Political Economy} 90(5): 881-94.

{p 8 8 2}
	van Hentenryck, Pascal, David McAllester, and Deepak Kapur. 1997. Solving polynomial systems using a branch and prune approach. {it:SIAM Journal on	Numerical Analysis} 34(2): 797-827.
	
{p 8 8 2} 
	Jaulin, Luc, Michel Kieffer, Olivier Didrit, and Eric Walter. 2001. {it:Applied Interval Analysis}. London, Berlin, and Heidelberg: Spring-Verlag.

{p 8 8 2}
	Moore, Ramon E., R. Baker Kearfott, and Michael J. Cloud. 2009. {it:Introduction to Interval Analysis}. Philadelpha: SIAM. 
	
{p 8 8 2}
	Pandian, Maharaja C. 1985. Convergence test and componentwise error estimates for Newton type methods. {it:SIAM Journal on Numerical Analysis} 22(4): 779-91.

{title:Also see} {help rowmat_utils:rowmat_utils}, {help int_utils:int_utils}, {help moremata:moremata} (all are required for {bf:intsolver})





