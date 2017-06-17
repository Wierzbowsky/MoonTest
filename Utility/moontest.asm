cpu z80
;		.z80

;		ASEG
		ORG	0100h

;-------------------------------------------------------------------
; описание: Точка входа в программу после передачи управления из ОС
;---------------------------------------------------------------------
Start:		DI
		RST	30H
		DB	00	
		DW	06CH
		RST	30H
		DB	00	
		DW	0C3H
		LD	de,TITLE	
		call	print_string

Card_detect:	call	init_card		;инициализация и проверка наличия карты
		cp	a,0ffh
		jp	z,card_not_found	;карта не найдена

card_info:
		ld	de,Blaster		;выведем информацию о чипе
		call	print_string

		ld	de,msg_Dev		;выведем информацию о чипе
		call	print_string
		ld	de,id_ym278
		ld	a,(dev_id)
		cp	20h
		jr	z,chip_0
		ld	de,id_unk
chip_0:
		call	print_string

		ld	de,msg_ROM		;выведем информацию о ПЗУ
		call	print_string
		ld	de,mem_2048		
		call	print_string
		ld	de, msg_RAM		;выведем информацию о ОЗУ
		call	print_string

		ld	c,0				;признак что памяти нет

		ld	de,0211h			;открываем ОЗУ на запись
		call	wave_out
	
		ld	de,0320h			;устанавливаем адрес 200000h
		call	wave_out

		ld	de,0400h                        ;старший байт
		call	wave_out		
		inc	d                               ;05 - младший байт адреса
		call	wave_out
		ld	de,0655h                        ;06 -запишем данные -> 55h
		call	wave_out		
		call	busy		;проверим готовность микросхемы
		ld	e,0AAh                          ;06 -запишем данные -> 0AAh
		call	wave_out		
		call	busy		;проверим готовность микросхемы

		nop
		nop
		nop
		nop
		nop

		ld	de,0211h			;открываем ОЗУ на чтение
		call	wave_out
		ld	de,0320h			;устанавливаем адрес 200000h
		call	wave_out
		ld	de,0400h                        ;старший байт
		call	wave_out		
		inc	d                               ;05 - младший байт адреса
		call	wave_out
		inc	d   
		call	wave_in
		ld	l,a
		call	wave_in

		cp	0AAh				;сравним что прочитали	
		jr	nz, chip_1
		ld	a,l
		cp	55h				;сравним что прочитали	
		jr	nz, chip_1
		ld	a,1
		or	c
		ld	c,a
chip_1:
		ld	de,0211h			;открываем ОЗУ на запись
		call	wave_out
		ld	de,0328h			;устанавливаем адрес 280000h
		call	wave_out

		ld	de,0400h                        ;старший байт
		call	wave_out		
		inc	d                               ;младший байт адреса
		call	wave_out
		ld	de,06AAh                        ;06 -запишем данные -> AAh
		call	wave_out		
		call	busy		;проверим готовность микросхемы
		ld	e,55h                          	;06 -запишем данные -> 55h
		call	wave_out		
		call	busy		;проверим готовность микросхемы

		nop
		nop
		nop
		nop
		nop

		ld	de,0211h			;открываем ОЗУ на чтение
		call	wave_out
		ld	de,0328h			;устанавливаем адрес 280000h
		call	wave_out
		ld	de,0400h                        ;старший байт
		call	wave_out		
		inc	d                               ;05 - младший байт адреса
		call	wave_out
		inc	d   
		call	wave_in
		ld	l,a
		call	wave_in

		cp	55h				;сравним что прочитали	
		jr	nz, chip_2
		ld	a,l
		cp	0AAh				;сравним что прочитали	
		jr	nz, chip_2
		ld	a,2
		or	c
		ld	c,a
chip_2:
		ld	a,c
		ld	(dev_mem),a
		ld	de,mem_none	
		and	a
		jr	z,chip_3
		ld	de,mem_1024
		cp	3
		jr	z,chip_3
		ld	de,mem_512
chip_3:
		call	print_string
		ld	de, 0210h			;закрываем доступ к ОЗУ карты
		call	wave_out

testram:        RST	30H
		DB	0
		DW	156H
		call	test_ram

exit:		LD	de,ENDING
		call	print_string
	        RST	30H
		DB	0
		DW	156H
		ret


;-------------------------------------------------------------------
; описание: Печать строки на экране
; параметры: de - адрес строки, hl - координаты
; возвращаемое  значение: нет
;---------------------------------------------------------------------
print_string:	push	hl
		push	bc
		push	de
do_print:	ld	c,9
		call	0005
		pop	de
		pop	bc
		pop	hl
		ret

;-------------------------------------------------------------------
; описание: Печать символа на экране
; параметры: a - символ
; возвращаемое  значение: нет
;---------------------------------------------------------------------
print_char:	push	hl
		ld	hl,PRINTCHAR
		ld	(hl),a
		ex	de,hl
		call	print_string
		pop	hl
		ret


;-------------------------------------------------------------------
; описание: Проверка нажатой клавиши
; параметры: нет
; возвращаемое  значение: нет
;---------------------------------------------------------------------
check_anykey:   RST	30H
		DB	0
		DW	9CH
		ret

;-------------------------------------------------------------------
; описание: Вывод сообщения об отсутствии карты 
; параметры: нет                                
; возвращаемое  значение: нет
;---------------------------------------------------------------------
card_not_found:
		ld	de,NOCARD
		call	print_string        ;выведем сообщение
		jp	exit

;-------------------------------------------------------------------
; описание: Вывод сообщения об отсутствии памяти ОЗУ
; параметры: нет                                
; возвращаемое  значение: нет
;---------------------------------------------------------------------
ram_not_found:
		ld	de,NORAM
		call	print_string        ;выведем сообщение
		ret

;-------------------------------------------------------------------
; описание: Процесс тестирования ОЗУ
; параметры: нет
; возвращаемое  значение: нет
;---------------------------------------------------------------------
test_ram:
		ld	a,(dev_mem)		;проверим наличие банков памяти
		and	a
		jp 	z,ram_not_found
		LD	de,TESTING
		call	print_string
test_ram_loop:	xor	a
		ld	hl,TESTFLAG
		ld	(hl),a

test_ram_00:	ld	(chk_byte),a
		ld	a,(dev_mem)		;проверим наличие банка 0
		and	1
		jp 	z,test_ram_12
		ld	hl,1030h
		ld	bc,0000h			;B - номер банка, С - номер сегмента
		LD	de,BANK1
		call	print_string

test_ram_0:	call	check_segment	;проверка одного сегмента
		ld	a,RAMOK                           ;сегмент исправен
		jp      z,test_ram_01
		ld	a,RAMBAD				;сегмент неисправен
		push	hl
		ld	hl,TESTFLAG
		inc	(hl)
		pop	hl

test_ram_01:	inc	c				;увеличим номер сегмента
		push	bc
		call	print_char
		pop	bc
		call	check_anykey
		jp	nz,test_ram_6
		ld	a,c
		cp	20h
		jp	nz,test_ram_0

		ld	hl,TESTFLAG
		ld	a,(hl)
		or	a
		jp	z,test_ram_02
		LD	de,FAILED
		call	print_string
		jp	test_ram_12
test_ram_02:	LD	de,PASSED
		call	print_string

test_ram_12:	ld	a,(dev_mem)		;проверим наличие банка 1
		and	2
		jp 	z,test_ram_32
		ld	hl,8730h
		ld	bc,0100h			;B - номер банка, С - номер сегмента
		xor	a
		push	hl
		ld	hl,TESTFLAG
		ld	(hl),a
		pop	hl
		LD	de,BANK2
		call	print_string

test_ram_2:	call	check_segment	;проверка одного сегмента
		ld	a,RAMOK                           ;сегмент исправен
		jp      z,test_ram_21
		ld	a,RAMBAD				;сегмент неисправен
		push	hl
		ld	hl,TESTFLAG
		inc	(hl)
		pop	hl

test_ram_21:	inc	c				;увеличим номер сегмента
		push	bc
		call	print_char
		pop	bc
		call	check_anykey
		jp	nz,test_ram_6
		ld	a,c
		cp	20h
		jp	nz,test_ram_2

		ld	hl,TESTFLAG
		ld	a,(hl)
		or	a
		jp	z,test_ram_22
		LD	de,FAILED
		call	print_string
		jp	test_ram_32
test_ram_22:	LD	de,PASSED
		call	print_string
		
test_ram_32:	ld	hl,PASSED+13
		inc	(hl)
		ld	hl,FAILED+13
		inc	(hl)
		ld	hl,8000h			;пауза между тестами
test_ram_33:	nop
		nop
		nop
		nop
		nop
		dec	hl
		ld	a,l
		or	h
		jr	nz,test_ram_33

		ld	hl,NRUNS
		dec	(hl)
		ld	a,(hl)
		or	a
		jp	nz,test_ram_loop
	
test_ram_5:	LD	de,COMPLETE
		call	print_string
		ret

test_ram_6:    	LD	de,ABORTED
		call	print_string
		ret


;-------------------------------------------------------------------
; описание: Проверка одного сегмента RAM
; параметры: B - номер банка
;	     C - номер сегмента по 16Кб
; возвращаемое  значение: Z = 1 исправен, Z = 0 неисправен
;---------------------------------------------------------------------
check_segment:
		push	hl
		push	de
		push	bc
		ld	de,0211h			;запись в RAM
		call	wave_out

		ld	a,c
		add	a,a
		add	a,a
		rrca
		rrca
		rrca
		rrca
		ld	l,a
		and	0Fh
		ld	h,a
		ld	a,l
		and	0F0h
		ld	l,a

		ld	a,b
		ld	e,20h
		and	a
		jr	z,check_segment_0
		ld	e,28h

check_segment_0:
		ld	a,e
		or	h
		ld	e,a
		inc	d
		call	wave_out

		ld	e,l
		inc	d
		call	wave_out
		ld	de,0500h
		call	wave_out
		inc	d

		ld	hl,4000h
		ld	a,(chk_byte)
		ld	e,a

check_segment_1:
		call	wave_out
		call	busy
		inc	e

		dec	hl
		ld	a,l
		or	h
		jr	nz,check_segment_1		
		pop	bc			

		push	bc
		ld	de,0211h			;чтение из RAM 
		call	wave_out

		ld	a,c
		add	a,a
		add	a,a
		rrca
		rrca
		rrca
		rrca
		ld	l,a
		and	0Fh
		ld	h,a
		ld	a,l
		and	0F0h
		ld	l,a

		ld	a,b
		ld	e,20h
		and	a
		jr	z,check_segment_3
		ld	e,28h

check_segment_3:
		ld	a,e
		or	h
		ld	e,a
		inc	d
		call	wave_out

		ld	e,l
		inc	d
		call	wave_out
		ld	de,0500h
		call	wave_out
		inc	d

		ld	hl,4000h
		ld	a,(chk_byte)
		ld	e,a

check_segment_4:
		call	wave_in
		cp	e
		jr	nz,check_segment_5

		inc	e
		dec	hl
		ld	a,l
		or	h
		jr	nz,check_segment_4

check_segment_5:
		ld	de,0210h			;Отключаем доступ к RAM
		call	wave_out
		pop	bc					
		pop	de
		pop	hl
		ret	

;-------------------------------------------------------------------
; описание: Инициализация карты ZXM-Moonsound
; параметры: нет
; возвращаемое  значение: A - 0 нет ошибок, иначе ошибка
;---------------------------------------------------------------------
init_card:

		in	a,(WB_STAT)                       ;проверяем наличие карты
		cp	0FFh
		jp	nz,init_0
		ret	

init_0:
		ld	de, 0400h 
		call	fm2_out
		ld	de, 0503h			; set 1 to NEW2, NEW
		call	fm2_out
		ld	de, 0bd00h			; RHYTHM
		call	fm1_out
		ld	de, 0210h			; Set WaveTable header
		call	wave_out
		
		in	a,(WB_WDAT)			;получим ID девайса
		and	0E0h
		ld	(dev_id),a
		xor	a
		ret	

;-------------------------------------------------------------------
; описание: Запись в регистры fm1
; параметры: D = адрес регистра 
;	     E = данные
; возвращаемое  значение: нет
;-------------------------------------------------------------------
fm1_out:
		ld	a, d
		out	(WB_REG1), a

		nop
		nop
		nop
		nop
		nop
		
		ld	a, e
		out	(WB_DAT1), a
		ret

;-------------------------------------------------------------------
; описание: Запись в регистры fm2
; параметры: D = адрес регистра 
;	     E = данные
; возвращаемое  значение: нет
;-------------------------------------------------------------------
fm2_out:
		ld	a,d
		out	(WB_REG2), a

		nop
		nop
		nop
		nop
		nop
	
		ld	a,e
		out	(WB_DAT2), a
		ret

;-------------------------------------------------------------------
; описание: Запись в регистры Wave
; параметры: D = адрес регистра 
;	     E = данные
; возвращаемое  значение: нет
;-------------------------------------------------------------------
wave_out:
		ld	a, d
		out	(WB_WREG),a
		
		nop
		nop
		nop
		nop
		nop

		ld	a, e
		out	(WB_WDAT),a
		ret

;-------------------------------------------------------------------
; описание: Чтение из регистра Wave
; параметры: D = адрес регистра 
; возвращаемое  значение: А - данные
;-------------------------------------------------------------------
wave_in:
		ld	a, d
		out	(WB_WREG),a

		nop
		nop
		nop
		nop
		nop

		in	a,(WB_WDAT)
		ret

;-------------------------------------------------------------------
; описание: Ожидание готовности микросхемы
; параметры: нет
; возвращаемое  значение: нет
;-------------------------------------------------------------------
busy:		nop
		nop
		nop
		nop
		nop

		in	a,(WB_STAT)
		rra
		jr	c,busy		
		ret


;-------------------------------------------------------------------


;-------------------------------------------------------------------
; описание: Сообщения о ошибках
;---------------------------------------------------------------------
NOCARD:		DB 	"Moonsound/Wozblaster is not detected!",10,13,"$"
NORAM:		DB 	10,13,"This Moonsound/Wozblaster doesn't have any RAM!",10,13,"$"

;-------------------------------------------------------------------
; описание: Информационные сообщения  
;---------------------------------------------------------------------
TITLE: 		DB	"Moonsound/Wozblaster Onboard RAM Tester v1.0",10,13,"ZX Version Copyright (C) 2015 Micklab",10,13,"MSX Version Copyright (C) 2015 Alexey Podrezov",10,13,10,13,"$"
PRINTCHAR:	DB	" $"
BLASTER: 	DB	"Currently installed Moonsound/Wozblaster:",10,13,10,13,"$"
ENDING:		DB	10,13,"Thanks for using the Moonsound/Wozblaster Onboard RAM Tester!",10,13,"Please check the README.TXT file for more info.",10,13,"$"
TESTING:	DB	10,13,"Starting 3 RAM tests, press any key to stop testing.",10,13,"$"
ABORTED:	DB	10,13,"The test was stopped by a user...",10,13,"$"
COMPLETE:	DB	10,13,"The test is complete...",10,13,"$"
BANK1:		DB	" BANK1 (512 kb): $"
BANK2:		DB	" BANK2 (512 kb): $"
CRLF:		DB	10,13,"$"
PASSED:		DB	" PASSED (try 1)",10,13,"$"
FAILED:		DB	" FAILED (try 1)",10,13,"$"

id_unk:		DB 	"Unknown",10,13,"$"
id_ym278:	DB 	"Yamaha YMF278",10,13,"$"

mem_none:	DB 	"None",10,13,"$"
mem_512:	DB 	"512 kb",10,13,"$"
mem_1024:	DB 	"1024 kb",10,13,"$"
mem_2048:	DB 	"2048 kb",10,13,"$"

msg_Dev:	DB 	" OPL chip: $"
msg_RAM:	DB 	" RAM size: $"
msg_ROM:	DB 	" ROM size: $"

RAMOK:		EQU	"."
RAMBAD:		EQU	"x"

WB_BASE:	EQU	0C4h
WB_REG1:	EQU	WB_BASE
WB_DAT1:	EQU	WB_BASE+1
WB_REG2:	EQU	WB_BASE+2
WB_DAT2:	EQU	WB_BASE+3
WB_STAT:	EQU	WB_BASE

WB_WREG:	EQU	7Eh
WB_WDAT:	EQU	WB_WREG+1

dev_id:		DB	0
dev_mem:	DB	0
chk_byte:	DB	0
TESTFLAG:	DB	0
NRUNS:		DB	3

;		END
