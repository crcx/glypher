
; macroinstructions for defining and invoking cdecl HLL procedures

macro cproc name,[arg]			; define procedure
 { common
    name:
    virtual at ebp+8
    if ~ arg eq
   forward
     local ..arg
     ..arg dd ?
     arg equ ..arg
   common
     end if
    end virtual
    local ..dynamic_data,..dynamic_size
    dynamic_data equ ..dynamic_data
    dynamic_size equ ..dynamic_size
    virtual at ebp - dynamic_size
     dynamic_data: }

macro enterc				; begin procedure instructions
 { rb (4 - ($-dynamic_data) and 11b) and 11b
   dynamic_size = $ - dynamic_data
   end virtual
   push ebp
   mov ebp,esp
   if dynamic_size
    sub esp,dynamic_size
   end if }

macro retc				; return from procedure
 { leave
   ret }

macro ccall proc,[arg]			; call procedure
 { common local ..size
   ..size = 0
   reverse
   pushd arg
   ..size = ..size+4
   common
   call proc
   add esp,..size }

macro cinvoke proc,[arg]		; invoke procedure (indirect)
 { common
    if ~ arg eq
     ccall [proc],arg
    else
     call [proc]
    end if }
