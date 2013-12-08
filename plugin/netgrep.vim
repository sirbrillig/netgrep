function! NetGrepPath(...)
  if exists('g:NetGrep_default_directory')
    let default_directory = g:NetGrep_default_directory
  else
    echom "Error: NetGrep requires setting g:NetGrep_default_directory"
    return ''
  endif

  let s:full_path = match(default_directory, '\v^[\~\/]')
  if s:full_path <# 0
    echom "Error: g:NetGrep_default_directory must be a full path"
    return ''
  endif

  let s:full_path = match(default_directory, '\v\/$')
  if s:full_path <# 0
    echom "Error: g:NetGrep_default_directory must end with a slash"
    return
  endif

  let grep_dir = ''
  if a:0 ># 0
    let grep_dir = a:1
  endif
  if grep_dir ==# ''
    let grep_dir = default_directory
  endif

  " Prepend default directory if a full path is not entered
  let s:full_path = match(grep_dir, '\v^[\~\/]')
  if s:full_path <# 0
    let grep_dir = default_directory . grep_dir
  endif

  return grep_dir
endfunction

function! RunNetGrep(pattern, ...)
  let tmpfile = tempname()

  if exists('g:NetGrep_server_name')
    let server_name = g:NetGrep_server_name
  else
    echom "Error: NetGrep requires g:NetGrep_server_name"
    return
  endif

  if a:0 ==# 0
    let grep_dir = NetGrepPath()
  else
    let grep_dir = NetGrepPath(a:1)
  endif

  echom 'Searching for pattern: ' . a:pattern . " in " . grep_dir

  execute "silent redir! > " . tmpfile
  silent echon '[Search results for pattern: ' . a:pattern . " in " . grep_dir . "]\n"
  let s:results = system("ssh " . server_name . " 'grep -Irn " . a:pattern . " " . grep_dir . "' ")
  silent echon s:results
  redir END

  execute 'silent !sed -i.bak "s/^\//scp:\/\/' . server_name . '\/\//" ' . tmpfile

  execute "silent cgetfile " . tmpfile
  copen

  call delete(tmpfile)
endfunction

function! RunNetFind(pattern, ...)
  if exists('g:NetGrep_server_name')
    let server_name = g:NetGrep_server_name
  else
    echom "Error: NetFind requires g:NetGrep_server_name"
    return
  endif

  if a:pattern ==# ''
    echom "Error: a filename to search for must be supplied"
    return
  endif

  let temp_file = tempname()

  if a:0 ==# 0
    let find_dir = NetGrepPath()
  else
    let find_dir = NetGrepPath(a:1)
  endif

  echom 'Searching for file matching: ' . a:pattern . " on " . server_name . " in " . find_dir

  execute "silent redir! > " . temp_file
  silent echon '[Search results for file matching: ' . a:pattern . " on " . server_name . " in " . find_dir . "]\n"
  let s:results = system("ssh " . server_name . " 'find " . find_dir . " -name ". a:pattern ." -printf match:\\%p:1:\\\\n'")
  silent echon s:results
  redir END

  execute 'silent !sed -i.bak "s/^match:\//match:scp:\/\/' . server_name . '\/\//" ' . temp_file

  " Make sure that quickfix can read the output
  set errorformat+=match:%f:%l:

  execute "silent cgetfile " . temp_file
  copen

  call delete(temp_file)
endfunction

command! -nargs=* NetGrep call RunNetGrep(<f-args>)

command! -nargs=* NetFind call RunNetFind(<f-args>)
