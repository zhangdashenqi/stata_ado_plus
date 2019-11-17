program define sddiff, rclass
    quietly {
      sum `1' if `2'==`3'
      local sd1=r(sd)
      sum `1' if `2'==`4'
      local sd2=r(sd)
      local sddiff=`sd1'-`sd2'
    }
    return scalar sddiff = `sddiff'
end

