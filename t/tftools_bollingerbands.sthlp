{smcl}
{* 22jun2017}{cmd:help tftools bollingerbands}
{hline}

{title:Title}
{pstd}{hi:tftools bollingerbands} {hline 2} Calculates the Bollinger bands for a single time-series variable. {p_end}

{title:Syntax}
{pstd}{cmdab:tftools bollingerbands [if] [in]}{cmd:, symbol({it: variable}) generate({it: newvar}) [period(integer) sdevs(string)]}{p_end}

{title:Description}
{pstd}
{it:tftools bollingerbands} calculates the Bollinger bands for a single time-series variable. 
Window for the standard deviation and simple moving averaging can be specified.
{it:tftools bollingerbands} creates three new variables: middle_band, upper_band and lower_band.
Calculation is based on the {it:tsset}.
{p_end}

{synoptset 16 tabbed}
{synopthdr}
{synoptline}
{synopt:{opt symbol}} is the variable that the Bollinger band calculation is based upon (usually the stock symbol that contains the daily prices).{p_end}
{synopt:{opt generate}} is the new variable prefix for the calculated Bollinger band values.{p_end}
{synopt:{opt period}} is the window for which standard deviation and simple moving average are calculated. Default is 20. {p_end}
{synopt:{opt sdevs}} is the factor that is multiplied by the standard deviation. Default is 2. {p_end}
{synoptline}

{title:Example}
{pstd}freduse SP500, clear{p_end}
{pstd}drop if SP500==.{p_end}
{pstd}drop date{p_end}
{pstd}rename daten date{p_end}
{pstd}gen obs=_n{p_end}
{pstd}tsset obs{p_end}
{pstd}tftools bollingerbands if year(date)>2015, symbol(SP500) generate(SP500_BB){p_end}
{pstd}twoway (line SP500 date) (line SP500_BB_upper_band date) (line SP500_BB_lower_band date) if year(date)>2015{p_end}

{title:Authors}
{pstd}{hi:Mehmet F. Dicle}, Loyola University New Orleans, USA ({hi:mfdicle@gmail.com}){p_end}
{pstd}{hi:John Levendis}, Loyola University New Orleans, USA{p_end}
