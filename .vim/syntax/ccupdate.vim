" Vim syntax file
" Language:	clear case update log
" Maintainer:	Patrick Lorenz <patrick.lorenz@de.transport.bombardier.com>
" Remark: Simply highlight lines depending on the operation at the begining of
"         each line 

if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn match commentLine		/^# .*/
syn match CheckedOutLine	/^CheckedOut:/
syn match HijackedDeletedLine	/^HijackedDeleted:/
syn match ErrorLine		/^Error:/
syn match HijackedPreservedLine	/^HijackedPreserved:/
syn match NonfileErrorLine	/^NonfileError:/

if !exists("did_ccupdate_syntax_inits")
  let did_ccupdate_syntax_inits = 1
  hi commentLine	ctermfg=cyan	guifg=cyan
  hi CheckedOutLine	ctermfg=yellow	guifg=yellow
  hi ErrorLine		ctermfg=red	guifg=red
  hi link HijackedDeletedLine CheckedOutLine
  hi link HijackedPreservedLine ErrorLine
  hi link NonfileErrorLine ErrorLine
endif

let b:current_syntax="ccupdate"
