def! Permalink()
	echo "Permalink!TODO"
	var current_file = expand("%")
enddef

command! -range Permalink call Permalink()
