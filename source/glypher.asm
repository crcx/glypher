; ----------------------------------------------------------------------
; Glypher, by Roger Levy
; based on RetroForth 7.6, by Charles Childers
; ----------------------------------------------------------------------

;format PE console
format PE GUI
stack 16000
entry start

include "include/macros.fasm"
include "include/win32a.inc"

section ".code" code readable writeable executable
start:
	call window
	call reset
	call load.words
	embed 'outline glypher_03.otl'
	;embed 'outline glypher_02.otl'  ;emergency
	jmp interpret

load.words:
	upsh words
	upsh words.1-words
	call eval
	ret

window:
	pusha
	invoke GetModuleHandle, 0
	mov [hinstance], eax

	invoke GetStdHandle, STD_INPUT_HANDLE
	mov [StdIn], eax
	invoke SetConsoleMode, eax, 5

	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov [StdOut], eax

	invoke SetConsoleTitle, "RetroForth"
	popa
	ret


code 'key', key
	dup
	pusha
	invoke ReadFile, [StdIn], emit_buffer, 1, written_buffer, 0
	popa
	mov eax, [emit_buffer]
	ret

code 'emit', emit
	push ebx
	push ecx
	call [emitv]
	pop ecx
	pop ebx
	next

code '(emit)', pemit
	upsh emitv
	next

code 'type', type
	push ebx
	push ecx
	call [typev]
	pop ecx
	pop ebx
	next
code '(type)', ptype
	upsh typev
	next

code 'hemit', hemit
	push ebx
	push ecx
	call [hemitv]
	pop ecx
	pop ebx
	next
code '(hemit)', phemit
	upsh hemitv
	next
code 'htype', htype
	push ebx
	push ecx
	call [htypev]
	pop ecx
	pop ebx
	next
code '(htype)', phtype
	upsh htypev
	next


cemit:
	pusha
	mov [emit_buffer], eax	; keep it safe
	invoke WriteFile, [StdOut], emit_buffer, 1, written_buffer, 0
	popa
	drop
	ret
code 'ctype', ctype
       mov ebx, [esi]
       pusha
       invoke WriteFile, [StdOut], ebx, eax, written_buffer, 0
       popa
       drop
       drop
next


code 'pick',pick
	; add eax, 1
	sal eax, 2
	add eax, esi
	mov eax, [eax]
	ret

code 'depth',depth
	dup
	mov eax, esi
	sub eax, s0
	neg eax
	sar eax, 2
	sub eax, 1
	ret

code 'bye', windows_bye
	invoke ExitProcess,0
ret


code 'LoadLibrary', ll
	invoke LoadLibrary, eax
next

code 'GetProcAddress', gpa
	upop edx
	invoke GetProcAddress,edx,eax
next

code 'pascal_invoke', _pascal_invoke
	swap
	upop [faddr]		; Get the function address
	upop ecx
	cmp ecx, 0
	jz .run
.chain: push eax
	drop
	loop .chain
.run:	upsh [faddr]		; Restore the function address
	call dword eax
next

code 'c_invoke', _c_invoke
	swap
	upop [faddr]		; Get the function address
	xor ebx,ebx
        upop ecx
        cmp ecx, 0
        jz .run
.chain:	push dword eax
        drop
        add ebx, 4
        loop .chain
.run:   mov dword [tempX], ebx
	upsh [faddr]		; Restore the function address
	call dword eax
        mov ebx, dword [tempX]
        add esp, ebx
next
faddr dd 0

emitv dd cemit
typev dd ctype
hemitv dd cemit
htypev dd ctype

hinstance rd 1
StdIn rd 1
StdOut rd 1
emit_buffer rd 1
written_buffer rd 1
tempX rd 1
keyv rd 1

;---------------------------------------------------------------------
; windows-specific linkage stuff:
data import

  library kernel,'KERNEL32.DLL'

  import kernel,\
	 GetModuleHandle,'GetModuleHandleA',\
	 ExitProcess,'ExitProcess',\
	 GetStdHandle, 'GetStdHandle',\
	 WriteFile, 'WriteFile',\
	 ReadFile, 'ReadFile',\
	 SetConsoleMode, 'SetConsoleMode',\
	 SetConsoleTitle, 'SetConsoleTitleA',\
	 CreateFile, 'CreateFileA',\
	 GetLastError,'GetLastError',\
	 CloseHandle,'CloseHandle',\
	 CreateConsoleScreenBuffer,'CreateConsoleScreenBuffer',\
	 SetConsoleActiveScreenBuffer,'SetConsoleActiveScreenBuffer',\
	 LoadLibrary,'LoadLibraryA',\
	 GetProcAddress,'GetProcAddress'
end data

interpret:
.o:	call query	; ( Get a WORD )
.word:	upsh 32
	call parse	; ( Parse until we find <SPACE> )
	jnz .find		; ( Look for the end of the line )
	drop
	drop
	jmp .o		; ( Loop back to start if no words found )
.find:	call find
	jnc .exec		; ( Found? Interpret it )
	call number	; ( No? Then try a number )
	jnc .word		; ( Loop back )
	call word_not_found	;
	jmp .o		; ( And Loop back )
.exec:	upop edi		; ( This is where we actually call the )
	call edi		; ( words we find )
	jmp .word		; ( And Loop back )
next
; ----------------------------------------------------------------------
code 'mfind', mfind		;
	push ebx		;
	mov ebx, mlast		;
	jmp find.o		;
; ----------------------------------------------------------------------
code 'find', find		;
	push ebx		;
	mov ebx, flast		;
.o:	push ecx		;
	upop ecx		;
.a:	mov ebx,[ebx]		;
	or ebx,ebx		;
	jz .end 		;
	cmp cl,[ebx+8]		;
	jne .a			;
.len:	push esi		; same length
	push edi		;
	push ecx		;
	mov esi,eax		;
	lea edi,[ebx+9] 	;
	rep cmpsb		;
	pop ecx 		;
	pop edi 		;
	pop esi 		;
	jne .a			;
	mov eax,[ebx+4] 	; exact match
	clc			;
	jmp .ret		;
.end:	upsh ecx		; no matches
	stc			;
.ret:	pop ecx 		;
	pop ebx 		;
next
; ----------------------------------------------------------------------
code '>number', number		;
	push dword [base]	;
        mov [base],10
	mov ecx,eax		; n   (keep on stack in case of failure)
	mov ebx,[esi]		; a
	dup			;
	xor eax,eax		; the number
	xor edx,edx		; temp
	mov dl,[ebx]		;
	cmp dl,45		; -     Sign prefix
	pushf			;
	jne .a			;
	inc ebx 		;
	dec ecx 		;
	mov dl,[ebx]		;
.a:	sub dl,36		; $%&'  Base prefix
	cmp dl,4		;
	ja .b			;
	mov dl,[edx+bases]	;
	mov byte [base],dl	;
	inc ebx 		;
	dec ecx 		;
.b:	mov dl,[ebx]		; digits
	inc ebx 		;
	call digit		;
	jc .err 		;
	loop .b 		;
	jmp .c			;
.err:	add esp, 4		;
	drop			;
	stc			;
	jmp .ret		;
.c:	popf			;
	jne .d			;
	neg eax 		;
.d:	add esi,8		;
	clc			;
.ret:	pop dword [base]	;
next
; ----------------------------------------------------------------------
digit:	cmp byte [base],255	;
	je .x10 		;
	cmp dl,57		; 9
	jbe .a			;
	and dl,5Fh		; uppercase
	cmp dl,65		; throw out chars between '9' and 'A'
	jb .err 		;
	sub dl,7		;
.a:	sub dl,48		; 0
	cmp dl, byte [base]	;
	jb .x10 		;
.err:	stc			; not a digit
	ret			;
.x10:	imul eax,[base] 	;
	add eax,edx		;
	clc			;
next
; ----------------------------------------------------------------------
query:				;
	mov dword ecx,[source]	;
	or ecx,ecx		;
	jnz query_mem		;
	mov dword [tp],tib	; Reset TP, TIN
	mov dword [tin],tib	;
	upsh '>'
	call hemit
.a:	call key		; Get a keypress
	cmp al, 13		;
	je .cr			;
	cmp al, 10		;
	je .cr			;
	xchg edi,[tp]		; Store the char in the TIB
	stosb			;
	xchg [tp],edi		;
	drop			;
	jmp .a			; And Loop back around
.cr:	drop			; We just eat CR & LF
next
; ----------------------------------------------------------------------
query_mem:			;
	mov edi,[tin]		;
	upsh edi		; Input pointer
	dup			;
	cmp Byte [edi],10	; Skip LF
	jne .a			;
	inc edi 		; Increase our pointer
.a:	mov [tin],edi		;
	sub ecx,edi		; Remaining length
	jbe .eof		;
	mov al,10		; Line Feed
	repne scasb		;
	mov eax,edi		;
	jne .b			;
	dec eax 		;
	cmp Byte [eax-1],13	; We make CR optional
	jne .b			;
	dec eax 		;
.b:	upop [tp]		;
	drop			;
	next			;
.eof:	drop			;
	drop			;
	add esp,4		; Discard caller
	pop Dword [tp]		;
	pop Dword [tin] 	;
	pop Dword [source]	;
next
; ----------------------------------------------------------------------
code 'eval', eval		; This takes an address & count to eval
	push Dword [source]	; Save "source"
	push Dword [tin]	; Save ">in"
	push Dword [tp] 	; Save "tp"
	add eax,[esi]		;
	upop [source]		; New "source"
	upop [tin]		; New ">in"
	jmp interpret		; Interpret the memory area
				; No need for 'next' here
; ----------------------------------------------------------------------
dovar:	dup			; This little snippit of code is what
	pop eax 		; pushes the address of a variable to
next				; the stack when a variable is called
; ----------------------------------------------------------------------
code ',', comma 		; comma (,) saves a value to "here"
	mov ecx,4		; By default, it uses a dword (4 bytes)
.a:	mov edx,[h]		;
	mov [edx],eax		;
	drop			;
	add edx,ecx		;
	mov [h],edx		;
	mov dword [tail], -1	; Disable tail recursion
next
code '1,', comma1		; comma1 (1,) saves 1 byte to "here"
	mov ecx,1		;
	jmp comma.a
code '2,', comma2		; comma2 (2,) saves 2 bytes to "here"
	mov ecx,2		;
	jmp comma.a
code '3,', comma3		; comma3 (3,) saves 3 bytes to "here"
	mov ecx,3		;
	jmp comma.a
; ----------------------------------------------------------------------
dodoes: dup			; Handle DOES>
	pop eax 		;
	xchg eax,[esp]		;
next
; ----------------------------------------------------------------------
code 'dolit', dolit
	dup			; This is where we handle literals.
	mov eax,[esp]		;
	mov eax,[eax]		;
	add dword [esp],4	;
next
; ----------------------------------------------------------------------
code 'create', create
	upsh 32 		; Name
	call parse		;
	jmp real_create 	;
code '(create)', real_create	;
	push ecx		;
	mov edi,[d]		; LFA
	mov ecx,[last]		; last
	mov edx,[ecx]		;
	mov [edi],edx		; LFA= [last]
	mov [ecx],edi		; last= LFA
	mov ecx,[h]		;
	mov [edi+4],ecx 	; CFA= here
	mov [edi+8],al		; Length
	add edi,9		;
	upop ecx		;
	push esi		;
	mov esi,eax		;
	rep movsb		;
	mov [d],edi		; d= d+9+length
	pop esi 		;
	pop ecx 		;
	mov eax,dovar		; Code
	jmp compile		;
; ----------------------------------------------------------------------
mcode 'does>', does		;
	upsh pdoes		;
	call compile		;
	upsh dodoes		;
	jmp compile		;
; ----------------------------------------------------------------------
pdoes:	dup			;
	mov eax,[last]		; eax= header
	mov eax,[eax]		;
	mov eax,[eax+4] 	; eax= CFA
	pop ebx 		;
	sub ebx,eax		;
	sub ebx,5		;
	mov [eax+1],ebx 	; Change "call dovar" to "call <code after does>"
	drop			;
next
; ----------------------------------------------------------------------
code ']', rbracket		; This is the actual compiler loop
.word:	upsh 32 		; Space
	call parse		; Scan for a word name or number
	jnz .find		; n=0 means EOL
	drop			; 2drop
	drop			;
	call query		;
	jmp .word		; Was a 'ret'
.find:	call mfind		;
	jnc .exec		; Macros
	call find		;
	jnc .com		; Regular words
	call number		;
	jnc .lit		; Numbers
	call word_not_found	; Go figure..
	upsh $c3		; Compile a ret (avoid problems)
	call comma1		;
	jmp .word		; And go on compiling (avoid errors)
.exec:	upop edi		; Execute words in 'macro'
	call edi		;
	jmp .word		;
.com:	call compile		; Compile a call to words in 'forth'
	jmp .word		;
.lit:
        call literal
	jmp .word		;
; ----------------------------------------------------------------------
code 'compile', compile 	; This routine compiles in CALL's to
	sub eax,[h]		; words. Address is passed in EAX
	sub eax,5		;
	upsh 0xE8		; CALL opcode
	call comma1		; 0xE8
	call comma		; ADDRESS
	mov dword [tail], 0	; Enable tail-call
next
; ----------------------------------------------------------------------
mcode '[', lbracket		; Switch back to the interpreter
	add esp,4		;
next
; ----------------------------------------------------------------------
mcode ';;', ssemi		; Exit a word (; will call this!)
	mov edx,[h]		;
	sub edx,5		;
	cmp byte [edx],0xE8	; Was the last thing compiled a CALL?
	jnz .a			; No, skip the next line
	cmp dword [tail],0	; See if we should compile a tail-call
	jnz .a			; No? skip it and compile a ret
	inc byte [edx]		; Yes, change to JMP
	next			; and exit
.a:	mov byte [edx+5],0xC3	; If not a CALL, compile in a RET
	inc dword [h]		;
next
; ----------------------------------------------------------------------
mcode ';', semi 		; Compile in an exit to the current word
	call ssemi		; And go back to the interpreter
	jmp lbracket		;
; ----------------------------------------------------------------------
code ':', colon 		; Ok, this is the entry to the compiler
	call create		; * Create a new word
	sub dword [h],5 	; * Undo 'call dovar'
	jmp rbracket		; * And jump to the real compiler
; ----------------------------------------------------------------------
mcode 'dup', cdup
        upsh 0xfc4689
	call comma3
	upsh 0xfc768d
	call comma3
next

mcode 'literal', literal
	call cdup
	upsh $c0c7
	call comma2
	call comma
next

; ----------------------------------------------------------------------
code 'forth', dict_forth	; Switch to the 'forth' vocabulary
	mov dword [last], flast ;
next
; ----------------------------------------------------------------------
code 'macro', dict_macro	; Switch to the 'macro' vocabulary
	mov dword [last], mlast ;
next
; ----------------------------------------------------------------------
; Convert number to a string:
code '#', pound 	        ;
	push edx	        ;
	push edi	        ;
	mov edi,nbuf		;
.a:	xor edx,edx	        ;
	div dword [base]        ;
	add dl,'0'	        ;
	cmp dl,'9'	        ;
	jbe .b		        ;
	add dl,7+32	        ;
.b:	dec edi 	        ;
	mov [edi],dl	        ;
	or eax,eax	        ;
	jnz .a		        ;
	mov eax,edi	        ; Print
	upsh nbuf 		;
	sub eax,edi	        ; # of digits
	pop edi 	        ;
	pop edx 	        ;
next


; ----------------------------------------------------------------------
code 'parse', parse		;
	mov edi,[tin]		; Pointer into TIB
	mov ecx,[tp]		;
	sub ecx,edi		;
	inc ecx 		;
	repe scasb		;
	dec edi 		;
	inc ecx 		;
	dup			;
	mov [esi],edi		; a
	repne scasb		;
	mov eax,edi		;
	dec eax 		;
	sub eax,[esi]		; n
	mov [tin],edi		;
next
; ----------------------------------------------------------------------
code 'reset', reset		; This word is used to reset the stack
	mov esi, s0		; to the proper starting point
next
code 'cmove', _cmove		;
	mov ecx,eax		;
	drop			;
	mov edi,eax		;
	drop			;
	push esi		;
	mov esi,eax		;
.a:	mov dl, byte [esi]	; htp123 on irc.freenode.net#fasm
	mov byte [edi], dl	; suggested a fix for these two lines.
	inc edi 		; It is now implemented. Thanks!
	inc esi 		;
	loop .a 		;
	pop esi 		;
	drop			;
next
; ----------------------------------------------------------------------
code 'unknown', word_not_found 		; What to do if we can't find a word
	call htype		; Display the name
	upsh '?'		; Followed by a ?
	call hemit		;
	upsh ' '
	call hemit
next
; ----------------------------------------------------------------------
code 'last', var_last		; Needed for 'reset' to work properly
	upsh [last]		; in this release. The changes to 'words'
next				; make this essential.
code 'sp@', spfetch
 dup
 mov eax, esp
next
code 'dp@', dpfetch
 dup
 mov eax, esi
next
code '?lit', qlit
 mov ecx, [h]
 add ecx, -6
 movzx ecx, word [ecx]
 cmp ecx, $c0c7
 jne .a
 mov ecx, [h]
 add ecx, -4
 dup
 mov eax, [ecx]
 add ecx, -8
 mov [h], ecx
 dup
 mov eax, -1
 jmp .b
.a:
 dup
 mov eax, 0
.b:
next

mcode 'drop', mdrop
 upsh $ad
 call comma1
next

code 'here', here
 upsh [h]
next

mcode 'if', mif
 upsh $c085
 call comma2
 call mdrop
 upsh $74
 call comma2
 call here
next

mcode 'then', mthen
 mov ecx, eax
 drop
 call here
 sub eax, ecx
 add ecx, -1
 mov byte [ecx], al
 drop
 upsh $90
 call comma1
next

code 'system',fsystem
 upsh system
next

code 'glypher',fglypher
 upsh glypher
next

code 'jump',jump
 pop edx
 add edx, eax
 lea edx, [5+eax*4+edx]
 add edx, [-4+edx]
 drop
 jmp edx
; ----------------------------------------------------------------------
var 'h0', h, h0 		; h0 (pointer to HERE)
var 'base', base, 10		; current numeric base
var 'lastc', lastc, 'k'
d		dd d0		;
tail		dd 0		; Allow tail-calls?
buffer		dd 0		; Buffer (for ports to use as needed)
source		dd 0		; Evaluate from RAM or KBD
tin		dd 0		; >IN
tp		dd tib		; TP (pointer to input buffer)
bases		db 16,2,8,255	; $hex %bin &oct 'ascii
; ----------------------------------------------------------------------
last  dd flast			; Last word in dictionary
flast dd forth_link		; Last word in 'forth'
mlast dd macro_link		; Last word in 'macro'
; ----------------------------------------------------------------------

words: file "words.f"
words.1:

glypher: file "glypher.z"
glypher.1:

system: ;file "zblocks.dat"

;----------------------------------------------------------------------
; section "bss"
; ----------------------------------------------------------------------
tib: rb 1024			; Text Input Buffer (1k)

     rb 2048
s0:  rb 2048

h0:  rb 1024*1024*64		; Code (64 MB)
d0:  rb 100000			; Dictionary

     rb 16
nbuf: rb 1