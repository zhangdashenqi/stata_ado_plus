*! version 1.0  Apr 2012 by LQ
*! This program runs example from ht.sthlp and opens internet browser

program htexample
	version 8.2
	if (_caller() < 8.2)  version 8
	else		      version 8.2

	set more off
	`0'
end

program NotSmall
	if "`c(flavor)'"=="Small" {
		window stopbox stop ///
		"Dataset used in this example" ///
		"too large for Small Stata"
	}
end
	

program Msg
	di as txt
	di as txt "-> " as res `"`0'"'
end

program Xeq
	di as txt
	di as txt `"-> "' as res _asis `"`0'"'
	`0'
end

program ex1
	Msg preserve
    Xeq htopen using htexample, replace
    Xeq sysuse auto, clear
    Xeq htput <h1> Statistical Analysis </h1>
    Xeq sum gear_ratio
    Xeq htput This example uses data from `r(N)' automobiles with a mean Gear Ratio of `: di %8.2f r(mean)'
    Xeq htput <h2> Table 1 </h2>
    Xeq htsummary price foreign, head format(%8.2f) test
    Xeq htsummary mpg foreign, format(%8.2f) test
    Xeq recode mpg (min/25 = 0 "Low/Medium") (25/max = 1 "High"), gen(mympg)
    Xeq label var mympg "Mileage (level)"
    Xeq htsummary mympg foreign, freq rowtotal row test
    Xeq htsummary weight foreign, median format(%8.2f) test
    Xeq htsummary length foreign, log format(%8.2f) test close
    Xeq htput <h2> Table 2 </h2>
    Xeq htlog regress weight length
    Xeq twoway (scatter weight length) (lfit weight length) , name(htexample, replace)
    Xeq graph export htexample.png, replace
    Xeq htput <h2> Figure </h2>
    Xeq htput <img src="htexample.png">
    Xeq htclose
    Xeq showex1
	Msg restore
end

program showex1
	Msg preserve
    Xeq if "$S_OS" == "Windows" shell start htexample.html
    Xeq if "$S_OS" != "Windows" shell open htexample.html
	Msg restore
end

