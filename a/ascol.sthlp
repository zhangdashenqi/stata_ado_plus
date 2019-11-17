{smcl}
{* 08aug2015}{...}
{cmd:help ascol}{right:version:  1.0.0}
{hline}

{title:Title}

{p 4 8}
{opt ascol}  -  Collapse stock returns and stock prices from {break}
daily to weekly, monthly, quarterly, and yearly frequency


{title:Syntax}

{p 4 6 2}
{cmd:ascol}
varlist {cmd:,} {cmdab:r:turn}{cmd:}
{cmdab:p:rice}{cmd:}
{cmdab: [frequency options]}{cmd:}

{title:options}

{p 4 6 2}  {cmdab:r:eturn}{cmd:}  {break}
This option tells the program that the data is stock returns data. {break}
Since stock returns are already expressed in percentage change form, {break}
the collapse treatement would be to sum these returns within the {break}
specified time interval. 

    {cmdab:p:rice}{cmd:}  

{p 4 6 2} Alternatively, users can specify that the data in memory is {break}
share prices data using option {opt price}. The return and price {break}
cannot be combined together. To collapse prices to desired frequency, {break}
the program finds the last traded prices of the period which the users {break}
specify. 


{title:Frequency Options}


{p 4 4 2}
This program convert stock returns and stock prices data from {break}
daily to weekly, monthly, quarterly, or yearly frequency using {break}
the following options; {p_end}

{p 4 4 2} {cmdab:tow:eekly(}{cmd:)} converts from daily to weekly frequency   {break}
{cmdab:tom:onth(}{cmd:)} converts from daily to monthly frequency   {break}
 {cmdab:toq:uarter(}{cmd:)} converts from daily to quarterly frequency   {break}
 {cmdab:toy:ear(}{cmd:)} converts from daily to yearly frequency   {p_end}
  


{title:Example Data Set}

clear
set obs 1000
gen date=date("1/1/2012" , "DMY")+_n
format %td date
tsset date
gen pr=10
replace pr=pr[_n-1]+uniform() if _n>1
gen ri=(pr/l.pr)-1
save stocks,replace



{title:Example 1: From Daily to weekly -  returns}
  
 {p 4 8 2}{stata "use stocks, clear" :. use stocks, clear}{p_end}
 {p 4 8 2}{stata "ascol ri, toweek returns " :. ascol ri, toweek returns }
 
 OR 
 {p 4 8 2}{stata "ascol ri, tow r " :. ascol ri, tow r }
 
 
{p 4 4 2} ascol is the program name, {opt ri} is the stock return variable in our data set, {break}
{opt toweek} is the program option that tells Stata that we want to convert daily {break} 
data to weakly frequency, and the {opt returns} option tells Stata that our {opt ri} variable {break}
 is stock returns.
 
 {title:Example 1: From Daily to monthly -  prices}
  
 {p 4 8 2}{stata "use stocks, clear" :. use stocks, clear}{p_end}
 {p 4 8 2}{stata "ascol pr, tomonth price " :. ascol pr, tomonth price }
 
 OR 
 {p 4 8 2}{stata "ascol pr, tow p " :. ascol pr, tow p }
 
{p 4 4 2} {opt pr} is the stock prices variable in our data set, {opt tomonth} option tells {break}
Stata that we want to convert daily share prices {break} 
to monhtly frequency, and the {opt price} option tells Stata that our {opt pr} variable {break}
is stock price.
 

{title:Converting Data to Other Frequencies}
  
 {p 4 4 2} ascol can also be used similarly as in the above examples to convert from daily 
 to monthly, quarterly, and yearly frequency. The options to be used in each case are given below;

{p 4 8 2} From daily to monthly, option {opt tomonth} or {opt tom} is to be used {p_end}
{p 4 8 2} From daily to quarterly, option {opt toquarter} or {opt} toq is to be used {p_end}
{p 4 8 2} From daily to yearly, option {opt toyear} or {opt toy} is to be used {p_end}
 
 
{title:Author}

{p 4 8 2} 

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: *
*                                                                             *
*                       Dr. Attaullah Shah                                    *
*            Institute of Management Sciences, Peshawar, Pakistan             *
*                     Email: attaullah.shah@imsciences.edu.pk   
*                 See my webpage for more programs and help at:
*                    {browse "http://www.OpenDoors.Pk/STATA"}                      
*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*






