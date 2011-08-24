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
try
	if &cp || (exists('g:loaded_EasyColourColourScheme') && (g:plugin_development_mode != 1))
		throw "Already loaded"
	endif
catch
	finish
endtry
let g:loaded_EasyColourColourScheme = 1

function! EasyColour#ColourScheme#LoadColourScheme(name)
	let ColourScheme = EasyColour#LoadDataFile#LoadColourSpecification(a:name)

	if has_key(ColourScheme, 'Background')
		let &background = tolower(ColourScheme['Background'])
	endif

	if has_key(ColourScheme, 'Basis')
		if ColourScheme['Basis'] != 'None'
			exe 'runtime!' 'colors/' . ColourScheme['Basis'] . '.vim'
		endif
	endif
	let g:colors_name = a:name

	if has_key(ColourScheme, 'Dark') && &background == 'dark'
		let details = 'Dark'
		let handler = 'Standard'
	elseif has_key(ColourScheme, 'Light') && &background == 'light'
		let details = 'Light'
		let handler = 'Standard'
	elseif has_key(ColourScheme, 'Dark') && &background == 'light'
		" These checks may need to be made more complicated
		" to include checking of LightAuto etc
		let handler = 'Auto'
	elseif has_key(ColourScheme, 'Light') && &background == 'dark'
		" These checks may need to be made more complicated
		" to include checking of DarkAuto etc
		let handler = 'Auto'
	else
		echoerr "No colour customisations defined"
	endif

	if handler == 'Standard'
		if ! has_key(ColourScheme[details], 'Normal')
			if &background == 'dark'
				let ColourScheme[details]['Normal'] = ["White","Black"]
			else
				let ColourScheme[details]['Normal'] = ["Black","White"]
			endif
		endif
		call s:StandardHandler(ColourScheme[details])
	elseif handler == 'Auto'
		call s:AutoHandler(ColourScheme)
	endif
endfunction

let s:gui_fields = {'FG': 'guifg', 'BG': 'guibg', 'Style': 'gui', 'SP': 'guisp'}
let s:all_gui_fields = ['guifg', 'guibg', 'gui', 'guisp']
let s:field_order = ["FG","BG","Style","SP"]

function! s:StandardHandler(Colours)
	for hlgroup in ['EasyColourNormalForce'] + keys(a:Colours)
		" Force Normal to be handled first...
		if hlgroup == 'Normal'
			continue
		elseif hlgroup == 'EasyColourNormalForce'
			let hlgroup = 'Normal'
		endif

		if hlgroup !~ '^\k*$'
			echoerr "Invalid highlight group: '" . hlgroup . "'"
		endif

		if has("gui_running")
			if type(a:Colours[hlgroup]) == type([])
				let group_colours = a:Colours[hlgroup]
			else
				let group_colours = [a:Colours[hlgroup]]
			endif
			let command = 'hi ' . hlgroup
			let index = 0
			let handled = []
			for part in group_colours
				if stridx(part, '=') != -1
					let definition = split(part, '=')
					if has_key(s:gui_fields, definition[0])
						let field = s:gui_fields[definition[0]]
					else
						echoerr "Unrecognised field: '" . definition[0] . "' with entry '" . hlgroup . "'"
					endif
					let colour = definition[1]
				else
					let field = s:gui_fields[s:field_order[index]]
					" This will be more complicated for non-GUI versions!
					let colour = part
				endif

				let handled += [field]
				let command .= ' ' . field . '=' . colour
				let index += 1
			endfor
			for field in s:all_gui_fields
				if index(handled, field) == -1
					let command .= ' ' . field . '=NONE'
				endif
			endfor
		else
			echoerr "Terminal implementation not complete yet, sorry!"
		endif

		"echo command
		exe command
	endfor
endfunction

function! s:AutoHandler(ColourScheme)
	echoerr "Not implemented yet"
endfunction
