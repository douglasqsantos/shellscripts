"============= Esquema de cores ====================
" a vantagem de manter um esquema de cores
" no próprio vimrc é que você fica independente
" de sistema, a definição de cores está no próprio vimr
"
" Vim color file
" Maintainer:	Hans Fugal <hans@fugal.net>
" Last Change:	$Date: 2003/05/06 16:37:49 $
" Last Change:	$Date: 2003/06/02 19:40:21 $
" URL:		http://hans.fugal.net/vim/colors/desert.vim
" Version:	$Id: desert.vim,v 1.6 2003/06/02 19:40:21 fugalh Exp $

" cool help screens
" :he group-name
" :he highlight-groups
" :he cterm-colors
set background=dark
syntax on
if version > 580
" no guarantees for version 5.8 and below, but this makes it stop
" complaining
hi clear
if exists("syntax_on")
syntax reset
endif
endif
let g:colors_name="desert"

hi Normal	guifg=White guibg=grey20

" highlight groups
hi Cursor	guibg=khaki guifg=slategrey
"hi CursorIM
"hi Directory
"hi DiffAdd
"hi DiffChange
"hi DiffDelete
"hi DiffText
"hi ErrorMsg
hi VertSplit	guibg=#c2bfa5 guifg=grey50 gui=none
hi Folded	guibg=grey30 guifg=gold
hi FoldColumn	guibg=grey30 guifg=tan
hi IncSearch	guifg=slategrey guibg=khaki
"hi LineNr
hi ModeMsg	guifg=goldenrod
hi MoreMsg	guifg=SeaGreen
hi NonText	guifg=LightBlue guibg=grey30
hi Question	guifg=springgreen
hi Search	guibg=peru guifg=wheat
hi SpecialKey	guifg=yellowgreen
hi StatusLine	guibg=#c2bfa5 guifg=black gui=none
hi StatusLineNC	guibg=#c2bfa5 guifg=grey50 gui=none
hi Title	guifg=indianred
hi Visual	gui=none guifg=khaki guibg=olivedrab
"hi VisualNOS
hi WarningMsg	guifg=salmon
"hi WildMenu
"hi Menu
"hi Scrollbar
"hi Tooltip

" syntax highlighting groups
hi Comment	guifg=SkyBlue
hi Constant	guifg=#ffa0a0
hi Identifier	guifg=palegreen
hi Statement	guifg=khaki
hi PreProc	guifg=indianred
hi Type		guifg=darkkhaki
hi Special	guifg=navajowhite
"hi Underlined
hi Ignore	guifg=grey40
"hi Error
hi Todo		guifg=orangered guibg=yellow2

" color terminal definitions
hi SpecialKey	ctermfg=darkgreen
hi NonText	cterm=bold ctermfg=darkblue
hi Directory	ctermfg=darkcyan
hi ErrorMsg	cterm=bold ctermfg=7 ctermbg=1
hi IncSearch	cterm=NONE ctermfg=yellow ctermbg=green
hi Search	cterm=NONE ctermfg=grey ctermbg=blue
hi MoreMsg	ctermfg=darkgreen
hi ModeMsg	cterm=NONE ctermfg=brown
hi LineNr	ctermfg=3
hi Question	ctermfg=green
hi StatusLine	cterm=bold,reverse
hi StatusLineNC cterm=reverse
hi VertSplit	cterm=reverse
hi Title	ctermfg=5
hi Visual	cterm=reverse
hi VisualNOS	cterm=bold,underline
hi WarningMsg	ctermfg=1
hi WildMenu	ctermfg=0 ctermbg=3
hi Folded	ctermfg=darkgrey ctermbg=NONE
hi FoldColumn	ctermfg=darkgrey ctermbg=NONE
hi DiffAdd	ctermbg=4
hi DiffChange	ctermbg=5
hi DiffDelete	cterm=bold ctermfg=4 ctermbg=6
hi DiffText	cterm=bold ctermbg=1
hi Comment	ctermfg=darkcyan
hi Constant	ctermfg=brown
hi Special	ctermfg=5
hi Identifier	ctermfg=6
hi Statement	ctermfg=3
hi PreProc	ctermfg=5
hi Type		ctermfg=2
hi Underlined	cterm=underline ctermfg=5
hi Ignore	cterm=bold ctermfg=7

" O trecho abaixo formata a barra de status com algumas opções interessantes!
" mostra o código ascii do caractere sob o cursor e outras coisas mais
set statusline=%F%m%r%h%w\ [FORMATO=%{&ff}]\ [TIPO=%Y]\ [ASCII=\%03.3b]\ [HEX=\%02.2B]\ [linha,coluna=%04l,%04v][%p%%]\ [LINHAS=%L]
set laststatus=2 " Sempre exibe a barra de status

" seta: numeração, indentação expansão de tab para espaços
" mostra fechamento de parêntese, mostra régua, modo em que
" está etc.
"set ai et sm js
"set showcmd showmode
"set ruler
"syntax enable
"-----------------------------------------------------
" Destaca espaços e tabs redundantes
" caso queira usar descomente as ultimas linha e reinicie o
" vim ou pressione ,u caso etnha a função de recarregar (veja linha17)
" Highlight redundant whitespace and tabs.
highlight RedundantWhitespace ctermbg=red guibg=red
match RedundantWhitespace /\s\+$\| \+\ze\t/

" Habilita a detecção do tipo de arquivo
" Enable file type detection
" Use the default filetype settings, so that mail gets 'tw' set to 72,
" 'cindent' is on in C files, etc.
" Also load indent files, to automatically do language-dependent indenting.
"filetype plugin indent on

" Cria um cabeçalho para scripts bash
fun! InsertHeadBash()
   normal(1G)
   :set ft=bash
   :set ts=4
   call append(0, "#!/bin/bash")
   call append(1, "# Site: http://www.douglas.wiki.br")
   call append(2, "# Autor: Douglas Quintiliano dos Santos")
   call append(3, "# Criado em:" . strftime("%a %d/%b/%Y hs %H:%M"))
   call append(4, "# ultima modificação:" . strftime("%a %d/%b/%Y hs %H:%M"))
   call append(5, "# Propósito do script:")
   normal($)
endfun
map ,sh :call InsertHeadBash()<cr>

" Ao entrar em modo insert ele muda a cor da barra de status
" altera a cor da linha de status dependendo do modo
if version >= 700
        au InsertEnter * hi StatusLine term=reverse ctermbg=5 gui=undercurl guisp=Magenta
        au InsertLeave * hi StatusLine term=reverse ctermfg=0 ctermbg=2 gui=bold,reverse
endif

" Fechamento automático de parênteses
"imap { {}<left>
"imap ( ()<left>
"imap [ []<left>
"O autocomando abaixo coloca um cabeçalho para scripts 'bash' caso a linha 1 esteja vazia, observe que os arquivos em questão tem que ter a extensão .sh
au BufEnter *.sh if getline(1) == "" | :call setline(1, "#!/bin/bash") | endif
" tem que estar em modo normal!
nmap <C-Down> ddp
nmap <C-Up> ddkP

"  Remover linhas em branco duplicadas
map ,d <esc>:%s/\(^\n\{2,}\)/\r/g<cr>})

"remove espaços redundantes no fim das linhas
map <F7> <esc>mz:%s/\s\+$//g<cr>`z
"fiz uma adição ao comando depois do <esc> mz
"cria uma marca para voltar ao ponto em que se está
"e 'z retorna a este ponto ao final do comando

"  Destacar palavra sob o cursor
nmap <s-f> :let @/="<C-r><C-w>"<CR>

" Permite recarregar o vim para que modificações no
" próprio vimrc seja ativadas com o mesmo sendo editado
nmap <F12> :<C-u>source ~/.vimrc <BAR> echo "Vimrc recarregado!"<CR>
map ,u :source ~/.vimrc<CR>  " Para recarregar o .vimrc
map ,v :e ~\.vimrc<CR>  " para editar o .vimrc


" Redimensionar a janela com
" ALT+seta à direita e esquerda
map <M-right> <ESC>:resize +2 <CR>
map <M-left> <ESC>:resize -2 <CR>



"-----------------------------------------------------
"" dá permissão para arquivos dos tipos descritos abaixo
" Automatically give executable permissions if filename ends in .sh, .pl or
" .cgi
au BufWritePost *.sh,*.pl,*.cgi :!chmod a+x <afile>


"coloca a data tipo Ter 26/Out/2004 hs 10:53 na linha atual
iab ,d <C-R>=strftime("%a %d/%b/%Y hs %H:%M")<CR>
iab ,m <quintilianodouglas@gmail.com>
"
"" a função (strftime) é predefinida pelo sistema
iab YDATE <C-R>=strftime("%a %d/%b/%Y hs %H:%M")<CR>
iab HDATE <C-R>=strftime("%a %d/%b/%Y hs %H:%M")<CR>
" Example: 1998-11-05 19:20:43 MST
"
" " Estas linhas sao para não dar erro
" " na hora de salvar arquivos
cab W  w
cab Wq wq
cab wQ wq
cab WQ wq
cab Q  q
