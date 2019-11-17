*! version 1.0.2 10mar2012 Daniel Klein

pr des2
	vers 9.2
	
	* prefix
	gettoken call exec : 0 ,p(":")
	if (`"`macval(call)'"' != `"`macval(0)'"') {
		if (`"`macval(call)'"' != ":") {
			loc 0 `call'
			gettoken col exec : exec ,p(":")
			if (`"`macval(exec)'"' == "") err 198
		}
		else loc 0
	}
	
	syntax [varlist(default = none)] /*
	*/ [ , /*
	*/ VARWidth(numlist int max = 1 >=14 <=32) /*
	*/ VALWidth(numlist int max = 1 >=11 <=32) /*
	*/ Short /* undocumented
	*/ CMD(str) /*
	*/ * /*
	*/ ]
	
	* set command
	if ("`options'" != "") {
		if ("`cmd'" != "") {
			di as err "`options' not allowed with cmd()"
			e 198
		}
		loc cmd `options'
	}
	if ("`cmd'" == "") loc cmd tabulate
	mata : st_local("at", strofreal(strpos(st_local("cmd"), "@")))
	if !(`at') loc cmd `cmd' @
	
	* r(varlist)
	if (`"`macval(exec)'"' != "") {
		cap `exec'
		if _rc `exec'
		loc varlist `varlist' `r(varlist)'
		if ("`varlist'" == "") e 0 // done
	}
	
	* check varlist
	if ("`varlist'" == "") {
		
			// header
		di as txt _n "File: " as res c(filename)
		di as txt "Date: " as res c(filedate)
		di as txt "obs: " _col(7) as res c(N)
		di as txt "vars: " _col(7) as res c(k)
		if ("`short'" != "") | (c(k) == 0) e 0 // done
		unab varlist : _all
	}
	
	* setting
	if ("`varwidth'" == "") loc varwidth 15
	if ("`valwidth'" == "") loc valwidth 12
	
	loc c1 = `varwidth' + 2
	loc c2 = `c1' + 8
	loc c3 = `c2' + 10
	loc c4 = `c3' + `valwidth' + 2

	* header2
	di as txt _n "variable name" _col(`c1') "type" /*
	*/ _col(`c2') "format" _col(`c3') "value label" /*
	*/ _col(`c4') "variable label" _n
	
	* output
	foreach v of loc varlist {
		loc nam = abbrev("`v'", `varwidth')
		loc ty : t `v'
		loc fmt : f `v'
		loc lb = abbrev("`: val l `v''", `valwidth')
		if ("`lb'" != "") {
			loc add _col(`c3') "{stata label list `lb':`lb'}"
		}
		else loc add
		loc varl : var l `v'
		
		loc _cpycmd : subinstr loc cmd "@" "`nam'" ,all
		di `"{stata `"`_cpycmd'"':{bf:`nam'}}"' /*
		*/ _col(`c1') as txt "`ty'" _col(`c2') "`fmt'" /*
		*/ `add' _col(`c4') as res `"`macval(varl)'"'
	}
end
e

1.0.2	10mar2012	may be used as prefix for commands returning r(varlist)
1.0.1	14nov2011	fix bug (variable labels containing quotes)
1.0.0	15oct2011	sent to SSC (beta)
