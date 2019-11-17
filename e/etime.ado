*! etime Version 1.0 dan_blanchette@unc.edu  26Jan2008
*! research computing, unc-ch
** - made etime give error message if the first time it's invoked
**    is not with the start option.
** etime Version 1.0 dan_blanchette@unc.edu  23Jun2004 
** - fixed display when lasts longer than a day
** etime Version 1.0 dan_blanchette@unc.edu  30Sep2003
** the carolina population center, unc-ch

program define etime, sclass
 syntax [, Start ]
 version 8

 if "`start'"=="start"  {
  local stardate= date("`c(current_date)'","dmy")
 
  local startime= "`c(current_time)'"
  gettoken t startime : startime, parse(":")
   local i=1
   while `"`t'"' !="" {
    if "`t'"!=":" {
     local s`i'="`t'"
     local i=`i'+1
    }
   gettoken t startime : startime, parse(":")
   }
  local startime=(`s1'*60*60)+(`s2'*60)+`s3'
  sreturn local stardate `stardate'
  sreturn local startime `startime'
 }
 
 if "`start'"==""  {
  if `"`s(stardate)'"' == "" {
    di as err "the first time you invoke {help etime:etime} you need to use the start option"     
    exit 499
  } 
  local endate= date("`c(current_date)'","dmy")
 
  local endtime="`c(current_time)'"
  gettoken t endtime : endtime, parse(":")
   local i=1
   while `"`t'"' !="" {
    if "`t'"!=":" {
     local e`i'="`t'"
     local i=`i'+1
    }
   gettoken t endtime : endtime, parse(":")
   }
  local endtime=(`e1'*60*60)+(`e2'*60)+`e3'
  local edays=`endate'-`s(stardate)'
  if (`endate'>=`s(stardate)') & (`e1'==0) {
   local e1=24
  }
  local endtime=(`edays'*24*60*60)+`endtime'
  local etime=`endtime'-`s(startime)'
 
  local edays=int(`etime'/(24*60*60))
  local ehr=int((`etime'-(`edays'*24*60*60))/(60*60))
  local emin=int((`etime'-(`ehr'*60*60)-(`edays'*24*60*60))/60)
  local esec=int((`etime'-(`ehr'*60*60))-(`emin'*60)-(`edays'*24*60*60))
 
  local esecs=`etime'
  local etime="`edays':`ehr':`emin':`esec'"
 
  sreturn local stardate `s(stardate)'
  sreturn local startime `s(startime)'
  sreturn local endate `endate'
  sreturn local endtime `endtime'
  sreturn local etime `etime'
  sreturn local esecs `esecs'
 
  if `edays'>0 {
   di `"{res}Elapsed time is `edays' days `ehr' hours `emin' minutes `esec' seconds "'
  }
  else if `ehr'>0 {
   di `"{res}Elapsed time is `ehr' hours `emin' minutes `esec' seconds "'
  }
  else if `emin'>0 {
   di `"{res}Elapsed time is `emin' minutes `esec' seconds "'
  }
  else  {
   di `"{res}Elapsed time is `esec' seconds "'
  }
 }
 

end

