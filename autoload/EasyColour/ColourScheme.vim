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

	let has_basis = 0
	if has_key(ColourScheme, 'Basis')
		if ColourScheme['Basis'] != 'None'
			exe 'runtime!' 'colors/' . ColourScheme['Basis'] . '.vim'
			let has_basis = 1
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
		if ! has_basis && ! has_key(ColourScheme[details], 'Normal')
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
let s:cterm_fields = {'FG': 'ctermfg', 'BG': 'ctermbg', 'Style': 'term'}
let s:all_cterm_fields = ['ctermfg', 'ctermbg', 'term']
let s:all_gui_fields = ['guifg', 'guibg', 'gui', 'guisp']
let s:field_order = ["FG","BG","SP","Style"]

function! s:StandardHandler(Colours)
	if has("gui_running")
		let colour_map = 'None'
		let field_map = s:gui_fields
		let all_fields = s:all_gui_fields
	else
		if &t_Co == 256
			let colour_map = 'CT256'
		elseif &t_Co == 16
			let colour_map = 'CT16'
		elseif &t_Co == 8
			let colour_map = 'CT8'
		else
			echoerr "Unrecognised terminal colour count"
		endif
		let field_map = s:cterm_fields
		let all_fields = s:all_cterm_fields
	endif

	for hlgroup in ['EasyColourNormalForce'] + keys(a:Colours)
		" Force Normal to be handled first...
		if hlgroup == 'Normal'
			continue
		elseif hlgroup == 'EasyColourNormalForce'
			if has_key(a:Colours, 'Normal')
				let hlgroup = 'Normal'
			else
				continue
			endif
		endif

		if hlgroup !~ '^\k*$'
			echoerr "Invalid highlight group: '" . hlgroup . "'"
		endif

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
				if has_key(field_map, definition[0])
					let internal_name = definition[0]
				elseif index(s:field_order, definition[0])
					" Probably supported by GUI and not CTERM... skip silently
					continue
				else
					echoerr "Unrecognised field: '" . definition[0] . "' with entry '" . hlgroup . "'"
				endif
				let colour_name = definition[1]
			else
				let internal_name = s:field_order[index]
				let colour_name = part
			endif
			let field = field_map[internal_name]

			if colour_map == 'None' || internal_name == 'Style'
				let colour = colour_name
			else
				let colour = EasyColour#Translate#FindNearest(colour_map, colour_name)
			endif

			let handled += [field]
			let command .= ' ' . field . '=' . colour
			let index += 1
		endfor
		for field in all_fields
			if index(handled, field) == -1
				let command .= ' ' . field . '=NONE'
			endif
		endfor

		"echo command
		exe command
	endfor
endfunction

function! s:AutoHandler(ColourScheme)
	echoerr "Not implemented yet"
endfunction
