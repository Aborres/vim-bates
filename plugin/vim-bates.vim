
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

let g:bates_search_cursor = '|'

"Read only
let g:bates_opened_files = [] "List of files that got opened [1-9]
let g:bates_saved_files  = [] "List of cached files any key except [1-9]

let g:bates_files_list = []

let g:bates_text = []

let g:bates_file_tracking = []

"Internal
let s:bates_init = 0

let g:bates_main_page = 0
let g:bates_search    = 1
let g:bates_curr_page = g:bates_main_page

let g:bates_search_mode_input    = 0
let g:bates_search_mode_navigate = 1
let g:bates_search_mode = g:bates_search_mode_input

let g:bates_search_filter = g:bates_search_cursor

let g:bates_idx = 0

func! BatesInit() abort
  if (!s:bates_init)
    let s:bates_init = 1
  endif
endfunc

func! BatesReset() abort
  call BatesInit()

  let g:bates_idx = 0
  let g:bates_curr_page   = g:bates_main_page
  let g:bates_search_mode = g:bates_search_mode_input
endfunc

func! BatesClearAll() abort
  let l:bates_saved_files = []
  let g:bates_opened_files = []
  let g:bates_files_list = []
  let g:bates_text = []
  let g:bates_search_filter = g:bates_search_cursor

  let g:bates_idx = 0
  let g:bates_curr_page   = g:bates_main_page
  let g:bates_search_mode = g:bates_search_mode_input

  call BatesReset()
endfunc

func! BatesCacheFileAt(key, file) abort

  if (a:key =~ '[1-9]')
    return
  endif

  call bates#plugin#cache_file(a:key, g:bates_saved_files, a:file, g:bates_allow_duplicates)
endfunc

func! BatesCacheFocusedFileAt(key) abort
  let l:file = bates#plugin#get_focused_file()
  call BatesCacheFileAt(a:key, l:file)
endfunc

func! BatesRequestKeyForFocusedFile() abort
  let l:key = bates#plugin#get_key()
  call BatesCacheFocusedFileAt(l:key)
endfunc

func! BatesRequestKeyForFile(file) abort
  let l:key = bates#plugin#get_key()
  call BatesCacheFileAt(l:key, a:file)
endfunc

func! BatesCacheOpenedFile() abort

  if (!bates#plugin#is_focused_valid())
    return
  endif

  call bates#plugin#trackfile()

  let l:count = len(g:bates_opened_files)
  if (l:count != bates#plugin#max_temp())

    let l:pos = l:count + 1 
    call bates#plugin#cache_focused_file(l:pos, g:bates_opened_files, 0)

  else

    let l:id = 1
    let l:i_pos = 0
    let l:r_pos = -1

    if (g:bates_temp_files_scroll) "Up
      let l:id = bates#plugin#max_temp()
      let l:i_pos = bates#plugin#max_temp()
      let l:r_pos = 0
    endif
    
    call bates#plugin#scroll_temp_list(l:id, l:i_pos, l:r_pos)

  endif

endfunc

func! Bates() abort

  call BatesReset()

  let l:ve_args = #{
          \ title:'Bates',
          \ filter: 'bates#plugin#filter',
          \ callback: 'bates#plugin#callback',
          \ borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
          \ resize: 1,
          \ highlight: 'Normal',
          \ wrap: 0,
          \ scrollbar: 1,
          \ close: 'none'
        \}

  let l:popup = popup_menu("", l:ve_args)
  call bates#text#main_page(l:popup)

endfunc

autocmd BufReadPost,BufNewFile * call BatesCacheOpenedFile()

