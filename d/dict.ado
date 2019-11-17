*! 1.0.1 程振兴 2017年12月25日
*! 0.0.1 2017年12月22日修复了无法分离出网络释义的问题
*! 1.0.0 2017年12月25日增加了中文翻译成英文的功能
*! 1.0.1 2017年12月29日增加了依赖库，规范了dict命令
*! 2.0.0 2018年01月12日增加了句子的中英互译。
capture program drop dict
program define dict
	version 12.0
	syntax anything(name = content), [NOsplit Sentence Cite]
	clear all 
	qui set more off, permanently

	foreach word in `content'{
		if "`sentence'" == ""{
			if ustrregexm("`word'", "[\u4e00-\u9fa5]+"){
				qui{
					percentencode "`word'"
					local a = "`r(percentencode)'"
					copy "http://cn.bing.com/dict/search?q=`a'&qs=n&form=Z9LH5&sp=-1&pq=`a'&sc=2-2&sk=&cvid=F0EB8DBE335C4C6683304A4D16ECD8FB" temp.txt, replace
					local times = 0
					while _rc != 0{
						local times = `times' + 1
						sleep 1000
						qui cap copy "http://cn.bing.com/dict/search?q=`a'&qs=n&form=Z9LH5&sp=-1&pq=`a'&sc=2-2&sk=&cvid=F0EB8DBE335C4C6683304A4D16ECD8FB" temp.txt, replace
						if `times' > 10{
							di as error "错误！：因为你的网络速度贼慢，无法获得数据"
							exit 601
						}
					}
					cap unicode encoding set gb18030
					cap unicode translate temp.txt
					cap unicode erasebackups, badidea
					infix strL v 1-20000 using temp.txt, clear
					keep if index(v, "<title>")
					replace v = subinstr(v, "网络释义：", "net.", .)
					set obs 13
					gen v2 = _n - 3
					gen v3 = _n
					tostring v2, replace
					tostring v3, replace
					replace v2 = "【词语】" if v2 == "-2"
					replace v2 = "【拼音】" if v2 == "-1"
					replace v2 = "【英语】" if v2 == "0"
					replace v3 = "`word'" if v3 == "1"
					replace v3 = ustrregexs(0) if ustrregexm(v[1],"\[(.*)\]") & v3 == "2"
					replace v3 = subinstr(v3, "]", "", .)
					replace v3 = subinstr(v3, "[", "", .)
					replace v3 = ustrregexs(0) if ustrregexm(v[1], "，[a-z].(.*)；") & v3 == "3"
					replace v3 = subinstr(v3, "，", "", .)
					gen strL a = v3[3] in 1
					cap which moss
					if _rc != 0{
						ssc install moss
						di as yellow "由于这是你第一次运行该命令且你的电脑上没有安装moss命令，已自动为你安装moss命令。"
					}
					moss a, match("([a-z]+\.+?)") regex unicode
					levelsof _count, local(b)
					local c = `b' + 3
					forval i = 4/`c'{
						local j = `i' - 3
						replace v2 = _match`j'[1] if v2 == "`j'"
					}
					drop if _n > `c'
					global p = ""
					forval i = 1/`b'{
						global p = "$p" + " " + _match`i'
					}
					keep v v2 v3
					split v3 if v3[_n+1] == "4", parse($p)
					local j = 2
					forval i = 4/`c'{
						replace v3 = v3`j'[3] if v3 == "`i'"
						local j = `j' + 1
					}
					replace v3 = "" if v2 == "【英语】" 
					keep v2 v3
					rename v2 a
					rename v3 b
					replace b = subinstr(b, "2", "", .)
					format b %-50s
					compress
					cap erase temp.txt
				}
				forval i = 1/`=_N'{
					local temp = a[`i']
					if "`temp'" == "【单词】"{
						local temp = "word"
					}
					if "`temp'" == "【读音】"{
						local temp = "prounciation"
					}
					if "`temp'" == "【释义】"{
						local temp = "means"
					}
					di as text a[`i'] + ":" + b[`i']
				}
				if "`nosplit'" == ""{
					di as yellow "----------------------------------------------------------"
				}
			}
			else{
				qui{
					copy "http://cn.bing.com/dict/search?q=`word'&qs=n&form=Z9LH5&sp=-1&pq=`word'&sc=7-3&sk=&cvid=E8E3C113211944A69B575B5DA2C9009A" temp.txt, replace
					local times = 0
					while _rc != 0{
						local times = `times' + 1
						sleep 1000
						qui cap copy "http://cn.bing.com/dict/search?q=`word'&qs=n&form=Z9LH5&sp=-1&pq=`word'&sc=7-3&sk=&cvid=E8E3C113211944A69B575B5DA2C9009A" temp.txt, replace
						if `times' > 10{
							di as error "错误！：因为你的网络速度贼慢，无法获得数据"
							exit 601
						}
					}
					cap unicode encoding set gb18030
					cap unicode translate temp.txt
					cap unicode erasebackups, badidea
					infix strL v 1-20000 using temp.txt, clear
					keep if index(v, "keywords")
					set obs 13
					gen v2 = _n - 3
					gen v3 = _n
					tostring v2, replace
					tostring v3, replace
					replace v2 = "【单词】" if v2 == "-2"
					replace v2 = "【读音】" if v2 == "-1"
					replace v2 = "【释义】" if v2 == "0"
					replace v3 = "`word'" if v3 == "1"
					replace v3 = ustrregexs(0) if ustrregexm(v[1],"美\[(.*)\]") & v3 == "2"
					replace v = subinstr(v, " ", "", .)
					replace v3 = ustrregexs(0) if ustrregexm(v[1], "，[a-z].(.*)；") & v3 == "3"
					replace v3 = subinstr(v3, "，", "", .)
					replace v2 = ustrregexs(2) if ustrregexm(v3[3],"([a-z]+\.+?)") & v2 == "8"
					gen strL a = v3[3] in 1
					cap which moss
					if _rc != 0{
						ssc install moss
						di as yellow "由于这是你第一次运行该命令且你的电脑上没有安装moss命令，已自动为你安装moss命令。"
					}
					moss a, match("([a-z]+\.+?)") regex unicode
					levelsof _count, local(b)
					local c = `b' + 3
					forval i = 4/`c'{
						local j = `i' - 3
						replace v2 = _match`j'[1] if v2 == "`j'"
					}
					drop if _n > `c'
					global p = ""
					forval i = 1/`b'{
						global p = "$p" + " " + _match`i'
					}
					keep v v2 v3
					split v3 if v3[_n+1] == "4", parse($p)
					local j = 2
					forval i = 4/`c'{
						replace v3 = v3`j'[3] if v3 == "`i'"
						local j = `j' + 1
					}
					replace v3 = "" if v2 == "【释义】" 
					keep v2 v3
					rename v2 a
					rename v3 b
					format b %-50s
					compress
					cap erase temp.txt 
					if index(b[_N], "网络释义"){
						split b if index(b[_N], "网络释义"), parse(网络释义：)
					}
					local obs = `c' + 1
					set obs `obs'
					replace a = "net." if a == ""
					replace b = b2[_n-1] if b == ""
					replace b = b1 if index(b, "网络释义")
					keep a b
					replace b = "`word'" if a == "【单词】"
				}
				forval i = 1/`=_N'{
					local temp = a[`i']
					if "`temp'" == "【单词】"{
						local temp = "word"
					}
					if "`temp'" == "【读音】"{
						local temp = "prounciation"
					}
					if "`temp'" == "【释义】"{
						local temp = "means"
					}
					di as text a[`i'] + ":" + b[`i']
				}
				if "`nosplit'" == ""{
					di as yellow _dup(60) "-"
				}
			}
		}
		if "`sentence'" != ""{
			qui percentencode "`word'"
			local b = "`r(percentencode)'"
			qui copy "http://www.youdao.com/w/`b'/#keyfrom=dict2.top" temp.txt, replace
			local times = 0
			while _rc != 0{
				local times = `times' + 1
				sleep 1000
				qui cap copy "http://www.youdao.com/w/`a'/#keyfrom=dict2.top" temp.txt, replace
				if `times' > 10{
					di as error "错误！：因为你的网络速度贼慢，无法获得数据"
					exit 601
				}
			}
			cap unicode encoding set gb18030
			cap unicode translate temp.txt
			cap unicode erasebackups, badidea
			qui infix strL v 1-20000 using temp.txt, clear
			qui keep if index(v[_n+1], "机器翻译")
			qui replace v = ustrregexs(1) if ustrregexm(v[1],">(.*)<")
			local c = v[1]
			di as text "【原文】：`word'"
			di as text "【译文】：`c'"
			if "`nosplit'" == ""{
				di as yellow _dup(60) "-"
			}
		}
	}
	if "`cite'" != ""{
		di as yellow "程振兴. dict: 使用Stata进行中英文转换. version: 2.0.0. 2017.12.21"
	}
	cap erase temp.txt
end


