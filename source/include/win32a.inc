
macro pushd arg
 { if _#arg in <_addr arg,_ADDR arg>
    local ..opcode,..address
    virtual at 0
     label ..address at arg
     mov eax,dword [..address]
     load ..opcode from 0
    end virtual
    if ..opcode = 0A1h
     push arg
    else
     lea edx,[..address]
     push edx
    end if
   else if arg eqtype ""
    local ..continue
    call ..continue
    db arg,0
    ..continue:
   else
    push arg
   end if
 }


; Win32 programming headers (ASCII)

include 'include/stdcall.inc'
include 'include/cdecl.inc'
include 'include/import.inc'
include 'include/export.inc'
include 'include/resource.inc'
include 'include/struct.inc'

struc CHAR count { rb count }

include 'include/kernel32.inc'
include 'include/user32.inc'
include 'include/gdi32.inc'
include 'include/comctl32.inc'
include 'include/comdlg32.inc'
include 'include/shell32.inc'
include 'include/wsock32.inc'
