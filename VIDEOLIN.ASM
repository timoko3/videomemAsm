.model tiny
.code
org 100h

Start:	mov ax, 0B800h
	mov es, ax
	
	xor bx, bx
	mov bx, 160 * 5	

	; init loop

	xor cx, cx
	mov cx, 80

	lineOut:
	mov byte ptr es:[bx], 03h
	
	mov byte ptr es:[bx+1], 04h
	inc bx
	inc bx
		
	loop lineOut

	mov ax, 4C00h
	int 21h

end Start