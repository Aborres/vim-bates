let s:bates_search_header = 'Search: '

func! bates#text#main_page(id)
  let l:text = []
  call add(l:text, '')

  call extend(l:text, bates#plugin#pool_to_text('Saved',  g:bates_saved_files,  1))
  call extend(l:text, bates#plugin#pool_to_text('Opened', g:bates_opened_files, 0))

  let g:bates_files_list = g:bates_saved_files + g:bates_opened_files
  let g:bates_header = 3

  call popup_settext(a:id, l:text)
  call bates#main_page#move_index(a:id, 0)

  let g:bates_text = l:text

  return l:text
endfunc

func! s:AddList(list, global_list, source, filter)
  for l:file in a:source
    if (!bates#plugin#is_in_list(a:list, l:file[1]))
      if (a:filter != '' && stridx(l:file[1], a:filter) == -1)
        continue
      endif
      let l:text = bates#plugin#filename(l:file[1])
      call add(a:list, l:text)
      call add(a:global_list, l:file)
    endif
  endfor
endfunc

func! s:CopyList(list, global_list, source, filter)
  for l:file in a:source
    if (a:filter != '' && stridx(l:file[1], a:filter) == -1)
      continue
    endif
    let l:text = bates#plugin#filename(l:file[1])
    call add(a:list, l:text)
    call add(a:global_list, l:file)
  endfor
endfunc

func! s:RemoveCursor(str)

  let l:pos = stridx(g:bates_search_filter, g:bates_search_cursor)
  if (l:pos == 0)
    return g:bates_search_filter[1:]
  endif

  if (l:pos > 0)
    return g:bates_search_filter[:l:pos - 1] . g:bates_search_filter[l:pos + 1:]
  endif

  return g:bates_search_filter
endfunc

func! bates#text#search_page(id)

  let l:list = [s:bates_search_header . g:bates_search_filter, '']

  let l:filter = s:RemoveCursor(g:bates_search_filter)

  let l:files = []
  "call s:AddList(l:files, g:bates_files_list, g:bates_saved_files,  l:filter)
  "call s:AddList(l:files, g:bates_files_list, g:bates_opened_files, l:filter)
  call s:CopyList(l:files, g:bates_files_list, g:bates_file_tracking, l:filter)

  let g:bates_header = 2

  let l:list = l:list + l:files
  call popup_settext(a:id, l:list)
  call bates#plugin#set_index_to(a:id, 0)

  let g:bates_text = l:list

  return l:list

endfunc
