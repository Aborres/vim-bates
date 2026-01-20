
let s:bates_idx = 0
let s:bates_header = 3

func! bates#plugin#max_temp() abort
  return min([g:bates_max_temp_files, 9])
endfunc

func! bates#plugin#set_idx(idx) abort
  let s:bates_idx = a:idx
endfunc

func! bates#plugin#get_idx() abort
  return s:bates_idx
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

func! s:FileToText(f, line) abort

  let l:file = a:f[1]

  if (!g:bates_show_abs_paths)
    let l:file = fnamemodify(l:file, ':t')
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
    let l:file = s:FileToText(l:f, a:line)
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

function s:Clamp(pos, size)

  if (a:pos < 0)
    return 0
  endif

  if (a:pos >= a:size)
    return a:size - 1
  endif

  return a:pos
endfunc

" range = saved_size + opened_size 
" two sections (0 - saved_size] and (saved_size - opened_size]
" idx to screen:
"   if in first section: + header
"   if in second section: entire first section size + second_section_header 
"   + 1
funct! bates#plugin#move_index(id, dir) abort

  let l:saved_size  = len(g:bates_saved_files)
  let l:opened_size = len(g:bates_opened_files)
  let s:bates_idx = s:Clamp(s:bates_idx + a:dir, l:saved_size + l:opened_size)

  let l:offset = s:bates_header + (bates#plugin#get_pool_idx(s:bates_idx) * s:bates_header) + 1
  call win_execute(a:id, ':'. string(s:bates_idx + l:offset)) 

endfunct

func! s:IsFileAlreadyOpened(path) abort

  let l:buffer_number = bufwinid(a:path)
  if (l:buffer_number <= 0)
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

func! bates#plugin#check_enter(id, key) abort

  if (a:key == "\<CR>")

    let l:idx = bates#plugin#get_idx()
    if (!bates#plugin#get_pool_idx(l:idx))
      call popup_close(a:id, g:bates_saved_files[l:idx])
    else
      call popup_close(a:id, g:bates_opened_files[l:idx - len(g:bates_saved_files)])
    endif
    return 1
  endif
  return 0
endfunc

func! bates#plugin#check_esc(id, key) abort

  if (a:key == "\<Esc>")
    call popup_close(a:id, [])
    return 1
  endif
  return 0
endfunc

func! bates#plugin#check_shortcut(id, key, pool) abort

  for l:i in range(0, len(a:pool) - 1)

    let l:f = a:pool[l:i]
    if (l:f[0] == a:key)
      call popup_close(a:id, l:f)
      return 1
    endif
  endfor
  return 0
endfunc

func! bates#plugin#check_down(id, key) abort
  if (a:key == 'j' || a:key == "\<Down>")
    call bates#plugin#move_index(a:id, 1)
    return 1
  endif
  return 0
endfunc

func! bates#plugin#check_up(id, key) abort
  if (a:key == 'k' || a:key == "\<Up>")
    call bates#plugin#move_index(a:id, -1)
    return 1
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

