.8086
.model small
.stack 1024
.data
bmp0 dd	00000000000000000000000000000000b,	;bit map 0
		00000000000000000000000000000000b,
		00000000000000000000000000000000b,
		00000000000000000000000000000000b,
		00010000000000000000000000000000b,
		00010000000000000000000000000000b,
		00010000000000000000000000001000b,
		00011110000000000000000000111100b,
		00000011110000000000000111001000b,
		00000000111000000000001100000000b
m0	dd	00000000011111111111111100000000b,
		00000000000111111111111100000000b,
		00000000000111111111110010000000b,
		00000000000111111111110011000000b,
		00000000001111111111111111000000b,
		00000000001111111111111111000000b,
		00000000000111111111110011000000b,
		00000000000111111111110010000000b,
		00000000000111111111111100000000b,
		00000000011111111111111100000000b
m1	dd	00000000111000000000001100000000b,
		00000011110000000000000111001000b,
		00011110000000000000000000111100b,
		00010000000000000000000000001000b,
		00010000000000000000000000000000b,
		00010000000000000000000000000000b,
		00000000000000000000000000000000b,
		00000000000000000000000000000000b,
		00000000000000000000000000000000b, 
		00000000000000000000000000000000b
		
bmp1 dd	00000000000000000000000000000000b,	;bit map 1
		00000000000000000000000000000000b,
		00000000000000000000000000000000b,
		00000000000000000000000000000000b,
		00000000000001000000000000000000b,
		00000000000010000000000000000000b,
		00000000000100000000000010000000b,
		00000000001111110000111111000000b,
		00000000000001100000110010000000b,
		00000000000011000000011000000000b
m2	dd	00000000000111111111111100000000b,
		00000000000111111111111100000000b,
		00000000000111111111110010000000b,
		00000000000111111111110011000000b,
		00000000001111111111111111000000b,
		00000000001111111111111111000000b,
		00000000000111111111110011000000b,
		00000000000111111111110010000000b,
		00000000000111111111111100000000b,
		00000000000111111111111100000000b
m3	dd	00000000000011000000011000000000b,
		00000000000001100000110010000000b,
		00000000001111110000111111000000b,
		00000000000100000000000010000000b,
		00000000000010000000000000000000b,
		00000000000001000000000000000000b,
		00000000000000000000000000000000b,
		00000000000000000000000000000000b,
		00000000000000000000000000000000b,
		00000000000000000000000000000000b

pregrid		dw	3 dup(0000h)
grid 		dw	14 dup(0000h)
acp			db	00h						;active page
hdp			db	01h						;hidden page
setup		db	1
rfrg		dw	5						;frog row
cfrg		dw	0						;frog column
rtmp		dw	?						;for passing accurate coordinates
ctmp		dw	?
status		db	"FROG CROSSING STREET     E=EXIT    TIME:      LEVEL:      SCORE:      BEST:$"
time		dw	0
time_txt	db	"     $"
level		dw	0
level_txt	db	"     $"
score		dw	0
score_txt	db	"     $"
best		dw	0
best_txt	db	"     $"
car0		dw	0
car1		dw	0
car2		dw	0
car3		dw	0
car4		dw	0
nh0			db	"NEW HIGH SCORE!  PLAY AGAIN?$"
nh1			db	"E=EXIT, PRESS ANY OTHER KEY TO RESUME.$"
gg0			db	"GOOD GAME.  PLAY AGAIN?$"
gg1			db	"E=EXIT, PRESS ANY OTHER KEY TO RESUME.$"
.code
;----------------------
DELAY		proc near stdcall t:word		;delay about 0.5t seconds
	mov		cx,0000h	;big loop 65536 times
DELAY0:
	mov		ax,1000h
	mov		bx,t
	mul		bx
	mov		dx,ax		;small loop 4096*t times
DELAY1:					;small loop
	dec		dx
	cmp		dx,0
	ja		DELAY1		;end of small loop
	loop	DELAY0		;big loop
	ret
DELAY		endp
;----------------------
SET_MODE	macro	mode				;set mode
	mov		ah,00h
	mov		al,mode
	int		10h
	endm
;----------------------
SET_PAGE	macro	pge					;set page
	mov		ah,05h
	mov		al,pge
	int		10h
	endm
;----------------------
SET_COLOR	macro	mode,color			;set color
	mov		ah,0bh
	mov		bh,mode
	mov		bl,color
	int		10h
	endm
;----------------------
WAIT_KEY	macro						;wait for keystroke
	mov		ah,00h
	int		16h
	endm
;----------------------
GET_KEY		macro						;get keystroke
	local	KEY_END
	mov		ah,01h		;read status
	int		16h
	pushf				;save flags
	push	ax			;save key
	mov		ah,06h		;clear buffer
	mov		dl,0ffh
	int		21h
	pop		ax			;restore key
	popf				;restore flags
	jnz		GETKEY_END	;if(no_key)return 0000h
	mov		ax,0000h
GETKEY_END:
	endm
;----------------------
CLR_KEY_BUF	proc near					;clear keyboard buffer
	mov		cx,100
CLR_KEY_BUF_LOOP:
	mov		ah,06h		;clear buffer
	mov		dl,0ffh
	int		21h
	loop	CLR_KEY_BUF_LOOP
	ret
CLR_KEY_BUF	endp
;----------------------
ASCII		proc near stdcall hex:word,txt:word	;convert hexadecimal into ASCII
	mov		ax,hex			;hexadecimal number(maximum 65535)
	mov		bx,10
	mov		cx,0
ASCII_NEXT:
	mov		dx,0
	div		bx				;dx=remainder;
	inc		cx
	add		dx,30h			;convert to ascii
	push	dx				;save ascii
	cmp		ax,0			;if(quotient=0)end conversion;
	ja		ASCII_NEXT
	
	mov		di,txt
	mov		dx,0			;character index
ASCII_STORE:
	pop		ax				;restore ascii
	mov		[di],al			;store ascii
	inc 	di
	inc		dx
	loop	ASCII_STORE
	
	mov		al,' '
ASCII_SPACE:				;fill with spaces
	cmp		dx,5
	je		ASCII_END
	mov		[di],al
	inc		di
	inc		dx
	jmp		ASCII_SPACE
ASCII_END:
	ret
ASCII		endp
;----------------------
PRT_STR		macro	pge,brow,bcol,string,color	;print string(compatible for multiple pages)
	local	STR_STA,STR_END
	mov		si,string
	mov		bp,0000h	;character index
	mov		bh,pge
	mov		bl,color
	mov		cx,1
	mov		dh,brow
	mov		dl,bcol		;column index
STR_STA:
	mov		al,[si+bp]
	cmp		al,'$'		;terminating character
	jz		STR_END
	mov		ah,02h		;set cursor
	int		10h
	mov		ah,09h		;print a character
	int		10h
	inc		bp			;next character
	inc		dl			;move right
	jmp		STR_STA
STR_END:
	endm
;----------------------
CONV		proc near stdcall row:word,col:word	;convert rough coordinate to accurate coordinate
	mov		si,offset rtmp
	mov		di,offset ctmp
	mov		bx,30
	mov		ax,row		;row
	mul		bx
	add		ax,20
	mov		[si],ax		;rtmp=row*30+20
	mov		ax,col		;column
	mul		bx
	mov		[di],ax		;ctmp=col*30
	ret
CONV		endp
;----------------------
BMP30BY30	macro	pge,row,col,color,src		;print bitmap 30 by 30
	local	BMP_NEW_WORD,BMP_ODD,BMP_DRAW_WORD,BMP_DONT_DRAW
	mov		si,src		;source bmp
	mov		bp,0000h	;word index
	mov		dx,row
	dec		dx

BMP_NEW_WORD:
	mov		ax,[si+bp]
	test	bp,0002h
	jnz		BMP_ODD
	mov		bx,16		;even word index
	mov		cx,col
	add		cx,29
	inc		dx
	jmp		BMP_DRAW_WORD
BMP_ODD:				;odd word index
	mov		bx,14

BMP_DRAW_WORD:
	test	ax,0001h
	jz		BMP_DONT_DRAW
	push	ax			;save ax and bx
	push	bx
	mov		al,color	;color
	mov		ah,0ch		;draw point
	mov		bh,pge		;page
	int		10h			;draw
	pop		bx			;restore ax and bx
	pop		ax
BMP_DONT_DRAW:
	shr		ax,1		;next bit
	dec		cx			;move left
	dec		bx			;decrease counter
	cmp		bx,0
	ja		BMP_DRAW_WORD

	add		bp,2		;if bx=30*2*2 then finish drawing
	cmp		bp,120
	jb		BMP_NEW_WORD
	endm
;----------------------
RECT		proc near stdcall pge:byte,row:word,col:word,\	;print rectangle
							rdim:word,cdim:word,color:byte,\
							rmax:word,cmax:word
	mov		bh,pge

	mov		cx,row		;calculate maximum
	add		cx,rdim
	mov		rmax,cx
	mov		cx,col
	add		cx,cdim
	mov		cmax,cx
	mov		cx,col
	
RECT_DRAW_LINE:			;draw line
	mov		dx,row		;set starting point
	cmp		cx,cmax
	jz		RECT_END
RECT_DRAW_POINT:		;draw point
	cmp		dx,rmax
	jz		RECT_NEXT_LINE
	cmp		dx,20		;row lower limit
	jb		RECT_SKIP
	cmp		dx,349		;row upper limit
	ja		RECT_SKIP
	mov		al,color
	mov		ah,0ch
	int		10h
RECT_SKIP:
	inc		dx
	jmp		RECT_DRAW_POINT
RECT_NEXT_LINE:			;next line
	inc		cx
	jmp		RECT_DRAW_LINE
RECT_END:
	ret
RECT		endp
;----------------------
SET_GRID	proc near stdcall row:word,col:word	;mark grids with car present 1
	mov		di,offset grid	;initial di
	mov		bx,row
	shl		bx,1
	add		di,bx
	mov		cx,col			;initial bx
	sub		cx,3
	mov		bx,80h
	ror		bx,cl
	mov		cx,4			;4 rows
SET_GRID_LOOP:
	or		[di],bx
	shr		bx,1
	or		[di],bx
	shl		bx,1
	add		di,2
	loop	SET_GRID_LOOP
	ret
SET_GRID	endp
;----------------------
CLR_GRID	proc near			;clear grids
	mov		di,offset pregrid	;initial di'
	mov		cx,17
CLR_GRID_LOOP:
	mov		word ptr[di],0000h
	add		di,2
	loop	CLR_GRID_LOOP
	ret
CLR_GRID	endp
;----------------------
CLR_SCR		proc near stdcall pge:byte	;clear screen
	mov		dx,0000h					;if(pge=0)es=0a000h;else es=0a800h
	mov		ax,0000h
	mov		al,pge
	mov		bx,0800h
	mul		bx
	add		ax,0a000h
	mov		es,ax
	mov		di,0000h		;word index
	mov		dx,03c4h		;to choose color plane
	mov		al,02h
	out		dx,al
	mov		dx,03c5h		;choose color plane
	mov		al,0fh
	out		dx,al
	mov		cx,(40*350)		;(640/16)*350 words
CLEAR_LOOP:
	mov		word ptr es:[di],0000h
	add		di,2
	loop	CLEAR_LOOP
	ret
CLR_SCR		endp
;----------------------
EXAMINE		proc near			;fetch key and examine
								;dl:0=nothing, 1=level up, 2=exit, 3=gg
	mov		dl,0		;nothing
	cmp		ah,048h		;up
	jne		NU
	cmp		rfrg,0		;up limit
	je		NU
	dec		rfrg
	jmp		KEY_END
NU:
	cmp		ah,04bh		;left
	jne		NL
	cmp		cfrg,0		;left limit
	je		NL
	dec		cfrg
	jmp		KEY_END
NL:
	cmp		ah,04dh		;right
	jne		NR
	cmp		cfrg,20		;right limit
	jne		NO_LEVEL_UP
	mov		dl,1		;level up
	jmp		EXAMINE_END
NO_LEVEL_UP:
	inc		cfrg
	jmp		KEY_END
NR:
	cmp		ah,050h		;down
	jne		ND
	cmp		rfrg,10		;down limit
	je		ND
	inc		rfrg
	jmp		KEY_END
ND:
	cmp		al,'e'		;'e'
	jne		KEY_END
	mov		dl,2		;exit
	jmp		EXAMINE_END
KEY_END:

	cmp		cfrg,3		;detect collision
	jb		EXAMINE_END
	cmp		cfrg,17
	ja		EXAMINE_END
	mov		di,offset grid
	mov		bx,rfrg
	shl		bx,1
	add		di,bx
	mov		cx,cfrg
	sub		cx,3
	mov		bx,80h
	ror		bx,cl
	test	[di],bx
	jz		EXAMINE_END
	mov		dl,3		;gg
EXAMINE_END:
	ret
EXAMINE		endp
;----------------------
PRT_LINE	proc near			;print line
	invoke	RECT,hdp,0,74,350,2,08h,0,0
	invoke	RECT,hdp,0,164,350,2,08h,0,0
	invoke	RECT,hdp,0,254,350,2,08h,0,0
	invoke	RECT,hdp,0,344,350,2,08h,0,0
	invoke	RECT,hdp,0,434,350,2,08h,0,0
	invoke	RECT,hdp,0,524,350,2,08h,0,0
	invoke	RECT,hdp,0,630,350,10,0fh,0,0
	ret
PRT_LINE	endp
;----------------------
PRT_FROG	proc near			;print frog
	invoke	CONV,rfrg,cfrg
	cmp		hdp,01h				;if(hdp=1)print bmp1;else print bmp0;
	je		PRT_FROG1
	BMP30BY30 hdp,rtmp,ctmp,02h,offset bmp0
	jmp		PRT_FROG_END
PRT_FROG1:
	BMP30BY30 hdp,rtmp,ctmp,02h,offset bmp1
PRT_FROG_END:
	ret
PRT_FROG	endp
;----------------------
PRT_CAR_UP	proc near stdcall row:word,col:word,color:byte,light_color:byte	;print car driving up
	mov		al,color			;generate light_color
	add		al,08h
	mov		light_color,al
	invoke	SET_GRID,row,col
	invoke	CONV,row,col
	invoke	RECT,hdp,rtmp,ctmp,120,60,color,0,0
	add		rtmp,40
	add		ctmp,4
	invoke	RECT,hdp,rtmp,ctmp,20,52,00000011b,0,0
	add		rtmp,21
	add		ctmp,-1
	invoke	RECT,hdp,rtmp,ctmp,30,54,light_color,0,0
	add		rtmp,31
	add		ctmp,1
	invoke	RECT,hdp,rtmp,ctmp,10,52,00000011b,0,0
	ret
PRT_CAR_UP	endp
;----------------------
PRT_CAR_DN	proc near stdcall row:word,col:word,color:byte,light_color:byte	;print car driving down
	mov		al,color			;generate light_color
	add		al,08h
	mov		light_color,al											;
	invoke	SET_GRID,row,col
	invoke	CONV,row,col
	invoke	RECT,hdp,rtmp,ctmp,120,60,color,0,0
	add		rtmp,18
	add		ctmp,4
	invoke	RECT,hdp,rtmp,ctmp,10,52,00000011b,0,0
	add		rtmp,11
	add		ctmp,-1
	invoke	RECT,hdp,rtmp,ctmp,30,54,light_color,0,0
	add		rtmp,31
	add		ctmp,1
	invoke	RECT,hdp,rtmp,ctmp,20,52,00000011b,0,0
	ret
PRT_CAR_DN	endp
;----------------------
PRT_STATUS	proc near			;print status bar
	invoke	ASCII,time,offset time_txt
	invoke	ASCII,level,offset level_txt
	invoke	ASCII,score,offset score_txt
	invoke	ASCII,best,offset best_txt
	PRT_STR	hdp,0,0,offset status,07h
	PRT_STR	hdp,0,40,offset time_txt,01h
	PRT_STR	hdp,0,52,offset level_txt,01h
	PRT_STR	hdp,0,64,offset score_txt,01h
	PRT_STR	hdp,0,75,offset best_txt,01h
	ret
PRT_STATUS	endp
;----------------------
LIMIT_DN	proc near stdcall car:word,span:word	;limit range of car
	mov		di,car
	mov		ax,[di]
	add		ax,span
	mov		[di],ax
	cmp		word ptr[di],11
	jb		LIMIT_DN_END
	mov		word ptr[di],0
LIMIT_DN_END:
	ret
LIMIT_DN	endp
;----------------------
LIMIT_UP	proc near stdcall car:word,span:word	;limit range of car
	mov		di,car
	mov		ax,[di]
	sub		ax,span
	mov		[di],ax
	cmp		word ptr[di],8000h
	jb		LIMIT_UP_END
	mov		word ptr[di],10
LIMIT_UP_END:
	ret
LIMIT_UP	endp
;----------------------
GAME		proc near			;controll cars
	cmp		level,1
	je		ROUND1
	cmp		level,2
	je		ROUND2
	cmp		level,3
	je		ROUND3
ROUND1:						;static
	invoke	PRT_CAR_DN,3,3,01h,0
	invoke	PRT_CAR_UP,8,6,02h,0
	invoke	PRT_CAR_DN,-1,12,03h,0
	jmp		GAME_END
ROUND2:						;dynamic
	cmp		setup,0
	jz		R2
	mov		car0,1			;initial position
	mov		car3,2
	mov		car4,3
R2:	
	invoke	LIMIT_DN,offset car0,1
	invoke	LIMIT_UP,offset car3,2
	invoke	LIMIT_DN,offset car4,1
	invoke	PRT_CAR_DN,car0,3,01h,0
	invoke	PRT_CAR_UP,car3,12,02h,0
	invoke	PRT_CAR_DN,car4,15,03h,0
	jmp		GAME_END
ROUND3:
	cmp		setup,0
	jz		R3
	mov		car0,4			;initial position
	mov		car1,5
	mov		car2,6
	mov		car4,7
R3:	
	invoke	LIMIT_DN,offset car0,2
	invoke	LIMIT_DN,offset car1,1
	invoke	LIMIT_UP,offset car2,2
	invoke	LIMIT_DN,offset car4,3
	invoke	PRT_CAR_DN,car0,3,04h,0
	invoke	PRT_CAR_DN,car1,6,05h,0
	invoke	PRT_CAR_UP,car2,9,06h,0
	invoke	PRT_CAR_DN,car4,15,07h,0
	jmp		GAME_END
GAME_END:
	ret
GAME		endp
;----------------------
.startup
	SET_MODE 10h			;graphics mode with 2 pages
	SET_COLOR 00h,00h		;set background color
	
NEW_GAME:
	cmp		level,0			;generate score if not level 1
	je		LEVEL1
	mov		dx,0000h
	mov		ax,0400h
	mov		bx,time
	div		bx
	add		score,ax
LEVEL1:

	call	CLR_KEY_BUF		;initialize
	inc		level
	mov		rfrg,5
	mov		cfrg,0
	mov		time,0
	mov		setup,1			;indicate first time calling GAME
	
CLEAR:
	call	CLR_GRID		;clear grids of last frame
	invoke	CLR_SCR,hdp		;clear hidden page
PRINT:
	call	PRT_LINE		;print at hidden page
	call	PRT_FROG		
	call	PRT_STATUS
	call	GAME
	mov		setup,0			;indicate not first time calling GAME
	mov		al,acp			;swap pages
	mov		ah,hdp
	mov		acp,ah
	mov		hdp,al
	SET_PAGE acp			;show active page
INPUT:
	GET_KEY
CHECK:
	call	EXAMINE
	inc		time
	cmp		dl,0			;nothing
	je		CLEAR
	cmp		dl,1			;level up
	je		NEW_GAME
	cmp		dl,2			;exit
	je		EXIT

GOOD_GAME:
	mov		level,0
	mov		dx,score		;generate best
	mov		score,0
	cmp		best,dx
	ja		NO_NEW_HIGH
	mov		best,dx
	PRT_STR	acp,10,30,offset nh0,01h
	PRT_STR	acp,12,30,offset nh1,01h
	jmp		NEXT_ROUND
NO_NEW_HIGH:
	PRT_STR	acp,10,30,offset gg0,01h
	PRT_STR	acp,12,30,offset gg1,01h
NEXT_ROUND:
	call	CLR_KEY_BUF		;clear keyboard buffer
	WAIT_KEY
	cmp		al,'e'			;exit
	je		EXIT
	jmp		NEW_GAME
	
EXIT:
	SET_MODE	03h			;text mode
	.exit
end

;[to do]
;clear buffer
;frog covered by car?
;car -3 10
;color debug
;rewrite rect
;macro->proc