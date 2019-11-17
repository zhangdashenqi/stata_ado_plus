*! version 1.0.0  13oct2017  Ben Jann

program grstyle
    version 9.2
    gettoken cmd : 0, parse(", ")
    if `"`cmd'"'=="init" {
        grstyle_`0' // grstyle_init ...
        exit
    }
    if `"`cmd'"'=="clear" {
        grstyle_`0' // grstyle_clear
        exit
    }
    if `"`cmd'"'=="refresh" {
        grstyle_`0' // grstyle_refresh
        exit
    }
    grstyle_set `0'
end

program grstyle_init
    grstyle_clear // clear previous grstyle settings
    syntax [name(name=handle)] [, path(str) Replace ///
        append /// undocumented
        ]
    if `"`handle'"'=="" {
        if `"`path'"'!="" {
            di as err "path() only allowed with {bf:grstyle init} {it:newscheme}"
            exit 198
        }
        if "`replace'"!="" {
            di as err "replace only allowed with {bf:grstyle init} {it:newscheme}"
            exit 198
        }
        if "`append'"!="" {
            di as err "append only allowed with {bf:grstyle init} {it:newscheme}"
            exit 198
        }
        local handle _GRSTYLE_
        if `"`c(scheme)'"'==`"`handle'"' {
            di as err "somethings is wrong; scheme _GRSTYLE_ already active"
            exit 499
        }
        local path `"`c(sysdir_personal)'"'
        mata: grstyle_mkdir(st_local("path"))
        local replace replace
    }
    else {
        if `"`c(scheme)'"'==`"`handle'"' {
            di as err `"`handle' not allowed"' _c
            di as err  "; {it:newscheme} must be different from current scheme"
            exit 198
        }
    }
    mata: grstyle_fn(st_local("handle"), st_local("path")) // returns local fn
    tempname fh
    quietly file open `fh' using `"`fn'"', write `replace' `append'
    if "`append'"=="" {
        file write `fh' `"#include `c(scheme)'"' _n
    }
    file close `fh'
    global GRSTYLE_FN `"`fn'"'
    global GRSTYLE_PS `"`c(scheme)'"'
    set scheme `handle'
end

program grstyle_clear
    syntax [, erase ]
    if "`erase'"!="" {
        if `"${GRSTYLE_FN}"'!="" {
            erase `"${GRSTYLE_FN}"'
        }
    }
    if `"${GRSTYLE_PS}"'!="" {
        set scheme ${GRSTYLE_PS}
        FlushSchemeMemory
    }
    macro drop GRSTYLE_FN
    macro drop GRSTYLE_PS
end

program grstyle_set
    local fn `"${GRSTYLE_FN}"'
    if `"`fn'"'=="" {
        di as err "grstyle not initialized"
        exit 499
    }
    tempname fh
    file open `fh' using `"`fn'"', write append
    file write `fh' `"`0'"' _n
    file close `fh'
end

program grstyle_refresh
    if `"${GRSTYLE_FN}"'=="" {
        di as err "grstyle not initialized"
        exit 499
    }
    FlushSchemeMemory
end

program FlushSchemeMemory
    nobreak {
        capt gr_current grname :
        if _rc local grname
        if `"`grname'"'=="Graph" {
            tempname tmpgrname
            graph rename Graph `tmpgrname'
        }
        two scatteri 0 0, nodraw scheme(s2color)
        graph drop Graph
        if `"`grname'"'=="Graph" {
            graph rename `tmpgrname' Graph 
        }
    }
end

version 9.2
mata:
mata set matastrict on

void grstyle_fn(handle, path)
{
    if (pathisabs(path)==0) path = pathjoin(pwd(), path)
    st_local("fn", pathjoin(path, "scheme-" + handle + ".scheme"))
}

void grstyle_mkdir(path)
{
    real scalar      i
    string scalar    d
    string rowvector dlist
    pragma unset     d
    pragma unset     dlist
    
    if (direxists(path)) return
    if (path=="") return
    printf("{txt}PERSONAL directory (see {helpb personal}) does not exist")
    printf("; will create directory\n")
    printf("{txt}%s\n", path)
    printf("{txt}press any key to continue, or Break to abort\n")
    more()
    while (1) {
        pathsplit(path, path, d)
        dlist = dlist, d
        if (path=="") break
        if (direxists(path)) break
    }
    for (i=cols(dlist); i>=1; i--) {
        path = pathjoin(path, dlist[i])
        mkdir(path)
    }
}

end

