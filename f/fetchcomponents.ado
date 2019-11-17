*! version 1.0
*! November 16, 2011
*! Author: Mehmet F. Dicle, mfdicle@gmail.com

program define fetchcomponents, rclass
	
	version 10.0

	syntax , symbol(string) [page(integer 0)]
	
	qui: {
	
		forval aa=0/`page' {
			noi: di "Page: `aa'"
			if (`aa'>0) {
				save temp000001.dta, replace
			}

			clear
			mata: financial_data("`symbol'",`aa')

			capture: split myvar, gen(var) parse("</td>")
			* "
			if (_rc==0) {
				drop myvar
				split var1, gen(var1) parse(">")
				* "
				order var11 var12 
				drop var1 var12
				rename var11 var1

				rename var1 Symbol
				keep Symbol
				drop if Symbol==char(13)
				compress
				
				if (`aa'>0) {
					append using temp000001.dta
					erase temp000001.dta
				}
				
				duplicates drop
				sort Symbol
			}
			else {
				if (`aa'>0) {
					use temp000001.dta, clear
					erase temp000001.dta
				}
				else {
					noi: di "There is no data to download!"
				}
			}
		}
	}
	
end


mata:
	void financial_data (string scalar ne, real scalar sayfa)
	{
		fetch ="http://finance.yahoo.com/q/cp?s=" + ne + "&c=" + strofreal(sayfa)
		fh = fopen(fetch, "r")
		icerik=""
		while ((line=fget(fh))!=J(0,0,"")) {
			icerik=icerik+line
		}
		fclose(fh)

		yer_bas = strpos(icerik, "Components for " + ne) + 1;
		datam = substr (icerik, yer_bas, .)

		yer_bas = strpos(datam, "<table") + 1;
		datam = substr (datam, yer_bas, .)

		yer_bas = strpos(datam, "<table");
		datam = substr (datam, yer_bas, .)

		yer_son = strpos(datam, "</table") - 1; 	
		datam = substr (datam, 1, yer_son)
		
		datam = subinstr(datam, char(34), "")
		datam = subinstr(datam, char(9), "")
		datam = subinstr(datam, char(13), "")
		datam = subinstr(datam, char(2), "")
		datam = subinstr(datam, "</td></tr>", char(13))
		datam = subinstr(datam, "<td class=yfnc_tabledata1>", "")
		datam = subinstr(datam, "<td class=yfnc_tabledata1 align=right>", "")
		datam = subinstr(datam, "<img width=10 height=14 border=0 src=http://l.yimg.com/a/i/us/fi/03rd/up_g.gif alt=Up>", "")
		datam = subinstr(datam, "<img width=10 height=14 border=0 src=http://l.yimg.com/a/i/us/fi/03rd/down_r.gif alt=Down>", "")

		datam = subinstr(datam, "<b>", "")
		datam = subinstr(datam, "</b>", "")
		datam = subinstr(datam, "</a>", "")
		datam = subinstr(datam, "<b>", "")
		datam = subinstr(datam, "<small>", "")
		datam = subinstr(datam, "</small>", "")
		datam = subinstr(datam, "</nobr>", "")
		datam = subinstr(datam, "<nobr>", "")
		datam = subinstr(datam, "<b style=color:#008800;>", "")
		datam = subinstr(datam, "<b style=color:#cc0000;>", "")
		datam = subinstr(datam, "<a href=/q?s=", "")
		datam = subinstr(datam, "<table width=100% cellpadding=2 cellspacing=1 border=0>", "")
		
		yer_bas = strpos(datam, "<tr>") + 1;
		datam = substr (datam, yer_bas, .)
		yer_bas = strpos(datam, "<tr>");
		datam = substr (datam, yer_bas, .)

		datam = subinstr(datam, "<td>", "")
		datam = subinstr(datam, "<tr>", "")
		datam = subinstr(datam, "  ", " ")
		datam = subinstr(datam, "  ", " ")
		datam = subinstr(datam, "  ", " ")

		satir = tokens(datam, char(13))
		sutun=satir'
		
		st_addvar("str244", "myvar")
		st_addobs(rows(sutun))
		st_sstore(.,"myvar",sutun)
			
	}
end



