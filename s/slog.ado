*! version 2.0.0 July 23, 2002 @ 14:13:53
*! uses a log stack to allow nested logging
program define slog
version 7
	/* 2.0.0 -- first update since sept 1995 - allows spaces in file names, uses newer syntax, exploits smcl */
	/* 1.1.1 -- put in noproc as option (which was missing before (oops)) */
	/* this will go beserk if a log gets used somewhere by mistake! */
	/* creates & uses two global macros: */
	/*  S_LOG for the current log file, and */
	/*  S_LOGSTK for the log stack (i.e. containing log files) */

	/* try to see if the using clause is in use */

	capture syntax using/ [, REPLACE APPEND NOProc Text Smcl noLink]
	local rc = _rc
	if `rc' {

		/* first check to see if 'using' was left off */

		if (`rc' == 100) | (`rc' == 101) {
			
			gettoken action 0 : 0, parse(" ,")

			syntax [, noLink]

			if "`action'"=="flush" {    /* erases the slog stack and closes the log file */
				global S_LOGSTK
				capture log close
				exit
				}

			if "`action'"=="close" {

				/* code for popping log file */
				/* no need for much fuss if there is no log stack */
				if `"$S_LOGSTK"' != "" {
					quietly log
					local theLog `"`r(filename)'"'
					_pop $S_LOGSTK
					local next `"`s(head)'"'
					global S_LOGSTK `"`s(tail)'"'
					if "`link'"=="" {
						display as text _newline "Going back to slog with " in smcl `"{view `"`"`next'"'"'}"' _newline
						}
					log close
					log using `"`next'"', append
					if "`link'"=="" {
						display as text _newline "Just returned from slogging with " in smcl `"{view `"`"`theLog'"'"'}"' _newline
						}
					}
				else {
					log close
					}
				exit
				}

			if "`action'"=="on" {
				log on
				}
			else {
				if "`action'"=="off" {
					log off
					}
				else {
					display as error "slog says: bad syntax"
					exit 198
					}
				}
			
			}	/* done popping or closing or clearing */
		else {
			/* checking other error codes?!?! */
			if `rc' == 198 {
				display as error "slog says there is somehthing fishy with the syntax"
				exit 198
				}

			display as error "slog got lost: "
			error `rc'
			}	/* end checking other error codes */
		}	/* end code for errors in capture */
	else {
		/* know that the file is asking to start a log file */

		/* check to be sure that the file name has no semicolons in it *sigh* */

		if index(`"`using'"', `"""') {
				capture useless `"""'
			/* durn highlighting fails with unbalanced special quotes, so the previous line does nothing at all! */
			display as result "slog says it is risky to have quotes in file names!"
			}
		
		/* cannot pre-check for error in overwriting yet */
		/* 		if "`replace'`append'"=="" { */
		/* 			/\* sconfirm new log file `"`using'"' *\/ */
		/* 			} */

		if "`replace'"!="" {
			if "`append'"!="" {
				disp as error "slog says: Please do not specify both replace and append!"
				exit 198
				}
			}

		if "`text'"!="" {
			if "`smcl'"!="" {
				display as error "slog says: Please do not specify that the log file is both text and smcl!"
				exit 198
				}
			}

		/* will cause time stamps to be a bit off... */
		/* silly bouncing between log files to assure files only are closed if the new file can open */

		quietly log
		local theLog  `"`r(filename)'"'
		if `"`theLog'"'!="" {
			quietly log close
			
			capture log using `"`using'"', `replace' `append' `noproc' `text' `smcl'
			local rc = _rc
			if `rc' {
				quietly log using `"`theLog'"', append
				if `rc'==602 {
					display as error "file " `"`using'"' " exists!"
					exit 602
					}

				display as error `"slog says: had trouble opening the log file `"`using'"' when running the command"'
				display as error `"log using `"`using'"', `replace' `append' `noproc' `text' `smcl'"'
				error `rc'
				}

				quietly log
				local next `"`r(filename)'"'
				quietly log close
				
				if "`replace'"=="" {
					local append "append"
					}
				
				quietly log using `"`theLog'"', append
				
			if "`link'"=="" {
				display as text _newline "Going to slog with " in smcl `"{view `"`"`next'"'"'}"' _newline
				}
			log close

			}
		
		log using `"`using'"', `replace' `append' `noproc' `text' `smcl'

		if `"`theLog'"'!="" {
			if "`link'"=="" {
				display as text _newline "Just came from slogging with " in smcl `"{view `"`"`theLog'"'"'}"' _newline
				}
			_push `"`theLog'"' $S_LOGSTK
			global S_LOGSTK `"`s(list)'"'
			}
		}
end
