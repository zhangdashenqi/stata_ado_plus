program define prcompw
*! version 1.0.0  <01Sep98>      STB-47 sg101
** Author:  John R. Gleason, Syracuse University, Syracuse NY, USA
**          (loesljrg@ican.net)
** Dialog-driven version of -prcomp-

   version 5.0
   window control clear
   macro drop DB*
   local varlist opt
   parse "`*'"
   global DB_var "`varlist'"

   global DB_CIx   "x 0"
   window control button   /*
      */    "Confidence Intervals" 5  4 80  9 DB_CIx default
   global DB_Tst   "x 1"
   window control button   /*
      */    "Significance Tests" 85  4 80  9 DB_Tst
   global DB_Ref 0
   window control check "Refresh" 170 4 65 9 DB_Ref
   global DB_ex   "exit 3000"
   window control button "Exit" 269  4 30  9 DB_ex  escape
   global DB_hlp  "whelp prcompw"
   window control button "Help" 239  4 30  9 DB_hlp help
   global DB_Yvar "Response (Y)"
   window control static DB_Yvar  5 17 56  8 center
   window control scombo DB_var   5 26 56 85 DB_VarY
   global DB_Xvar "Groups (X)"
   window control static DB_Xvar  65 17 56  8 center
   window control scombo DB_var   65 26 56 85 DB_VarX
   window control radbegin "a-"  125 17 17 8 DB_Wgt
   window control radend   "f- weight"  144 17 36 8 DB_Wgt
   global DB_Wgt 2
   window control scombo DB_var   125 26 56 85 DB_VarW
   global DB_Ifq "< if >"
   window control static DB_Ifq  185 17 75  8 center
   window control edit 185 26 75 9 DB_IF
   global DB_Inq "< in >"
   window control static DB_Inq  264 17 35  8 center
   window control edit 264 26 35 9 DB_IN
   window control static DB_Ifq  5 39 294 73 blackframe
   global DB_Lev "$S_level"
   window control edit 12 43 22 8 DB_Lev
   global DB_Lvtx "Conf. level"
   window control static DB_Lvtx 38 43 40 8 left
   window control check "Simult. (Tukey wsd)" 10 53 72 8 DB_Dst
   window control radbegin "Unequal SDs"     10 69 60 8 DB_eSD
   window control radio    "ANOVA Pooled SD" 10 77 70 8 DB_eSD
   window control radend   "Other (below)"   10 85 70 8 DB_eSD
   global DB_eSD 2
   window control edit 10  94 38 8 DB_ESD
   window control edit 52 94 30 8 DB_DFE
   global DB_Etx1 "Sigma"
   window control static DB_Etx1 10 103 38 8 center
   global DB_Etx2 "d.f."
   window control static DB_Etx2 52 103 30 8 center
   window control static DB_Ifq  86 39 213 73 blackframe

   global DB_Xord "Labels labels Means means Natural natural"
   window control scombo DB_Xord 90 43 60 42 DB_xord
   global DB_xord "Natural"
   global DB_XOtx "Display order of X levels"
   window control static DB_XOtx 90 53 90 8 left
   global DB_Ulab 1
   window control check "Use X value labels" 90 63 80 8 DB_Ulab
   global DB_AOV 0
   window control check "ANOVA summary table" 185 43 100 8 DB_AOV
   global DB_Mns 1
   window control check "Table of Y means and SEs" 185 53 100 8 DB_Mns
   global DB_Tab 1
   window control check "Table of intervals (tests)"  /*
      */    185 63 100 8 DB_Tab
   global DB_Gph 0
   window control check "Graph intervals (tests)" 90 85 90 8 DB_Gph
   global DB_Leg 1
   window control check "Show legend" 185 85 90 8 DB_Leg
   window control edit 90  94 205 8 DB_GphOp
   global DB_Gphtx "Graph options"
   window control static DB_Gphtx 90 103 205 8 center

   cap noi window dialog "Pairwise Comparisons > $S_FN"  . . 307 126
   macro drop DB*
   exit 0
end


program define x
   if "$DB_VarY"=="" | "$DB_VarX"=="" {
      window stopbox stop "Must choose a response variable (Y)" /*
         */ "and a group variable (X)"
      exit
   }
   if "$DB_VarW" != "" {
      local a "fweight= "
      if $DB_Wgt == 1 { local a "aweight= " }
   }
   local weight "[`a'$DB_VarW]"
   if "$DB_IF" != "" {
      if substr(ltrim("$DB_IF"), 1, 2) != "if" { local if "if " }
      local if "`if'$DB_IF "
   }
   if "$DB_IN" != "" {
      if substr(ltrim("$DB_IN"), 1, 2) != "in" {
         local if "`if'in "
      }
      local if "`if'$DB_IN"
   }
   local a "$DB_VarY $DB_VarX `weight' `if'"
   local stdrng "t"
   if $DB_Dst == 1 {
      qui cap which qsturng
      if _rc {
         window stopbox stop "qsturng.ado not found"
         exit
      }
      local stdrng "stdrng"
      if $DB_eSD == 1 {
         window stopbox stop  /*
            */  "options Unequal SDs and Tukey" "cannot be combined"
         exit
      }
   }
   local order = substr("$DB_xord", 1, 1)
   if index(" LMN", upper("`order'")) < 2 { local order "N" }
   local lbl : value label $DB_VarX
   if !$DB_Ulab { local lbl }
   if $DB_Ref { macro drop PrCmp* }
   prcmp0 `a'     /* the base calculations are in place */
   local R = rowsof(PrCmp0)  /* R == #(levels)+1 */
   if $DB_eSD == 2 {
      local sigma = PrCmp0[`R',3]
      local nu = PrCmp0[`R',1]
   }
   else if $DB_eSD == 3 {
      if ("$DB_ESD"=="") | ("$DB_DFE"=="") {
         window stopbox stop "Must supply both Sigma and d.f."
         exit
      }
      local sigma "$DB_ESD"
      local nu "$DB_DFE"
   }
   local R = `R' - 1
   prcmp1x 1 `1'
   if $DB_AOV == 1 { noi oneway `a' }
   if $DB_Mns == 1 { prcmp4 `R' `order' $DB_VarY $DB_VarX `lbl' }
   local level "$DB_Lev"
   if `level' > 1 { local level = `level' / 100 }
   local a "`level' `stdrng'"
   if $DB_eSD != 1 { local a "`a' `sigma' `nu'" }

   if `1' { local test "t" }
   prcmp1 `a'
   prcmp1x 2 `test'
   if !($DB_Gph + $DB_Tab) { exit }
   if "`test'" != "" { local test 2 }
   else { local test 3 }
   if $DB_Gph { global PrComp_G "$DB_GphOp" }
   prcmp`test' `R' `order' $DB_Tab $DB_Gph $DB_Leg `lbl'
   macro drop PrComp_G PrCmp1x
end
