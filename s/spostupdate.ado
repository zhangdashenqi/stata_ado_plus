//  Uninstall and re-install spost9_ado

program define spostupdate
    capture ado uninstall spost9_ado
    net from http://www.indiana.edu/~jslsoc/stata/
    net install spost9_ado
end
