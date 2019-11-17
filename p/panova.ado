
program define panova
 	version 7
 	local treat "`1'"
 	local x "`2'"
 	local subj "`3'"
 	quietly {
 		anova `x' `subj' `treat'
 		test `treat'
 		global S_1=r(F)
 	}
end
