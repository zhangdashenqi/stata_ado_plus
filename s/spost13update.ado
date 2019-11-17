//  Uninstall and re-install spost13 | long freese | 2013-03-12

program define spost13update
    capture ado uninstall spost9_ado
    capture ado uninstall test13_ado
    net from http://www.indiana.edu/~jslsoc/stata/
    net install test13_ado
    capture ado uninstall test9_legacy
    net from http://www.indiana.edu/~jslsoc/stata/
    net install test9_legacy
end

