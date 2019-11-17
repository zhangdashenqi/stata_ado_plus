*! version 1.1 Z.WANG 22NOV1999    (STB-54: sg134)
* version 1.0 Z.WANG  07Nov1999 
program define swaic, nclass
  version 6.0
  syntax [, FP(str) FChi(str) Back Model ]
  local yvar "`e(depvar)'"
  
  if "`e(cmd)'"=="" {
      di in r "last estimates not found"
      exit 301
  } 
  if index(`"logitlogisticpoissonprobit"', `"`e(cmd)'"')>0 {
    local cmd "`e(cmd)'"
    local yvar1 yvar(`yvar')
  }    
  if "`e(cmd)'"=="cox" {
      if "`e(cmd2)'"!="" {
      local cmd `e(cmd2)'
      local yvar1
      local yvar
    } 
    else {
	  di in gr "Please use stcox instead of cox in estimation command."
	  exit 199
    }
  }
  
  if `"`e(cmd2)'"'==`"streg"' {
     local dist `"dist(`e(cmd)')"' 
     local cmd `e(cmd2)'
     local yvar1
     local yvar
  } 
  if "`cmd'"==""{
    di in w "`e(cmd)' " in gr "not supported by " in w "swaic"
    di in gr _con `"Current"' in w `" swaic"' in gr `" only supports "' 
	di in w  _con "logit logistic poisson stcox streg" 
	di in gr `" and"' in w " probit" in gr "."
    exit 199
  }

  if "`e(offset)'"!="" {
    tempvar off 
    gen `off'=`e(offset)'
    lab var `off' "`e(offset)'"
    local offset offset(`off')
  }

  if "`e(vcetype)'"~="" { 
    local robust r
  }

  if "`e(clustvar)'"~="" {
    local cluster cluster(`e(clustvar)')
  }
  local ops `offset' `robust' `cluster' `dist'

  tempvar smpl
  qui gen `smpl'=e(sample)
  mat bs=e(b) 
  local xnames : colnames(bs) 
  _xnam `xnames'
  
  local xnames `r(alln)'
  local vnum =`r(vnum)'
  local factn=`r(factn)'  

  di in gr "Stepwise Model Selection by AIC"  
  di in gr "`cmd' regression. `dist'"
  di in gr "number of obs = " in ye e(N)
  di in gr _dup(72) "-"
  di in gr %8s "`yvar'" _col(17) %6s "Df" _col(17) %9s  "Chi2"  /*
    */  _col(29)  %9s "P>Chi2" _col(42)  %8s  "-2*ll"  /*
    */ _col(54) %7s "Df Res." _col(60) %6s "AIC"
  di in gr _dup(72) "-"

  token `xnames' 
  * Display Table
  if "`fp'"=="" {
    local fp "%9.4f" 
  }
  if "`fchi'"=="" {
    local fchi "%9.2f" 
  }

  local decreas=0
  local endhere=0
  if "`back'"~=""{
    qui `cmd' `yvar' `xnames' if `smpl', `ops'
    local aic0=-2*e(ll)+2*(e(df_m)+`factn')
    local dev0=-2*e(ll)
    local rdf0=e(N)-e(df_m)-`factn'
    local mdf0=e(df_m)
    di in gr "Full Model" in ye _col(42) `fchi' `dev0'  _col(52)  /*
      */ %6.0f `rdf0' _col(60) `fchi' `aic0'

    local i=1
    local xs `xnames'
    while `i'<=`vnum'{
      local i_1=`i'-1
      _stepb, `yvar1' xvar(`xs') cmd(`cmd') smpl(`smpl') /*
        */ factn(`factn')  `ops' 
      local pv`i' `r(pv)'
      local mdf`i' `r(mdf)'
      local aic`i' `r(aic)'
      local dev`i' `r(dev)'
      local chi`i'=`dev`i'' - `dev`i_1''
      local df`i'= `mdf`i_1''-`mdf`i''
      local p`i' = chiprob(`df`i'',`chi`i'')
      local rdf`i'= `rdf`i_1''+`df`i''

      if `decreas'==1 {
	    if `aic`i''>`aic`i_1''{ 
          local endhere=1
	    }  
	  } 
      if `aic`i''<`aic`i_1'' {
        if `endhere'==0 {
          local mlist `r(mlist)'
        }
        local decreas=1
      }
     di in gr "Step `i': " %8s "-`pv`i''" in ye %6.0f _col(10) `df`i'' /*
        */ _col(17) `fchi' `chi`i'' _col(29) `fp'  /*
        */ `p`i'' _col(42) `fchi' `dev`i''  _col(52)  /*
        */ %6.0f `rdf`i'' _col(60) `fchi' `aic`i''

      _newx, xvar(`xs') pick(`r(pv)')
      local xs `r(newlst)'
      local i=`i'+1
    }
  }

else {
  qui `cmd' `yvar' `xnames' if `smpl', `ops'
  local aic0=-2*e(ll_0)+2*`factn'
  local dev0=-2*e(ll_0)
  local rdf0=e(N)-`factn'
  local mdf0=0
  local df0=0
  di in gr "Null Model" in ye _col(42) `fchi' `dev0'  _col(52)  /*
    */ %6.0f `rdf0' _col(60) `fchi' `aic0'
  local xs `xnames'
  local i=1
  while `i'<=`vnum'{ 
    local i_1=`i'-1
    _stepf, `yvar1' xvar(`"`xs'"') cmd(`cmd') smpl(`smpl') /*
      */ `plist' factn(`factn') `ops' 
    local pv`i'  `r(pv)'
    local mdf`i'= `r(mdf)'
    local aic`i'= `r(aic)'
    local dev`i'= `r(dev)'
    local chi`i'=`dev`i_1'' - `dev`i''
    local df`i'= `mdf`i''-`mdf`i_1''
    local p`i' = chiprob(`df`i'',`chi`i'')
    local rdf`i'= `rdf0'-`mdf`i''
    local picked `picked' `pv`i''
    if `decreas'==1 {
	  if `aic`i''>`aic`i_1''{ 
       local endhere=1
	  }  
	} 
    if `aic`i''<`aic`i_1'' {
      if `endhere'==0 {
        local mlist `picked'
      }
      local decreas=1
    }
    di in gr "Step `i': " %8s "`pv`i''" in ye %6.0f _col(10) `df`i'' /*
      */ _col(17) `fchi' `chi`i'' _col(29) `fp'  /*
      */ `p`i'' _col(42) `fchi' `dev`i''  _col(52)  /*
      */ %6.0f `rdf`i'' _col(60) `fchi' `aic`i''

    local plist plist(`picked')
    _newx, xvar(`xs') pick(`pv`i'')
    local xs `r(newlst)'
    local i =`i'+1
  } 
}

di in gr _dup(72) "-"

if "`model'"!=""{ 
 `cmd' `yvar' `mlist' if `smpl', `options' nolog
}
qui `cmd' `yvar' `xnames' if `smpl', `options'
end

program define _stepb, rclass 
  syntax [, Yvar(str) (str Xvar(str) CMD(str) smpl(str) factn(str) *]
  token `xvar'
  local aicmin=10000
  local i=1
  while "``i''"~=""{
    local i_1=`i'-1  
    _newx, xvar(`xvar') pick(``i'') 
    local newx `r(newlst)'
    qui `cmd' `yvar' `newx' if `smpl', `options'
    local dev`i' = -2*e(ll)
    local df`i'=e(df_m)   
    local aic`i'=`dev`i''+2*(`df`i''+`factn')

    if `aic`i''<`aicmin' {
      local pv  "``i''" 		
      local mdf=`df`i''
      local dev=`dev`i''
      local mlist `newx'
      local aicmin=`aic`i''
    }
    local i=`i'+1
  }
  return local pv `pv'
  return local aic=`aicmin'
  return local mdf=`mdf'
  return local dev=`dev'
  return local mlist `mlist'
end

program define _stepf, rclass 
  syntax [, Yvar(str) plist(str) Xvar(str) factn(str) CMD(str) smpl(str)  *]
  token `xvar'
  local aicmin=10000
  local i=1
  while "``i''"~=""{
    local i_1=`i'-1  
    qui `cmd' `yvar' `plist' ``i'' if `smpl', `options'
    local dev`i' = -2*e(ll)
    local aic`i'=`dev`i''+2*(e(df_m)+`factn')
    if `aic`i''<`aicmin' {
      local pv  "``i''" 		
      local mdf=e(df_m)
      local dev=`dev`i''
      local aicmin=`aic`i''
    }
    local i=`i'+1
  }
  return local pv `pv'
  return local aic=`aicmin'
  return local mdf=`mdf'
  return local dev=`dev'
  return local pv `pv'
end

program define _ab, rclass
  token `0', parse(" _")
  unab cat:`1'*
  return local cname "`1'*"
  token `cat'
  local i=1
  while "``i''"!=""{
    local i=`i'+1
  }
  return scalar catdf=`i'-1
end

program define _xnam, rclass
  local factn=0
  while "`1'"!=""{  
    if substr("`1'", 1,1) !="_"{
      local xlist `xlist' `1'
    }
    else {
      local factn=`factn'+1
    }
    mac shift
  }
  token `xlist'
  local i=1 
  while "`1'"!=""{
    if substr("`1'", 1,1)=="I"{
      _ab `1'
      local catdf=r(catdf)
      local xnam`i' `r(cname)'
      mac shift `catdf'
    }
    else {
      local xnam`i' `1'
      mac shift
    }
    local alln `alln' `xnam`i''
    local i=`i'+1
  }
  return local alln `alln'
  return local vnum=`i'-1
  return local factn `factn'
end  

program define _newx, rclass
  syntax[, Xvar(str) Pick(str)]  
  token `xvar'
  while "`1'"!="" {
      if  "`1'"!="`pick'" {
	    local newlst "`newlst' `1'"
      }
	  mac shift
	}
  return local newlst `newlst'
end
