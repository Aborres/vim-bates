

funct! s:BatesSearchMoveIndexTo(id, pos) abort
  let g:bates_idx = bates#plugin#clamp(a:pos, len(g:bates_files_list))
  let l:offset = g:bates_header + 1
  call bates#plugin#set_index_to(a:id, g:bates_idx + l:offset)
endfunct

funct! s:BatesSearchMoveIndex(id, dir) abort
  call s:BatesSearchMoveIndexTo(a:id, g:bates_idx + a:dir)
endfunct

func! s:BatesSearchCheckDown(id, key) abort
  if (a:key == 'j' || a:key == "\<Down>")
    call s:BatesSearchMoveIndex(a:id, 1)
    return 1
  endif
  return 0
endfunc

func! s:BatesSearchCheckUp(id, key) abort
  if (a:key == 'k' || a:key == "\<Up>")
    call s:BatesSearchMoveIndex(a:id, -1)
    return 1
  endif
  return 0
endfunc

func! s:BatesSearchCheckDel(id, key) abort
  if (a:key == "\<BS>")

    let l:pos = stridx(g:bates_search_filter, g:bates_search_cursor)

    if (l:pos == 1)
      let g:bates_search_filter = g:bates_search_cursor
    elseif (l:pos > 1)
      let g:bates_search_filter = g:bates_search_filter[:l:pos - 2] . g:bates_search_cursor . g:bates_search_filter[l:pos + 1:]
    endif
    call bates#text#search_page(a:id)
    return 1
  endif

  return 0
endfunc

func! s:BatesSearchFilterInput(id, key) abort

  if (a:key >= ' ' && a:key <= '~')
    let l:pos = stridx(g:bates_search_filter, g:bates_search_cursor)
    if (l:pos == 0)
      let g:bates_search_filter = a:key . g:bates_search_cursor
    else
      let g:bates_search_filter = g:bates_search_filter[:l:pos - 1] . a:key . g:bates_search_filter[l:pos:]
    endif
    call bates#text#search_page(a:id)
    return 1
  endif
  return 0
endfunc

func! s:BatesFilterSearchInput(id, key) abort

  if (a:key == "\<Esc>")
    let g:bates_curr_page = g:bates_main_page
    call bates#text#main_page(a:id)
    return 1
  endif

  if (a:key == "\<CR>")
    let g:bates_search_mode = g:bates_search_mode_navigate
    call s:BatesSearchMoveIndexTo(a:id, 0)
    return 1
  endif

  if (s:BatesSearchCheckDel(a:id, a:key))
  endif

  if (s:BatesSearchFilterInput(a:id, a:key))
    return 1
  endif

  return 0
endfunc

func! s:BatesFilterSearchNavigate(id, key) abort

  if (a:key == "\<Esc>")
    let g:bates_search_mode = g:bates_search_mode_input
    call bates#plugin#set_index_to(a:id, 0)
    return 1
  endif

  if (a:key == "\<CR>")
    call popup_close(a:id, g:bates_files_list[g:bates_idx])
    return 1
  endif

  if (s:BatesSearchCheckDown(a:id, a:key))
    return 1
  endif

  if (s:BatesSearchCheckUp(a:id, a:key))
    return 1
  endif

  return 0
endfunc

func! bates#search#filter(id, key) abort

  if (g:bates_search_mode == g:bates_search_mode_input)
    return s:BatesFilterSearchInput(a:id, a:key)
  elseif(g:bates_search_mode == g:bates_search_mode_navigate)
    return s:BatesFilterSearchNavigate(a:id, a:key)
  endif

  return 0
endfunc
