
let g:bates_show_abs_paths = 0 "Show full paths in popup window

let g:bates_load_to_line      = 0 "Jump to exact line of saved file
let g:bates_load_to_column    = 0 "Jump to exact column of saved file
let g:bates_allow_duplicates  = 1 "Allow duplicated files in saved list
let g:bates_switch_focus      = 1 "Focus to buffer instead of reopening file
let g:bates_temp_files_scroll = 0 "0: Down, 1: Up 
let g:bates_max_temp_files    = 9 "Size of list for temp files, max of 9
let g:bates_sort_by           = 0 "0:Sort by key, 1: Sort by file

let g:bates_opened_files = [] "List of files that got opened [1-9]
let g:bates_saved_files  = [] "List of cached files any key except [1-9]

let s:bates_init = 0

func! BatesInit() abort

  if (!s:bates_init)
    let s:bates_init = 1
  endif

endfunc

func! BatesReset() abort
  call BatesInit()

  call bates#plugin#set_idx(0)
endfunc

func! BatesClearAll() abort
  let l:bates_saved_files = []
  let g:bates_opened_files = []
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

func! s:GetKey() abort

  echo("Bates: press key to save file ") 
  let l:key = 0 
  let l:search = 1
  while l:search
    let l:key = nr2char(getchar())
    let l:valid_char = ((type(l:key) == v:t_string) && (l:key != ' ') && (l:key != ''))
    let l:search = !l:valid_char 
  endwhile
  redraw!
  echo("Bates: saved key: " . l:key)
  redraw!

  return l:key
endfunc

func! BatesRequestKeyForFile(file) abort
  let l:key = s:GetKey()
  call BatesCacheFileAt(l:key, a:file)
endfunc

func! BatesRequestKeyForFocusedFile() abort
  let l:key = s:GetKey()
  call BatesCacheFocusedFileAt(l:key)
endfunc

func! BatesCacheOpenedFile() abort

  if (!bates#plugin#is_focused_valid())
    return
  endif

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

func! BatesFilter(id, key) abort

  if (bates#plugin#check_enter(a:id, a:key))
    return 1
  endif

  if (bates#plugin#check_esc(a:id, a:key))
    return 1
  endif

  if (bates#plugin#check_shortcut(a:id, a:key, g:bates_saved_files))
    return 1
  endif

  if (bates#plugin#check_shortcut(a:id, a:key, g:bates_opened_files))
    return 1
  endif

  if (bates#plugin#check_down(a:id, a:key))
    return 1
  endif

  if (bates#plugin#check_up(a:id, a:key))
    return 1
  endif

  return popup_filter_menu(a:id, a:key)
endfunc

func! BatesCallback(id, key) abort

  if (len(a:key))
    call bates#plugin#open_file(a:key)
    return
  endif

endfunc

func! Bates() abort

  call BatesReset()

  let l:ve_args = #{
          \ title:'Bates',
          \ filter: 'BatesFilter',
          \ callback: 'BatesCallback',
          \ borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
          \ resize: 1,
          \ highlight: 'Normal',
          \ wrap: 0,
          \ scrollbar: 1,
          \ close: 'none'
        \}

  let l:files = []
  call add(l:files, '')

  call extend(l:files, bates#plugin#pool_to_text('Saved',  g:bates_saved_files,  1))
  call extend(l:files, bates#plugin#pool_to_text('Opened', g:bates_opened_files, 0))

  let l:popup = popup_menu(l:files, l:ve_args)
  call bates#plugin#move_index(l:popup, 0)

endfunc

autocmd BufReadPost,BufNewFile * call BatesCacheOpenedFile()

