
{smcl}
{.-}
help for {cmd:poi2hdfe} {right:()}
{.-}
 
{title:Title}

poi2hdfe - Estimates a Poisson Regression Model with two high dimensional fixed effects.

{title:Syntax}

{p 8 15}
{cmd:poi2hdfe} {it:{help depvar}} [{it:{help indepvar}}] [{help if}] [{help in}] , {cmd:id1(}{it:{help varname}}{cmd:)} {cmd:id2(}{it:{help varname}}{cmd:)}
  [{it:options}]

{p}

{title:Description}

{p} 
This command allows for the estimation of a Poisson regression model with two high 
dimensional fixed effects. Estimation is implemented by an iterative process [using the 
algorithm of Guimaraes & Portugal (2010)] that avoids creating the dummy variables 
for the fixed effects. Depending on the data, the code may be very slow. It supports 
robust and cluster robust standard errors. It also allows the inclusion of an exposure 
variable. 

{title:Options}

{p 0 4}{cmd:tol1}{cmd:(}{it:float}{cmd:)} Specify the convergence criterion for estimation 
of the coefficients. Default is 1.000e-09.

{p 0 4}{cmd:tol2}{cmd:(}{it:float}{cmd:)} Specify the convergence criterion for estimation 
of the standard errors. Default is 1.000e-09.

{p 0 4} {cmd:exposure(}{it:varname}{cmd:)} add an exposure variable.

{p 0 4}{cmdab:rob:ust} produces robust standard errors.

{p 0 4} {cmd:cluster(}{it:varname}{cmd:)} computes clustered standard errors.

{p 0 4} {cmd:fe1(}{it:new varname}{cmd:)} {cmd:fe2(}{it:new varname}{cmd:)}:
stores the estimates of the two fixed effects.

{p 0 4}{cmdab:max:iter}{cmd:(}{it:integer}{cmd:)} specify a maximum number of iterations for
the intermediary Poisson regressions.

{p 0 4}{cmdab:start:val} uses {help reghdfe} to produce starting values. You must have {help reghdfe}
installed in your computer.

{p 0 4}{cmdab:poisson} use the {help poisson} for intermediary regressions instead of
the {help glm} command (the default).

{p 0 4} {cmd:sample(}{it:new varname}{cmd:)} create an indicator variable for the sample used
for the estimation.

{p 0 4}{cmdab:verb:ose} gives more information during estimation.

{p 0 4} {cmd:ever0(}{it:#}{cmd:)} accelerate the betas every # iterations.

{p 0 4} {cmd:ever1(}{it:#}{cmd:)} accelerate the fes for id1 every # iterations.

{p 0 4} {cmd:ever2(}{it:#}{cmd:)} accelerate the fes for id2 every # iterations.

{title:Examples}

Example 1:
Estimates a model with two high dimensional fixed effects.
Produces the same results as "poisson y x1 x2 i.id1 i.id2" 

{p 8 16}{inp:. poi2hdfe y x1 x2, id1(id1) id2(id2)}{p_end}

Example2:
Estimates a model with two high dimensional fixed effects and stores the estimates
of the fixed effects in the variables ff1 and ff2.

{p 8 16}{inp:. poi2hdfe y x1 x2, id1(id1) id2(id2) fe1(ff1) fe2(ff2)}{p_end}

{title:Tips}

Estimation with this command may be extremely slow. You should only use it if Stata's
official {help poisson} regression is not an option (because of the large number of dummy variables
for the fixed effects). The command is likely to converge faster if you use the option
{cmdab:startval}. To use this option you must previously install the {help reghdfe} command
by Sergio Correia. You may also want to use the option "verbose". This will produce
a larger output but you will have a good sense of the convergence process.
If you have trouble with convergence you may want to disable the acceleration. To do this
set the parameter {cmd:ever0} to a large number (eg.10000). This is done using the option 
"{cmd:ever0(}{it:10000}{cmd:)}". You may want to do the same with the parameters {cmd:ever1} and {cmd:ever2}.
To improve the speed of convergence you can decrease the tolerance levels - this will 
affect the precision of the estimates but will speed up computations.

{title:Remarks}

Please notice that this software is provided "as is", without warranty of any kind, whether
express, implied, or statutory, including, but not limited to, any warranty of merchantability
or fitness for a particular purpose or any warranty that the contents of the item will be error-free.
In no respect shall the author incur any liability for any damages, including, but limited to, 
direct, indirect, special, or consequential damages arising out of, resulting from, or any way 
connected to the use of the item, whether or not based upon warranty, contract, tort, or otherwise. 

{title:Acknowledgements}
This program uses the "fastsum" and "fastmean" Mata routines created by Sergio Correia.
{p}

{title:Author}

{p}
Paulo Guimaraes, Bank of Portugal, Portugal.

{p}
Email: {browse "mailto:pguimaraes2001@gmail.com":pguimaraes2001@gmail.com}

Your comments are welcome!

{title:Reference}

For more details, see:

Octavio Figueiredo, Paulo Guimaraes and, Douglas Woodward "Industry Concentration, Distance Decay, and
Knowledge Spillovers: Following the Patent Paper Trail" unpublished working paper.

Paulo Guimaraes and Pedro Portugal. "A Simple Feasible Alternative Procedure to Estimate Models with 
High-Dimensional Fixed Effects", Stata Journal, 10(4), 628-649, 2010.

If you use this command in your research please cite the above papers.

