
let g:bates_header = 3

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
    if (l:f[0] == a:key)
      return l:i
    endif
    let l:i = l:i + 1
  endfor
  return -1
endfunc

func! s:IsKeyFree(key, pool) abort
  return s:FindKey(a:key, a:pool) == -1
endfunc

func! bates#plugin#is_file_contained(file) abort
  for l:f in g:bates_saved_files
    if (l:f[1] == a:file)
      return 1
    endif
  endfor

  for l:f in g:bates_opened_files
    if (l:f[1] == a:file)
      return 1
    endif
  endfor
  return 0
endfunc

func! s:SortByKey(a, b) abort

  if a:a[0] ==# a:b[0]
    return 0
  endif

  return a:a[0] ># a:b[0] ? 1 : -1
endfunc

func! s:SortByFile(a, b) abort

  if a:a[1] ==# a:b[1]
    return 0
  endif

  let l:path_a = fnamemodify(a:a[1][0], ':t')
  let l:path_b = fnamemodify(a:b[1][0], ':t')

  return l:path_a[0] ># l:path_b[0] ? 1 : -1
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

func! s:GenerateElement(key, file) abort

  let l:line = line('.')
  let l:col  = col('.')

  return [a:key, a:file, l:line, l:col]
endfunc

func! s:GenerateFocusedElement(key) abort
  let l:file = bates#plugin#get_focused_file()
  return s:GenerateElement(a:key, l:file) 
endfunc

func! bates#plugin#is_in_list(list, file)
  for l:e in a:list
    if l:e[1] == a:file
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
  let l:file = l:element[1]

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

  let l:file = a:f[1]

  if (!g:bates_show_abs_paths)
    let l:file = bates#plugin#filename(l:file)
  endif

  if (a:line)
    return printf('%s: %s:%d', a:f[0], l:file, a:f[2])
  else
    return printf('%s: %s', a:f[0], l:file)
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

  let l:file = fnameescape(a:file[1])
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

  let l:line   = g:bates_load_to_line   ? a:file[2] : 0
  let l:column = g:bates_load_to_column ? a:file[3] : 0

  call cursor(l:line, l:column)

endfunc

func! bates#plugin#scroll_temp_list(id, i_pos, r_pos) abort

  let l:element = s:GenerateFocusedElement(a:id)

  call insert(g:bates_opened_files, element, a:i_pos)
  call remove(g:bates_opened_files, a:r_pos)

  let l:count = len(g:bates_opened_files)
  for l:i in range(0, l:count - 1)
    let g:bates_opened_files[l:i][0] = l:i + 1
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


