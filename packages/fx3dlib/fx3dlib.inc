.macro fx3dlib(addr)
    lcall(fx3dlibId, addr)
.endmacro
.macro fx3dlib(cc, addr)
    lcall(fx3dlibId, cc, addr)
.endmacro

fx3dlibId .equ 0x03

rotateVertex .equ 6
projectVertex .equ 9
drawTriangle .equ 12