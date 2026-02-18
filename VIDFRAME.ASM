.model tiny							
.code
.286
org 100h

COLOR 		  		EQU 0dh
TEXT_COLOR	  		EQU 5Eh

NO_MODE_SYMB  		EQU 04h
MODE_ONE_SYMB 		EQU 03h
MODE_TWO_SYMB 		EQU 05h

NEW_LINE_SYMB 		EQU '#'
END_STR_INPUT_SYMB	EQU '$'

Start:  mov ax, 0B800h  ; initializing video memory segment register
	mov es, ax

	xor bx, bx
	mov bx, 160d * 5d + 80d; init video segment shift  
		
	mov dh, 24h ; $ ASCII endStrSym 

	; read mode from cmd and put in dl symbol for frame

	call chooseMode
	
	; end programm interrupt
	endProgram:
	mov ax, 4C00h
	int 21h	

;-----------------------------------------------------------------------
; Analyzes cmd line and calls mode chosen in cmd
; Entry: nop
; Exit:  dl = symbol if basicMode chosen
; Exp:   nop
; Destr: si, dl
;-----------------------------------------------------------------------

chooseMode	PROC
	mov si, 80h   ; write in si cmd len addr

	mov dl, [si]  ; write in dl temporary cmd length
	
	cmp dl, 0
	jne skipNoMode	 ; handle the no mode case 
		wrongMode:   ; jump here if number don't match appropriate
		mov dl, NO_MODE_SYMB
		ret
	skipNoMode:
	
	; get mode number

	mov si, 82h
	mov dl, [si]

	; handle mode number

	cmp dl, 0 + '0'
	jne notZeroMode
		call complicatedMode
		ret
	notZeroMode:

	cmp dl, 1 + '0'
	jne notFirstMode
		mov dl, MODE_ONE_SYMB
		call basicMode
		ret
	notFirstMode:
	
	cmp dl, 2 + '0'
	jne notSecondMode 
		mov dl, MODE_TWO_SYMB
		call basicMode
		ret
	notSecondMode:

	cmp dl, 3 + '0'
	jne wrongMode
		call animationMode
		ret

chooseMode ENDP

;-----------------------------------------------------------------------
; Drawing basic version of frame just around string with the symbol with code in dl
; Entry: dl = symbol of frame
; Exit:  nop 
; Exp:   nop
; Destr: ax, bx, cx, si, di
;-----------------------------------------------------------------------

basicMode PROC
	mov si, 84h     ; string to print addr -> si
	
	call strlen   ; count string length procedure

	mov ax, cx
	add ax, 2
	add ax, ax
	call alignFrame
	
	mov ax, cx
	add ax, 2
	call printFrame

	mov di, 2
	call videoMemPointerMoveBack
	
	add bx, 160	; move to next line

	call outSymbol		; part of frame
	call printText
	call outSymbol 		; part of frame

	mov di, 2
	call videoMemPointerMoveBack
	
	add bx, 160	; move to next line	

	mov ax, cx
	add ax, 2
	call printFrame

	mov di, 2
	call videoMemPointerMoveBack

	ret
basicMode ENDP

;-----------------------------------------------------------------------
; Drawing complicated version of frame with additional parameter in cmd line
; Entry: si = pointer to next symbol to print
; Exit:  nop
; Exp:   nop
; Destr: si, ax, cx, dl, bx
;-----------------------------------------------------------------------

TEXT_START_ADDR EQU 	 84h + 10
FRAME_SYM_START_ADDR EQU 84h

complicatedMode PROC
	mov si, TEXT_START_ADDR ; get strlen
	call strlen

	mov si, FRAME_SYM_START_ADDR

	; put align num in ax
	mov ax, cx
	add ax, 6
	add ax, ax
	call alignFrame

	; init cycle
	mov al, 6
	mov ah, 1

	startComplicatedFrameCycle:
	cmp ah, al
	jge endComplicatedFrameCycle
		push ax
		call findSymForStr

		mov dl, [si]

		call printCompModeStrPreamble

		cmp ah, 3
		jne notTextStr
			push si
			mov si, TEXT_START_ADDR

			call printText

			pop si
			jmp printedStr
		notTextStr:
		
		mov ax, cx
		call printFrame

		printedStr:

		call printCompModeStrPostamble

		mov di, 6
		call videoMemPointerMoveBack
		add bx, 160	; move to next line	

		pop ax
		inc ah
	jmp startComplicatedFrameCycle
	endComplicatedFrameCycle:

	ret
complicatedMode ENDP

;-----------------------------------------------------------------------
; Drawing complicated version of frame with additional parameter in cmd line
; Entry: dh = ensStr symbol
; Exit:  nop
; Exp:   nop
; Destr: ax, bx, cx, dx, di, si
;-----------------------------------------------------------------------

animationMode PROC
	call initAnimation

	call calcStartStep

	mov cx, di
	StartAnimationCycle:
	cmp dh, al
	jg endAnimationCycle
		push ax

		mov si, FRAME_SYM_START_ADDR

		xor bx, bx
	    mov bx, 160 * 5 + 80; init video segment shift  

		call animationDrawFrame

		add dh, 2

		pop ax
	jmp StartAnimationCycle
	endAnimationCycle:

	ret
animationMode ENDP

initAnimation PROC
    mov si, TEXT_START_ADDR
    call countLineMaxLen
    mov di, ax
    call getAnimationIterationsCount
    mov dl, al
    ret
initAnimation ENDP

calcStartStep PROC
	xor dh, dh
	
	test cx, 1			
	jz ??not_odd
		add dh, 3d
		jmp ??is_odd
	??not_odd:
	add dh, 2d
	??is_odd:
	ret
calcStartStep ENDP

animationDrawFrame PROC
	; put align num in ax
	xor ax, ax
	mov al, dh
	add al, al
	call alignFrame

	call animationDrawFrameLines

	push cx
	mov cx, 65000d
	call delayForAnimation
	pop cx

	ret
animationDrawFrame ENDP

animationDrawFrameLines PROC
	; init cycle
	mov ax, 5d
	add ax, cx
	mov ah,1
	lineLoop:
		cmp ah, al
		jge done

		call animationDrawSingleLine

		inc ah
		jmp lineLoop
	done:
		ret
animationDrawFrameLines ENDP

animationDrawSingleLine PROC
	push ax
	push dx
	call findSymForStr

	mov dl, [si]
	add si, 1d
	call outSymbol

	; special text case
	cmp ah, 3d
	jne notTextStr2
		pop dx
		cmp dh, dl
		push dx
		jl notTextStr2
		

		call animationTextStrCase

		jmp printedStr2
	notTextStr2:

	mov dl, [si]
	add si, 1d

	xor ax, ax
	mov al, dh
	sub al, 2d
	
	call printFrame

	printedStr2:

	mov dl, [si]

	call outSymbol

	pop dx
	pop ax 
	ret
animationDrawSingleLine ENDP

moveBaseToNextLineStartPos PROC
			
	xor ax, ax
	mov al, dh
	shl ax, 1        ; ax = dh * 2
	sub bx, ax

	add bx, 160	; move to next line	

	ret
moveBaseToNextLineStartPos ENDP

;-----------------------------------------------------------------------
; Animation string with text handle
; Entry: si = symbol to print addr
;		 cx = len line
; Exit:  nop
; Exp:   zf = 0 means length str is even
;		 zf = 1 means length str is odd
; Destr: dl, si, bx, ah
;-----------------------------------------------------------------------

animationTextStrCase PROC
	mov dl, [si]
	call outSymbol
	call outSymbol
	add si, 1d

	mov dh, '$'

	push si
	mov  si, TEXT_START_ADDR

	call printText
	mov di, si

	pop si

	call outSymbol
	call outSymbol
	
	ret
animationTextStrCase ENDP

;-----------------------------------------------------------------------
; finds amount of animation iterations
; Entry: cx = final frame size
; Exit:  al = amount of animation iterations
; Exp:   nop
; Destr: al
;-----------------------------------------------------------------------

getAnimationIterationsCount PROC
	xor ax, ax
	mov al, cl

	add al, 6d

	ret
getAnimationIterationsCount ENDP

;-----------------------------------------------------------------------
; makes preamble for string with text in complicatedMode
; Entry: si = pointer to next symbol to print
; Exit:  nop
; Exp:   nop
; Destr: dl, bx
;-----------------------------------------------------------------------

printCompModeStrPreamble PROC
	call outSymbol

	inc si
	mov dl, [si]
	call outSymbol
	call outSymbol

	ret
printCompModeStrPreamble ENDP

;-----------------------------------------------------------------------
; makes postamble for string with text in complicatedMode
; Entry: si = pointer to next symbol to print
; Exit:  nop
; Exp:   nop
; Destr: dl, bx
;-----------------------------------------------------------------------

printCompModeStrPostamble PROC
	call outSymbol
	call outSymbol

	inc si
	mov dl, [si]
	call outSymbol

	ret
printCompModeStrPostamble ENDP

;-----------------------------------------------------------------------
; pareses current needed symbols of frame from cmd line
; Entry: ah = current str to print
;		 al = last str 
; Exit:  si = pointer to the needed symbol in cmd line
; Exp:   nop
; Destr: si
;-----------------------------------------------------------------------

findSymForStr PROC
	cmp ah, 1
	jne notFirst
		mov si, 84h
		ret

	notFirst:
	sub al, 1
	cmp ah, al
	
	jne notLast
		mov si, 84h + 6
		jmp ??end
	notLast:

	mov si, 84h + 3

	??end:
	add al, 1
	ret
findSymForStr ENDP

;-----------------------------------------------------------------------
; puts string of symbol to videoMem
; Entry: dl = symbol to print with
;		 dh = color code
;		 ax = amount symbols to print
; Exit:  nop 
; Exp:   nop 
; Destr: di, bx 
;-----------------------------------------------------------------------

printFrame PROC

	mov di, 0
	frameCycleStart:
	cmp di, ax
	jge endFrameCycle

	mov byte ptr es:[bx], dl
	mov byte ptr es:[bx + 1], COLOR

	inc di
	add bx, 2

	jmp frameCycleStart

	endFrameCycle:

	ret
printFrame ENDP

;-----------------------------------------------------------------------
; puts string to videoMem
; Entry: Entry: si = pointer to the begin of str
; Exit:  nop 
; Exp:   dh = ensStr symbol ASCII code
;		 
; Destr: ah, si, bx 
;-----------------------------------------------------------------------

printText PROC

	; text to videomem 
	cycleStart:																																													
	mov ah, [si]

	cmp ah, dh 
	je endStr
		cmp ah, NEW_LINE_SYMB
		je endStr:				
			mov byte ptr es:[bx], ah
			mov byte ptr es:[bx+1], TEXT_COLOR

			inc si
			add bx, 2

	jmp cycleStart

	endStr:

	ret
printText ENDP

;-----------------------------------------------------------------------
; counts max line len
; Entry: si = pointer to the begin of str
; Exit:  cx = max length line
;		 al = amount lines 		
; Exp:   dh = ensStr symbol ASCII code
; Destr: ax, cx, di, si
;-----------------------------------------------------------------------

countLineMaxLen PROC
	push bx 
	push dx
	xor bx, bx

	mov dh, NEW_LINE_SYMB
	??cycleStart:

	call strlen
	mov si, di

	cmp bx, cx
	jg ??notGreaterLine
		mov bx, cx
	??notGreaterLine:

	inc al 

	mov dl, [si]
	cmp dl, END_STR_INPUT_SYMB
	je ??cycleEnd

	inc si
	jmp ??cycleStart
	
	??cycleEnd:

	xor ah, ah
	mov cx, bx

	pop dx
	pop bx
	ret
countLineMaxLen ENDP

;-----------------------------------------------------------------------
; counts amount of symbols in str with endStr symbol '$'
; Entry: si = pointer to the begin of str
; Exit:  cx = length str
; Exp:   dh = ensStr symbol ASCII code
; Destr: ah, cx, di
;-----------------------------------------------------------------------

strlen PROC
	mov di, si
	xor cx, cx
	
	strlenCycle:
	mov ah, [di]

	cmp ah, dh
	je strlenEnd
	cmp ah, END_STR_INPUT_SYMB
	je strlenEnd
	inc di

	inc cx    ; increment symbols counter
	jmp strlenCycle
	strlenEnd:
	ret
strlen ENDP

;-----------------------------------------------------------------------
; puts symbol in video memory and moves to next cell for symbol
; Entry: dl 	 = symbol of frame
;		 es:[bx] = addr where to put symbol 
; Exit:  nop 
; Exp:   es:[bx] = point to appropriate memCell
; Destr: bx
;-----------------------------------------------------------------------

outSymbol PROC
	mov byte ptr es:[bx], dl
	mov byte ptr es:[bx + 1], COLOR
	add bx, 2

	ret
outSymbol ENDP

;-----------------------------------------------------------------------
; returns bx to the start position
; Entry: di = amount of extra symbols except from text symbols
; Exit:  nop
; Exp:   nop
; Destr: ax, bx
;-----------------------------------------------------------------------

videoMemPointerMoveBack PROC
	mov ax, cx 
	add ax, di
	add ax, ax

	sub bx, ax

	ret
videoMemPointerMoveBack ENDP

;-----------------------------------------------------------------------
; Alining frame for it to be in the center of screen
; Entry: ax = width of frame in symbols
; Exit:  bx = points at the left side of frame
; Exp:   bx = points in the center of some string
; Destr: ax, bx
;-----------------------------------------------------------------------

alignFrame PROC
	cmp ax, 2d
	jne notTwoCase
		sub bx, ax
		ret
	notTwoCase:
	shr ax, 2
	shl ax, 1
	sub bx, ax
	ret
alignFrame ENDP

;-----------------------------------------------------------------------
; Making delay for correct displaying of the animation
; Entry: cx = amount of tacts to skip
; Exit:  nop
; Exp:   nop
; Destr: cx
;-----------------------------------------------------------------------

delayForAnimation PROC
	delay:
		nop
		loop delay
	ret
delayForAnimation ENDP

end Start