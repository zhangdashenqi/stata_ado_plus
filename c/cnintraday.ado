program cnintraday
version 12.0
syntax anything(name=tickers),  [date(string) path(string)]

local currentdate: di %tdCY-N-D date("`c(current_date)'","DMY")
if "`date'" == "" local date "`currentdate'"
if "`date'" != "" {
	if length("`date'") != 10 {
		disp as error `"`date' is an invalid date"'
		exit 601
	}
}
if "`path'" != "" capture mkdir `path'
if "`path'" == "" {
	local path `c(pwd)'
	di "`path'"
}
foreach name in `tickers' {
	if length("`name'")>6 {
		disp as error `"`name' is an invalid stock code"'
		exit 601
	} 
	while length("`name'")<6 {
		local name = "0"+"`name'"
	}
	qui {
		if "`date'" == "`currentdate'" {
			cap postclose td
			postfile td str8 time price str10 chngprc volume transaction str9 tradedirection using `path'/`name'_`date'.dta, replace
			if `name'>=600000 {
				forvalues i = 1/10000 {
					cap copy `"http://vip.stock.finance.sina.com.cn/quotes_service/view/vMS_tradedetail.php?symbol=sh`name'&date=`date'&page=`i'"' "temp.txt",replace
					if _rc == 2 {
						clear
						exit 2
					}
					if `i' == 1 & _rc~=0 & _rc!=2 {
						clear
						disp as error `"please check the date and stock code"'
						exit 601
					}
					if c(stata_version) >= 14 {
						clear
						unicode encoding set gb18030
						unicode translate temp.txt, transutf8
						unicode erasebackups, badidea
					}
					infix strL v 1-200000 using temp.txt, clear
					keep if index(v,"</th></tr>")
					if _N == 0 {
						continue, break
					}
					split v, p("<th>" "</th>" "<td>" "</td>")
					keep v2 v4 v8 v10 v12 v14
					destring v4 v10 v12, ignore(",") replace
					replace v14 = regexs(1) if regexm(v14,">(.+)<")
					forvalues j = 1/`=_N' {
						post td (v2[`j']) (v4[`j']) (v8[`j']) (v10[`j']) (v12[`j']) (v14[`j'])
					}
				}
			}
			else {
				forvalues i = 1/10000 {
					cap copy `"http://vip.stock.finance.sina.com.cn/quotes_service/view/vMS_tradedetail.php?symbol=sz`name'&date=`date'&page=`i'"' "temp.txt",replace
					if _rc == 2 {
						clear
						exit 2
					}
					if `i' == 1 & _rc~=0 & _rc != 2{
						clear
						disp as error `"please check the date and stock code"'
						exit 601
					}
					if c(stata_version) >= 14 {
						clear
						unicode encoding set gb18030
						unicode translate temp.txt, transutf8
						unicode erasebackups, badidea
					}
					infix strL v 1-200000 using temp.txt, clear
					keep if index(v,"</th></tr>")
					if _N == 0 {
						continue, break
					}
					split v, p("<th>" "</th>" "<td>" "</td>")
					keep v2 v4 v8 v10 v12 v14
					destring v4 v10 v12, ignore(",") replace
					replace v14 = regexs(1) if regexm(v14,">(.+)<")
					forvalues j = 1/`=_N' {
						post td (v2[`j']) (v4[`j']) (v8[`j']) (v10[`j']) (v12[`j']) (v14[`j'])
					}
				}
			}
			postclose td
			erase temp.txt
			use `path'/`name'_`date'.dta,clear
			if _N == 0 {
				clear
				erase `path'/`name'_`date'.dta
				disp as error `"please check the date and stock code"'
				exit 601
			}
		}
		else {
			if `name'>=600000 {
				cap copy `"http://market.finance.sina.com.cn/downxls.php?date=`date'&symbol=sh`name'"' "temp.csv",replace
			}
			else {
				cap copy `"http://market.finance.sina.com.cn/downxls.php?date=`date'&symbol=sz`name'"' "temp.csv",replace
			}
			if _rc == 2 {
				clear
				exit 2
			}
			if _rc~=0 & _rc != 2 {
				clear
				disp as error `"please check the date and stock code"'
				exit 601
			}
			if c(stata_version) >= 14 {
				clear
				unicode encoding set gb18030
				unicode translate temp.csv, transutf8
				unicode erasebackups, badidea
			}
			insheet using temp.csv, clear
			if _N == 4 {
				if index(v[1],"javascript") {
					clear
					erase temp.csv
					disp as error `"please check the date and stock code"'
					exit 601
				}
			}
			if c(stata_version) >= 14 {
				rename 成交时间 time
				rename 成交价 price
				rename 价格变动 chngprc
				rename 成交量手 volume
				rename 成交额元 transaction
				rename 性质 tradedirection
			}
			else {
				rename v1 time
				rename v2 price
				rename v3 chngprc
				rename v4 volume
				rename v5 transaction
				rename v6 tradedirection
			}
			erase temp.csv
		}
		sort time
		gen stkcd = "`name'"
		label var stkcd "Stock Code"
		gen date = "`date'"
		label var date "Trading Date"
		label var time "Trading Time"
		label var price "Trading Price"
		label var chngprc "Price Change"
		label var volume "Trading volume(hundred shares)"
		label var transaction "Trading Amount in RMB"
		label var tradedirection "Buying, Selling or Neutral"
		if c(stata_version) >= 14 {
			replace tradedirection = "Buying" if tradedirection == "买盘"
			replace tradedirection = "Selling" if tradedirection == "卖盘"
			replace tradedirection = "Neutral" if tradedirection == "中性盘"
		}
		else {
			replace tradedirection = "Buying" if tradedirection == "����"
			replace tradedirection = "Selling" if tradedirection == "����"
			replace tradedirection = "Neutral" if tradedirection == "������"
		}
		order stkcd date
		sort time
		drop if time == ""
		drop if price == 0
		drop if tradedirection == "--"
		duplicates drop
		cap destring chngprc, ignore("+") force replace float
		replace chngprc = 0 if chngprc == .
		replace chngprc = . if chngprc == price
	}
	save `"`path'/`name'_`date'.dta"', replace
	di as text "You've got the `name''s trading detail data in `date'"
}
end
