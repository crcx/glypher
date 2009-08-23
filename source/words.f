macro
: (  ') parse drop drop ;
: //  10 parse drop drop ;
forth
: (  ') parse drop drop ;
: //  10 parse drop drop ;


macro
: f:  32 parse find compile ;
: m:  32 parse mfind compile ;
: swap  $0687 2, ;
: dup  $fc4689 3, $fc768d 3, ;
: over  m: dup $04468b 3, ;
: nip  $04c683 3, ;
: +  ?lit if $81 1, $c0 1, , ;; then $0603 2, m: nip  ;
: -  $d8f7 2, ;
: @  ?lit if m: dup $058b 2, , ;; then $008b 2, ;
: !  ?lit if $0589 2, , m: drop ;; then $c289 2, $89ad 2, $ad02 2, ;
: +!  ?lit if $0501 2, , m: drop ;; then $1e8b 2, $1801 2, m: drop m: drop ;
: :  create -5 h0 +! ;
: xor  $0633
: (bin)  ?lit if swap 2 + 1, , ;; then 2, m: nip ;
: and  $0623 m: (bin) ;
: or  $060b 2, m: nip ;
: c@  ?lit if m: dup $05b60f 3, , ;; then $00b60f 3, ;
: c!  ?lit if $0588 2, , m: drop ;; then $c289 2, m: drop $0288 2, m: drop ;
: u+  $044601 3, m: drop ;
: *  $26f7 2, m: nip ;
: /  $c389 2, $99ad 2, $fbf7 2, ;
: mod m: / $d089 2, ;
: push $50 1, m: drop ;
: pop $04ee83 3, $0689 2, $58 1, ;
: 2* $01e0c1 3, ;
: 2/ $01e8c1 3, ;
: not $fff083 3, ;
: r m: dup $24048b 3, ;
: nop $90 1, ;
: a!  $e88b 2, m: drop ;
: @+  m: dup $00458b 3, $04c583 3, ;
: a  m: dup $c58b 2, ;
: !+  ?lit if $0045c7 3, , $04c583 3, ;; then $004589 3, $04c583 3, m: drop ;
: */  $c88b 2, m: drop $f9f72ef7 , m: nip ;
: cells  m: 2* m: 2* ;
: 2drop m: drop m: drop ;
: 2dup m: over m: over ;
: i  m: r -1 m: literal m: + ;
forth
: align here 32 mod -32 + - 31 and h0 +! ;
: :  align create -5 h0 +! ] ;
: rot  push swap pop swap ;
: -rot  swap push swap pop ;

// Flow-Control
forth
: cmp ?lit if $f881 2, , ;; then $0639 2, ;
: ora $c00b 2, ;
: cj  1, $00 1, here ;
macro
: -zero ora $74 cj ;
: zero ora $75 cj ;
: less cmp $7d cj ;
: more cmp $7e cj ;
: less= cmp $7f cj ;
: more= cmp $7c cj ;
: negative  ora $79 cj ;

: = ( nn-f ) $850f
: (?) $063b 2, m: drop 2, $b ,
      $c0c7 2, -1 , $e9 1, 6 , $c0c7 2, 0 , ;
: > ( nn-f ) $8d0f m: (?) ;
: < ( nn-f ) $8e0f m: (?) ;

: min  $027f
: (which)  $d88b 2, m: drop $c33b 2, 2, $c38b 2, ;
: max  $027c m: (which) ;

: for  here m: push ;
: begin  here ;
: until  $c009 2, m: drop $840f 2, here - + -4 + , ;
: again  compile ;
: loop  m: pop  $48 1, $c009 2, $850f 2, here - + -4 + , m: drop ;


forth
: variable  create 0 , ;
: cfill ( ac n )  -rot for 2dup c! 1 + loop 2drop ;
: allot  here over 0 cfill h0 +! ;
: /mod  2dup mod -rot / ;
: exec  push ;
: 0;  -zero drop ;; then pop 2drop ;
: hex  16 base ! ;
: decimal  10 base ! ;
: abs  negative - then ;
: '  32 parse find ;
' cmove : cmove  swap [ compile ] ;
: space  32 emit ;
: .  negative '- emit - then
: u.  # type space ;
: .s  depth 0 less= drop ;; then 10 max for i pick . loop ;
macro
: 2@ $d88b 2, m: dup $04438b 3, $1b8b 2, $1e89 2, ;
forth
: 2@  2@ ;
: dump  swap a! for @+ . loop ;

variable mlast
variable flast
variable h1
: mark  macro last @ mlast ! forth last @ flast !
   h0 @ h1 ! ;
: empty  h1 @ h0 ! macro mlast @ last ! forth flast @
   last ! ;

: 2!  swap over 4 + ! ! ;
macro
: +a  ?lit if $c583 2, 1, ;; then $e803 2, m: drop ;


// Compiled macros
forth
: swap swap ; : dup dup ;
: drop drop ;
: over over ;
: @ @ ;
: ! ! ; : * * ;
: + + ; : - - ;
: cells cells ;
: +! +! ;

// Strings
forth
create st0 here 4 + , 16384 allot
create zpad 257 allot
: string  2dup st0 @ cmove st0 @ over st0 +! rot drop swap ;
: $compile  string swap m: literal m: literal ;
: z$ ( $c-a ) dup push zpad cmove 0 zpad pop + c! zpad ;
: count  dup 1 + swap c@ ;
: "  32 parse ;


variable lib
: from  z$ LoadLibrary lib ! ;
: proc z$ lib @ GetProcAddress ;
: import  push proc m: literal pop m: literal
   [ ' pascal_invoke ] literal compile ;
: cimport  push proc m: literal pop m: literal
   [ ' c_invoke ] literal compile ;
: (:)  (create) -5 h0 +! ;
: cvar  (:) proc m: literal m: ;; ;

// Base Imports
" zlib1.dll from
: compress2()  [ " compress2 5 cimport ] drop ;
: uncompress()  [ " uncompress 4 cimport ] ;

" randomad.dll from
: rndinit()  [ " TRandomInit 1 import ] drop ;
: tbrnd()  [ " TBRandom 0 import ] ;

" kernel32.dll from
: sleep  [ " Sleep 1 import ] drop ;
: GetLocalTime()  [ " GetLocalTime 1 import ] drop ;
: GlobalAlloc()  [ " GlobalAlloc 2 import ] ;
: GlobalFree()  [ " GlobalFree 1 import ] drop ;
: CreateFile()  [ " CreateFileA 7 import ] ;
: ReadFile()  [ " ReadFile 5 import ] ;
: WriteFile()  [ " WriteFile 5 import ] drop ;
: CloseHandle()  [ " CloseHandle 1 import ] drop ;
: GetFileSize()  [ " GetFileSize 2 import ] ;
: SetFilePointer()  [ " SetFilePointer 4 import ] drop ;
: SetEndOfFile()  [ " SetEndOfFile 1 import ] drop ;


// Random number
create t  8 cells allot
t GetLocalTime() t 3 cells + @ rndinit()
: rnd  tbrnd() over mod   abs swap negative drop - ;; then drop ;

// Files
variable temp
: malloc ( n-a ) 0 swap GlobalAlloc() ;
: free GlobalFree() ;
: file ( $c-nc ) z$ $C0000000 0 0 4 0 0 CreateFile()
   dup 0 GetFileSize() ;
: close  CloseHandle() ;
: read  ( $c-ac ) file swap push
   dup malloc swap 2dup
   r -rot temp 0 ReadFile() drop
   pop close ;
: write  ( a c $c ) file drop dup push
   0 0 0 SetFilePointer()
   r -rot temp 0 WriteFile()
   pop dup SetEndOfFile() close ;
: fload  32 parse read over swap eval free ;

// Compression
variable L
: buffer  [ 2049 1024 * malloc ] literal ;
: memory  2049 1024 * L ! -rot L -rot ;
: compress    ( ac $c- )
   push push buffer 4 + memory 9 compress2() L @ buffer
   swap dup buffer ! 4 + pop pop write ;
: uncompress ( aa-ac ) push dup @ 4 u+ r memory uncompress()
   drop pop L @ ;
: inflate  ( $c a- ) push read drop pop uncompress 2drop ;

: m~ m: drop ;

// NoteTab Outlines
: H="(  m: // ;
: header-  push dup begin 1 + dup c@ $0a = until 1 +
   swap over - + pop + ;
: outline  32 parse read over swap header- eval free ;

