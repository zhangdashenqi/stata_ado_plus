program define ranksamplediff, rclass
  quietly {
    sum `1' if `2'==`3', meanonly
    local y1=r(mean)
    sum `1' if `2'==`4', meanonly
    local y2=r(mean)
    local diff=`y1'-`y2'
  }
  return scalar diff = `diff'
end

