if exists("g:vimStudio_vaxe_init")
	if g:vimStudio_vaxe_init == 1
		finish
	endif
endif

let g:vimStudio_vaxe_init = 1

"-------------------------------------------------------------------------

let g:vimStudio_vaxe#plugin_dir = expand("<sfile>:p:h:h")

let g:vimStudio_vaxe#is_valid_project = 0

let g:vimStudio_vaxe#workdir = ""
let g:vimStudio_vaxe#project = ""
let g:vimStudio_vaxe#target = ""

"-------------------------------------------------------------------------

function! vimStudio_vaxe#set_vaxe_project_and_workdir()
	let g:vimStudio_vaxe#project = vimStudio#request(g:vimStudio#plugin_dir, "project", "get_conf_property", ['"' . g:vimStudio#buf#mask_bufname . '"', '"vaxe"', '"project"'])
	
	if len(g:vimStudio_vaxe#project) > 0
		let g:vimStudio_vaxe#workdir = vimStudio#request(g:vimStudio#plugin_dir, "project", "get_path_by_index", ['"' . g:vimStudio#buf#mask_bufname . '"', 0])
		let g:vimStudio_vaxe#project = g:vimStudio_vaxe#workdir . '/' . g:vimStudio_vaxe#project
		
		if filereadable(g:vimStudio_vaxe#project) != 1
			let g:vimStudio_vaxe#workdir = ""
			let g:vimStudio_vaxe#project = ""
			
			return 0
		endif
	endif
	
	return 1
endfunction

function! vimStudio_vaxe#set_vaxe_build_mode()
	let result = vimStudio#request(g:vimStudio#plugin_dir, "project", "get_conf_property", ['"' . g:vimStudio#buf#mask_bufname . '"', '"vimStudio"', '"projectType"'])
	
	if result == "lime"
		let g:vaxe_lime = g:vimStudio_vaxe#project
		let g:vaxe_lime_target = g:vimStudio_vaxe#target
	elseif result == "flow"
		let g:vaxe_flow = g:vimStudio_vaxe#project
		let g:vaxe_flow_target = g:vimStudio_vaxe#target
	elseif result == "hxml"
		let g:vaxe_hxml = g:vimStudio_vaxe#project
	endif
endfunction

function! vimStudio_vaxe#set_buffer_settings()
	if g:vimStudio_vaxe#is_valid_project == 1
		let vaxe_configured = 0
		
		if exists("b:vaxe_configured")
			let vaxe_configured = b:vaxe_configured
		endif
		
		if vaxe_configured == 0
			if exists("g:vaxe_lime") | let b:vaxe_lime = g:vaxe_lime | endif
			if exists("g:vaxe_flow") | let b:vaxe_flow = g:vaxe_flow | endif
			if exists("g:vaxe_hxml") | let b:vaxe_hxml = g:vaxe_hxml | endif
			
			let vimStudio_workdir = getcwd()
			
			loadview
			execute "cd" fnameescape(g:vimStudio_vaxe#workdir)
			call vaxe#AutomaticHxml()
			execute "cd" fnameescape(vimStudio_workdir)
			mkview
			
			let b:vaxe_configured = 1
		endif
	endif
endfunction

autocmd BufEnter ?* :call vimStudio_vaxe#set_buffer_settings()

"-------------------------------------------------------------------------

function! vimStudio_vaxe#on_project_before_open()
	let g:vimStudio_vaxe#is_valid_project = 0
	
	let g:vimStudio_vaxe#workdir = ""
	let g:vimStudio_vaxe#project = ""
	let g:vimStudio_vaxe#target = ""
	
	let projectType = vimStudio#request(g:vimStudio#plugin_dir, "project", "get_conf_property", ['"' . g:vimStudio#buf#mask_bufname . '"', '"vimStudio"', '"projectType"'])
	
	if projectType == "lime" || projectType == "flow" || projectType == "hxml"
		let result = vimStudio_vaxe#set_vaxe_project_and_workdir()
		
		if result == 1
			if exists("g:vaxe_lime") | unlet g:vaxe_lime | endif
			if exists("g:vaxe_lime_target") | unlet g:vaxe_lime_target | endif
			
			if exists("g:vaxe_flow") | unlet g:vaxe_flow | endif
			if exists("g:vaxe_flow_target") | unlet g:vaxe_flow_target | endif
			
			if exists("g:vaxe_hxml") | unlet g:vaxe_hxml | endif
			
			let g:vimStudio_vaxe#target = vimStudio#request(g:vimStudio#plugin_dir, "project", "get_conf_property", ['"' . g:vimStudio#buf#mask_bufname . '"', '"vaxe"', '"target"'])
			call vimStudio_vaxe#set_vaxe_build_mode()
			
			call add(g:vimStudio#integration#context_menu_dir, g:vimStudio_vaxe#plugin_dir . "/menu")
			let g:vimStudio_vaxe#is_valid_project = 1
		endif
	endif
	
	return 1
endfunction

function! vimStudio_vaxe#on_project_after_open()
	if g:vimStudio_vaxe#is_valid_project == 1
		if exists("g:vaxe_lime") == 1
			call vimStudio#request(g:vimStudio_vaxe#plugin_dir, "vaxe", "add_lime_source", ['"' . g:vimStudio#buf#mask_bufname . '"', '"' . g:vimStudio_vaxe#project . '"', '"' . g:vimStudio_vaxe#target . '"'])
			call vimStudio#request(g:vimStudio_vaxe#plugin_dir, "vaxe", "make_hxml_by_xml", ['"' . g:vimStudio#buf#mask_bufname . '"', '"' . g:vimStudio_vaxe#project . '"', '"' . g:vimStudio_vaxe#target . '"'])
		endif
		
		call vimStudio#request(g:vimStudio_vaxe#plugin_dir, "vaxe", "hxml_set_target", ['"' . g:vimStudio_vaxe#project . '"', '"' . g:vimStudio_vaxe#target . '"'])
	endif
	
	return 1
endfunction

function! vimStudio_vaxe#on_before_project_close()
	if g:vimStudio_vaxe#is_valid_project == 1
		let g:vimStudio_vaxe#workdir = ""
		let g:vimStudio_vaxe#project = ""
		let g:vimStudio_vaxe#target = ""
		
		let g:vimStudio_vaxe#is_valid_project = 0
		call remove(g:vimStudio#integration#context_menu_dir, index(g:vimStudio#integration#context_menu_dir, g:vimStudio_vaxe#plugin_dir . "/menu"))
	endif
	
	return 1
endfunction

function! vimStudio_vaxe#on_make_project()
	let continue_to_make = 1
	
	if g:vimStudio_vaxe#is_valid_project == 1
		let continue_to_make = 0
		make
	endif
	
	return continue_to_make
endfunction

function! vimStudio_vaxe#on_after_project_rename(old_mask_bufname)
	if g:vimStudio_vaxe#is_valid_project == 1
		call vimStudio#request(g:vimStudio_vaxe#plugin_dir, "vaxe", "rename_project", ['"' . a:old_mask_bufname .'"', '"' . g:vimStudio#buf#mask_bufname . '"', '"' . g:vimStudio_vaxe#project . '"'])
		call vimStudio_vaxe#set_vaxe_project_and_workdir()
		call vimStudio_vaxe#set_vaxe_build_mode()
	endif
	
	return 1
endfunction

function! vimStudio_vaxe#on_after_update_project()
	if g:vimStudio_vaxe#is_valid_project == 1
		call vimStudio#request(g:vimStudio_vaxe#plugin_dir, "vaxe", "update_sources", ['"' . g:vimStudio#buf#mask_bufname . '"', '"' . g:vimStudio_vaxe#project . '"'])
	endif
	
	return 1
endfunction

"-------------------------------------------------------------------------

function! vimStudio_vaxe#on_after_add_file(parent_index, file_path, new_name, is_copy, result)
	if g:vimStudio_vaxe#is_valid_project == 1
		if a:result == 1
			if vimStudio#request(g:vimStudio_vaxe#plugin_dir, "vaxe", "is_valid_file", ['"' . a:file_path . '"']) == 1
				let add_source = vimStudio#dialogs#confirm("Add hx-source?")
			else
				let add_source = 0
			endif
			
			if add_source == 1
				call vimStudio#request(g:vimStudio_vaxe#plugin_dir, "vaxe", "add_source", ['"' . g:vimStudio#buf#mask_bufname . '"', '"' . g:vimStudio_vaxe#project . '"', a:parent_index, '"' . a:file_path . '"', a:is_copy])
			endif
		endif
	endif
	
	return 1
endfunction

function! vimStudio_vaxe#on_before_delete_file(file_index, file_path, delete_from_disk)
	if g:vimStudio_vaxe#is_valid_project == 1
		if vimStudio#request(g:vimStudio_vaxe#plugin_dir, "vaxe", "is_valid_file", ['"' . a:file_path . '"']) == 1
			if vimStudio#request(g:vimStudio_vaxe#plugin_dir, "vaxe", "check_source_file", ['"' . a:file_path . '"']) == 1
				let delete_source = vimStudio#dialogs#confirm("Delete hx-source?")
			else
				let delete_source = 1
			endif
			
			if delete_source == 1
				call vimStudio#request(g:vimStudio_vaxe#plugin_dir, "vaxe", "delete_source", ['"' . g:vimStudio#buf#mask_bufname . '"', '"' . g:vimStudio_vaxe#project . '"', '"' . a:file_path . '"'])
			endif
		endif
	endif
	
	return 1
endfunction

function! vimStudio_vaxe#on_after_rename_file(file_index, selected_file, new_name, result)
	if g:vimStudio_vaxe#is_valid_project == 1
		if a:result == 1
			call vimStudio#request(g:vimStudio_vaxe#plugin_dir, "vaxe", "rename_source", ['"' . g:vimStudio#buf#mask_bufname . '"', '"' . g:vimStudio_vaxe#project . '"', '"' . a:selected_file . '"', '"' . a:new_name . '"'])
		endif
	endif
	
	return 1
endfunction

"-------------------------------------------------------------------------

function! vimStudio_vaxe#on_menu_item(menu_id)
	if g:vimStudio_vaxe#is_valid_project == 1
		if a:menu_id == "vaxe_build"
			make
			return 0
		endif
	endif
	
	return 1
endfunction

"-------------------------------------------------------------------------

call vimStudio#integration#register_module("vimStudio_vaxe")

call add(g:vimStudio#integration#project_template_dir, g:vimStudio_vaxe#plugin_dir . "/template/project")
call add(g:vimStudio#integration#file_template_dir, g:vimStudio_vaxe#plugin_dir . "/template/file")
