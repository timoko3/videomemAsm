.model tiny
.code
org 100h

Start:  mov ax, 0b800h
	mov es, ax

	xor bx, bx
	mov bx, 160 * 5 + 80

	mov byte ptr es:[bx],   03h
	mov byte ptr es:[bx+1], 04h 
	
	mov ax, 4C00h
	int 21h

end Start