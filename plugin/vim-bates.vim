
let g:bates_show_abs_paths = 0

let g:bates_load_to_line     = 0
let g:bates_load_to_column   = 0
let g:bates_allow_duplicates = 0
let g:bates_switch_focus     = 1

let s:bates_files = []
let s:bates_init = 0
let s:bates_idx = 0

func! BatesInit() abort

  if (!s:bates_init)
    let s:bates_init = 1
  endif

endfunc

func! BatesReset() abort
  call BatesInit()

  let s:bates_idx = 0
endfunc

func! s:FindKey(key) abort
  let l:i = 0
  for l:f in s:bates_files
    if (l:f[0] == a:key)
      return l:i
    endif
    let l:i = l:i + 1
  endfor
  return -1
endfunc

func! s:IsKeyFree(key) abort
  return s:FindKey(a:key) == -1
endfunc

func! s:IsFileContained(file) abort
  for l:f in s:bates_files
    if (l:f[1] == file)
      return 1
    endif
  endfor
  return 0
endfunc

func! s:CmpList(a, b) abort

  if a:a[0] ==# a:b[0]
    return 0
  endif

  return a:a[0] ># a:b[0] ? 1 : -1
endfunc

func! s:Sort() abort
  call sort(s:bates_files, 's:CmpList')
endfunc

func! BatesCacheFileAt(key) abort

  if (a:key == '0')
    echo("0 Can't be used as a shortcut key")
    return
  endif

  let l:idx = s:FindKey(a:key)

  let l:file = expand('%:p')
  let l:line = line('.')
  let l:col  = col('.')

  if (!g:bates_allow_duplicates)
    if (s:IsFileContained(l:file))
      return
    endif
  endif

  let l:element = [a:key, l:file, l:line, l:col]

  if (l:idx < 0)
    call add(s:bates_files, l:element)
    call s:Sort()
  else
    let s:bates_files[l:idx] = l:element
  endif

endfunc

func! BatesCacheFile() abort

  let l:count = len(s:bates_files)
  if (!l:count)
    call BatesCacheFileAt(1)
    return
  endif

  let l:file = s:bates_files[l:count - 1]
  call BatesCacheFileAt(l:file[0] + 1)
endfunc

func! BatesClearAll() abort
  let l:bates_files = []
endfunc

func! s:IsFileAlreadyOpened(path) abort

  let l:buffer_number = bufnr(a:path)
  if l:buffer_number <= 0
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

function s:Clamp(pos)

  if (a:pos < 0)
    return 0
  endif

  let l:count = len(s:bates_files)
  if (a:pos >= l:count)
    return l:count - 1
  endif

  return a:pos
endfunc

func! BatesOpenFile(file) abort

  let l:file = fnameescape(a:file[1])
  let l:buffer = s:IsFileAlreadyOpened(l:file)
  if (g:bates_switch_focus && (l:buffer > -1))
    call s:FocusBuffer(l:buffer)
  else
    execute 'edit ' . l:file
  endif

  let l:line   = g:bates_load_to_line   ? a:file[2] : 0
  let l:column = g:bates_load_to_column ? a:file[3] : 0

  call cursor(l:line, l:column)

endfunc

funct! s:MoveIndex(id, dir) abort
  let s:bates_idx = s:Clamp(s:bates_idx + a:dir)
  call win_execute(a:id, ':'. string(s:bates_idx + 2)) 
endfunct

func! BatesFilter(id, key) abort

  if (a:key == "\<CR>")
    call popup_close(a:id, s:bates_idx)
    return 1
  endif

  if (a:key == "\<Esc>")
    call popup_close(a:id, -1)
    return 1
  endif

  for l:i in range(0, len(s:bates_files) - 1)

    let l:f = s:bates_files[l:i]
    if (l:f[0] == a:key)
      echo(l:f)
      call popup_close(a:id, l:i)
      return 1
    endif

  endfor

  if (a:key == 'j' || a:key == "\<Down>")
    call s:MoveIndex(a:id, 1)
    return 1
  endif

  if (a:key == 'k' || a:key == "\<Up>")
    call s:MoveIndex(a:id, -1)
    return 1
  endif

endfunc

func! BatesCallback(id, key) abort

  if (a:key != -1)
    call BatesOpenFile(s:bates_files[a:key])
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
  for l:f in s:bates_files

    let l:file = l:f[1]
    if (!g:bates_show_abs_paths)
      let l:file = fnamemodify(l:file, ':t')
    endif

    let l:file = printf('%s: %s:%d', l:f[0], l:file, l:f[2])
    call add(l:files, l:file)
  endfor
  call add(l:files, '')

  let l:popup = popup_menu(l:files, l:ve_args)

endfunc
