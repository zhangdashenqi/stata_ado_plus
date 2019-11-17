capture program drop graph2tex
program define graph2tex
  syntax , [ EPSfile(string) RESet NUMber CAPtion(string) LABel(string) ht(real 3) ]

  if "`epsfile'" == "" {
    if "$graph2tex_epsfile" != "" {
      local epsfile $graph2tex_epsfile
    }
    else {
      local epsfile defaultgraphname
    }
  }
  if "`reset'" != "" global graph2tex_graphnum = 0
  if "`number'" != "" {
    global graph2tex_graphnum = $graph2tex_graphnum + 1
    local epsfile `epsfile'$graph2tex_graphnum
  }

  quietly graph export `epsfile'.eps , replace 
  noisily display "% exported graph to `epsfile'.eps
  if ("`label'" != "") display "% We can see in Figure \ref{fig:`label'} that"
  display "\begin{figure}[h]"
  display "\begin{centering}"
  display "  \includegraphics[height=`ht'in]{`epsfile'}"
  if ("`caption'" != "") display "  \caption{`caption'}"
  if ("`label'" != "") display "  \label{fig:`label'}"
  display "\end{centering}"
  display "\end{figure}"
end
