; /etc/castle.config

; Defines the icons on the castle home
; Format:
; Pointer to shortcut name, or 0xFFFF
; If first word is not 0xFFFF,
;   pointer to file name
;   16x16 icon

; Row 1
.dw fileManagerStr, fileManagerPath
.db 0x38, 0xf0, 0x47, 0x08, 0x80, 0x08, 0x80, 0x1e
.db 0x81, 0xe1, 0x86, 0x01, 0x48, 0x79, 0x48, 0x19
.db 0x48, 0x2a, 0x48, 0xca, 0x4b, 0x02, 0x28, 0x02
.db 0x28, 0x04, 0x28, 0x78, 0x2b, 0x80, 0x1c, 0x00

.dw demoStr, demoPath
.db 0xc0, 0x03, 0x80, 0x01, 0x3f, 0x94, 0x00, 0x14
.db 0x0f, 0x80, 0x00, 0x22, 0x03, 0x9c, 0x00, 0x00
.db 0xc0, 0x00, 0xa4, 0xa4, 0xaa, 0xea, 0xac, 0xaa
.db 0xc6, 0xa4, 0x00, 0x00, 0x80, 0x01, 0xc0, 0x03

.dw helloStr, helloPath
.db 0xa1, 0xb0, 0xa4, 0x92, 0xea, 0x95, 0xac, 0x95
.db 0xa6, 0x92, 0x00, 0x00, 0x00, 0x00, 0x0f, 0xf0
.db 0x30, 0x0c, 0xc1, 0x83, 0x07, 0xc0, 0x87, 0xd8
.db 0xc7, 0xfc, 0xe3, 0xfc, 0xe3, 0xfd, 0xe7, 0xfd

.dw countStr, countPath
.db 0x4c, 0xc0, 0xc2, 0x20, 0x44, 0x44, 0x48, 0x20
.db 0xee, 0xc0, 0x00, 0x00, 0x57, 0x30, 0x54, 0x40
.db 0x76, 0x72, 0x11, 0x50, 0x16, 0x70, 0x00, 0x00
.db 0x39, 0x18, 0x0a, 0xa8, 0x11, 0x19, 0x12, 0x88

.dw settingsStr, settingsPath
.db 0x00, 0x02, 0x5f, 0xe7, 0x00, 0x0a, 0x5f, 0x94
.db 0x00, 0x28, 0x5f, 0xb0, 0x00, 0x00, 0x5f, 0xe0
.db 0x00, 0x00, 0x1f, 0xf8, 0x20, 0x04, 0x2f, 0xf4
.db 0x28, 0x14, 0x28, 0x14, 0x28, 0x14, 0x28, 0x14

; Row 2
.dw licenseStr, licensePath
.db 0x00, 0x00, 0x00, 0x00, 0x03, 0xc0, 0x0c, 0x30
.db 0x10, 0x08, 0x13, 0xc8, 0x24, 0x24, 0x24, 0x04
.db 0x24, 0x04, 0x24, 0x24, 0x13, 0xc8, 0x10, 0x08
.db 0x0c, 0x30, 0x03, 0xc0, 0x00, 0x00, 0x00, 0x00

.dw 0xFFFF

.dw 0xFFFF

.dw 0xFFFF

.dw 0xFFFF

fileManagerStr:
    .db "File Manager", 0
fileManagerPath:
    .db "/bin/fileman", 0
helloStr:
    .db "Hello World", 0
helloPath:
    .db "/bin/hello", 0
demoStr:
    .db "Graphical Demo", 0
demoPath:
    .db "/bin/gfxdemo", 0
countStr:
    .db "Counting Demo", 0
countPath:
    .db "/bin/count", 0
settingsStr:
    .db "System Settings", 0
settingsPath:
    .db "/bin/settings", 0
licenseStr:
    .db "License", 0
licensePath:
    .db "/etc/LICENSE", 0
