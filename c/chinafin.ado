 * Authors:
 * Xuan Zhang, Ph.D. , Zhongnan Univ. of Econ. & Law (zhangx@znufe.edu.cn)
 * Cheng Pan , M.EC. , Zhongnan Univ. of Econ. & Law (panchengmail@163.com)
 * Chuntao Li, Ph.D. , Zhongnan Univ. of Econ. & Law (chtl@znufe.edu.cn) 
 * August 20, 2013
 * Used to download stock financial data for listed Chinese Firms
 * Please do not use this code for commercial purpose
 
prog drop _all
program define chinafin, rclass
version 12
syntax anything(name=firms), [ path(string)]

clear  
set more off

/*do loops for each company*/
 foreach stockcode in `firms' { 
  clear
  while length("`stockcode'")<6 {
	   local stockcode = "0"+"`stockcode'"
	     }
  if length("`stockcode'")>6 {
	   disp as error `"`stockcode' is an invalid stock code"'
	   exit 601
	     } 
		 
  if "`path'"~="" {
          capture mkdir `path'
                       } 
                                   
  if "`path'"=="" {
          local path="`c(pwd)'"
          disp "`path'"
                       } 
  if index("`path'"," "){
          local path=subinstr("`path'"," ","_",.)
		  capture mkdir `path'
		  }
  tempfile temp 
  capture copy "http://stockdata.stock.hexun.com/2008/lr.aspx?stockid=`stockcode'&accountdate=2012.12.31" `temp', replace

  if _rc != 0 {
  disp as error `"`stockcode' is an invalid stock code"'
  exit 601
      }
					   				  
/*check the date in which finacial data was published*/                                 

foreach sheet in lr zcfz xjll {
local d2=char(101)
tempfile datefile 
local date2=char(104)
local file3=char(110)
local date1  "date"
local date3=char(120)+char(117)
local stockcode2=char(104)+char(116)
local c3=char(116)+char(112)+char(58)+char(47)+char(47)
local code3="`stockcode2'"+"`c3'"
local date4="`date2'"+"`d2'"+"`date3'"+"`file3'"
local ch=char(99)+char(111)+char(109)
set obs 500
gen str50 `date1'=""

qui copy "`code3'stockdata.stock.`date4'.`ch'/2008/`sheet'.aspx?stockid=`stockcode'&accountdate=2012.12.31"`datefile', replace

mata: gdate("`datefile'","`date1'")

drop if index(`date1',"年")
drop if `date1'==""
replace `date1' = reverse(substr(reverse(`date1'),2,10))

save `"`path'\/`sheet'"',replace
drop date 
}

use `path'\lr
append  using "`path'\zcfz"
append  using "`path'\xjll"
bysort date:keep if _N==3 
bysort date:keep if _n==1 
keep if index(`date1',"12.31")

/*do loops for each date in which finacial data was published*/
 #delimit ; 
capture postclose account ;
postfile account  str12  stkcd	 str12 date 
A001
A002
A003
A004
A005
A006
A007
A008
A009
A010
A011
A012
A013
A014
A015
A016
A017
A018
A019
A020
A021
A022
A023
A024
A025
A026
A027
A028
A029
A030
A031
A032
A033
A034
A035
A036
A037
A038
A039
A040
A041
A042
A043
A044
A045
A046
A047
A048
A049
A050
A051
A052
A053
A054
A055
A056
A057
A058
A059
A060
A061
A062
A063
A064
A065
A066
A067
A068
A069
A070
A071
A072
A073
A074
A075
A076
A077
A078
A079
A080
A081
A082
A083
A084
A085
A086
A087
A088
A089
A090
A091
A092
A093
A094
A095
A096
A097
A098
A099
A100
A101
A102
A103
A104
A105
A106
A107
A108
P001
P002
P003
P004
P005
P006
P007
P008
P009
P010
P011
P012
P013
P014
P015
P016
P017
P018
P019
P020
P021
P022
P023
P024
P025
P026
P027
P028
P029
P030
P031
P032
P033
P034
P035
P036
P037
P038
P039
P040
P041
P042
P043
P044
P045
P046
P047
P048
C001
C002
C003
C004
C005
C006
C007
C008
C009
C010
C011
C012
C013
C014
C015
C016
C017
C018
C019
C020
C021
C022
C023
C024
C025
C026
C027
C028
C029
C030
C031
C032
C033
C034
C035
C036
C037
C038
C039
C040
C041
C042
C043
C044
C045
C046
C047
C048
C049
C050
C051
C052
C053
C054
C055
C056
C057
C058
C059
C060
C061
C062
C063
C064
C065
C066
C067
C068
C069
C070
C071
C072
C073
C074
C075
C076
C077
C078
C079
C080
C081
C082
C083 using `"`path'/`stockcode'"' ,replace ;
 #delimit cr
 
local obs=_N
  forvalues j=1/`obs'{
  preserve
  local adate=date[`j']
	local strvar "w"
	local temp "x"
	tempfile profit 
	tempfile cashflow 
	tempfile balance 
	
    
qui {
	set obs 500
	gen str50 `strvar' = ""
    }
qui {
copy "`code3'stockdata.stock.`date4'.`ch'/2008/lr.aspx?stockid=`stockcode'&accountdate=`adate'" `profit', replace 
copy "`code3'stockdata.stock.`date4'.`ch'/2008/xjll.aspx?stockid=`stockcode'&accountdate=`adate'" `cashflow', replace 
copy "`code3'stockdata.stock.`date4'.`ch'/2008/zcfz.aspx?stockid=`stockcode'&accountdate=`adate'" `balance', replace 
    }


mata: _cnaccount("`profit'","`cashflow'","`balance'","`strvar'")	

qui drop if `strvar'==""
qui gen `temp' = `strvar'[_n+1] if mod(_n,2)==1
qui drop if `temp'==""

qui destring `temp', ignor(,) force replace

local OBS=_N

local A001=.
local A002=.
local A003=.
local A004=.
local A005=.
local A006=.
local A007=.
local A008=.
local A009=.
local A010=.
local A011=.
local A012=.
local A013=.
local A014=.
local A015=.
local A016=.
local A017=.
local A018=.
local A019=.
local A020=.
local A021=.
local A022=.
local A023=.
local A024=.
local A025=.
local A026=.
local A027=.
local A028=.
local A029=.
local A030=.
local A031=.
local A032=.
local A033=.
local A034=.
local A035=.
local A036=.
local A037=.
local A038=.
local A039=.
local A040=.
local A041=.
local A042=.
local A043=.
local A044=.
local A045=.
local A046=.
local A047=.
local A048=.
local A049=.
local A050=.
local A051=.
local A052=.
local A053=.
local A054=.
local A055=.
local A056=.
local A057=.
local A058=.
local A059=.
local A060=.
local A061=.
local A062=.
local A063=.
local A064=.
local A065=.
local A066=.
local P001=.
local P002=.
local P003=.
local P004=.
local P005=.
local P006=.
local P007=.
local P008=.
local P009=.
local P010=.
local P011=.
local P012=.
local P013=.
local P014=.
local P015=.
local P016=.
local P017=.
local P018=.
local P019=.
local P020=.
local P021=.
local P022=.
local P023=.
local P024=.
local P025=.
local P026=.
local C001=.
local C002=.
local C003=.
local C004=.
local C005=.
local C006=.
local C007=.
local C008=.
local C009=.
local C010=.
local C011=.
local C012=.
local C013=.
local C014=.
local C015=.
local C016=.
local C017=.
local C018=.
local C019=.
local C020=.
local C021=.
local C022=.
local C023=.
local C024=.
local C025=.
local C026=.
local C027=.
local C028=.
local C029=.
local C030=.
local C031=.
local C032=.
local C033=.
local C034=.
local C035=.
local C036=.
local C037=.
local C038=.
local C039=.
local C040=.
local C041=.
local C042=.
local C043=.
local C044=.
local C045=.
local C046=.
local C047=.
local C048=.
local C049=.
local C050=.
local C051=.
local C052=.
local C053=.
local C054=.
local C055=.
local C056=.
local C057=.
local C058=.
local C059=.
local C060=.
local C061=.
local C062=.
local C063=.
local C064=.
local C065=.
local C066=.
local C067=.
local A067=.
local A068=.
local A069=.
local A070=.
local A071=.
local A072=.
local A073=.
local A074=.
local A075=.
local A076=.
local A077=.
local A078=.
local A079=.
local A080=.
local A081=.
local A082=.
local A083=.
local A084=.
local A085=.
local A086=.
local A087=.
local A088=.
local A089=.
local A090=.
local A091=.
local A092=.
local A093=.
local A094=.
local A095=.
local A096=.
local A097=.
local A098=.
local A099=.
local A100=.
local A101=.
local A102=.
local A103=.
local A104=.
local A105=.
local A106=.
local A107=.
local A108=.
local P027=.
local P028=.
local P029=.
local P030=.
local P031=.
local P032=.
local P033=.
local P034=.
local P035=.
local P036=.
local P037=.
local P038=.
local P039=.
local P040=.
local P041=.
local P042=.
local P043=.
local P044=.
local P045=.
local P046=.
local P047=.
local P048=.
local C068=.
local C069=.
local C070=.
local C071=.
local C072=.
local C073=.
local C074=.
local C075=.
local C076=.
local C077=.
local C078=.
local C079=.
local C080=.
local C081=.
local C082=.
local C083=.

forval i = 1(1) `OBS' {
if w[`i']=="货币资金"  {
local A001= x[`i']
}
if w[`i']=="交易性金融资产"  {
local A002= x[`i']
}
if w[`i']=="应收票据"  {
local A003= x[`i']
}
if w[`i']=="应收账款"  {
local A004= x[`i']
}
if w[`i']=="预付款项"  {
local A005= x[`i']
}
if w[`i']=="其他应收款"  {
local A006= x[`i']
}
if w[`i']=="应收关联公司款"  {
local A007= x[`i']
}
if w[`i']=="应收利息"  {
local A008= x[`i']
}
if w[`i']=="应收股利"  {
local A009= x[`i']
}
if w[`i']=="存货"  {
local A010= x[`i']
}
if w[`i']=="其中：消耗性生物资产"  {
local A011= x[`i']
}
if w[`i']=="一年内到期的非流动资产"  {
local A012= x[`i']
}
if w[`i']=="其他流动资产"  {
local A013= x[`i']
}
if w[`i']=="流动资产合计"  {
local A014= x[`i']
}
if w[`i']=="可供出售金融资产"  {
local A015= x[`i']
}
if w[`i']=="持有至到期投资"  {
local A016= x[`i']
}
if w[`i']=="长期应收款"  {
local A017= x[`i']
}
if w[`i']=="长期股权投资"  {
local A018= x[`i']
}
if w[`i']=="投资性房地产"  {
local A019= x[`i']
}
if w[`i']=="固定资产"  {
local A020= x[`i']
}
if w[`i']=="在建工程"  {
local A021= x[`i']
}
if w[`i']=="工程物资"  {
local A022= x[`i']
}
if w[`i']=="固定资产清理"  {
local A023= x[`i']
}
if w[`i']=="生产性生物资产"  {
local A024= x[`i']
}
if w[`i']=="油气资产"  {
local A025= x[`i']
}
if w[`i']=="无形资产"  {
local A026= x[`i']
}
if w[`i']=="开发支出"  {
local A027= x[`i']
}
if w[`i']=="商誉"  {
local A028= x[`i']
}
if w[`i']=="长期待摊费用"  {
local A029= x[`i']
}
if w[`i']=="递延所得税资产"  {
local A030= x[`i']
}
if w[`i']=="其他非流动资产"  {
local A031= x[`i']
}
if w[`i']=="非流动资产合计"  {
local A032= x[`i']
}
if w[`i']=="资产总计"  {
local A033= x[`i']
}
if w[`i']=="短期借款"  {
local A034= x[`i']
}
if w[`i']=="交易性金融负债"  {
local A035= x[`i']
}
if w[`i']=="应付票据"  {
local A036= x[`i']
}
if w[`i']=="应付账款"  {
local A037= x[`i']
}
if w[`i']=="预收款项"  {
local A038= x[`i']
}
if w[`i']=="应付职工薪酬"  {
local A039= x[`i']
}
if w[`i']=="应交税费"  {
local A040= x[`i']
}
if w[`i']=="应付利息"  {
local A041= x[`i']
}
if w[`i']=="应付股利"  {
local A042= x[`i']
}
if w[`i']=="其他应付款"  {
local A043= x[`i']
}
if w[`i']=="应付关联公司款"  {
local A044= x[`i']
}
if w[`i']=="一年内到期的非流动负债"  {
local A045= x[`i']
}
if w[`i']=="其他流动负债"  {
local A046= x[`i']
}
if w[`i']=="流动负债合计"  {
local A047= x[`i']
}
if w[`i']=="长期借款"  {
local A048= x[`i']
}
if w[`i']=="应付债券"  {
local A049= x[`i']
}
if w[`i']=="长期应付款"  {
local A050= x[`i']
}
if w[`i']=="专项应付款"  {
local A051= x[`i']
}
if w[`i']=="预计负债"  {
local A052= x[`i']
}
if w[`i']=="递延所得税负债"  {
local A053= x[`i']
}
if w[`i']=="其他非流动负债"  {
local A054= x[`i']
}
if w[`i']=="非流动负债合计"  {
local A055= x[`i']
}
if w[`i']=="负债合计"  {
local A056= x[`i']
}
if w[`i']=="实收资本（或股本）"  {
local A057= x[`i']
}
if w[`i']=="资本公积"  {
local A058= x[`i']
}
if w[`i']=="盈余公积"  {
local A059= x[`i']
}
if w[`i']=="减：库存股"  {
local A060= x[`i']
}
if w[`i']=="未分配利润"  {
local A061= x[`i']
}
if w[`i']=="少数股东权益"  {
local A062= x[`i']
}
if w[`i']=="外币报表折算价差"  {
local A063= x[`i']
}
if w[`i']=="非正常经营项目收益调整"  {
local A064= x[`i']
}
if w[`i']=="归属母公司所有者权益（或股东权益）"  {
local A065= x[`i']
}
if w[`i']=="所有者权益（或股东权益）合计"  {
local A066= x[`i']
}
if w[`i']=="一、营业收入"  {
local P001= x[`i']
}
if w[`i']=="减：营业成本"  {
local P002= x[`i']
}
if w[`i']=="营业税金及附加"  {
local P003= x[`i']
}
if w[`i']=="销售费用"  {
local P004= x[`i']
}
if w[`i']=="管理费用"  {
local P005= x[`i']
}
if w[`i']=="勘探费用"  {
local P006= x[`i']
}
if w[`i']=="财务费用"  {
local P007= x[`i']
}
if w[`i']=="资产减值损失"  {
local P008= x[`i']
}
if w[`i']=="加：公允价值变动净收益"  {
local P009= x[`i']
}
if w[`i']=="投资收益"  {
local P010= x[`i']
}
if w[`i']=="其中：对联营企业和合营企业的投资收益"  {
local P011= x[`i']
}
if w[`i']=="影响营业利润的其他科目"  {
local P012= x[`i']
}
if w[`i']=="二、营业利润" | w[`i']== "三、营业利润" {
local P013= x[`i']
}
if w[`i']=="加：补贴收入"  {
local P014= x[`i']
}
if w[`i']=="营业外收入"  {
local P015= x[`i']
}
if w[`i']=="减：营业外支出"  {
local P016= x[`i']
}
if w[`i']=="其中：非流动资产处置净损失"  {
local P017= x[`i']
}
if w[`i']=="加：影响利润总额的其他科目"  {
local P018= x[`i']
}
if w[`i']=="三、利润总额" |  w[`i']=="四、利润总额"  {
local P019= x[`i']
}
if w[`i']=="减：所得税"  {
local P020= x[`i']
}
if w[`i']=="加：影响净利润的其他科目"  {
local P021= x[`i']
}
if w[`i']=="四、净利润" |  w[`i']=="五、净利润"{
local P022= x[`i']
}
if w[`i']=="归属于母公司所有者的净利润" |  w[`i']=="（一）归属于母公司所有者的净利润" {
local P023= x[`i']
}
if w[`i']=="少数股东损益" |  w[`i']=="（二）少数股东损益" {
local P024= x[`i']
}
if w[`i']=="五、每股收益" | w[`i']=="六、每股收益"  {
local P025= x[`i']
}
if w[`i']=="（一）基本每股收益"  {
local P026= x[`i']
}
if w[`i']=="一、经营活动产生的现金流量"  {
local C001= x[`i']
}
if w[`i']=="销售商品、提供劳务收到的现金"  {
local C002= x[`i']
}
if w[`i']=="收到的税费返还"  {
local C003= x[`i']
}
if w[`i']=="收到其他与经营活动有关的现金"  {
local C004= x[`i']
}
if w[`i']=="经营活动现金流入小计"  {
local C005= x[`i']
}
if w[`i']=="购买商品、接受劳务支付的现金"  {
local C006= x[`i']
}
if w[`i']=="支付给职工以及为职工支付的现金"  {
local C007= x[`i']
}
if w[`i']=="支付的各项税费"  {
local C008= x[`i']
}
if w[`i']=="支付其他与经营活动有关的现金"  {
local C009= x[`i']
}
if w[`i']=="经营活动现金流出小计"  {
local C010= x[`i']
}
if w[`i']=="经营活动产生的现金流量净额"  {
local C011= x[`i']
}
if w[`i']=="二、投资活动产生的现金流量"  {
local C012= x[`i']
}
if w[`i']=="收回投资收到的现金"  {
local C013= x[`i']
}
if w[`i']=="取得投资收益收到的现金"  {
local C014= x[`i']
}
if w[`i']=="处置固定资产、无形资产和其他长期资产收回的现金净额"  {
local C015= x[`i']
}
if w[`i']=="处置子公司及其他营业单位收到的现金净额"  {
local C016= x[`i']
}
if w[`i']=="收到其他与投资活动有关的现金"  {
local C017= x[`i']
}
if w[`i']=="投资活动现金流入小计"  {
local C018= x[`i']
}
if w[`i']=="购建固定资产、无形资产和其他长期资产支付的现金"  {
local C019= x[`i']
}
if w[`i']=="投资支付的现金"  {
local C020= x[`i']
}
if w[`i']=="取得子公司及其他营业单位支付的现金净额"  {
local C021= x[`i']
}
if w[`i']=="支付其他与投资活动有关的现金"  {
local C022= x[`i']
}
if w[`i']=="投资活动现金流出小计"  {
local C023= x[`i']
}
if w[`i']=="投资活动产生的现金流量净额"  {
local C024= x[`i']
}
if w[`i']=="三、筹资活动产生的现金流量"  {
local C025= x[`i']
}
if w[`i']=="吸收投资收到的现金"  {
local C026= x[`i']
}
if w[`i']=="取得借款收到的现金"  {
local C027= x[`i']
}
if w[`i']=="收到其他与筹资活动有关的现金"  {
local C028= x[`i']
}
if w[`i']=="筹资活动现金流入小计"  {
local C029= x[`i']
}
if w[`i']=="偿还债务支付的现金"  {
local C030= x[`i']
}
if w[`i']=="分配股利、利润或偿付利息支付的现金"  {
local C031= x[`i']
}
if w[`i']=="支付其他与筹资活动有关的现金"  {
local C032= x[`i']
}
if w[`i']=="筹资活动现金流出小计"  {
local C033= x[`i']
}
if w[`i']=="筹资活动产生的现金流量净额"  {
local C034= x[`i']
}
if w[`i']=="四、汇率变动对现金的影响"  {
local C035= x[`i']
}
if w[`i']=="四(2)、其他原因对现金的影响"  {
local C036= x[`i']
}
if w[`i']=="五、现金及现金等价物净增加额"  {
local C037= x[`i']
}
if w[`i']=="期初现金及现金等价物余额"  {
local C038= x[`i']
}
if w[`i']=="期末现金及现金等价物余额"  {
local C039= x[`i']
}
if w[`i']=="附注：1、将净利润调节为经营活动现金流量"  {
local C040= x[`i']
}
if w[`i']=="净利润"  {
local C041= x[`i']
}
if w[`i']=="加：资产减值准备"  {
local C042= x[`i']
}
if w[`i']=="固定资产折旧、油气资产折耗、生产性生物资产折旧"  {
local C043= x[`i']
}
if w[`i']=="无形资产摊销"  {
local C044= x[`i']
}
if w[`i']=="长期待摊费用摊销"  {
local C045= x[`i']
}
if w[`i']=="处置固定资产、无形资产和其他长期资产的损失"  {
local C046= x[`i']
}
if w[`i']=="固定资产报废损失"  {
local C047= x[`i']
}
if w[`i']=="公允价值变动损失"  {
local C048= x[`i']
}
if w[`i']=="财务费用"  {
local C049= x[`i']
}
if w[`i']=="投资损失"  {
local C050= x[`i']
}
if w[`i']=="递延所得税资产减少"  {
local C051= x[`i']
}
if w[`i']=="递延所得税负债增加"  {
local C052= x[`i']
}
if w[`i']=="存货的减少"  {
local C053= x[`i']
}
if w[`i']=="经营性应收项目的减少"  {
local C054= x[`i']
}
if w[`i']=="经营性应付项目的增加"  {
local C055= x[`i']
}
if w[`i']=="其他"  {
local C056= x[`i']
}
if w[`i']=="经营活动产生的现金流量净额2"  {
local C057= x[`i']
}
if w[`i']=="2、不涉及现金收支的重大投资和筹资活动"  {
local C058= x[`i']
}
if w[`i']=="债务转为资本"  {
local C059= x[`i']
}
if w[`i']=="一年内到期的可转换公司债券"  {
local C060= x[`i']
}
if w[`i']=="融资租入固定资产"  {
local C061= x[`i']
}
if w[`i']=="3、现金及现金等价物净变动情况"  {
local C062= x[`i']
}
if w[`i']=="现金的期末余额"  {
local C063= x[`i']
}
if w[`i']=="减：现金的期初余额"  {
local C064= x[`i']
}
if w[`i']=="加：现金等价物的期末余额"  {
local C065= x[`i']
}
if w[`i']=="减：现金等价物的期初余额"  {
local C066= x[`i']
}
if w[`i']=="加：其他原因对现金的影响2"  {
local C067= x[`i']
}
if w[`i']=="现金及存放同业款项"  {
local A067= x[`i']
}
if w[`i']=="客户资金存款"  {
local A068= x[`i']
}
if w[`i']=="存放中央银行款项"  {
local A069= x[`i']
}
if w[`i']=="结算备付金"  {
local A070= x[`i']
}
if w[`i']=="客户备付金"  {
local A071= x[`i']
}
if w[`i']=="贵金属"  {
local A072= x[`i']
}
if w[`i']=="拆出资金"  {
local A073= x[`i']
}
if w[`i']=="衍生金融资产"  {
local A074= x[`i']
}
if w[`i']=="买入返售金融资产"  {
local A075= x[`i']
}
if w[`i']=="应收保费"  {
local A076= x[`i']
}
if w[`i']=="应收代位追偿款"  {
local A077= x[`i']
}
if w[`i']=="应收分保帐款"  {
local A078= x[`i']
}
if w[`i']=="应收分保未到期责任准备金"  {
local A079= x[`i']
}
if w[`i']=="应收分保未决赔款准备金"  {
local A080= x[`i']
}
if w[`i']=="应收分保寿险责任准备金"  {
local A081= x[`i']
}
if w[`i']=="应收分保长期健康险责任准备金"  {
local A082= x[`i']
}
if w[`i']=="保户质押贷款"  {
local A083= x[`i']
}
if w[`i']=="定期存款"  {
local A084= x[`i']
}
if w[`i']=="发放贷款及垫款"  {
local A085= x[`i']
}
if w[`i']=="存出保证金"  {
local A086= x[`i']
}
if w[`i']=="代理业务资产"  {
local A087= x[`i']
}
if w[`i']=="交易席位费"  {
local A088= x[`i']
}
if w[`i']=="独立帐户资产"  {
local A089= x[`i']
}
if w[`i']=="向中央银行借款"  {
local A090= x[`i']
}
if w[`i']=="同业及其他金融机构存放款项"  {
local A091= x[`i']
}
if w[`i']=="质押借款"  {
local A092= x[`i']
}
if w[`i']=="拆入资金"  {
local A093= x[`i']
}
if w[`i']=="衍生金融负债"  {
local A094= x[`i']
}
if w[`i']=="卖出回购金融资产款"  {
local A095= x[`i']
}
if w[`i']=="吸收存款"  {
local A096= x[`i']
}
if w[`i']=="代理买卖证券款"  {
local A097= x[`i']
}
if w[`i']=="代理承销证券款"  {
local A098= x[`i']
}
if w[`i']=="预收保费"  {
local A099= x[`i']
}
if w[`i']=="代理业务负债"  {
local A100= x[`i']
}
if w[`i']=="应付保单红利"  {
local A101= x[`i']
}
if w[`i']=="保户储金及投资款"  {
local A102= x[`i']
}
if w[`i']=="未到期责任准备金"  {
local A103= x[`i']
}
if w[`i']=="未决赔款准备金"  {
local A104= x[`i']
}
if w[`i']=="寿险责任准备金"  {
local A105= x[`i']
}
if w[`i']=="长期健康险责任准备金"  {
local A106= x[`i']
}
if w[`i']=="独立帐户负债"  {
local A107= x[`i']
}
if w[`i']=="一般风险准备"  {
local A108= x[`i']
}
if w[`i']=="利息净收入"  {
local P027= x[`i']
}
if w[`i']=="利息收入"  {
local P028= x[`i']
}
if w[`i']=="利息支出"  {
local P029= x[`i']
}
if w[`i']=="手续费及佣金净收入"  {
local P030= x[`i']
}
if w[`i']=="手续费及佣金收入"  {
local P031= x[`i']
}
if w[`i']=="代理买卖证券业务净收入"  {
local P032= x[`i']
}
if w[`i']=="证券承销业务净收入"  {
local P033= x[`i']
}
if w[`i']=="委托客户管理资产业务净收入"  {
local P034= x[`i']
}
if w[`i']=="已赚保费"  {
local P035= x[`i']
}
if w[`i']=="保险业务收入"  {
local P036= x[`i']
}
if w[`i']=="分保费收入"  {
local P037= x[`i']
}
if w[`i']=="分出保费"  {
local P038= x[`i']
}
if w[`i']=="提取未到期责任准备金"  {
local P039= x[`i']
}
if w[`i']=="退保金"  {
local P040= x[`i']
}
if w[`i']=="赔付支出"  {
local P041= x[`i']
}
if w[`i']=="摊回赔付支出"  {
local P042= x[`i']
}
if w[`i']=="提取保险责任准备金"  {
local P043= x[`i']
}
if w[`i']=="摊回保险责任准备金"  {
local P044= x[`i']
}
if w[`i']=="保单红利支出"  {
local P045= x[`i']
}
if w[`i']=="分保费用"  {
local P046= x[`i']
}
if w[`i']=="业务及管理费"  {
local P047= x[`i']
}
if w[`i']=="摊回分保费用"  {
local P048= x[`i']
}
if w[`i']=="客户存款和同业存放款项净增加额"  {
local C068= x[`i']
}
if w[`i']=="向中央银行借款净增加额"  {
local C069= x[`i']
}
if w[`i']=="向其他金融机构拆入资金净增加额"  {
local C070= x[`i']
}
if w[`i']=="收取利息、手续费及佣金的现金"  {
local C071= x[`i']
}
if w[`i']=="处置交易性金融资产净增加额"  {
local C072= x[`i']
}
if w[`i']=="拆入资金净增加额"  {
local C073= x[`i']
}
if w[`i']=="回购业务资金净增加额"  {
local C074= x[`i']
}
if w[`i']=="收到原保险合同保费取得的现金"  {
local C075= x[`i']
}
if w[`i']=="收到再保业务现金净额"  {
local C076= x[`i']
}
if w[`i']=="保户储金及投资款净增加额"  {
local C077= x[`i']
}
if w[`i']=="客户贷款及垫款净增加额"  {
local C078= x[`i']
}
if w[`i']=="存放中央银行和同业款项净增加额"  {
local C079= x[`i']
}
if w[`i']=="支付的手续费及佣金的现金"  {
local C080= x[`i']
}
if w[`i']=="支付原保险合同赔付款项的现金"  {
local C081= x[`i']
}
if w[`i']=="支付保单红利的现金"  {
local C082= x[`i']
}
if w[`i']=="质押贷款净增加额"  {
local C083= x[`i']
}
  }
 
 #delimit ; 
 
post account ("`stockcode'") ("`adate'")
(`A001')
(`A002')
(`A003')
(`A004')
(`A005')
(`A006')
(`A007')
(`A008')
(`A009')
(`A010')
(`A011')
(`A012')
(`A013')
(`A014')
(`A015')
(`A016')
(`A017')
(`A018')
(`A019')
(`A020')
(`A021')
(`A022')
(`A023')
(`A024')
(`A025')
(`A026')
(`A027')
(`A028')
(`A029')
(`A030')
(`A031')
(`A032')
(`A033')
(`A034')
(`A035')
(`A036')
(`A037')
(`A038')
(`A039')
(`A040')
(`A041')
(`A042')
(`A043')
(`A044')
(`A045')
(`A046')
(`A047')
(`A048')
(`A049')
(`A050')
(`A051')
(`A052')
(`A053')
(`A054')
(`A055')
(`A056')
(`A057')
(`A058')
(`A059')
(`A060')
(`A061')
(`A062')
(`A063')
(`A064')
(`A065')
(`A066')
(`A067')
(`A068')
(`A069')
(`A070')
(`A071')
(`A072')
(`A073')
(`A074')
(`A075')
(`A076')
(`A077')
(`A078')
(`A079')
(`A080')
(`A081')
(`A082')
(`A083')
(`A084')
(`A085')
(`A086')
(`A087')
(`A088')
(`A089')
(`A090')
(`A091')
(`A092')
(`A093')
(`A094')
(`A095')
(`A096')
(`A097')
(`A098')
(`A099')
(`A100')
(`A101')
(`A102')
(`A103')
(`A104')
(`A105')
(`A106')
(`A107')
(`A108')
(`P001')
(`P002')
(`P003')
(`P004')
(`P005')
(`P006')
(`P007')
(`P008')
(`P009')
(`P010')
(`P011')
(`P012')
(`P013')
(`P014')
(`P015')
(`P016')
(`P017')
(`P018')
(`P019')
(`P020')
(`P021')
(`P022')
(`P023')
(`P024')
(`P025')
(`P026')
(`P027')
(`P028')
(`P029')
(`P030')
(`P031')
(`P032')
(`P033')
(`P034')
(`P035')
(`P036')
(`P037')
(`P038')
(`P039')
(`P040')
(`P041')
(`P042')
(`P043')
(`P044')
(`P045')
(`P046')
(`P047')
(`P048')
(`C001')
(`C002')
(`C003')
(`C004')
(`C005')
(`C006')
(`C007')
(`C008')
(`C009')
(`C010')
(`C011')
(`C012')
(`C013')
(`C014')
(`C015')
(`C016')
(`C017')
(`C018')
(`C019')
(`C020')
(`C021')
(`C022')
(`C023')
(`C024')
(`C025')
(`C026')
(`C027')
(`C028')
(`C029')
(`C030')
(`C031')
(`C032')
(`C033')
(`C034')
(`C035')
(`C036')
(`C037')
(`C038')
(`C039')
(`C040')
(`C041')
(`C042')
(`C043')
(`C044')
(`C045')
(`C046')
(`C047')
(`C048')
(`C049')
(`C050')
(`C051')
(`C052')
(`C053')
(`C054')
(`C055')
(`C056')
(`C057')
(`C058')
(`C059')
(`C060')
(`C061')
(`C062')
(`C063')
(`C064')
(`C065')
(`C066')
(`C067')
(`C068')
(`C069')
(`C070')
(`C071')
(`C072')
(`C073')
(`C074')
(`C075')
(`C076')
(`C077')
(`C078')
(`C079')
(`C080')
(`C081')
(`C082')
(`C083');

#delimit cr
restore
di "You've got the `stockcode' 's financial data in `adate'"
}

postclose account 
}
foreach code in `firms' {
  while length("`code'")<6 {
	   local code = "0"+"`code'"
	     }
capture use `"`path'/`code'"', clear
if _rc != 0 {
exit
}

label var A001"货币资金"
label var A002"交易性金融资产"
label var A003"应收票据"
label var A004"应收账款"
label var A005"预付款项"
label var A006"其他应收款"
label var A007"应收关联公司款"
label var A008"应收利息"
label var A009"应收股利"
label var A010"存货"
label var A011"消耗性生物资产"
label var A012"一年内到期的非流动资产"
label var A013"其他流动资产"
label var A014"流动资产合计"
label var A015"可供出售金融资产"
label var A016"持有至到期投资"
label var A017"长期应收款"
label var A018"长期股权投资"
label var A019"投资性房地产"
label var A020"固定资产"
label var A021"在建工程"
label var A022"工程物资"
label var A023"固定资产清理"
label var A024"生产性生物资产"
label var A025"油气资产"
label var A026"无形资产"
label var A027"开发支出"
label var A028"商誉"
label var A029"长期待摊费用"
label var A030"递延所得税资产"
label var A031"其他非流动资产"
label var A032"非流动资产合计"
label var A033"资产总计"
label var A034"短期借款"
label var A035"交易性金融负债"
label var A036"应付票据"
label var A037"应付账款"
label var A038"预收款项"
label var A039"应付职工薪酬"
label var A040"应交税费"
label var A041"应付利息"
label var A042"应付股利"
label var A043"其他应付款"
label var A044"应付关联公司款"
label var A045"一年内到期的非流动负债"
label var A046"其他流动负债"
label var A047"流动负债合计"
label var A048"长期借款"
label var A049"应付债券"
label var A050"长期应付款"
label var A051"专项应付款"
label var A052"预计负债"
label var A053"递延所得税负债"
label var A054"其他非流动负债"
label var A055"非流动负债合计"
label var A056"负债合计"
label var A057"实收资本（或股本）"
label var A058"资本公积"
label var A059"盈余公积"
label var A060"库存股"
label var A061"未分配利润"
label var A062"少数股东权益"
label var A063"外币报表折算价差"
label var A064"非正常经营项目收益调整"
label var A065"归属母公司所有者权益（或股东权益）"
label var A066"所有者权益（或股东权益）合计"
label var P001"营业收入"
label var P002"营业成本"
label var P003"营业税金及附加"
label var P004"销售费用"
label var P005"管理费用"
label var P006"勘探费用"
label var P007"财务费用"
label var P008"资产减值损失"
label var P009"公允价值变动净收益"
label var P010"投资收益"
label var P011"对联营企业和合营企业的投资收益"
label var P012"影响营业利润的其他科目"
label var P013"营业利润"
label var P014"补贴收入"
label var P015"营业外收入"
label var P016"营业外支出"
label var P017"非流动资产处置净损失"
label var P018"影响利润总额的其他科目"
label var P019"利润总额"
label var P020"所得税"
label var P021"影响净利润的其他科目"
label var P022"净利润"
label var P023"归属于母公司所有者的净利润"
label var P024"少数股东损益"
label var P025"每股收益"
label var P026"基本每股收益"
label var C001"经营活动产生的现金流量"
label var C002"销售商品、提供劳务收到的现金"
label var C003"收到的税费返还"
label var C004"收到其他与经营活动有关的现金"
label var C005"经营活动现金流入小计"
label var C006"购买商品、接受劳务支付的现金"
label var C007"支付给职工以及为职工支付的现金"
label var C008"支付的各项税费"
label var C009"支付其他与经营活动有关的现金"
label var C010"经营活动现金流出小计"
label var C011"经营活动产生的现金流量净额"
label var C012"投资活动产生的现金流量"
label var C013"收回投资收到的现金"
label var C014"取得投资收益收到的现金"
label var C015"处置固定资产、无形资产和其他长期资产收回的现金净额"
label var C016"处置子公司及其他营业单位收到的现金净额"
label var C017"收到其他与投资活动有关的现金"
label var C018"投资活动现金流入小计"
label var C019"购建固定资产、无形资产和其他长期资产支付的现金"
label var C020"投资支付的现金"
label var C021"取得子公司及其他营业单位支付的现金净额"
label var C022"支付其他与投资活动有关的现金"
label var C023"投资活动现金流出小计"
label var C024"投资活动产生的现金流量净额"
label var C025"筹资活动产生的现金流量"
label var C026"吸收投资收到的现金"
label var C027"取得借款收到的现金"
label var C028"收到其他与筹资活动有关的现金"
label var C029"筹资活动现金流入小计"
label var C030"偿还债务支付的现金"
label var C031"分配股利、利润或偿付利息支付的现金"
label var C032"支付其他与筹资活动有关的现金"
label var C033"筹资活动现金流出小计"
label var C034"筹资活动产生的现金流量净额"
label var C035"汇率变动对现金的影响"
label var C036"其他原因对现金的影响"
label var C037"现金及现金等价物净增加额"
label var C038"期初现金及现金等价物余额"
label var C039"期末现金及现金等价物余额"
label var C040"将净利润调节为经营活动现金流量"
label var C041"净利润"
label var C042"资产减值准备"
label var C043"固定资产折旧、油气资产折耗、生产性生物资产折旧"
label var C044"无形资产摊销"
label var C045"长期待摊费用摊销"
label var C046"处置固定资产、无形资产和其他长期资产的损失"
label var C047"固定资产报废损失"
label var C048"公允价值变动损失"
label var C049"财务费用"
label var C050"投资损失"
label var C051"递延所得税资产减少"
label var C052"递延所得税负债增加"
label var C053"存货的减少"
label var C054"经营性应收项目的减少"
label var C055"经营性应付项目的增加"
label var C056"其他"
label var C057"经营活动产生的现金流量净额2"
label var C058"不涉及现金收支的重大投资和筹资活动"
label var C059"债务转为资本"
label var C060"一年内到期的可转换公司债券"
label var C061"融资租入固定资产"
label var C062"现金及现金等价物净变动情况"
label var C063"现金的期末余额"
label var C064"现金的期初余额"
label var C065"现金等价物的期末余额"
label var C066"现金等价物的期初余额"
label var C067"其他原因对现金的影响2"
label var A067"现金及存放同业款项"
label var A068"客户资金存款"
label var A069"存放中央银行款项"
label var A070"结算备付金"
label var A071"客户备付金"
label var A072"贵金属"
label var A073"拆出资金"
label var A074"衍生金融资产"
label var A075"买入返售金融资产"
label var A076"应收保费"
label var A077"应收代位追偿款"
label var A078"应收分保帐款"
label var A079"应收分保未到期责任准备金"
label var A080"应收分保未决赔款准备金"
label var A081"应收分保寿险责任准备金"
label var A082"应收分保长期健康险责任准备金"
label var A083"保户质押贷款"
label var A084"定期存款"
label var A085"发放贷款及垫款"
label var A086"存出保证金"
label var A087"代理业务资产"
label var A088"交易席位费"
label var A089"独立帐户资产"
label var A090"向中央银行借款"
label var A091"同业及其他金融机构存放款项"
label var A092"质押借款"
label var A093"拆入资金"
label var A094"衍生金融负债"
label var A095"卖出回购金融资产款"
label var A096"吸收存款"
label var A097"代理买卖证券款"
label var A098"代理承销证券款"
label var A099"预收保费"
label var A100"代理业务负债"
label var A101"应付保单红利"
label var A102"保户储金及投资款"
label var A103"未到期责任准备金"
label var A104"未决赔款准备金"
label var A105"寿险责任准备金"
label var A106"长期健康险责任准备金"
label var A107"独立帐户负债"
label var A108"一般风险准备"
label var P027"利息净收入"
label var P028"利息收入"
label var P029"利息支出"
label var P030"手续费及佣金净收入"
label var P031"手续费及佣金收入"
label var P032"代理买卖证券业务净收入"
label var P033"证券承销业务净收入"
label var P034"委托客户管理资产业务净收入"
label var P035"已赚保费"
label var P036"保险业务收入"
label var P037"分保费收入"
label var P038"分出保费"
label var P039"提取未到期责任准备金"
label var P040"退保金"
label var P041"赔付支出"
label var P042"摊回赔付支出"
label var P043"提取保险责任准备金"
label var P044"摊回保险责任准备金"
label var P045"保单红利支出"
label var P046"分保费用"
label var P047"业务及管理费"
label var P048"摊回分保费用"
label var C068"客户存款和同业存放款项净增加额"
label var C069"向中央银行借款净增加额"
label var C070"向其他金融机构拆入资金净增加额"
label var C071"收取利息、手续费及佣金的现金"
label var C072"处置交易性金融资产净增加额"
label var C073"拆入资金净增加额"
label var C074"回购业务资金净增加额"
label var C075"收到原保险合同保费取得的现金"
label var C076"收到再保业务现金净额"
label var C077"保户储金及投资款净增加额"
label var C078"客户贷款及垫款净增加额"
label var C079"存放中央银行和同业款项净增加额"
label var C080"支付的手续费及佣金的现金"
label var C081"支付原保险合同赔付款项的现金"
label var C082"支付保单红利的现金"
label var C083"质押贷款净增加额"
save,replace
if c(stata_version) >= 14 {
	qui {
	clear
	local path2="`c(pwd)'"
	cd "`path'"
	unicode encoding set gb18030
	unicode translate `code'.dta,transutf8
	unicode erasebackups,badidea
	cd "`path2'"
	use "`path'/`code'"
	save,replace
	}
	
}
}

	erase `path'\lr.dta
	erase `path'\zcfz.dta
	erase `path'\xjll.dta
	di "finished"
	di "Your finacial data have been saved in `path'"
end

version 12
capture mata mata drop gdate()
capture mata mata drop _cnaccount()
mata:
void function gdate(
     string scalar dfile,
	 string scalar date)
{
        line0 = cat(dfile)
        line = select(line0,strpos(line0,`"<script type="text/javascript">dateurl="'))
        line = subinstr(line,`"<script type="text/javascript">dateurl="char((104,116,116,112,58,47,47)stockdata.stock.char((104, 101, 120,117,110)).com/2008/lr.aspx?stockid="',"")
		line2 = subinstr(subinstr(line, `"]];</script>"', ""), `"],["',",")
		line3 = subinstr(line2," ","")
		line4 = subinstr(line3,","," ")
		v = tokens(line4, " ")'
		st_sview(x=.,.,date)
		x[1..rows(v)] = v	

	}

void function _cnaccount(
		string scalar pfile,
		string scalar cfile,
		string scalar bfile,
		string scalar vn)
		
{    
        line0 = cat(pfile)
        line = select(line0,strpos(line0,`"<span id="ControlEx1_lbl">"'))
        line = subinstr(line,`"<span id="ControlEx1_lbl"><tr><td class='dotborder' width='45%'><div class='tishi'><strong>"',"")
		line = subinstr(subinstr(line, `"</div></td></span>"', ""), `"</strong></div></td><td><div class='tishi'>"'," ")
		line = subinstr(line, `"</div></td><tr><td class='dotborder' width='45%'><div class='tishi'><strong>"', " ")
		v=tokens(line, " ")'
		profit=v[(3::rows(v)),.]
		ROW=2*floor(rows(profit)/2)
		profit=v[(3::ROW),.]

        
        line0 = cat(cfile)
        line = select(line0,strpos(line0,`"<span id="ControlEx1_lbl">"'))
        line = subinstr(line,`"<span id="ControlEx1_lbl"><tr><td class='dotborder' width='45%'><div class='tishi'><strong>"',"")
		line = subinstr(subinstr(line, `"</div></td></span>"', ""), `"</strong></div></td><td><div class='tishi'>"'," ")
		line =  subinstr(line, `"</div></td><tr><td class='dotborder' width='45%'><div class='tishi'><strong>"', " ")
		line =  subinstr(line, `"</div></td><tr><td height='1' colspan='2' bgcolor='#cfcfcf'></td></tr><tr><td colspan='2' class='lastbgcolor'><div class='tishi'><strong>"', " ")
		line =  subinstr(line, `"</strong></div></td></tr><tr><td height='1' colspan='2' bgcolor='#cfcfcf'></td></tr><tr><td class='dotborder' width='45%'><div class='tishi'><strong>"', " --  ")
		line =  subinstr(line, `"</strong></div></td></tr><tr><td height='1' colspan='2' bgcolor='#cfcfcf'></td></tr><tr><td height='1' colspan='2' bgcolor='#cfcfcf'></td></tr><tr><td colspan='2' class='lastbgcolor'><div class='tishi'><strong>"', " --  ")
		
		v=tokens(line, " ")'
		cashflow=v[(3::rows(v)),.]
		ROW=2*floor(rows(cashflow)/2)
		cashflow=v[(3::ROW),.]
  
        line0 = cat(bfile)
        line = select(line0,strpos(line0,`"<span id="ControlEx1_lbl">"'))
        line = subinstr(line,`"<span id="ControlEx1_lbl"><tr><td class='dotborder' width='45%'><div class='tishi'><strong>"',"")
		line = subinstr(subinstr(line, `"</div></td></span>"', ""), `"</strong></div></td><td><div class='tishi'>"'," ")
		line =  subinstr(line, `"</div></td><tr><td class='dotborder' width='45%'><div class='tishi'><strong>"', " ")
		v=tokens(line, " ")'
		balance=v[(3::rows(v)),.]
		ROW=2*floor(rows(balance)/2)
		balance=v[(1::ROW),.]


		account= balance\ profit \ cashflow

  		st_sview(x=.,.,vn)
  		x[1..rows(account)] = account	
}
end
