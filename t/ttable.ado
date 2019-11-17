*! version 1.0.0 27apr00
program define ttable
  version 6.0
  display
  display in green "        Critical Values of Student's t"
  display in green "       .10     .05     .025    .01     .005    .0005  1-tail"
  display in green " df    .20     .10     .050    .02     .010    .0010  2-tail"
  if "`1'"~="" { tdisp `1' }
  else {
    local i = 1
    while `i'<=30 {
      tdisp `i'
      local i = `i' + 1
    }

    local i = 35
    while `i'<=100 {
      tdisp `i'
      local i = `i' + 5
    }
    local i = 120
    while `i'<=200 {
      tdisp `i'
      local i = `i' + 20
    }
  }
end

program define tdisp
  display %3.0f `1' "  " %6.3f invt(`1',.80) "  " %6.3f invt(`1',.90) "  " /*
    */ in green %6.3f invt(`1',.95) "  " in yellow %6.3f invt(`1',.98) "  " /*
    */  %6.3f invt(`1',.99) /*
    */ "  " %7.3f invt(`1',.999)
end
