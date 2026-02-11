.model tiny							
.code
.286
org 100h

Start:  mov ax, 0B800h  ; initializing video memory segment register
	mov es, ax

	xor bx, bx
	mov bx, 160 * 5 + 80  ; init video segment shift
		
	mov dh, 24h ; $ ASCII const
	
	; read mode from cmd and put in dl symbol for frame

	call getMode

	cmp dl, 0 + '0'
	jne notComplicatedMode
		call complicatedMode
		jmp endProgram
	notComplicatedMode:

	call basicMode
	
	; end programm interrupt
	endProgram:
	mov ax, 4C00h
	int 21h	

getMode	PROC
	mov si, 80h   ; write in si cmd len addr

	mov dl, [si]  ; write in dl temporary cmd length
	
	cmp dl, 0
	jne skipNoMode	 ; handle the no mode case 
		wrongMode:   ; jump here if number don't match appropriate
		mov dl, 04h
		ret
	skipNoMode:
	
	; get mode number

	mov si, 82h
	mov dl, [si]

	; handle mode number

	cmp dl, 0 + '0'
	jne notZeroMode
		ret
	notZeroMode:

	cmp dl, 1 + '0'
	jne notFirstMode
		mov dl, 03h

		ret
	notFirstMode:
	
	cmp dl, 2 + '0'
	jne wrongMode 
		mov dl, 05h

		ret

getMode ENDP

basicMode PROC
	mov si, 84h     ; string to print addr -> si
	
	call strlen   ; count string length procedure
	

	mov ax, cx
	add ax, 2
	call printFrame
	call videoMemPointerMoveBack
	
	add bx, 160	; move to next line

		
	call outSymbol		; part of frame
	call printText
	call outSymbol 		; part of frame
	call videoMemPointerMoveBack
	
	add bx, 160	; move to next line	

	mov ax, cx
	add ax, 2
	call printFrame
	call videoMemPointerMoveBack

	ret
basicMode ENDP

complicatedMode PROC
	mov si, 84h + 10 ; get strlen
	call strlen

	mov si, 84h

	; init cycle
	mov al, 6
	mov ah, 1

	startComplicatedFrameCycle:
	cmp ah, al
	jge endComplicatedFrameCycle
		push ax
		call findSymForStr

		mov dl, [si]

		call printStrPreamble

		cmp ah, 3
		jne notTextStr
			push si
			mov si, 84h + 10

			call printText

			pop si
			jmp printedStr
		notTextStr:

		mov ax, cx
		call printFrame

		printedStr:

		call printStrPostamble

		call videoMemPointerMoveBack
		add bx, 160	; move to next line	

		pop ax
		inc ah
	jmp startComplicatedFrameCycle
	endComplicatedFrameCycle:

	ret
complicatedMode ENDP

printStrPreamble PROC
	call outSymbol

	inc si
	mov dl, [si]
	call outSymbol
	call outSymbol

	ret
printStrPreamble ENDP

printStrPostamble PROC
	call outSymbol
	call outSymbol

	inc si
	mov dl, [si]
	call outSymbol

	ret
printStrPostamble ENDP

findSymForStr PROC
	cmp ah, 1
	jne notFirst
		mov si, 84h
		ret

	notFirst:
	cmp ah, 5
	jne notSixth
		mov si, 84h + 6
		ret
	notSixth:

	mov si, 84h + 3

	ret
findSymForStr ENDP

printFrame PROC

	mov di, 1
	frameCycleStart:

	mov byte ptr es:[bx], dl
	mov byte ptr es:[bx + 1], 03h

	cmp di, ax
	je endFrameCycle

	inc di
	add bx, 2

	jmp frameCycleStart

	endFrameCycle:

	add bx, 2

	ret
printFrame ENDP

printText PROC

	; text to videomem 
	cycleStart:																																													
	mov ah, [si]

	cmp ah, dh 
	je endStr			
	mov byte ptr es:[bx], ah
	mov byte ptr es:[bx+1], 15h

	inc si
	add bx, 2

	jmp cycleStart

	endStr:

	ret
printText ENDP

strlen PROC
	mov di, si
	xor cx, cx
	
	
	strlenCycle:
	mov ah, [di]

	cmp ah, dh
	je strlenEnd
	inc di

	inc cx    ; increment symbols counter
	jmp strlenCycle
	strlenEnd:
	ret
strlen ENDP

outSymbol PROC
	mov byte ptr es:[bx], dl
	mov byte ptr es:[bx + 1], 03h
	add bx, 2

	ret
outSymbol ENDP

videoMemPointerMoveBack PROC
	mov ax, cx 
	add ax, 6
	add ax, ax

	sub bx, ax

	ret
videoMemPointerMoveBack ENDP
		
String	db 'Hello$'

end Start