
; macroinstruction for making import section

macro library [name,string]
 { forward
    local _label
    if ~ name#.needed
    dd 0,0,0,RVA _label,RVA name
    end if
   common
    dd 0,0,0,0,0
   forward
    if ~ name#.needed
    _label db string,0
    end if }

macro import name,[label,string]
 { common
    name:
   forward
    if used label
     local _label
     label dd RVA _label
    end if
   common
    if $ > name
     name#.needed = FALSE
     dd 0
    else
     name#.needed = TRUE
    end if
   forward
    if used label
    _label dw 0
	   db string,0
    end if }
