.model tiny							
.code
org 100h

Start:  mov ax, 0B800h  ; initializing video memory segment register
	mov es, ax

	xor bx, bx
	mov bx, 160 * 5 + 80  ; init video segment shift
		
	mov dh, 24h ; $ ASCII const

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

printFrame PROC
	mov ax, cx
	add ax, 2

	mov di, 1
	frameCycleStart:

	mov byte ptr es:[bx], 04h
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
	mov byte ptr es:[bx], 04h
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
	mov byte ptr es:[bx], 04h
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