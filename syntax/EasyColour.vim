" Easy Colour:
"   Author:  A. S. Budden <abudden _at_ gmail _dot_ com>
" Copyright: Copyright (C) 2011 A. S. Budden
"            Permission is hereby granted to use and distribute this code,
"            with or without modifications, provided that this copyright
"            notice is copied with it. Like anything else that's free,
"            the EasyColour plugin is provided *as is* and comes with no
"            warranty of any kind, either expressed or implied. By using
"            this plugin, you agree that in no event will the copyright
"            holder be liable for any damages resulting from the use
"            of this software.

" ---------------------------------------------------------------------
syn clear

redir => highlights
silent hi
redir END

let lines = split(highlights, '\n')
let keywords = []
for line in lines
	let keyword = split(line)[0]
	let keywords += [keyword,]
endfor

syn clear vimVar

syn match Keyword /^\k\+:/me=e-1
for keyword in keywords
	if keyword =~ '^\k*$'
		execute 'syn match '.keyword." /^\t".keyword.":/ms=s+1,me=e-1"
	endif
endfor


let b:current_syntax = "EasyColour"
