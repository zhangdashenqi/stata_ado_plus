program chinaaddress
	version 14.0
	syntax, baidukey(string) LATitude(string) LONGitude(string) [PROvince(string) CITy(string) DIStrict(string) STReet(string) ADDress(string) DEScription(string)]

	quietly {
		tempvar baidumap
		if "`province'"    == "" local province    province
		if "`city'"        == "" local city        city
		if "`district'"    == "" local district    district
		if "`street'"      == "" local street      street
		if "`address'"     == "" local address     address
		if "`description'" == "" local description discription

		gen `baidumap' = ""
		forvalues i = 1/`=_N' {
			if `latitude'[`i'] == . | `longitude'[`i'] == . {
				noisily di as text "the latitude|longitude is missing and no address can be extracted in `i'"
				continue
			}
			replace `baidumap' = fileread(`"http://api.map.baidu.com/geocoder/v2/?output=json&ak=`baidukey'&location=`=string(`latitude'[`i'])',`=string(`longitude'[`i'])'"') in `i'
			local times = 0
			while filereaderror(`baidumap'[`i']) != 0 {
				local times = `times' + 1
				replace `baidumap' = fileread(`"http://api.map.baidu.com/geocoder/v2/?output=json&ak=`baidukey'&location=`=string(`latitude'[`i'])',`=string(`longitude'[`i'])'"') in `i'
				if `times' > 10 {
					disp as error "Internet speeds is too low to get the data"
					exit `=filereaderror(`baidumap'[`i'])'
				}
			}
			if index(`baidumap'[`i'],"AK有误请检查再重试") {
				di as error "error: please check your baidukey"
				continue,break
			}
			else if index(`baidumap'[`i'],`"address":"",""') {
				noisily di as text "the location is wrong and no address can be extracted in `i'"
				replace `baidumap' = "" in `i'
			}
		}
		gen `province'    = ustrregexs(1) if ustrregexm(`baidumap',`"province":"(.*?)",""')
		gen `city'        = ustrregexs(1) if ustrregexm(`baidumap',`"city":"(.*?)",""')
		gen `district'    = ustrregexs(1) if ustrregexm(`baidumap',`"district":"(.*?)",""')
		gen `street'      = ustrregexs(1) if ustrregexm(`baidumap',`"street":"(.*?)",""')
		gen `address'     = ustrregexs(1) if ustrregexm(`baidumap',`"address":"(.*?)",""')
		gen `description' = ustrregexs(1) if ustrregexm(`baidumap',`"description":"(.*?)",""')

	}
end
