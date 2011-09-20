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
	if &cp || (exists('g:loaded_EasyColourTranslate') && (g:plugin_development_mode != 1))
		throw "Already loaded"
	endif
catch
	finish
endtry
let g:loaded_EasyColourTranslate = 1

let s:RGBMap = {}
let s:loaded_rgb_map = 0
let s:calculated_available_colours = 0

" 88 Colour and 256 Colour terminals are calculated on the fly
let s:available_colours = 
			\ {
			\     'CT8': 
			\         [
			\             'Black',
			\             'DarkBlue',
			\             'DarkGreen',
			\             'DarkCyan',
			\             'DarkRed',
			\             'DarkMagenta',
			\             'Brown',
			\             'Grey',
			\         ],
			\     'CT16':
			\         [
			\             'Black',
			\             'DarkBlue',
			\             'DarkGreen',
			\             'DarkCyan',
			\             'DarkRed',
			\             'DarkMagenta',
			\             'Brown',
			\             'Grey',
			\             'DarkGrey',
			\             'Blue',
			\             'Green',
			\             'Cyan',
			\             'Red',
			\             'Magenta',
			\             'Yellow',
			\             'White',
			\         ],
			\ }

" Colours that might not be in RGB.txt: map to existing colour
let s:missing_colour_map = {
			\ 'darkyellow': 'brown'
			\ }

let s:available_rgb_colours = {}

function! s:CalculateAvailableRGBColours()
	if ! s:loaded_rgb_map
		call s:LoadRGBMap()
	endif
	for k in ['CT8', 'CT16']
		let s:available_rgb_colours[k] = {}
		for colour in s:available_colours[k]
			let s:available_rgb_colours[k][colour] = s:RGBMap[tolower(colour)]
		endfor
	endfor

	let s:available_rgb_colours['CT256'] = {}

	" 88/256 Colour Table consists of 16 colours as CT16,
	" A cube of 6x6x6 colours and then a selection
	" of greys.
	for c in range(len(s:available_colours['CT16']))
		let s:available_rgb_colours['CT256'][c] = s:available_rgb_colours['CT16'][s:available_colours['CT16'][c]]
	endfor

	" Handle the colour cube - (colours 16-231)
	for r in range(6)
		for g in range(6)
			for b in range(6)
				let colour_num = 16 + (r*36) + (g*6) + b
				let cv = []
				for x in [r,g,b]
					if x > 0
						let xv = (x*40) + 55
					else
						let xv = 0
					endif
					let cv += [xv]
				endfor
				let s:available_rgb_colours['CT256'][colour_num] = cv
			endfor
		endfor
	endfor

	for grey in range(24)
		let level = (grey*10) + 8
		let s:available_rgb_colours['CT256'][232+grey] = [level,level,level]
	endfor
	let s:calculated_available_colours = 1
endfunction

function! s:LoadRGBMap()
	let rgb_files = split(globpath(&rtp, 'rgb.txt'),',')
	if len(rgb_files) < 1
		echoerr "Could not find rgb.txt"
	endif
	let s:RGBMap = {}
	for rgb_file in rgb_files
		let entries = readfile(rgb_file)
		for entry in entries
			if entry[0] == '!'
				continue
			endif
			" Remove leading and trailing whitespace and sort out formatting:
			let entry = substitute(entry, '^\s*\(\d\+\)\s\+\(\d\+\)\s\+\(\d\+\)\s\+\(.\{-}\)\s*$', '\1 \2 \3\t\4', '')
			" Split on tabs to separate numbers and name
			let parts = split(entry, '\t\+')
			let numbers = split(parts[0], '\s\+')
			if len(numbers) != 3
				echoerr "Wrong length in number split: '" . entry . "' (" . parts[0] . ")"
			endif
			let name = substitute(tolower(parts[1]), '\s\+', '', 'g')

			let colour = [str2nr(numbers[0]), str2nr(numbers[1]), str2nr(numbers[2])]
			let s:RGBMap[name] = colour
		endfor
	endfor
	let s:loaded_rgb_map = 1
endfunction

function! s:RGBToHex(colour)
	return printf('#%02X%02X%02X', a:colour[0], a:colour[1], a:colour[2])
endfunction

function! EasyColour#Translate#FindNearest(subset, colour)
	if ! s:calculated_available_colours
		call s:CalculateAvailableRGBColours()
	endif

	if ! has_key(s:available_rgb_colours, a:subset)
		echoerr "Unrecognised subset: " . a:subset
	endif

	if ! s:loaded_rgb_map
		call s:LoadRGBMap()
	endif

	let colour_key = tolower(a:colour)
	if colour_key =~ '^#\x\{6}$'
		let req_rgb_colour = [str2nr(colour_key[1:2], 16), str2nr(colour_key[3:4], 16), str2nr(colour_key[5:6], 16)]
	elseif has_key(s:RGBMap, colour_key)
		let req_rgb_colour = s:RGBMap[colour_key]
	elseif has_key(s:missing_colour_map, colour_key)
		let req_rgb_colour = s:RGBMap[s:missing_colour_map[colour_key]]
	else
		echoerr "Unrecognised colour: '" . a:colour . "'"
	endif

	let min_distance = 0
	let closest_colour = ''
	for subset_colour in keys(s:available_rgb_colours[a:subset])
		let rgb_colour = s:available_rgb_colours[a:subset][subset_colour]

		" Now find the 'distance' to each colour
		let distance = s:ColourDistance(req_rgb_colour, rgb_colour)
		if closest_colour == '' || distance < min_distance
			let min_distance = distance
			let closest_colour = subset_colour
		endif
	endfor
	return [min_distance, closest_colour]
endfunction

function! s:ColourDistance(colour1, colour2)
	let xdiff = a:colour1[0] - a:colour2[0]
	let ydiff = a:colour1[1] - a:colour2[1]
	let zdiff = a:colour1[2] - a:colour2[2]

	let distance = sqrt((xdiff*xdiff)+(ydiff*ydiff)+(zdiff*zdiff))
	return distance
endfunction

" Debug functions:
function! EasyColour#Translate#PrintRGBMap()
	if ! s:loaded_rgb_map
		call s:LoadRGBMap()
	endif
	echo s:RGBMap
endfunction

function! EasyColour#Translate#PrintColours()
	if ! s:loaded_rgb_map
		call s:LoadRGBMap()
	endif
	call s:CalculateAvailableRGBColours()

	echo len(keys(s:available_rgb_colours['CT256']))
	echo s:available_rgb_colours['CT256']
endfunction
