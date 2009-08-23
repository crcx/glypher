
; structure definition helper

macro struct name
 { virtual at 0
   name name
   sizeof.#name = $ - name
   name equ sizeof.#name
   end virtual }
