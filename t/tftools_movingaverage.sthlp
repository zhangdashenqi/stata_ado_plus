{smcl}
{* 22jun2017}{cmd:help tftools movingaverage}
{hline}

{title:Title}
{pstd}{hi:tftools movingaverage} {hline 2} Calculates several different moving averages for a single time-series variable.{p_end}

{title:Syntax}
{pstd}{cmdab:tftools movingaverage [if] [in]}{cmd:, symbol({it: variable}) generate({it: newvar}) period(integer) ma_type(string)}{p_end}

{title:Description}
{pstd}
{it:tftools movingaverage} calculates the moving average for a single time-series variable.
Window for the moving averaging can be specified as well as the type of averaging (i.e. simple or exponential). You can also calculate moving standard deviation as well as moving maximum, minimum and sum. 
{it:tftools movingaverage} creates a new variable. Averaging is based on the {it:tsset}.
{p_end}

{synoptset 16 tabbed}
{synopthdr}
{synoptline}
{synopt:{opt symbol}} is the variable that the moving average calculation is based upon (usually the stock symbol that contains the daily prices).{p_end}
{synopt:{opt generate}} is the new variable prefix for the calculated moving average values.{p_end}
{synopt:{opt period}} is the moving average window. It is based on the tsset command. {p_end}
{synopt:{opt ma_type}} is the moving average type. sma (simple moving average), ema (exponential moving average), sd (moving standard deviation), sum (moving sum), min (moving minimum) and max (moving maximum).{p_end}
{synoptline}

{title:Example}
{pstd}freduse SP500, clear{p_end}
{pstd}drop if SP500==.{p_end}
{pstd}drop date{p_end}
{pstd}rename daten date{p_end}
{pstd}gen obs=_n{p_end}
{pstd}tsset obs{p_end}
{pstd}tftools movingaverage if year(date)>2015, symbol(SP500) generate(SP500) period(100) ma_type(sma){p_end}
{pstd}twoway (line SP500 date) (line SP500_sma_100 date) if year(date)>2015{p_end}

{title:Authors}
{pstd}{hi:Mehmet F. Dicle}, Loyola University New Orleans, USA ({hi:mfdicle@gmail.com}){p_end}
{pstd}{hi:John Levendis}, Loyola University New Orleans, USA{p_end}
