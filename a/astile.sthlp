{smcl}
{right:version:  3.0.0}
{cmd:help astile} {right:1 APR 2017}
{hline}
{viewerjumpto "Options" "astile##options"}{...}

{title:Title}

{p 4 8}{cmd:astile}  -  Creates variable containing quantile categories {p_end}


{title:Syntax}

{p 8 15 2}
{cmd:astile}
{newvar} {cmd:=} {it:{help exp}}
{ifin}
[{cmd:,} {it:{help astile##astile_options:nquantiles(#)}}
{it:{help by}}({it:varlist})]


{title:Description}

{p 4 4 2} {cmd: astile} creates a new variable that categorizes exp by its quantiles. For example, we might be interested in making 10 firm size-based
portfolios. This will involve placing the smallest 10% firms in portfolio 1, next 10% in portolio 2, and so on.{cmd: astile} creates
a new variable as specified in the {newvar} option from the existing variable which is specified in the {cmd:=} {it:{help exp}}. Values of the {newvar}
ranges from 1, 2, 3, ... up to n, where n is the maximum number of quantile groups
specified in the {cmd: nq} option. For example, if we want to make 10 portfolios, values of the {newvar} will range from 1 to 10.
{p_end}


{p 4 4 2} {cmd: astile} is faster than Stata official {help xtile}. It's speed efficiency matters more in larger data sets or when the quantile 
categories are created multiple times, e.g, we might want to create portfolios in each year or each month. Unlike Stata's
official {help xtile}, {cmd: astile} is {help byable}. {cmd: astile} handles groupwise calculations super efficiently. For example, the difference in time when 
used with {help bys} and without {help bys} is usually few seconds in a million observations and 1000 groups. {p_end}

{marker astile_options}{...}
{title:Options}

{p 4 4 2} 
{cmd:astile} has the following two optional options. {p_end}

{p 4 4 2} 1. {opt nq:uantiles} {p_end}
{p 4 4 2} The {cmd: nq}(#) option specifies the number of quantiles. For example, nq(4) will create quratiles, making 4 equal groups of the data 
based on the values of the selected variable. The default value of {cmd:nq} is 2, that is the median.{p_end}
		
{p 4 4 2} 2. {opt by} {p_end}
{p 4 4 2} {cmd: astile} is {help byable}. Hence, it can be run on groups as specified by option {opt by}({it:varlist}). 		

 
{title:Example 1: Create 10 groups of firms based on thier market value}
 {p 4 8 2}{stata "webuse grunfeld" :. webuse grunfeld}{p_end}
 {p 4 8 2}{stata "astile size10=mvalue, nq(10)" :. astile size10=mvalue, nq(10)} {p_end}


 {title:Example 2: Create 5 groups of firms based on thier market value in each year} 
 {p 4 8 2}{stata "webuse grunfeld" :. webuse grunfeld}{p_end}
 {p 4 8 2}{stata "astile size5=mvalue, nq(5) by(year)" :. astile size5=mvalue, nq(5) by(year)} {p_end}
 {p 4 8 2} OR {p_end}
  {p 4 8 2}{stata "bys year: astile size5=mvalue, nq(5)" :. bys year: astile size5=mvalue, nq(5)} {p_end}

 
 {title:Limitatons}

{p 4 4 2} {cmd: This version of astile} does not support weights, altdef and  cutpoint options that are available in the official xtile function. 
In the next version, I plan to inlcude some of these options.
{p_end}


{title:Author}


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: *
*                                                                   *
*            Dr. Attaullah Shah                                     *
*            Institute of Management Sciences, Peshawar, Pakistan   *
*            Email: attaullah.shah@imsciences.edu.pk                *
*           {browse "www.OpenDoors.Pk": www.OpenDoors.Pk}                                       *
*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*


{marker also}{...}
{title:Also see}

{psee}
{stata "ssc desc fastxtile":fastxtile}, 
{stata "ssc desc egenmore":egenmore}, 
{stata "help xtile":xtile}, 
{stata "ssc desc asreg":asreg},
{stata "ssc desc asrol":asrol},
{stata "ssc desc searchfor":searchfor}





