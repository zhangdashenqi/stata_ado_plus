{smcl}
{* 3jan2013}{...}
{cmd:help ttable}{right: }
{hline}

{title:Title}

{p2colset 5 25 10 2}{...}
{p2col:{hi: ttable} {hline 2}} {hi: Mean Comparison for a lot of variables between two groups with formatted table output}
{p_end}
{p2colreset}{...}


{title:Syntax}

{p 4 18 2}
{cmdab:ttable} syntax varlist(min=1) [if] [in], by(varname){cmd:,}


{pstd}{it:varlist} is a list of numerical variables to be tested. 
For each of those variables, we need to perform a standard t-test to compare her mean difference between two groups specified by {hi:by(varname)}  
{p_end}

{pstd} {hi:{it:varname}} must be a dichotomous variable for the sample specified by {hi: [if] and [in]}. {hi:{it:varname}}  maybe either numerical or string, provided that it only takes two different values for the sample. {p_end}



{title:A Simulated Examples}


clear
set obs 1000

forval i = 1(1) 10 {
  gen x`i' = `i'+uniform()*`i'
  }
  gen num_d = uniform()>0.2+x1*.3+x2*.4-x3*.5
 
  gen xs = string(uniform())+"A"
  gen str_d = "A"
  replace str_d = "B" if x1<1.400
 
 ttable x1, by(num_d) 

 ttable x1 xs, by(num_d) 

 ttable x1-x10, by(num_d)

 ttable x1-x10, by(num_d)

 ttable x1-x10 xs, by(str_d)
  
 ttable x1-x10 in 1/800, by(str_d)
 
 ttable x1-x10 in 1/800 if x1<1.8, by(str_d)

{title: After Test}
{pstd} Users can copy the output from Stata's result window, then paste to a MS word document. After that, highlight the pasted words and transform into a table. {p_end}


{title:Authors}

{pstd}Xuan Zhang{p_end}
{pstd}Zhongnan University of Economics and Law{p_end}
{pstd}Wuhan, China{p_end}
{pstd}zhangx@znufe.edu.cn{p_end}


{pstd}Chuntao Li{p_end}
{pstd}Zhongnan University of Economics and Law{p_end}
{pstd}Wuhan, China{p_end}
{pstd}chtl@znufe.edu.cn{p_end}

