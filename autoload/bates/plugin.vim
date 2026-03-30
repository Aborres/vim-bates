
let g:bates_header = 3

let s:bates_init = 0

let g:bates_main_page = 0
let g:bates_search    = 1
let g:bates_curr_page = g:bates_main_page

let g:bates_search_mode_input    = 0
let g:bates_search_mode_navigate = 1
let g:bates_search_mode = g:bates_search_mode_input

let g:bates_search_filter = g:bates_search_cursor

let g:bates_idx = 0

func! s:FileName(file) abort
  return fnamemodify(a:file, ':t')
endfunc

func! s:GenerateElement(key, file) abort

  let l:line = line('.')
  let l:col  = col('.')

  let l:e = {}
  let l:e.key  = a:key
  let l:e.name = s:FileName(a:file)
  let l:e.file = a:file
  let l:e.line = l:line
  let l:e.col  = l:col

  return l:e

endfunc

func! bates#plugin#max_temp() abort
  return min([g:bates_max_temp_files, 9])
endfunc

func! bates#plugin#set_idx(idx) abort
  let g:bates_idx = a:idx
endfunc

func! bates#plugin#get_idx() abort
  return g:bates_idx
endfunc

func! s:FindKey(key, pool) abort
  let l:i = 0
  for l:f in a:pool
    if (l:f.key == a:key)
      return l:i
    endif
    let l:i = l:i + 1
  endfor
  return -1
endfunc

func! s:IsKeyFree(key, pool) abort
  return s:FindKey(a:key, a:pool) == -1
endfunc

func! bates#plugin#find_file(file) abort
  for l:f in g:bates_saved_files
    if (l:f.file == a:file)
      return l:f
    endif
  endfor

  for l:f in g:bates_opened_files
    if (l:f.file == a:file)
      return l:f
    endif
  endfor
  return {}
endfunc

func! bates#plugin#find_file_name(file) abort
  for l:f in g:bates_saved_files
    if (l:f.name == a:file)
      return l:f
    endif
  endfor

  for l:f in g:bates_opened_files
    if (l:f.name == a:file)
      return l:f
    endif
  endfor
  return {}
endfunc

func! bates#plugin#is_file_contained(file) abort
  return !empty(bates#plugin#find_file(a:file))
endfunc

func! s:SortByKey(a, b) abort

  if a:a.key ==# a:b.key
    return 0
  endif

  return a:a.key ># a:b.key ? 1 : -1
endfunc

func! s:SortByFile(a, b) abort

  if a:a.file ==# a:b.file
    return 0
  endif

  let l:path_a = fnamemodify(a:a, ':t')
  let l:path_b = fnamemodify(a:b, ':t')

  return l:path_a.key ># l:path_b.key ? 1 : -1
endfunc

func! s:Sort(list, sort_by) abort
  if (a:sort_by == 0)
    call sort(a:list, 's:SortByKey')
  else
    call sort(a:list, 's:SortByFile')
  endif
endfunc

func! bates#plugin#get_focused_file() abort
  return expand('%:p')
endfunc

func! bates#plugin#is_focused_valid() abort
  return &buftype ==# ''
endfunc

func! s:GenerateFocusedElement(key) abort
  let l:file = bates#plugin#get_focused_file()
  return s:GenerateElement(a:key, l:file) 
endfunc

func! bates#plugin#is_in_list(list, file)
  for l:e in a:list
    if l:e.file == a:file
      return 1
    endif
  endfor
  return 0
endfunc

func! bates#plugin#trackfile()

  let l:file = bates#plugin#get_focused_file()

  if (!bates#plugin#is_in_list(g:bates_file_tracking, l:file))
    let l:element = s:GenerateElement('0', l:file) "Key doesn't matter here
    call add(g:bates_file_tracking, l:element)
  endif

  if (len(g:bates_file_tracking) >= g:bates_num_file_tracking)
    call remove(g:bates_file_tracking, 0)
  endif
endfunc

func! bates#plugin#cache_file(key, pool, file, allow_duplicates) abort

  if (a:key == '0')
    echo("0 Can't be used as a shortcut key")
    return
  endif

  let l:element = s:GenerateElement(a:key, a:file)
  let l:file = l:element.file

  if (!a:allow_duplicates)
    if (bates#plugin#is_file_contained(l:file))
      return
    endif
  endif

  let l:idx = s:FindKey(a:key, a:pool)

  if (l:idx < 0)
    call add(a:pool, l:element)
    call s:Sort(a:pool, g:bates_sort_by)
  else
    let a:pool[l:idx] = l:element
  endif

endfunc

func! bates#plugin#cache_focused_file(key, pool, allow_duplicates) abort
  let l:file = bates#plugin#get_focused_file()
  call bates#plugin#cache_file(a:key, a:pool, l:file, a:allow_duplicates) 
endfunc

func! bates#plugin#filename(file) abort
    return fnamemodify(a:file, ':t')
endfunc

func! bates#plugin#file_to_text(f, line) abort

  let l:file = a:f.file

  if (!g:bates_show_abs_paths)
    let l:file = bates#plugin#filename(l:file)
  endif

  if (a:line)
    return printf('%s: %s:%d', a:f.key, l:file, a:f.line)
  else
    return printf('%s: %s', a:f.key, l:file)
  endif
endfunc

func! bates#plugin#pool_to_text(name, pool, line) abort

  let l:files = []

  call add(l:files, a:name)
  call add(l:files, '')
  for l:f in a:pool
    let l:file = bates#plugin#file_to_text(l:f, a:line)
    call add(l:files, l:file)
  endfor
  call add(l:files, '')

  return l:files

endfunc

func! bates#plugin#get_pool_idx(idx) abort

  let l:saved_size  = len(g:bates_saved_files)

  if (a:idx >= l:saved_size)
    return 1
  endif

  return 0

endfunc

function bates#plugin#clamp(pos, size)

  if (a:pos < 0)
    return 0
  endif

  if (a:pos >= a:size)
    return a:size - 1
  endif

  return a:pos
endfunc

funct! bates#plugin#set_index_to(id, pos) abort
  call win_execute(a:id, ':'. string(a:pos))
endfunct

func! s:IsFileAlreadyOpened(path) abort

  let l:buffer_number = bufnr(a:path)
  if (l:buffer_number < 0)
    return -1
  endif

  let l:win_number = index(tabpagebuflist(), l:buffer_number)
  if (l:win_number < 0)
    return -1
  endif

  return l:buffer_number
endfunc

func! s:FocusBuffer(buffer) abort

  let l:wnr = bufwinnr(a:buffer)
  if l:wnr != -1
    execute l:wnr . 'wincmd w'
    return 1
  "else "This is for switching windows to the one containing the buffer
  "  execute 'buffer' l:bnr
  endif

  return 0
endfunc

func! bates#plugin#open_file(file) abort

  let l:file = fnameescape(a:file.file)
  let l:buffer = s:IsFileAlreadyOpened(l:file)
  if (g:bates_switch_focus && (l:buffer > -1))
    if (bufnr('%') != winbufnr(l:buffer))
      if (!s:FocusBuffer(l:buffer))
        echo(printf("Failed to focus buffer %d %s %d", l:buffer, l:file, bufnr('%')))
      endif
    endif
  else
    execute 'edit ' . l:file
  endif

  let l:line   = g:bates_load_to_line   ? a:file.line : 0
  let l:column = g:bates_load_to_column ? a:file.col : 0

  call cursor(l:line, l:column)

endfunc

func! bates#plugin#scroll_temp_list(id, i_pos, r_pos) abort

  let l:element = s:GenerateFocusedElement(a:id)

  call insert(g:bates_opened_files, element, a:i_pos)
  call remove(g:bates_opened_files, a:r_pos)

  let l:count = len(g:bates_opened_files)
  for l:i in range(0, l:count - 1)
    let g:bates_opened_files[l:i].key = l:i + 1
  endfor

endfunc

func! bates#plugin#get_key() abort

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

func! bates#plugin#filter(id, key) abort

  if (g:bates_curr_page == g:bates_main_page)
    if (bates#main_page#filter(a:id, a:key))
      return 1
    endif
  elseif (g:bates_curr_page == g:bates_search)
    if (bates#search#filter(a:id, a:key))
      return 1
    endif
  endif

  return popup_filter_menu(a:id, a:key)
endfunc

func! bates#plugin#callback(id, key) abort

  if (len(a:key))
    call bates#plugin#open_file(a:key)
    return
  endif

endfunc

func! bates#plugin#init() abort
  if (!s:bates_init)
    let s:bates_init = 1
  endif
endfunc

func! bates#plugin#reset() abort

  call bates#plugin#init()

  let g:bates_idx = 0
  let g:bates_curr_page   = g:bates_main_page
  let g:bates_search_mode = g:bates_search_mode_input
  let g:bates_search_filter = g:bates_search_cursor
endfunc

func! bates#plugin#clear_all() abort
  let l:bates_saved_files = []
  let g:bates_opened_files = []
  let g:bates_files_list = []
  let g:bates_text = []

  let g:bates_idx = 0
  let g:bates_curr_page   = g:bates_main_page
  let g:bates_search_mode = g:bates_search_mode_input

  call bates#plugin#reset()
endfunc

func! bates#plugin#cache_file_at(key, file) abort

  if (a:key =~ '[1-9]')
    return
  endif

  call bates#plugin#cache_file(a:key, g:bates_saved_files, a:file, g:bates_allow_duplicates)
endfunc

func! bates#plugin#cache_focused_file_at(key) abort
  let l:file = bates#plugin#get_focused_file()
  call bates#plugin#cache_file_at(a:key, l:file)
endfunc

func! bates#plugin#request_key_for_focused_file() abort
  let l:key = bates#plugin#get_key()
  call bates#plugin#cache_focused_file_at(l:key)
endfunc

func! bates#plugin#request_key_for_file(file) abort
  let l:key = bates#plugin#get_key()
  call bates#plugin#cache_file_at(l:key, a:file)
endfunc

func! bates#plugin#cache_opened_file() abort

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

func! bates#plugin#bates() abort

  call bates#plugin#reset()

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
