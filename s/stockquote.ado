*! version on 0.1 28dec2008

/*
 stockquote.ado is a "use" command which loads data from the web. 
 It currently can query yahoo financial services for tickers.
 http://ichart.finance.yahoo.com/table.csv?s=AAPL&a=01&b=3&c=1985&d=04&e=4&f=2006&g=d&ignore=.csv
 stockquote AAPL, fm(1) fd(2) fy(1999) lm(3) ld(4) ly(2000) frequency(d)
 Kit: Thanks for streamlining it all to stata-ish.
*/

program def stockquote
version 9.0

syntax anything(name=ticksym), fm(integer) fd(integer) fy(integer) lm(integer) ld(integer) ly(integer) frequency(string)

local url = "http://ichart.finance.yahoo.com/table.csv"

if ("`frequency'" != "d" & "`frequency'" != "w" & "`frequency'" != "m"){
 display as error "frequency may be one of d,w or m"
 exit
}
local bugfm = `fm'-1
local buglm = `lm'-1
tempfile stockquote
capture copy "`url'?s=`ticksym'&a=`bugfm'&b=`fd'&c=`fy'&d=`buglm'&e=`ld'&f=`ly'&g=`frequency'&ignore=.csv" `stockquote'

if _rc != 0{
 display as error "Yahoo does not have this range or could not be reached"
 display "Please make sure you are online and/or redefine your range"
 exit
}
clear
insheet using `stockquote'

gen str mydate = date[_N+1-_n]
drop date
gen str date = mydate
drop mydate
label variable date "Date"

foreach x in  open high low close volume adjclose {
 gen my`x' = `x'[_N+1-_n]
 drop `x'
 gen `x' = my`x'
 drop my`x'
}
label data "Symbol: `ticksym', Source: http://finance.yahoo.com"
label variable  open "Opening price for time period"
label variable  high "High price for time period"
label variable  low "Low price for time period"
label variable  close "Closing price for time period"
label variable  volume "Volume traded for time period"
label variable  adjclose "Adjusted Closing price for time period"
describe

end


