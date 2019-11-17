*! 1.0.1  24mar2000  Jeroen Weesie/ICS
program define mati, rclass
	version 6.0

	tempname ans
	matrix `ans' = `0'

	mat list `ans', title("Answer: (unnamed)") noheader
	return matrix ANS `ans'
end
exit

mati W'
mati inv(e(V)'*e(V))
mati w2
