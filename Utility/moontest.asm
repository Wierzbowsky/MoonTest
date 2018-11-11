cpu z80
;		.z80

;		ASEG
		ORG	0100h

;-------------------------------------------------------------------
; описание: Точка входа в программу после передачи управления из ОС
;---------------------------------------------------------------------
Start:
		RST	30H
		DB	00
		DW	06CH
		RST	30H
		DB	00	
		DW	0C3H
		LD	de,TITLE	
		call	print_string

Card_detect:
		call	init_card	;инициализация и проверка наличия карты
		jp	nz,card_info	;карта найдена

        ld  de,NOCARD		; карта не найдена
        call    print_string
        jp  exit

card_info:
		ld	de,BLASTER		;выведем информацию о чипе
		call	print_string

		ld	de,msg_Dev		;выведем информацию о чипе
		call	print_string
		call	get_card_id
		ld	de,id_ym278
		cp	20h
		jr	z,chip_ym278
		ld	de,id_unk
chip_ym278:
		call	print_string

		ld	de,msg_ROM		;выведем информацию о ПЗУ
		call	print_string


		ld	de, msg_RAM		;выведем информацию о ОЗУ
		call	print_string


		ld b, 4		; start with 4 banks detected
detect_ram:
		ld a, b
		dec a
		add a,a
		add a,a
		add a,a
		ld l, a
		call Check_mem
		jr z, detected_ram
		djnz detect_ram
detected_ram:
		ld	de, 0210h			;закрываем доступ к ОЗУ карты
		call	wave_out

		ld a, b
		ld	(dev_mem),a
		call print_small_int
		ld de, msg_total
		call print_string
		ld hl, msg_total_x - 2
		inc b
_select_ram_msg:
		inc hl
		inc hl
		djnz _select_ram_msg
		ld e, (hl)
		inc hl
		ld d, (hl)
		call print_string

        RST	30H
		DB	0
		DW	156H
		ld  a, (dev_mem)
		or a
		jp nz, ram_found
		ld	de,NORAM
		call	print_string
		jp exit

ram_found:
		ld de, TESTING
		call    print_string
		call	test_ram
		jp z, test_aborted_by_user
		call	test_ram_update_pass
		call	test_ram
		jp z, test_aborted_by_user
		call	test_ram_update_pass
		call	test_ram
		jp z, test_aborted_by_user
		LD	de,COMPLETE
		call	print_string
		jp exit

test_aborted_by_user:
		LD  de,ABORTED
		call    print_string

exit:
		LD	de,ENDING
		call	print_string
		RST	30H
		DB	0
		DW	156H
		ret


; L <- higher 5 bits 21-17 of the RAM address
; E -> address bits normalized to the OPL4 RAm address
; modify: AF
_normalize_high_addr_bits:
	ld a, l
	and 01fh  ; take 5 high bits
	or 20h  ; set the 6th bit (200000h) of address - RAM area
	ld e, a
	ret

; L <- higher 5 bits 21-17 of the RAM address
; ZF=1 memory detected,  ZF=0 memory not detected
; modify: de, af, l
Check_mem:
		di
		call    busy        ;проверим готовность микросхемы
		ld  de,0211h            ;открываем ОЗУ на запись
		call    wave_out
		inc d
		call _normalize_high_addr_bits
		push de
		call    wave_out
		ld  de,0400h		; set 00 for 15-8 bits of addr
		call    wave_out
		inc d		; same 00 for 7-0 bits of addr
		call    wave_out
		ld  de,0655h		; write the 55h to the address
		call    wave_out
		call    busy        ;проверим готовность микросхемы
		ld e,0AAh		; write AAh to the address
		call    wave_out
		; now try reading that back
		call    busy        ;проверим готовность микросхемы
        nop
        nop
        nop
        nop
        nop
		ld  de,0211h            ;открываем ОЗУ на чтение
		call    wave_out
		pop de
		call    wave_out
		ld  de,0400h        ; set 00 for 15-8 bits of addr
		call    wave_out
		inc d       ; same 00 for 7-0 bits of addr
		call    wave_out
		inc d
		call    wave_in
		cp  55h
		jr nz, Check_mem_exit
		call    wave_in
		cp 0AAh
Check_mem_exit:
		ei
		ret

;-------------------------------------------------------------------
; описание: Печать строки на экране
; параметры: de - адрес строки, hl - координаты
; возвращаемое  значение: нет
;---------------------------------------------------------------------
print_string:	push	hl
		push	bc
		push	de
		ld	c,9
		call	0005
		pop	de
		pop	bc
		pop	hl
		ret


; A <- int (0 <= x <= 9)
print_small_int:
		add 30h		; and follow with print_char! (instead of call/jp)
;-------------------------------------------------------------------
; описание: Печать символа на экране
; параметры: a - символ
; возвращаемое  значение: нет
;---------------------------------------------------------------------
print_char:
		push	de
		ld	de,PRINTCHAR
		ld	(de),a
		call	print_string
		pop	de
		ret


;-------------------------------------------------------------------
; описание: Процесс тестирования ОЗУ
; параметры: нет
; возвращаемое  значение: нет
;---------------------------------------------------------------------
test_ram:
		ld hl, test_bank
		ld b, 0
		ld (hl), b				;B - номер банка

test_ram_loop:
		xor	a
		ld	(TESTFLAG),a

		ld	hl,1030h
		ld c, 0 				;С - номер сегмента
		LD	de, BANK
		call	print_string
		ld a, b
		call print_small_int
		LD  de, BANK_E
		call    print_string

test_ram_check_segment:
		call	check_segment	;проверка одного сегмента
		ld	a,RAMOK                           ;сегмент исправен
		jp      z,test_ram_segment_ok
		ld	a,RAMBAD				;сегмент неисправен
		push	hl
		ld	hl,TESTFLAG
		inc	(hl)
		pop	hl

test_ram_segment_ok:
		inc	c				;увеличим номер сегмента
		push	bc
		call	print_char
		pop	bc
		RST	30H
		DB	0
		DW  9CH  ;  check if key pressed
		jp	nz,test_ram_abort
		ld	a,c
		cp	20h
		jp	nz,test_ram_check_segment

		ld	hl,TESTFLAG
		ld	a,(hl)
		or	a
		LD	de,PASSED
		jp	z,test_ram_print_status
		LD	de,FAILED
test_ram_print_status:
		call	print_string

		ld	hl,8000h			;пауза между тестами
test_ram_pause:
		nop
		nop
		nop
		nop
		nop
		dec	hl
		ld	a,l
		or	h
		jr	nz,test_ram_pause

        ld a, (dev_mem)
        ld hl, test_bank
        inc (hl)
		ld b, (hl)
        cp b
        jp nz, test_ram_loop

		xor a
		or	1	; set ZF = 0 before return
		ret
	
test_ram_abort:
		xor a		; set ZF = 1 before return
		ret


test_ram_update_pass:
		ld	hl,PASSED_NUM
		inc	(hl)
		ld	hl,FAILED_NUM
		inc	(hl)
		ret


_check_segment_normalize_addr:
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
		ret

_check_segment_normalize_bank_addr:
		ld  a,b
        and 3
        rlca
        rlca
        or  20h
		or  h
		ld  e,a
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

		call _check_segment_normalize_addr

		call _check_segment_normalize_bank_addr

		inc	d
		call	wave_out

		ld	e,l
		inc	d
		call	wave_out
		ld	de,0500h
		call	wave_out
		inc	d

		ld	hl,4000h
		ld	a,55h
		ld	e,a

check_segment_write_loop:
		call	wave_out
		call	busy

		inc	e
		dec	hl
		ld	a,l
		or	h
		jr	nz,check_segment_write_loop		

		pop	bc			

		push	bc
		ld	de,0211h			;чтение из RAM 
		call	wave_out

		call _check_segment_normalize_addr

        call _check_segment_normalize_bank_addr

		inc	d
		call	wave_out

		ld	e,l
		inc	d
		call	wave_out
		ld	de,0500h
		call	wave_out
		inc	d

		ld	hl,4000h
		ld	a,55h
		ld	e,a

check_segment_read_loop:
		call	wave_in
		cp	e
		jr	nz,check_segment_exit

		inc	e
		dec	hl
		ld	a,l
		or	h
		jr	nz,check_segment_read_loop

check_segment_exit:
		ld	de,0210h			;Отключаем доступ к RAM
		call	wave_out
		pop	bc					
		pop	de
		pop	hl
		ret	

;-------------------------------------------------------------------
; описание: Инициализация карты OPL4
; параметры: нет
; возвращаемое  значение: ZF=1 - ошибка, иначе все ок
;---------------------------------------------------------------------
init_card:
		in	a,(WB_STAT)                       ;проверяем наличие карты
		inc a
		ret	z		; WB_STAT port returned FFh
		; all operations below (fm1_out, fm2_out, wave_out) doesn't
		; change the flags so it is safe to just return afterwards with ZF=0
		ld	de, 0400h 
		call	fm2_out
		ld	de, 0503h			; set 1 to NEW2, NEW
		call	fm2_out
		ld	de, 0bd00h			; RHYTHM
		call	fm1_out
		ld	de, 0210h			; Set WaveTable header
		call	wave_out
		ret

get_card_id:
		in  a,(WB_WDAT)         ;получим ID девайса
		and 0E0h
		ld  (dev_id),a
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
TITLE: 		DB	"Moonsound/Wozblaster Onboard RAM Tester v1.0",10,13
			DB	"ZX Version Copyright (C) 2015 Micklab",10,13
			DB	"MSX Version Copyright (C) 2015 Alexey Podrezov",10,13
			DB	"MSX Version Copyright (C) 2018 Volodymyr Bezobiuk",10,13
			DB	10,13,"$"
BLASTER: 	DB	"Currently installed Moonsound/Wozblaster:",10,13,10,13,"$"
ENDING:		DB	10,13,"Thanks for using the Moonsound/"
			DB	"Wozblaster Onboard RAM Tester!",10,13
			DB	"Please check the README.TXT file for more info.",10,13,"$"
TESTING:	DB	10,13,"Starting 3 RAM tests, press any key to interrupt testing.",10,13,"$"
ABORTED:	DB	10,13,10,13,"Test interrupted by user...",10,13,"$"
COMPLETE:	DB	10,13,10,13,"Test completed.",10,13,"$"
BANK:		DB  " BANK $"
BANK_E:		DB	": $"
PASSED:		DB	" PASSED (try "
PASSED_NUM:	DB	"1)",10,13,"$"
FAILED:		DB	" FAILED (try "
FAILED_NUM:	DB	"1)",10,13,"$"
PRINTCHAR:	DB	" $"

id_unk:		DB 	"Unknown",10,13,"$"
id_ym278:	DB 	"Yamaha YMF278",10,13,"$"

msg_Dev:	DB 	" OPL chip: $"
msg_RAM:	DB 	" RAM size: $"
msg_ROM:	DB 	" ROM size: 2048K",10,13,"$"

msg_total	DB  " x 512K = $"
msg_total_0	DB	"no RAM installed$"
msg_total_1	DB	"512K",10,13,"$"
msg_total_2	DB	"1024K",10,13,"$"
msg_total_3	DB	"1536K",10,13,"$"
msg_total_4	DB	"2048K",10,13,"$"
msg_total_x	DW	msg_total_0, msg_total_1, msg_total_2, msg_total_3, msg_total_4

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
test_bank:	DB	0
TESTFLAG:	DB	0

;		END

