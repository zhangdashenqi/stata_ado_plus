program define hangroot_ex
	Msg preserve
	preserve
	if "`1'" == "1" {
		Xeq sysuse nlsw88, clear
		Xeq gen ln_w = ln(wage)
		Xeq reg ln_w grade age ttl_exp tenure
		Xeq predict resid, resid
		Xeq hangroot resid
	}
	if "`1'" == "2a" {
		Xeq sysuse nlsw88, clear
		Xeq gen ln_w = ln(wage)
		Xeq reg ln_w grade age ttl_exp tenure union
		Xeq predict resid2, resid
		Xeq hangroot resid2
	}

	if "`1'" == "2b" {
		qui sysuse nlsw88, clear
		qui gen ln_w = ln(wage)
		qui reg ln_w grade age ttl_exp tenure union
		qui predict resid2, resid
		Xeq hangroot resid2, ci susp theoropt(lpattern(-))
	}
	if "`1'" == "2c" {
		qui sysuse nlsw88, clear
		qui gen ln_w = ln(wage)
		qui reg ln_w grade age ttl_exp tenure union
		qui predict resid2, resid
		Xeq hangroot resid2, ci susp notheor
	}

	if "`1'" == "3a" {
		Xeq sysuse nlsw88, clear
		capture lognfit wage
		if _rc {
			di as error "this example can only be run when lognfit is installed from SSC"
			exit 198
		}
		Xeq lognfit wage
		Xeq hangroot, ci
	}
	if "`1'" == "3b" {
		Xeq sysuse nlsw88, clear
		Xeq hangroot wage, dist(lognormal) ci
	}
	if "`1'" == "4" {
		Xeq sysuse nlsw88, clear
		Xeq hangroot wage, dist(theoretical collgrad)
	}
	Msg restore 
	restore
end

program Msg
        di as txt
        di as txt "-> " as res `"`0'"'
end

program Xeq, rclass
        di as txt
        di as txt `"-> "' as res `"`0'"'
        `0'
end
