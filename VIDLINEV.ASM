.model tiny
.code
org 100h

Start:	mov ax, 0B800h
	mov es, ax
	
	xor bx, bx
	mov bx, 160 * 5 + 80
	
	;counter initialization
	xor cx, cx
	mov cx, 24
	
	drawVerticalLine:

	mov byte ptr es:[bx], 03h
	mov byte ptr es:[bx+1], 04h
	
	add bx, 160	
	loop drawVerticalLine	

	mov ax, 4C00h
	int 21h

end Start