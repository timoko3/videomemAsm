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

	mov si, offset String     ; string to print addr -> si
	
	call strlen   ; count string length procedure
	
	call printFrame
	
	add bx, 160	; move to next line

	call printText
	
	add bx, 160	; move to next line	

	call printFrame
	
	; end programm interrupt
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

printFrame PROC
	mov ax, cx
	add ax, 2

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
	
	; return bx start value
	sub ax, 1
	add ax, ax 
	sub bx, ax

	ret
printFrame ENDP

printText PROC
	; part of frame
	mov byte ptr es:[bx], dl
	mov byte ptr es:[bx+1], 03h
	add bx, 2

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

	; part of frame
	mov byte ptr es:[bx], dl
	mov byte ptr es:[bx+1], 03h
	add bx, 2

	; return bx start value
	mov ax, cx
	add ax, 2
	add ax, ax
	sub bx, ax

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
		
String	db 'Hello$'

end Start