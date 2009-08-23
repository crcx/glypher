
; macroinstructions for defining and invoking stdcall HLL procedures

macro proc name,[arg]			; define procedure
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
     ..ret = $ - (ebp+8)
    end virtual
    local ..dynamic_data,..dynamic_size
    dynamic_data equ ..dynamic_data
    dynamic_size equ ..dynamic_size
    virtual at ebp - dynamic_size
     dynamic_data: }

macro enter size,level			; begin procedure instructions
 { if size eq & level eq
    rb (4 - ($-dynamic_data) and 11b) and 11b
    dynamic_size = $ - dynamic_data
    end virtual
    push ebp
    mov ebp,esp
    if dynamic_size
     sub esp,dynamic_size
    end if
   else
    enter size,level
   end if }

macro return				; return from procedure
 { leave
   ret ..ret }

macro stdcall proc,[arg]		; call procedure
 { reverse
    pushd arg
   common
    call proc }

macro invoke proc,[arg] 		; invoke procedure (indirect)
 { common
    if ~ arg eq
     stdcall [proc],arg
    else
     call [proc]
    end if }
