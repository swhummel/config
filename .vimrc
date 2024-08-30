set nocompatible
set runtimepath=~/.vim,$VIM/vimfiles,$VIMRUNTIME
set bg=dark
set shiftwidth=4
set tabstop=4
set expandtab
set ic               "uncasesenitive
set smartcase        "if in searchstring is an uppers case, switch to case senitive serach
set hlsearch         "highlight search results
set incsearch        "match the search string while typing
set nowrap
set pastetoggle=<F8> "Treppeneffekt bei c&p verhindern
set history=1000
set ruler            "always shoe cursor position
set number
set noerrorbells
set termencoding=utf-8
set encoding=utf-8
set t_Co=256
set term=screen-256color
colorscheme xoria256
"colorscheme amethyst
" repair backspace
set bs=2

" *****************************************************************************
" auto completion of files
" *****************************************************************************
set wildmenu         "show menu with possible tab completions
set wildmode=longest,list
"set wildmode=longest,list,full "double tab opens the menu
set wildignore+=*.a,*.o
set wildignore+=*.bmp,*.gif,*.ico,*.jpg,*.png
set wildignore+=.DS_Store,.git,.hg,.svn
set wildignore+=*~,*.swp,*.tmp

" *****************************************************************************
" highlighting special chars
" *****************************************************************************
" highlight tabs
set list
"set list listchars=tab:»,trail:¤
set listchars=tab:»·,trail:¤ ",eol:¶,precedes:«,extends:»
"set listchars=tab:»­,trail:· ",eol:¶,precedes:«,extends:»
"whitespace example:     
"tab example:	
"
" *****************************************************************************
" highlighting
" *****************************************************************************
"match Todo /TODO:\?\|SHU:\?\|todo:\?/
"match Todo /TODO:\?\|SHU :\?\|todo:\?\|TODO SHU:\?\|TODO SHU remove this log statement - should never be commited:\?/
match Todo /TODO SHU remove this log statement - should never be commited:\?\|TODO SHU:\?\|SHU:\?\|TODO:\?/


" *****************************************************************************
" set tags db
" *****************************************************************************
set tags=$VIEW/tags

" *****************************************************************************
" Spell
" *****************************************************************************
"set spell spelllang=de,en  " do this with mapping
set spellfile=~/.vim/spell.add
" only show top 10 spell matches
set sps=best,10

" *****************************************************************************
" text witdh
" *****************************************************************************
set   textwidth=240
"highlight ColorColumn ctermbg=235 guibg=#2c2d27
highlight ColorColumn ctermbg=189 guibg=#ff0000
let &colorcolumn=join(range(81,81),",")
"let &colorcolumn=join(range(81,999),",")
"let &colorcolumn="80,".join(range(120,999),",")
" 34567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890

syntax on
filetype plugin on
filetype indent on

" ********************************************
" keyboard mappings
" ********************************************
" map ctag bindings to use no altgr
"nnoremap ä <C-]>
"nnoremap Ä <C-O>
map <F1> <C-]>
map <F2> <C-O>

map <F3> :set diffopt+=iwhite<cr>
map <F4> :set diffopt-=iwhite<cr>

" comment/uncomment
map <F5> :norm i//<cr>
map <F6> :norm xx<cr>

" switch bettween openfiles
map <F7>    :bn<CR>
map <F8>    :bp<CR>

map <F9>     :TlistToggle<cr>
"enable/disable spellchecking
map <F10> :set spell!<CR><Bar>:echo 'Spell check: ' . strpart('OffOn', 3 * &spell, 3)<CR>

" next/previous diff
map <F11> ]c
map <F12> [c

" map %:h<tab> to %%
cnoremap <expr> %% getcmdtype() == ':' ? expand('%:h').'/' : '%%'


" ********************************************
" macros
" ********************************************
:let @t='0$F 100i d120|j'
:let @f='V%zf'

:let @p='04li4li8li 3li 3li 3li 3li 9li 9li8li 3li 3li 3li 3li 9li 9li8li 3li 3li 3li 3li 9li 9li8li 3li 3li 3li 3li 9li 9li8li 3li 3li 3li 3li 9li 9li8li 3li 3li 3li 3li 9li 9li8li 3li 3li 3li 3li 9li 9li8li 3li 3li 3li 3li 9li 9li8li8li8li8li8li8li8li8li8li8li2li2li2li'
"PCSStatus - 2565001
:let @i='04li	FSystemLifeSign2li		FSystGenStat2li		Reserved4li	INrCouSent2li		Reserved2li		Reserved2li			DoInstNr2li			ConStat2li			Reserved2li			Reserved8li	In8li	Out8li	Uncertain2li			ErrCode2li			ErrStat2li			Reserved2li			Reserved'
"CCUO_CCUC - 2053001
:let @o='8li	ILifeSignTCMS4li		IProjectID2li			IProjectVariant2li			Reserved8li	IKmCnt4li		IMCnt4li		Reserved24li	GPSData4li		ITrainSpeed2li			IDriveDir2li			IDriveDirSwitch32li	IDoorstatus2li		IDoorsReleasedL2li		DoorsReleasedR2li		ITimeZone2li		IDaylightTime4li		ITempOutside4li		ITempInside2li		ITrainMode2li		IOperationMode'

" ********************************************
" mouse scrolling
" ********************************************
"set mouse=a
"map <MouseDown> <C-Y>
"map <MouseUp>   <C-E>


" ********************************************
" syntax highlighting for special files
" ********************************************
" qmake project files ends with .pro and syntax is like normal makefiles
autocmd BufReadPost *.pro :set syntax=qmake
autocmd BufReadPost *.pri :set syntax=qmake
autocmd BufReadPost *.cs  :set syntax=cccs
autocmd BufReadPost update*.updt :set syntax=ccupdate

" syntax helog
autocmd BufReadPost *.log :set syntax=helog

autocmd BufReadPost *.uml :set syntax=plantuml

autocmd BufReadPost *.handlebars :set syntax=handlebars

autocmd BufReadPost *.json :set syntax=json
autocmd BufReadPost *.awk :set syntax=awk

" ********************************************
" Abbreviations - General Editing - Inserting Dates and Times
" ********************************************
" First, some command to add date stamps (with and without time).
" I use these manually after a substantial change to a webpage.
" [These abbreviations are used with the mapping for ",L".]
"
  iab Ydate <C-R>=strftime("%y%m%d")<CR>
" Example: 971027
"
  iab Ytime <C-R>=strftime("%H:%M")<CR>
" Example: 14:28
"
  iab YDT   <C-R>=strftime("%y%m%d %T")<CR>
" Example: 971027 12:00:00
"
  iab YDATE <C-R>=strftime("%a %b %d %T %Z %Y")<CR>
" Example: Tue Dec 16 12:07:00 CET 1997

  iab dmt <C-R>=strftime("%d.%m.-%H:%M")<CR>

"
" On Windows the functions "strftime" seems to have a different
" format.  Therefore the following may be necessary:  [980730]
" if !has("unix")
" iab YDATE <C-R>=strftime("%c %a")<CR>
" else
" iab YDATE <C-R>=strftime("%D %T %a")<CR>
" endif

" abbreviation comment head
ab abhead   /**
            \<CR>Declaration of class adapter::code::CodingStyleExample.
            \<CR>
            \<CR>@copyright Copyright (C) 2022 Bombardier Transportation.
            \<CR>This software is supplied under the terms of a license agreement or
            \<CR>nondisclosure agreement with Bombardier Transport, and may not be copied or
            \<CR>disclosed except in accordance with the terms of that agreement.
            \<CR>/

" abbreviation comment a function
ab abcf     /**
            \<CR>Short desciption.
            \<CR>
            \<CR>Detailed description.
            \<CR>
            \<CR>\param[in]
            \<CR>\param[out]
            \<CR>\return
            \<CR>/

ab abtodo //TODO SHU - RTC-...
ab ablog  //TODO SHU remove this log statement - should never be commited

" ****************************************************
" change color of status line based on mode
" ****************************************************
" first, enable status line always
set laststatus=2
"
" now set it up to change the status line based on mode
if version >= 700 
    au InsertEnter * hi StatusLine term=reverse ctermfg=0 ctermbg=11 gui=undercurl guisp=Red
    au InsertLeave * hi StatusLine term=reverse ctermfg=15 ctermbg=8 gui=bold,reverse
endif


" folding
"augroup remember_folds
"    autocmd!
"        autocmd BufWinLeave notes mkview
"        autocmd BufWinEnter notes silent! loadview
"augroup END

" Tabulatoren sollten bei uns eigentlich 4 Zeichen breit sein und mit
" Leerzeichen erweitert werden. Folgende Zeilen in der .vimrc stellen das unter
" anderem ein:
" define tabstop expand and width
au BufEnter *.[ch]      set ai et sw=4 ts=4
au BufEnter *.cc        set ai et sw=4 ts=4
au BufEnter *.cpp       set ai et sw=4 ts=4
au BufEnter *.java      set ai et sw=4 ts=4
au BufEnter *.idl       set ai et sw=4 ts=4
au BufEnter *.p[ml]     set ai et sw=4 ts=4
au BufEnter .vimrc      set ai et sw=4 ts=4
au BufEnter *.html      set ai    sw=2 ts=2
au BufEnter *.shtml     set ai    sw=2 ts=2
au BufEnter *.cs        set ai et sw=4 ts=4
au BufEnter *.sh        set ai et sw=4 ts=4
au BufEnter *.asn1      set ai et sw=4 ts=4
au BufEnter *.xml       set ai et sw=2 ts=2
au BufEnter *.xslt      set ai et sw=2 ts=2
au BufEnter *.uml       set ai et sw=2 ts=2
au BufEnter *.md        set ai et sw=2 ts=2

au BufEnter *.json      set ai et sw=4 ts=4 filetype=json
"autocmd BufNewFile,BufRead *.json set ft=javascript

"au BufNewFIle,BufFilePre,BufRead *.md set filetype=markdown
au BufNewFIle,BufFilePre,BufRead *.md set filetype=plantuml

"Folgende Zeilen in der .vimrc bewirken, dass Leerzeichen am Ende jeder Zeile
"automatisch gelöscht werden, wenn man eine Datei mit entsprechender Endung
"speichert: 
" automatically remove trailing white spaces
"au BufWrite *.[ch]      :%s/ \+$//e
"au BufWrite *.cc        :%s/ \+$//e
"au BufWrite *.cpp       :%s/ \+$//e
"au BufWrite *.java      :%s/ \+$//e
"au BufWrite *.idl       :%s/ \+$//e
"au BufWrite *.p[ml]     :%s/ \+$//e
"au BufWrite *.sh        :%s/ \+$//e
"au BufWrite *.cs        :%s/ \+$//e
"au BufWrite *.pr[io]    :%s/ \+$//e
"au BufWrite *.asn1      :%s/ \+$//e
"au BufWrite *.xml       :%s/ \+$//e

" disable arrow keys
"noremap <Up> <Nop>
"noremap <Down> <Nop>
"noremap <Left> <Nop>
"noremap <Right> <Nop>

" use in diff mode another colorscheme
"if &diff
    "colorscheme blue
"endif

" *****************************************************
" Vundle
" *****************************************************
" git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
" We use a start wrapper (always exist) to load Vundle if it exists.
  let std_vundle_start_file=glob("~/.vim/vundle_start.vim")
  let std_vundle_main_file=glob("~/.vim/bundle/Vundle.vim/autoload/vundle.vim")
  if filereadable(std_vundle_main_file)
     let std_vundle_start_result="file readable: " . std_vundle_main_file
     exe "source " . std_vundle_start_file
  else
     let std_vundle_start_result="file not readable: " . std_vundle_main_file
  endif
" Plugin help list in ~/.vim/vundle_start.vim

