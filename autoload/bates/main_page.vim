
funct! s:BatesMainPageMoveIndexTo(id, pos, check_pools=1) abort

  let g:bates_idx = bates#plugin#clamp(a:pos, len(g:bates_files_list))
  let l:offset = g:bates_header + (bates#plugin#get_pool_idx(g:bates_idx) * g:bates_header) + 1

  call bates#plugin#set_index_to(a:id, g:bates_idx + l:offset)
endfunct

" range = saved_size + opened_size 
" two sections (0 - saved_size] and (saved_size - opened_size]
" idx to screen:
"   if in first section: + header
"   if in second section: entire first section size + second_section_header 
"   + 1
funct! bates#main_page#move_index(id, dir) abort
  call s:BatesMainPageMoveIndexTo(a:id, g:bates_idx + a:dir)
endfunct

func! s:BatesMainPageCheckEnter(id, key) abort

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

func! s:BatesMainPageCheckEsc(id, key) abort

  if (a:key == "\<Esc>")
    call popup_close(a:id, [])
    return 1
  endif
  return 0
endfunc

func! s:BatesMainPageCheckShorcut(id, key, pool) abort

  for l:i in range(0, len(a:pool) - 1)

    let l:f = a:pool[l:i]
    if (l:f[0] == a:key)
      call popup_close(a:id, l:f)
      return 1
    endif
  endfor
  return 0
endfunc

func! s:BatesMainPageCheckSearch(id, key) abort
  if (a:key == '/')
    let g:bates_curr_page = g:bates_search
    let g:bates_search_mode = 0
    call bates#text#search_page(a:id)
  endif
  return 0
endfunc

func! s:BatesMainPageCheckDown(id, key) abort
  if (a:key == 'j' || a:key == "\<Down>")
    call bates#main_page#move_index(a:id, 1)
    return 1
  endif
  return 0
endfunc

func! s:BatesMainPageCheckUp(id, key) abort
  if (a:key == 'k' || a:key == "\<Up>")
    call bates#main_page#move_index(a:id, -1)
    return 1
  endif
  return 0
endfunc

func! bates#main_page#filter(id, key) abort

  if (s:BatesMainPageCheckEnter(a:id, a:key))
    return 1
  endif

  if (s:BatesMainPageCheckEsc(a:id, a:key))
    return 1
  endif

  if (s:BatesMainPageCheckShorcut(a:id, a:key, g:bates_saved_files))
    return 1
  endif

  if (s:BatesMainPageCheckShorcut(a:id, a:key, g:bates_opened_files))
    return 1
  endif

  if (s:BatesMainPageCheckDown(a:id, a:key))
    return 1
  endif

  if (s:BatesMainPageCheckUp(a:id, a:key))
    return 1
  endif

  if (s:BatesMainPageCheckSearch(a:id, a:key))
    return 1
  endif

  return 0
endfunc

