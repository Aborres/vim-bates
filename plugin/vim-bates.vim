
let g:bates_show_abs_paths = 0 "Show full paths in popup window

let g:bates_load_to_line      = 0 "Jump to exact line of saved file
let g:bates_load_to_column    = 0 "Jump to exact column of saved file
let g:bates_allow_duplicates  = 1 "Allow duplicated files in saved list
let g:bates_switch_focus      = 1 "Focus to buffer instead of reopening file
let g:bates_temp_files_scroll = 0 "0: Down, 1: Up 
let g:bates_max_temp_files    = 9 "Size of list for temp files, max of 9
let g:bates_sort_by           = 0 "0:Sort by key, 1: Sort by file

let g:bates_search_pool       = 0  "0:Use list of tracked files, 1:Use file list from main pannel
let g:bates_num_file_tracking = 20 "Only effective is g:bates_search_pool == 0 
let g:bates_search_ignorecase = 1 
let g:bates_fuzzy_search      = 1 

let g:bates_search_cursor = '|'

"Read only
let g:bates_opened_files = [] "List of files that got opened [1-9]
let g:bates_saved_files  = [] "List of cached files any key except [1-9]

let g:bates_files_list = []

let g:bates_text = []

let g:bates_file_tracking = []

func! BatesInit() abort
  call bates#plugin#init()
endfunc

func! BatesReset() abort
  call bates#plugin#reset()
endfunc

func! BatesClearAll() abort
  call bates#plugin#clear_all()
endfunc

func! BatesCacheFileAt(key, file) abort
  call bates#plugin#cache_file_at(a:key, a:file)
endfunc

func! BatesCacheFocusedFileAt(key) abort
  call bates#plugin#cache_focused_file_at(a:key)
endfunc

func! BatesRequestKeyForFocusedFile() abort
  call bates#plugin#request_key_for_focused_file()
endfunc

func! BatesRequestKeyForFile(file) abort
  call bates#plugin#request_key_for_file(a:file)
endfunc

func! BatesCacheOpenedFile() abort
  call bates#plugin#cache_opened_file()
endfunc

func! Bates() abort
  call bates#plugin#bates()
endfunc

autocmd BufReadPost,BufNewFile * call BatesCacheOpenedFile()

