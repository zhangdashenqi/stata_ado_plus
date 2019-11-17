*! Version 0.3 Nov 7, 2019
*! Clickable list of the post from theZenofStata
*! By zhangdashenqi @ theZenofStata
*! Email: zhangqingjun3@qq.com
*! GitHub: https://github.com/zhangdashenqi
*! WeChat Subscription Account: Stata之禅

* 0.1 Initial version
* 0.2 Release version. 
* 	  Date: Sep 27, 2019
* 0.3 Version: repalce source form github to gitee
*	  Date: Nov 7, 2019

cap program drop zstata
program define zstata, rclass
	version 14.0
	syntax [, Gitee]
	if "`gitee'"==""{
		zstata1
	}
	else{
		cap erase info.error
		!curl -V > nul 2>nul ||echo n > info.error
		local e : dir . files info.error
		if `"`e'"'!=""{
			dis "请首先安装curl命令行工具！"
			local cmd !start https://curl.haxx.se/download.html
			dis in w `">> {stata `"`cmd'"':点击进入下载页面}"'
			erase info.error
		}
		if `"`e'"'==""{
			zstata2
		}	
	}
end

cap program drop zstata1
program define zstata1, rclass
	dis in w _n "{c TLC}{hline 60}{c TRC}" _n ///
		 "{c |}{space 22}{bf:the Zen of Stata}{space 22}{c |}" _n ///
		 "{c BLC}{hline 60}{c BRC}"
		 
	_zstata1 Stata-Graph/master/do/
	
	_zstata1 the_zen_of_stata/master/
	
	dis in w "{c TLC}{hline 60}{c TRC}"
	local cmd !start https://github.com/zhangdashenqi
	dis in w `"{c |} >> [{stata `"`cmd'"':Open GitHub}]"' ///
		`"{space 3}打开GitHub{space 30}{c |}"'
	dis in w "{c BLC}{hline 60}{c BRC}"
end


cap program drop _zstata1
program define _zstata1, rclass
	local url "https://raw.githubusercontent.com/zhangdashenqi/"
	local repo `url'`1'readme.md
	copy "`repo'" "list.txt", replace

	preserve
	quietly{
		clear
		set obs 1
		gen v = fileread("list.txt")
		split v, p("### ")
		drop v
		sxpose, clear
		gen item = ustrregexs(1) if ustrregexm(_var1 , `"\d{3}(.+?)\n"')
		gen link = ustrregexs(1) if ustrregexm(_var1 , `"]\(\./(.+?)\)"')
		drop if item==""|link==""
	}
	local url "https://raw.githubusercontent.com/zhangdashenqi/"
	local dolink `url'`1'
	local num = _N

 
	forvalues i = 1(1)`num'{
		local item = item[`i']
		local link = link[`i']
		dis `" [{stata `"copy "`dolink'`link'.do" "`link'.do""':download}]"' ///
			`" [{stata `"doedit "`link'.do""':edit}]"' ///
			`"{res} `item'"'
	}
	
	restore
	erase list.txt
end

cap program drop zstata2
program define zstata2, rclass
	dis in w _n "{c TLC}{hline 60}{c TRC}" _n ///
		 "{c |}{space 22}{bf:the Zen of Stata}{space 22}{c |}" _n ///
		 "{c BLC}{hline 60}{c BRC}"
		 
	_zstata2 Stata-Graph/raw/master/do/
	
	_zstata2 the_zen_of_stata/raw/master/
	
	dis in w "{c TLC}{hline 60}{c TRC}"
	local cmd !start https://github.com/zhangdashenqi
	dis in w `"{c |} >> [{stata `"`cmd'"':Open GitHub}]"' ///
		`"{space 3}打开GitHub{space 30}{c |}"'
	dis in w "{c BLC}{hline 60}{c BRC}"
end


cap program drop _zstata2
program define _zstata2, rclass
	// local url "https://raw.githubusercontent.com/zhangdashenqi/"
	local url "https://gitee.com/zhangdashenqi/"
	local repo `url'`1'readme.md
	!curl "`repo'" -o "list.txt"

	preserve
	quietly{
		clear
		set obs 1
		gen v = fileread("list.txt")
		split v, p("### ")
		drop v
		sxpose, clear
		gen item = ustrregexs(1) if ustrregexm(_var1 , `"\d{3}(.+?)\n"')
		gen link = ustrregexs(1) if ustrregexm(_var1 , `"]\(\./(.+?)\)"')
		drop if item==""|link==""
	}
	// local url "https://raw.githubusercontent.com/zhangdashenqi/"
	local url "https://gitee.com/zhangdashenqi/"
	local dolink `url'`1'
	local num = _N

 
	forvalues i = 1(1)`num'{
		local item = item[`i']
		local link = link[`i']
		dis `" [{stata `"!curl "`dolink'`link'.do" -o "`link'.do""':download}]"' ///
			`" [{stata `"doedit "`link'.do""':edit}]"' ///
			`"{res} `item'"'
	}
	
	restore
	erase list.txt
end

