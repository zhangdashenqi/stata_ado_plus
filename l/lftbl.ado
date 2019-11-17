/* ssa1 - Actuarial or Life Table Analysis of Time-to-Event Data
          Henry Krakauer and John Stewart,  HCFA                    */
          
set ado 15

program define lftbl
version 2.1
/*------------------ TAKE CARE OF DATA SET INFORMATION --------------*/
while "%S_FN" == "" | "%S_FN" == "_U_S_E_R.dta" {
   !cls
   display _newline(10)
   display "ENTER THE NAME OF THE DATA SET TO BE USED IN THIS ANALYSIS"
   display "(include subdirectory if not current one):  " _request(dsn)
   if "%dsn" ~= "" {capture use %dsn`,clear}
                 }
macro define filename "%S_FN"
capture save _U_S_E_R, replace
/*------------------ ASK FOR INFORMATION ON REQUEST -----------------*/
macro define t ""
macro define d ""
macro define unit ""
!cls
while "%t"=="" | _rc ~=0 {
  !cls
  display _newline(8) "         SPECIFICATION OF REQUEST"
  display _newline(2) "Specify time-to-event variable:" _request(t)
  capture confirm variable %t
  if _rc~=0 {macro define t ""}
              }
while "%d"=="" | _rc ~=0 {
  !cls
  display _newline(8) "         SPECIFICATION OF REQUEST"
  display _newline(2) "Specify time-to-event variable:  %t"
  display _newline(1) "Specify event marker variable:" _request(d)
  capture confirm variable %d
  if _rc~=0 {macro define d ""}
              }
while "%unit"=="" | _rc~=0 {
  !cls
  display _newline(8) "         SPECIFICATION OF REQUEST"
  display _newline(2) "Specify time-to-event variable:  %t"
  display _newline(1) "Specify event marker variable:   %d"
  display _newline(1) "Specify time unit (day/week/month/year--day is default):" _request(unit)
              }
display _newline(1) "Specify grouping  variable (enter for none):  " _request(g)
macro define gtst "y"
if "%g"=="" {
  capture generate x=1
  macro define g "x"
  macro define gtst "n"
           }
capture confirm variable %g
if _rc~=0 & "%gtst"=="y" {
  while "%g"=="" | _rc~=0 {
    !cls
    display _newline(8) "         SPECIFICATION OF REQUEST"
    display _newline(2) "Specify time-to-event variable:  %t"
    display _newline(1) "Specify event marker variable:   %d"
    display _newline(1) "Specify time unit (day/week/month/year--day is default):  %unit"
    display _newline(1) "Specify grouping  variable (enter for none):  " _request(g)
    capture confirm variable %g
    if _rc~=0  {macro define g ""}
                          }
                         }
keep %t %d %g
/*------------------------ ADJUST TIME TO DAYS ---------------------*/
capture if "!%unit!"=="!!" {
  replace %t=%t}
capture if substr("%unit",1,1)=="d" {
  replace %t=%t}
capture if substr("%unit",1,1)=="m" {
  replace %t=%t*(365.25/12)}
capture if substr("%unit",1,1)=="w" {
  replace %t=%t*(365.25/52)}
capture if substr("%unit",1,1)=="y" {
  replace %t=365.25*%t}
/*------------------------ REQUEST INTERVALS ------------------------*/
macro define i1 "o"
capture confirm number %i1
while _rc~=0  & "%i1"~=""       {
!cls
          /*-------------- REQUEST FIRST INTERVAL -------------*/
display _newline(8) "        SPECIFICATION OF TIME CATEGORIES"
display "This system provides the following default categories for the "
display "life table (values are in days and starting value is first):
display "    0 -   <7     7 - < 15    15 - < 30    30 - < 60   60 - <90
display "   90 - <180   180 - <360   360 - <540   540 - <720    > 720
display "Specify starting value of first interval desired or just press"
display "enter to use default values (the first interval must start with 0,"
display "enter values in ascending order, press enter after entry):  " _request(i1)
capture confirm number %i1
                                     }
          /*-------------- REQUEST INTERVALS 2-N --------------*/
if "%i1"~=""  {
  macro define curri=%i1
  macro define inum=2
  while "%curri"~=""     {
    !cls
    macro define intvno=1
    display "The starting values entered so far are:
    display "Interval   Starting Value"
    while %intvno<%inum {
      display %8.0f=%intvno _column(20) %`i`%intvno
      macro define intvno=%intvno + 1
                        }
    display _newline(2)
    display "Specify starting value of next interval desired or just press"
    display "enter to quit entering values (press enter after value):  " _request(i`%inum)
    capture confirm number %`i`%inum
    if _rc==0 | "%`i`%inum"==""   {
      macro define curri="%`i`%inum"
      macro define inum=%inum+1
                        }
                          }
 macro define inum=%inum-2 /* one for add at end and one for '' */
/*-------------------------- PROCESSING MESSAGE ---------------------*/
if "%i1"~="" & "%i2"~="" {
!cls
display _newline(10) "        CREATING REQUESTED INTERVALS. THIS WILL TAKE A FEW SECONDS "
                        }
          /*-------------- CREATE INTERVALS -------------------*/
if "%i1"~="" {
  if "%i2"~="" {
    capture gen intvl=%i1 if %t>=%i1 & %t<%i2 - 1
    macro define inew=2
    macro define inext=3
    while %inew<%inum {
      capture replace intvl=%`i`%inew if %t<%`i`%inext & %t>=%`i`%inew -1
      macro define inew=%inext
      macro define inext=%inext+1
                      }
    capture replace intvl=%`i`%inum if %t>%`i`%inew & %t~=.
                }
  capture if "%i2"=="" {gen intvl=%i1 if %t>%i1 & %t~=.}
              }
               }
/*---------------------- END REQUEST INTERVALS ----------------------*/
if "%i1"==""  {
!cls
display _newline(10) "        CREATING DEFAULT INTERVALS.  THIS WILL TAKE A FEW SECONDS"
                        }

/*---------------------- DEFAULT INTERVALS --------------------------*/
if "%i1"=="" {
  capture gen intvl=0 if %t>=0 & %t<7
  capture replace intvl=7 if %t>=7 & %t<15
  capture replace intvl=15 if %t>=15 & %t<30
  capture replace intvl=30 if %t>=30 & %t<60
  capture replace intvl=60 if %t>=60 & %t<90
  capture replace intvl=90 if %t>=90 & %t<180
  capture replace intvl=180 if %t>=180 & %t<360
  capture replace intvl=360 if %t>=360 & %t<540
  capture replace intvl=540 if %t>=540 & %t<720
  capture replace intvl=720 if %t>=720 & %t~=.
  macro define inum=10
          }

/*-------------------------- PROCESSING MESSAGE ---------------------*/
!cls
set display pagesize 0
display _newline(10) "           LIFE TABLES NOW BEING CALCULATED,"
display              "                     PLEASE WAIT. "
/*-------------------------- SORT -----------------------------------*/
sort %g intvl %t

/*-------------------- CALCULATE STATISTICS -------------------------*/
capture by %g: generate total=_N
capture by %g: generate tt=sum(%t)
capture by %g: generate td=sum(%d)
capture by %g: generate s=td*log(tt/td) if _n==_N
capture by %g intvl: gen dead=sum(%d)
capture by %g intvl: gen lost=_N
capture by %g intvl: keep if _n==_N
macro define gtot=_N
capture by %g: gen start=total
capture by %g: gen atrisk=total
capture by %g: replace start=start[_n-1] -lost[_n-1] if _n>1
capture by %g: replace atrisk=start-(lost-dead)/2
capture by %g: gen fail=dead/atrisk
capture by %g: gen dintvl=(intvl[_n+1]-intvl[_n])
capture by %g: gen hazard=2*fail/((2-fail)*dintvl)
capture by %g: gen se_hzrd=hazard*sqrt((1-(dintvl*hazard/2)^2)/(atrisk*fail))
capture by %g: gen csurv=1-fail
capture by %g: gen surv=1
capture by %g: replace surv=surv[_n-1]*csurv[_n-1] if _n>1
capture by %g: gen failed=1-surv
capture by %g: gen v1=fail/(atrisk-dead)
capture by %g: gen sv1=sum(v1)
capture by %g: gen se=surv[_n-1]*sqrt(sv1[_n-1]) if _n>1
capture by %g: replace se=0 if _n==1
capture by %g: gen upper=failed+1.96*se
capture by %g: gen lower=failed-1.96*se
capture by %g: gen uppse=hazard+1.96*se_hzrd
capture by %g: gen lowse=hazard-1.96*se_hzrd
/*------------------------- GRAPH -----------------------------------*/
!cls
set display pagesize 23
graph failed upper lower intvl, by(%g) xlab ylab  c(lII) s(oii) /*
*/  b1("DAYS AFTER ADMISSION") b2(" ") l1("PROPORTION DEAD")
/*===================================================*/
graph hazard uppse lowse intvl, by(%g) xlab ylab c(lII) s(oii) /*
*/  b1("DAYS AFTER ADMISSION") b2(" ") l1("HAZARD OF DEATH")
/*===================================================*/

/*-----------------------VARIABLE LABELS ----------------------------*/
capture label variable start "Begin Totl"
capture label variable dead " Deaths "
capture label variable lost " Lost "
capture label variable atrisk " At Risk "
capture label variable fail "Prop Fail "
capture label variable csurv "Prop Surv "
capture label variable surv "Cum Surv "
capture label variable failed "Cum Fail "
capture label variable se "Std Error "
capture label variable upper "Upper Lim "
capture label variable lower "Lower Lim "
capture macro define v=1
capture macro define vtest=0

/*---------------------- TABLE PRESENTATION (failed)----------------*/
set display pagesize 0
while %vtest<=%gtot {
!cls
display _newline(5) _column(24) "RESULTS OF LIFE TABLE ANALYSIS--FAILED"
display "Interval","Beg Totl" "  Deaths" "  # Lost" "  Cum Fail", "Std Err" " Upper Lim","Lower Lim"
while %v<=%inum & %g[_n+%vtest]~=. & (%v==1 | "%vtest"=="%gtot" |/*
      */  (%v~=1 & %g[_n+%vtest]<=%g[_n+%vtest-1])) {
  display %3.0f=intvl[_n+%vtest],"days",%8.0f=start[_n+%vtest] %8.0f=dead[_n+%vtest] /*
          */ %8.0f=lost[_n+%vtest] /*
          */ %10.6f=failed[_n+%vtest] %7.4f=se[_n+%vtest] /*
          */ %9.4f=upper[_n+%vtest] %9.4f=lower[_n+%vtest]
  capture macro define v=%v+1
  capture macro define vtest=%vtest+1
                                                           }
macro define v=1
display _column(5) "VARIABLES:   TIME TO EVENT= %t    EVENT MARKER=%d    TIME UNIT=%unit"
display _column(25) "DATASET USED:  %filename"
if "%g"~="x" {display _column(25) "GROUPING VARIABLE %g = "%g`[_n+%vtest-1]}
display "                           PRESS ENTER TO CONTINUE" _request(c)
if %vtest==%gtot {macro define vtest=%vtest+1}*/
                    }
/*=========================================*/
capture macro define v=1
capture macro define vtest=0
/*---------------------- TABLE PRESENTATION (hazard)-----------------*/
while %vtest<=%gtot {
!cls
display _newline(5) _column(21) "RESULTS OF LIFE TABLE ANALYSIS--HAZARD"
display "Interval","Beg Totl" "  Cum Fail" " Std Err" "   Hazard "  /*
     */ "  Std Err"  " Upper Lim","Lower Lim"
while %v<=%inum & %g[_n+%vtest]~=. & (%v==1 | "%vtest"=="%gtot" |/*
      */  (%v~=1 & %g[_n+%vtest]<=%g[_n+%vtest-1])) {
  display %3.0f=intvl[_n+%vtest],"days",%8.0f=start[_n+%vtest] /*
          */ %8.5f=failed[_n+%vtest] %9.4f=se[_n+%vtest] /*
          */ %10.5f=hazard[_n+%vtest],%9.5f=se_hzrd[_n+%vtest] /*
          */ %9.5f=uppse[_n+%vtest] %9.5f=lowse[_n+%vtest]
  capture macro define v=%v+1
  capture macro define vtest=%vtest+1
                                                    }
macro define v=1
display _column(5) "VARIABLES:   TIME TO EVENT= %t    EVENT MARKER=%d    TIME UNIT=%unit"
display _column(25) "DATASET USED:  %filename"
if "%g"~="x" {display _column(25) "GROUPING VARIABLE %g = "%g`[_n+%vtest-1]}
display "                           PRESS ENTER TO CONTINUE" _request(c)
if %vtest==%gtot {macro define vtest=%vtest+1}
                    }
/*=========================================*/

/*--------------FIRST SET OF CHI SQUARE STATISICS -------------------*/
!cls
set display pagesize 23
if "%g"~="x" {
  quietly by %g: keep if _n==_N
  quietly gen st=sum(td)*log(sum(tt)/sum(td))
  quietly gen ss=sum(s)
  quietly gen chi2=2*(st-ss) if _n==_N
  quietly gen df=_N-1 if _n==_N
  quietly gen p_value=chiprob(df,chi2)
  display "Likelihood ratio test statistic for homogeneity (group=%g):"
  display " "
  display "Chi2 (" df[_N] ") = " chi2[_N] ",   P = " p_value[_N]
 }

/*------------- SECOND SET OF CHI SQUARE STATISICS ------------------*/
capture use _U_S_E_R, clear
display " "
if "%g"~="x" {
  display "Logrank test of homogeneity (group=%g):"
  logrank %t %d, by(%g)
             }
end

