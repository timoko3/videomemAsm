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
; makes frame animation
; Entry: dh = ensStr symbol
; Exit:  nop
; Exp:   nop
; Destr: ax, bx, cx, dx, di, si
;-----------------------------------------------------------------------

animationMode PROC
	call initAnimation

	call calcStartStep

	; mov cx, di
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

;-----------------------------------------------------------------------
; puts appropriate parameters in mem and counts amount of frames to start animation  
; Entry: no
; Exit:  si = start addr of text in mem
; 		 di = amount of text lines
;		 cx = max text line length
;		 dl = amount of animation frames
; Exp:   no
; Destr: si, dl, di, ax,cx
;-----------------------------------------------------------------------

initAnimation PROC
    mov si, TEXT_START_ADDR
    call countLineMaxLen
    mov di, ax
    call getAnimationIterationsCount
    mov dl, al
    ret
initAnimation ENDP

;-----------------------------------------------------------------------
; calculates start step of animation
; Entry: no
; Exit:  dh = start step of animation
; Exp:   no
; Destr: dh
;-----------------------------------------------------------------------

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

;-----------------------------------------------------------------------
; draws frame in animation
; Entry: dh = current frame index 
; Exit:  no
; Exp:   nop
; Destr: ax, bx, si, di 
;-----------------------------------------------------------------------

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

;-----------------------------------------------------------------------
; draws animation frame line 
; Entry: nop
; Exit:  dl = symbol if basicMode chosen
; Exp:   nop
; Destr: ax, bx, si, di 
;-----------------------------------------------------------------------

animationDrawFrameLines PROC
	; init cycle
	mov ax, 4d + 1d
	add ax, di 
	mov ah,1
	lineLoop:
		cmp ah, al
		jge done
		
		
		push bx
		mov bl, 3d 
		cmp ah, bl
		pop bx

		jne notTextStr2
			cmp dh, dl
			jl notTextStr2

			call animationSpecialTextCase
			
		notTextStr2:

		call animationDrawSingleLine

		inc ah
		jmp lineLoop
	done:
		ret
animationDrawFrameLines ENDP

;-----------------------------------------------------------------------
; draws end of frame line
; Entry: di = amount of text lines to print
;		 al = last str 
; Exit:  no
; Exp:   nop
; Destr: ah, si, di, bx
;-----------------------------------------------------------------------

animationSpecialTextCase PROC
	mov si , TEXT_START_ADDR
	??textPrintCycle:
	cmp di , 0d
	jle ??printedStr
		push ax 
		push dx
		push di
		mov di, si

		call startFrameLine

		call animationDrawText

		call endFrameLine

		mov si, di
		pop di

		pop dx
		call moveBaseToNextLineStartPos
		push dx
		

		dec di

		pop dx
		pop ax 
		inc ah
	jmp ??textPrintCycle
	
	??printedStr:

	ret
animationSpecialTextCase ENDP

;-----------------------------------------------------------------------
; draws not textLine 
; Entry: bx = video mem pointer
;		 si = pointer for symbol to print with 
; Exit:  no
; Exp:   nop
; Destr: bx
;-----------------------------------------------------------------------

animationDrawSingleLine PROC
	push ax
	push dx

	call startFrameLine

	mov dl, [si]
	add si, 1d

	xor ax, ax
	mov al, dh
	sub al, 2d
	
	push di
	call printFrame
	pop di

	call endFrameLine

	pop dx

	call moveBaseToNextLineStartPos

	pop ax 
	ret
animationDrawSingleLine ENDP

;-----------------------------------------------------------------------
; puts drawing pointer to the start of the next line
; Entry: dh = current frame Index
;		 al = last str 
; Exit:  no
; Exp:   nop
; Destr: ax, dx, bx
;-----------------------------------------------------------------------

moveBaseToNextLineStartPos PROC
			
	xor ax, ax
	mov al, dh
	shl ax, 1        ; ax = dh * 2
	sub bx, ax

	add bx, 160	; move to next line	

	ret
moveBaseToNextLineStartPos ENDP

;-----------------------------------------------------------------------
; draws start of frame line
; Entry: ah = current str to print
;		 al = last str 
; Exit:  no
; Exp:   nop
; Destr: si, dl
;-----------------------------------------------------------------------

startFrameLine PROC
	call findSymForStr

	mov dl, [si]
	add si, 1d
	call outSymbol

	ret
startFrameLine ENDP

;-----------------------------------------------------------------------
; draws end of frame line
; Entry: si = addr of symbol to draw with
; Exit:  no
; Exp:   no
; Destr: dl, bx
;-----------------------------------------------------------------------

endFrameLine PROC
	mov dl, [si]
	call outSymbol

	ret
endFrameLine ENDP

;-----------------------------------------------------------------------
; Animation string with text handle
; Entry: si = symbol to print addr
;		 cx = len text space in line
; 		 di = addr text in memory
; Exit:  nop
; Exp:   zf = 0 means length str is even
;		 zf = 1 means length str is odd
; Destr: dl, si, bx, ah, di, cx
;-----------------------------------------------------------------------

animationDrawText PROC
	mov dl, [si]
	call outSymbol
	call outSymbol
	add si, 1d

	mov dh, '$'

	push cx

	push si
	mov  si, di

	call printText
	add si, 1d  ;skip # symbol
	mov di, si

	pop si

	??beginFillFreeSpace:
	cmp cx, 0d
	jle ??endedFillFreeSpace
		call outSymbol
		dec cx
	jmp ??beginFillFreeSpace
	??endedFillFreeSpace:

	call outSymbol
	call outSymbol
	
	pop cx

	ret
animationDrawText ENDP

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
; Exit:  cx = amountNotFilledSpace 
; Exp:   dh = ensStr symbol ASCII code
;		 
; Destr: ah, si, bx, cx
;-----------------------------------------------------------------------

printText PROC

	; text to videomem 
	cycleStart:																																													
	mov ah, [si]

	cmp ah, dh 
	je endStr
		cmp ah, NEW_LINE_SYMB
		je endStr				
			mov byte ptr es:[bx], ah
			mov byte ptr es:[bx+1], TEXT_COLOR

			inc si
			add bx, 2

			dec cx
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