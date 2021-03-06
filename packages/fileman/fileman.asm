#include "kernel.inc"
#include "corelib.inc"
    .db "KEXC"
    .db KEXC_ENTRY_POINT
    .dw start
    .db KEXC_STACK_SIZE
    .dw 100
    .db KEXC_KERNEL_VER
    .db 0, 6
    .db KEXC_NAME
name_ptr:
    .dw titlePrefix
    .db KEXC_HEADER_END
start:
    pcall(getLcdLock)
    pcall(getKeypadLock)

    kld(de, corelibPath)
    pcall(loadLibrary)

    pcall(allocScreenBuffer)

    ; Set current path
    ld bc, 1024 + (titlePrefixEnd - titlePrefix)
    pcall(malloc)
    push ix \ pop de
    kld(hl, titlePrefix)
    ld bc, titlePrefixEnd - titlePrefix
    ldir
    ex de, hl
    ld a, '/'
    ld bc, 0
    cpdr \ cpdr ; Note: this prevents us from having / be the initial path
    inc hl
    kld((currentPath), hl)
    push ix \ pop hl
    push hl
        pcall(getCurrentThreadId)
        pcall(getEntryPoint)
        ld b, h \ ld c, l
    pop hl
    or a
    sbc hl, bc
    kld((name_ptr), hl)

    ; Allocate space for fileList and directoryList
    ld bc, 512 ; Max 256 subdirectories and 256 files per directory
    pcall(malloc)
    push ix \ pop hl
    kld((fileList), hl)
    pcall(malloc)
    push ix \ pop hl
    kld((directoryList), hl)

doListing:
    kld(hl, (currentPath))
    inc hl
    ld a, (hl)
    dec hl
    or a ; cp 0 (basically, test if we're at the root
    jr z, _

    ; Add a .. entry if this is not the root
    kld(hl, (directoryList))
    kld(de, dotdot)
    ld (hl), e
    inc hl
    ld (hl), d
    inc hl
    kld((directoryList), hl)

_:  kld(hl, (currentPath))
    ex de, hl
    kld(hl, listCallback)
    exx
        ld bc, 0
    exx
    pcall(listDirectory)
    exx
    push bc
        exx
    pop bc
    ; B: Num directories
    ; C: Num files
    ; Sort results
    kld(hl, (currentPath))
    inc hl
    ld a, (hl)
    or a
    jr z, _ 
    inc b ; Add the imaginary '..' entry
_:  push bc
        ld a, b
        or a
        jr z, ++_
        kld(ix, (directoryList))
        pcall(memSeekToStart)
        kld((directoryList), ix)
        ld a, b
        ld b, 0
        ld c, a
        ; Check for root and move past the .. if not
        kld(hl, (currentPath))
        inc hl
        ld a, (hl)
        push ix \ pop hl
        or a ; cp 0
        jr z, _
        ; We are not on the root, so skip the .. entry for sorting
        inc hl \ inc hl
        dec bc
_:      ld d, h \ ld e, l
        add hl, bc
        add hl, bc
        ex hl, de
        dec de \ dec de
        ld bc, 2
        ; This is weird. We know this pcall is on page 0x00, so this
        ; just takes it apart and gets the address in the jump table
        ; directly so that we can offer it to callbackSort
        ld ix, 0x4000 - (((compareStrings_sort >> 8) + 1) * 3)
        pcall(callbackSort) ; Sort directory list
    pop bc \ push bc
        ld a, c
        or a
        jr z, _
        kld(ix, (fileList))
        pcall(memSeekToStart)
        kld((fileList), ix)
        push ix \ pop hl
        ld d, h \ ld e, l
        ld b, 0
        add hl, bc
        add hl, bc
        ex hl, de
        dec de \ dec de
        ld bc, 2
        ld ix, 0x4000 - (((compareStrings_sort >> 8) + 1) * 3)
        pcall(callbackSort) ; Sort file list
_:  pop bc
    ld a, b
    kld((totalDirectories), a)
    ld a, c
    kld((totalFiles), a)
    ; All sorted, now draw it
drawList:
    pcall(clearBuffer)
    kld(hl, (currentPath))
    push hl \ pop ix
    pcall(memSeekToStart)
    push ix \ pop hl
    ld a, 0b00000100
    push bc
        ld bc, initialPath - titlePrefix
        or a
        add hl, bc
    pop bc
    corelib(drawWindow)

    ld de, 0x0808
    kld(a, (scrollTop))
    ld h, a
    push bc
        kld(ix, (directoryList))
        xor a
_:      cp h
        jr z, _
        dec h
        inc ix \ inc ix
        dec b
        jr nz, -_
_:      ld a, b
        or a
        jr z, .drawFiles
        xor a
        push hl \ kcall(.draw) \ pop hl
.drawFiles:
    pop bc \ push bc
        kld(ix, (fileList))
        xor a
_:      cp h
        jr z, _
        dec h
        inc ix \ inc ix
        dec c
        jr nz, -_
_:      ld a, c
        ld b, a
        or a
        jr z, ._done
        ld a, 1
        kcall(.draw)
._done:
    pop bc
    jr .done

.draw:
    push af
        ld a, e
        cp 0x38 ; Stop drawing at Y=0x38
        jr nz, ++_
        ld a, b
        or a
        jr z, _
        kld(hl, downCaretIcon)
        ld b, 3
        push de
            ld de, 0x5934
            pcall(putSpriteOR)
        pop de
_:  pop af
    ret
_:  pop af
    ld l, (ix)
    ld h, (ix + 1)
    pcall(drawStr)
    push bc
        or a
        jr z, _
        ; File size
        pcall(stringLength)
        or a
        adc hl, bc
        inc hl
        push af
            push de
                ld e, (hl)
                inc hl
                ld d, (hl)
                inc hl
                ld a, (hl)
                ex de, hl
            pop de
            kcall(drawFileSize)
        pop af
_:      ld b, 6
        or a
        jr z, _
        kld(hl, fileIcon)
        jr ++_
_:      kld(hl, directoryIcon)
_:      ld d, 2
        pcall(putSpriteOR)
        ld d, 8
        ld b, 8
        pcall(newline)
    pop bc
    inc ix \ inc ix
    djnz .draw
    ret

.done:
    push bc
        ld a, b
        add c
        ld b, 0
        ld c, a
        jr nc, $+3
        inc b
        push bc

            ; Draw remainder of UI
            kld(a, (scrollTop))
            or a
            jr z, _
            kld(hl, upCaretIcon)
            ld de, 0x5908
            ld b, 3
            pcall(putSpriteOR)

_:          ld e, 8 ; x
            kld(a, (scrollOffset))
            kld(hl, scrollTop)
            sub (hl)
            ld l, a
            add a, a
            add a, a
            add a, l
            add a, l
            add a, 7
            ld l, a ; y
            ld c, 87 ; w
            ld b, 7 ; h
            pcall(rectXOR)

            kld(a, (scrollOffset))
            ld d, a ; Index

idleLoop:
            pcall(fastCopy)
            pcall(flushKeys)
            corelib(appWaitKey)
            jr nz, idleLoop

            cp kDown
            kjp(z, .handleDown)
            cp kUp
            kjp(z, .handleUp)
            cp kLeft
            kjp(z, .handleParent)
            cp kClear
            kjp(z, .handleParent)
            cp kEnter
            kjp(z, .handleEnter)
            cp k2nd
            kjp(z, .handleEnter)
            cp kRight
            kjp(z, .handleEnter)
            cp kDel
            kjp(z, .handleDelete)
            cp kMode
            kjp(z, .exit)
            jr idleLoop
.handleDown:
        pop bc
        ld a, d
        inc a
        cp c
        push bc
            ld c, 87
            ld b, 7
            jr nc, idleLoop
            ld a, d
            push hl
                kld(hl, scrollTop)
                sub (hl)
            pop hl
            cp 7
            jr z, .tryScrollDown
            push de
                ld d, a
                add a, a
                add a, a
                add a, d
                add a, d ; A *= 6
                add a, 7
            pop de
            ld l, a
            pcall(rectXOR)
            add a, 6
            ld l, a
            pcall(rectXOR)
            inc d
            ld a, d
            kld((scrollOffset), a)
            kjp(idleLoop)
.tryScrollDown:
            inc d
            ld a, d
            kld((scrollOffset), a)
            kld(hl, scrollTop)
            inc (hl)
        pop bc
    pop bc
    kjp(drawList)
.handleUp:
            ld a, d
            or a
            kjp(z, idleLoop)
            push hl
                kld(hl, scrollTop)
                sub (hl)
            pop hl
            or a ; cp 0
            jr z, .tryScrollUp
            push de
                ld d, a
                add a, a
                add a, a
                add a, d
                add a, d ; A *= 6
                add a, 7
            pop de
            ld l, a
            pcall(rectXOR)
            sub a, 6
            ld l, a
            pcall(rectXOR)
            dec d
            ld a, d
            kld((scrollOffset), a)
            kjp(idleLoop)
.tryScrollUp:
            dec d
            ld a, d
            kld((scrollOffset), a)
            kld(hl, scrollTop)
            dec (hl)
        pop bc
    pop bc
    kjp(drawList)
.handleEnter:
        pop bc
    pop bc
    ; Determine if it's a file or a directory
    ld a, d
    cp b
    kjp(nc, openFile)
    ; Handle directory
    add a, a
    kld(hl, (directoryList))
    add l
    ld l, a
    jr nc, $+3
    inc h
    ld e, (hl)
    inc hl
    ld d, (hl)
    ld a, (de)
    cp '.'
    kjp(z, .handleParent_noPop)
    kld(hl, (currentPath))
    xor a
    ld bc, 0
    cpir
    dec hl
    ex de, hl
    pcall(stringLength)
    inc bc
    ldir
    ex de, hl
    dec hl
    ld a, '/' ; Add trailing slash
    ld (hl), a
    inc hl
    xor a
    ld (hl), a
    kjp(freeAndLoopBack)
.handleDelete:
        pop bc
    pop bc
    ld a, d
    cp b
    jr c, .deleteDirectory
    push de
    push bc
        kld(hl, deletionMessage)
        kld(de, deletionOptions)
        xor a
        ld b, 0
        corelib(showMessage)
    pop bc
    pop de
    or a ; cp 0
    kjp(z, freeAndLoopBack)
    ; DELETE IT
    ; Load it onto currentPath for a moment
    ld a, d
    sub b
    add a, a
    kld(hl, (fileList))
    add l
    ld l, a
    jr nc, $+3
    inc h
    ld e, (hl)
    inc hl
    ld d, (hl)
    kld(hl, (currentPath))
    xor a
    ld bc, 0
    cpir
    dec hl
    ex de, hl
    pcall(stringLength)
    inc bc
    ldir
    kld(de, (currentPath))
    pcall(deleteFile)
    ex de, hl
    pcall(stringLength)
    add hl, bc
    ld a, '/'
    cpdr
    inc hl
    xor a
    ld (hl), a
    jr freeAndLoopBack
.deleteDirectory:
    ; TODO: delete directories
    kjp(freeAndLoopBack)
.exit:
        pop bc
    pop bc
    ret
.handleParent:
        pop bc
    pop bc
.handleParent_noPop:
    kld(hl, (currentPath))
    push hl \ pop de
    pcall(stringLength)
    add hl, bc
    ld a, '/'
    ld bc, 0
    cpdr \ cpdr
    inc hl \ inc hl
    pcall(cpHLDE)
    jr nz, _
    inc hl
_:  xor a
    ld (hl), a
    ;jr freeAndLoopBack

freeAndLoopBack:
    xor a
    kld((scrollTop), a)
    kld((scrollOffset), a)

    kld(a, (totalDirectories))
    or a
    jr z, +_
    ld b, a
    kld(hl, (directoryList))
.freeDirs:
    ld e, (hl)
    inc hl
    ld d, (hl)
    inc hl
    push de \ pop ix
    ld a, (ix)
    cp '.'
    pcall(nz, free)
    djnz .freeDirs
_:  kld(a, (totalFiles))
    or a
    kjp(z, doListing)
    ld b, a
    kld(hl, (fileList))
.freeFiles:
    ld e, (hl)
    inc hl
    ld d, (hl)
    inc hl
    push de \ pop ix
    pcall(free)
    djnz .freeFiles
    kjp(doListing)

openFile:
    sub b
    add a, a
    kld(hl, (fileList))
    add l
    ld l, a
    jr nc, $+3
    inc h
    ld e, (hl)
    inc hl
    ld d, (hl)
    ; Copy DE into the current path, but not for long
    kld(hl, (currentPath))
    xor a
    ld bc, 0
    cpir
    dec hl
    push hl
        ex de, hl
        pcall(stringLength)
        inc bc
        ldir
        kld(de, (currentPath))
        corelib(open)
    pop hl
    jr nz, .fail
    ; TODO: Something?
    pcall(killCurrentThread)
.fail:
    ; It failed to open, complain to the user
    kld(hl, openFailMessage)
    kld(de, openFailOptions)
    xor a
    ld b, 0
    corelib(showMessage)
    kjp(freeAndLoopBack)

; AHL: File size
; E: Y pos
drawFileSize:
    ; TODO: Files >65535 bytes
    ld d, 96 - 11
    push bc
        ld b, 0
_:      ld c, 10
        pcall(divHLbyC)
        add a, '0'
        pcall(drawChar)
        ld a, -8
        add a, d
        ld d, a
        ld c, 0
        pcall(cpHLBC)
        jr nz, -_
    pop bc
    ret

listCallback:
    push hl
    exx
    pop hl
        push bc
            cp fsFile
            jr z, _

            ; Handle directory
            ld hl, kernelGarbage
            pcall(stringLength)
            inc bc ; Include delimiter
            pcall(malloc) ; TODO: Handle out of memory (how?)
            push ix \ pop de
            ldir

            kld(hl, (directoryList))
            push ix \ pop de
            ld (hl), e
            inc hl
            ld (hl), d
            inc hl
            kld((directoryList), hl)
        pop bc
        inc b
    exx
    ret
_:          ; Handle file
            push hl
                ld hl, kernelGarbage
                pcall(stringLength)
                ld a, 4
                add c \ ld c, a \ jr nc, $+3 \ inc b ; Add delimter, file size
                pcall(malloc) ; TODO: Handle out of memory (how?)
                push ix \ pop de
                dec bc \ dec bc \ dec bc
                ldir
            pop hl
            ; File size
            ld bc, -6
            or a
            adc hl, bc
            ld a, (hl)
            ld (de), a
            dec hl \ inc de
            ld a, (hl)
            ld (de), a
            dec hl \ inc de
            ld a, (hl)
            ld (de), a

            kld(hl, (fileList))
            push ix \ pop de
            ld (hl), e
            inc hl
            ld (hl), d
            inc hl
            kld((fileList), hl)
        pop bc
        inc c
    exx
    ret

currentPath:
    .dw 0
fileList:
    .dw 0
directoryList:
    .dw 0
totalFiles:
    .db 0
totalDirectories:
    .db 0
scrollOffset:
    .db 0
scrollTop:
    .db 0

corelibPath:
    .db "/lib/core", 0
upText:
    .db "..\n", 0
dotdot:
    .db "..", 0
titlePrefix:
    .db "File Manager: "
initialPath:
    .db "/home/", 0
titlePrefixEnd:
directoryIcon:
    .db 0b11100000
    .db 0b10011000
    .db 0b11101000
    .db 0b10001000
    .db 0b11111000
    .db 0
fileIcon:
    .db 0b01111000
    .db 0b10001000
    .db 0b10001000
    .db 0b10001000
    .db 0b11111000
    .db 0
downCaretIcon:
    .db 0b11111000
    .db 0b01110000
    .db 0b00100000
upCaretIcon:
    .db 0b00100000
    .db 0b01110000
    .db 0b11111000
deletionMessage:
    .db "Are you sure\nyou want to\ndelete this?", 0
deletionOptions:
    .db 2
    .db "Cancel", 0
    .db "Delete", 0
openFailMessage:
    .db "Sorry, this\nfile could not\nbe opened.", 0
openFailOptions:
    .db 1
    .db "Dismiss", 0
