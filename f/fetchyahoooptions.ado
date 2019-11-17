*! version 1.0
*! December 10, 2011
*! Author: Mehmet F. Dicle, mfdicle@gmail.com

program define fetchyahoooptions, rclass
	
	version 10.0
	
	syntax anything(name=tickers), m(string) [iv(real 0.0001)]
	
	local downloaded=0

	qui: {
		foreach name in `tickers' {
			foreach tarih in `m' {
				clear 
				* Some symbols contain special characters (ex. .,-,^). These need to be kept the same for downloading the data from Yahoo! Finance
				* However, special characters need to be replaced to be used as Stata variables. 
				local name2 :subinstr local name "." "_", all
				local name2 :subinstr local name2 "^" "_", all
				local name2 :subinstr local name2 "-" "_", all

				mata: get_options("`name'","`tarih'")

				capture: split myvar, parse("</td>") gen(mfd)
				if (_rc==0) {
					local downloaded=1
					replace IRX=IRX/100
					rename mfd1 Strike
					rename mfd2 Symbol
					rename mfd3 Last
					rename mfd4 Change
					rename mfd5 Bid
					rename mfd6 Ask
					rename mfd7 Volume
					rename mfd8 Open_Interest
					drop myvar
					drop if Symbol==""
					destring Strike Last Change Bid Ask Volume Open_Interest, replace force
					gen Type="Call" if substr(Symbol,length("`name'")+7,1)=="c"
					replace Type="Put" if substr(Symbol,length("`name'")+7,1)=="p"
					gen Maturity=date(substr(Symbol,length("`name'")+1,6),"YMD",2100) 
					format Maturity %td
					gen Underlying = upper("`name'")
					order Underlying Maturity Type Symbol 
					save temp_0000_`name2'_`tarih'.dta, replace
					noi: di "Options data for `name' (`tarih') are downloaded."
				}
			}
		}

		// append downloaded files
		if (`downloaded'==1) { 
			local ilk=1
			foreach name in `tickers' {
				foreach tarih in `m' {
					* Some symbols contain special characters (ex. .,-,^). These need to be kept the same for downloading the data from Yahoo! Finance
					* However, special characters need to be replaced to be used as Stata variables. 
					local name2 :subinstr local name "." "_", all
					local name2 :subinstr local name2 "^" "_", all
					local name2 :subinstr local name2 "-" "_", all

					if (`ilk'==0)  {
						capture: append using "temp_0000_`name2'_`tarih'.dta"
						if (_rc==0) erase "temp_0000_`name2'_`tarih'.dta"
					}
					if (`ilk'==1)  {
						capture: use "temp_0000_`name2'_`tarih'.dta", clear
						if (_rc==0) {
							erase "temp_0000_`name2'_`tarih'.dta"
							local ilk=0
						}
					}
				}
			}
		}
		
		capture: sort Underlying Maturity Type Strike		

		if (`downloaded'==1) {			
			if ("`iv'"!="") {
				gen T=(Maturity-date(c(current_date),"DMY"))/360
				label variable T "Years to maturity"
				sort Underlying Maturity T Type Strike		

				gen d1=.
				gen d2=.
				gen Call=.
				gen Put=.
				gen IV=.
				label variable IV "Implied Volatility"
			
				forval aa=0(`iv')1 {
					replace d1=(ln(Price/Strike) + ((IRX + ((`aa'^2)/2))*T)) / (`aa'*(T^.5)) if IV==.
					replace d2=d1-(`aa'*(T^.5)) if IV==.
					replace Call=(Price*normal(d1))-(Strike*exp(-IRX*T)*normal(d2)) if IV==.
					replace Put=(Strike*exp(-IRX*T)*normal(-d2))-(Price*normal(-d1)) if IV==.
					replace IV=`aa' if ((Type=="Call") & (round(Call,0.01)==round(Ask,0.01)) & (IV==.)) | ((Type=="Put") & (round(Put,0.01)==round(Ask,0.01)) & (IV==.))
				}
				drop Call Put d1 d2 T
			}
		}
		capture: drop IRX
	}
	
	if (`downloaded'==0) {
		di as err "There are no option prices available for the selected symbols and maturity dates!"
	}
	
end



mata:
	void get_options (string scalar symbol, string scalar month)
	{
		icerik = file_get_contents("http://finance.yahoo.com/q/op?s=" + symbol + "&m=" + month)
		price = get_price(icerik,symbol)
		isthere = check_table (icerik,"Strike")
		if (isthere) {
			tablo = get_table (icerik,"table","Strike")
			tablo2 = get_table2 (icerik,"table","Strike")
			bos=table_data (tablo + tablo2)
		}
		stata("gen Price = " + price)
		icerik_rf = file_get_contents("http://finance.yahoo.com/q?s=^IRX")
		price_rf = get_price(icerik_rf,"^IRX")
		stata("gen IRX = " + price_rf)
	}

	// clean inside the tags. i.e. <td height="3"> to <td>
	string clean_tags (string scalar raw, string scalar tag)
	{
		while (strpos(raw, "<" + tag + " ")) {
			bas_pos = strpos(raw, "<" + tag + " ")
			bas_txt = substr (raw, 1, bas_pos - 1 + strlen("<" + tag))
			
			son_txt = substr (raw, bas_pos + strlen("<" + tag), .)
			son_pos = strpos(son_txt, ">")
			son_txt = substr (son_txt, son_pos, .)
			
			raw = bas_txt + son_txt
		}
		return (raw)
	}


	// remove select tags from a string
	string strip_select_tags (string scalar raw, string scalar tag)
	{
		while (strpos(raw, "<" + tag)) {
			bas_pos = strpos(raw, "<" + tag)
			bas_txt = substr (raw, 1, bas_pos - 1)
			son_txt = substr (raw, bas_pos + strlen("<" + tag + ">"), .)
			raw = bas_txt + son_txt
			
			bas_pos = strpos(raw, "</" + tag)
			if (bas_pos) {
				bas_txt = substr (raw, 1, bas_pos - 1)
				son_txt = substr (raw, bas_pos + strlen("</" + tag + ">"), .)
				raw = bas_txt + son_txt
			}
		}
		return (raw)
	}

	// remove tags from a string
	string strip_tags (string scalar raw)
	{
		tags = ("tr", "TR", "td", "TD", "strong", "STRONG", "/strong", "/STRONG", "span", "SPAN", "/span", "/SPAN", "img", "IMG", "/img", "/IMG", "br", "BR", "!-", "table", "TABLE", "/table", "/TABLE")
		for (j=1; j<=cols(tags); j++) {
			tag = tags[j]
			while (strpos(raw, "<" + tag)) {
				bas_pos = strpos(raw, "<" + tag)
				bas_txt = substr (raw, 1, bas_pos - 1)
				son_txt = substr (raw, bas_pos + strlen("<" + tag + ">"), .)
				raw = bas_txt + son_txt
			}
		}
		return (raw)
	}

	// remove a tag with its content
	string remove_tags (string scalar raw, string scalar tag)
	{
		while (strpos(strlower(raw), "<" + tag)) {
			bas_pos = strpos(strlower(raw), "<" + tag)
			bas_txt = substr (raw, 1, bas_pos - 1)
			son_txt = substr (raw, bas_pos, .)
			bas_pos2 = strpos(strlower(son_txt), "</" + tag + ">") + 3 + strlen(tag)
			son_txt = substr (son_txt, bas_pos2 + 1, .)
			raw = bas_txt + son_txt
		}
		return (raw)
	}
	
	// get contents within a tag
	string between_tags (string scalar raw, string scalar tag)
	{
		bas_pos = strpos(strlower(raw), "<"  + tag + ">") + 2 + strlen(tag)
		son_pos = strpos(strlower(raw), "</" + tag)
		txt_length = son_pos - bas_pos
		output = substr (raw, bas_pos, txt_length)
		return (output)
	}

	// get current price
	string get_price (string scalar raw, string scalar ticker)
	{
		bas_pos = strpos(strlower(raw), "<span id=" + char(34) + "yfs_l10_" + strlower(ticker) + char(34) + ">") + strlen(ticker) + 20
		if (bas_pos<100) bas_pos = strpos(strlower(raw), "<span id=" + char(34) + "yfs_l84_" + strlower(ticker) + char(34) + ">") + strlen(ticker) + 20
		if (bas_pos>100) { 
			output = substr (raw, bas_pos, .)
			son_pos = strpos(strlower(output), "</span>")
			output = substr (output, 1, son_pos-1)
		}
		if (bas_pos<100) output = cat("http://download.finance.yahoo.com/d/quotes.csv?s=" + ticker + "&f=l1")
		// There was a problem in the previous versions of the code because parsed Yahoo Finance page has changed.
		// Thanks to Ashton Verdery, the line above is used if Yahoo Finance options page does not contain labels yfs_l10 or yfs_l84
		return (output)
	}

	// check whether this is an actual options page. i.e. if there are any options.
	real check_table (string scalar raw, string scalar aranan)
	{
		kalan = strpos(strlower(raw), strlower(aranan))
		return (kalan)
	}
	
	// get position in a text. i.e. position of <table> before the heading of Return (Mkt)
	string get_table (string scalar raw, string scalar tag, string scalar aranan)
	{
		kalan = strlower(raw)
		while (strpos(kalan, "<" + strlower(tag)) < strpos(kalan, strlower(aranan))) {
			kalan = substr (kalan, strpos(kalan, "<" + strlower(tag)) + 2 + strlen(tag), .)
		}
		kalan = "<" + strlower(tag) + " " + kalan
		
		son_pos = strpos(kalan, "</" + strlower(tag))
		kalan=substr(kalan, 1, son_pos + 2 + strlen(tag))

		return (kalan)
	}

	// get the second position in a text. i.e. position of <table> before the heading of Return (Mkt)
	string get_table2 (string scalar raw, string scalar tag, string scalar aranan)
	{
		kalan = strlower(raw)
		kalan = substr(kalan, strpos(kalan, strlower(aranan)) + strlen(aranan), .)
		kalan = get_table(kalan,tag,aranan)
		return (kalan)
	}
	
	// remove double space from a string
	string remove_space (string scalar raw)
	{
		while (strpos(raw, "  ")) {
			raw = subinstr(raw, "  ", " ")
		}
		return (raw)
	}

	// get contents of a file as a string
	string file_get_contents (string scalar raw)
	{
		fh = fopen(raw, "r")
		raw=""
		while ((line=fget(fh))!=J(0,0,"")) {
			raw=raw+line
		}
		fclose(fh)
		return (raw)
	}

	// data from html table
	void table_data (string scalar raw)
	{
		datam = raw
		datam = subinstr(datam, char(13), "")
		datam = subinstr(datam, "</tr>", char(13))
		datam = subinstr(datam, "</TR>", char(13))
		datam = subinstr(datam, char(9), "")

		datam = clean_tags (datam, "th")
		datam = clean_tags (datam, "td")
		datam = clean_tags (datam, "a")
		datam = clean_tags (datam, "b")
		datam = clean_tags (datam, "font")
		datam = clean_tags (datam, "img")
		datam = clean_tags (datam, "table")
		datam = clean_tags (datam, "span")
		
		datam = strip_select_tags (datam,"font")
		datam = strip_select_tags (datam,"strong")
		datam = strip_select_tags (datam,"span")
		datam = strip_select_tags (datam,"a")		
		datam = strip_select_tags (datam,"b")
		datam = strip_select_tags (datam,"img")
		
		datam = subinstr(datam, "<tr>", "")
		datam = subinstr(datam, "<td>", "")
		datam = subinstr(datam, "<th>", "")
		
		datam = subinstr(datam, ",", "")
		
		if (strpos(datam, "</td>")) {
			satir = tokens(datam, char(13))
			
			sutun=satir'
			st_addvar("str244", "myvar")
			st_addobs(rows(sutun))
			st_sstore(.,"myvar",sutun)
		}
	}
	
end




