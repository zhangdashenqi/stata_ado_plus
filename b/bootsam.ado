program define bootsam
   sum `1'
   gen ck=(1+(`2'/sqrt(_result(4)))^2)^-0.5
   gen ysm=ck*(`1'+`2'*invnorm(uniform()))
   drop ck	
end
