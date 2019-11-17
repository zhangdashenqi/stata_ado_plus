*! Version 1.1.1 NJC/CFB 17 October 1999  (STB-52 ip29)
* NJC 1.1.0 8 October 1999
* NJC 1.0.1 27 May 1999
* NJC 1.0.0 11 May 1999
program def archcopy
        version 6.0
        if "`0'" == "" {
                di in g "syntax: " in w "archcopy " /*
                */ in g "filename.ext [" in w ","   /*
                */ in g " copy_options]"
                exit 198
        }
        gettoken file 0 : 0 , parse(" ,")
        syntax [, PUBlic Text replace ]
        local dir : sysdir STBPLUS
        local init = substr("`file'",1,1)
        local dirsep = cond("$S_OS" == "MacOS", ":", "/")

        #delimit ;
        copy http://fmwww.bc.edu/repec/bocode/`init'/`file'
             `dir'`init'`dirsep'`file', `public' `text' `replace' ;
        #delimit cr
end



