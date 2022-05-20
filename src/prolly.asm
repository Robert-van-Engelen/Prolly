; prolly.asm - a MERGEd BASIC programs rotator to roll MERGEd programs down
; Author: Dr. Robert A van Engelen, 2022
; License: BSD-3 open source
; Requires: AS61860 http://shop-pdp.net/ashtml/asxxxx.php
;
; PC-1360 usage:
;   CALL 32818	create a new MERGEd BASIC program consisting of one line 1 "
;   CALL 32820	rotate MERGEd BASIC programs and make the previous current
;
; PC-1350 with 16K RAM card (target.asm __RAM_SLOT1__ = 16) usage:
;   CALL 8242	create a new MERGEd BASIC program consisting of one line 1 "
;   CALL 8244	rotate MERGEd BASIC programs and make the previous current
; PC-1350 without RAM card (target.asm __RAM_SLOT1__ = 0) usage:
;   CALL 24626	create a new MERGEd BASIC program consisting of one line 1 "
;   CALL 24628	rotate MERGEd BASIC programs and make the previous current

.area	PROGRAM (REL)

.include "target.asm"
.include "regs.asm"

;	RAM location of BASIC programs depends on the machine and RAM cards
.globl	RAM_BASIC

.radix	D

install::
	JRP installer

create::
	JRP create_new

; ------------------------------------------------------------------------------
; rotate MERGEd BASIC programs and make the previous current
; changes I,A,B,X,Y,K,L,M,N,T,U,V,W
; ------------------------------------------------------------------------------

rotate::
	LIDP BASIC_FLAGS
	TSID 0x80
	JRZP quit		; if MERGE flag not set, then quit
	LP REG_A
	LIDP BASIC_START_L
	LII 6-1
	MVWD			; BA <- [BASIC_START], X <- [BASIC_END], Y <- [BASIC_MERGE]
	LP REG_X
	SBB			; X <- [BASIC_END] - [BASIC_START]
	LP REG_A
	LIQ REG_X
	EXB			; BA <-> X
	CALL blk_swap		; swap memory block (X..Y-1) with block (Y..X+BA-1)
	; FALL THROUGH

; ------------------------------------------------------------------------------
; set BASIC MERGE address to the last MERGEd program and sync BASIC pointers
; changes A,B,X,Y
; ------------------------------------------------------------------------------

set_merge:
	LP REG_X
	LIDP BASIC_START_L
	MVBD			; X <- [BASIC_START]

next_merged:			; repeat
	LP REG_Y
	LIQ REG_X
	MVB			;   Y <- X = position at 0xff marker
	LIB 0
1$:	IXL			;   repeat  get line number MSB in A <- (++X)
	INCA			;     compare to 0xff marker
	JRZP at_marker		;     if marker then check if program end
	IX			;     ++X skip line number LSB
	IXL			;     A <- line length (++X)
	LP REG_X		;     add line length to X (B == 0)
	ADB
	JRM 1$			;   loop

at_marker:
	LP REG_A
	LIDP BASIC_END_L
	MVBD			;   BA <- [BASIC_END]
	;LP REG_X		;   assert P == REG_X
	SBB
	DECP
	ADB			;   compare X - [BASIC_END]
	JRCM next_merged	; loop until X >= [BASIC_END]
	LIDP BASIC_MERGE_L
	LP REG_Y
	EXBD			; [BASIC_MERGE] <-> Y

sync_basic:
	LII 6-1
	LP REG_A
	LIDP BASIC_START_L
	MVWD			; BA <- [BASIC_START], X <- [BASIC_END], Y <- [BASIC_MERGE]
	;LP REG_K		l assert P == REG_K
	LIQ REG_Y
	MVB			; LK <- Y = [BASIC_MERGE]
	LIDP RAM_BASIC_START_L
	LP REG_A
	EXWD			; [RAM_BASIC_START] <-> BA, [RAM_BASIC_END] <-> X, [RAM_BASIC_MERGE] <-> Y
	LIDP BASIC_EXEC_L
	;LP REG_K		; assert P == REG_K
	EXBD			; [BASIC_EXEC] <-> LK = [BASIC_MARGE]
	LP STATE
	ANIM 0			; (STATE) <- 0 so that cursor up won't hang on non-existing line

quit:
	RTN

; ------------------------------------------------------------------------------
; create new MERGEd program consisting of one line with opening quote 1 "
; changes A,X,Y
; ------------------------------------------------------------------------------

create_new:
	LII 4-1
	LP REG_A
	LIDP BASIC_START_L
	MVWD			; A <- [BASIC_START_L], X <- [BASIC_END_L]
	DX			; --X = [BASIC_END_L] - 1
	;LP REG_Y		; assert P == REG_Y
	LIQ REG_X
	MVB			; Y <- X = [BASIC_END_L] - 1
	LP REG_X
	SBB			; X <- X-1-BA = [BASIC_END_L] - 1 - [BASIC_START_L]
	JRZP store_new		; if no programs are present, skip MERGE step
	IY			; ++Y = [BASIC_END_L]
	LP REG_A
	LIQ REG_Y
	MVB			; BA <- Y = [BASIC_END_L]
	;LP REG_X		; assert P == REG_X
	LIQ REG_Y
	MVB			; X <- Y = [BASIC_END_L]
	LIDP BASIC_MERGE_L
	LP REG_A
	EXBD			; [BASIC_MERGE] <-> BA
	LIDP RAM_BASIC_MERGE_L
	;LP REG_X		; assert P == REG_X
	EXBD			; [RAM_BASIC_MERGE] <-> X
	LIDP BASIC_FLAGS	; set [BASIC_FLAGS] MERGE flag
	ORID 0x80
	LIDP RAM_BASIC_FLAGS	; set [RAM_BASIC_FLAGS] MERGE flag
	ORID 0x80

store_new:
	RA
	IYS			; (++Y) = 0 line number high order byte
	INCA
	IYS			; (++Y) = 1 line number low order byte
	INCA
	IYS			; (++Y) = 2 line length
	LIA '"
	IYS			; (++Y) = '"'
	LIA 13
	IYS			; (++Y) = 13 carriage return
	LIA 255
	IYS			; (++Y) = 255 END marker
	LIDP BASIC_END_L
	LP REG_Y
	EXBD			; [BASIC_END_L] <-> Y
	JRM sync_basic

; ------------------------------------------------------------------------------
; swap two consecutive memory blocks in place with zero storage overhead
; first block address in X, second block address in Y, combined size in BA
; changes I,A,B,X,Y,K,L,M,N,T,U,V,W
; ------------------------------------------------------------------------------

blk_swap:
	LP REG_M
	LIQ REG_A
	LII 6-1
	MVW			; save 6 registers NM <- BA, UT <- X, WV <- Y

;	1. reverse the combined memory blocks (X..X+BA-1) of size BA,
;	   this swaps the two blocks, but the data they contain is reversed

	CALL blk_reverse

;	2. reverse block (X..Y-1) of size Y-X (second block)
;	   compute:
;	     X <- UT		= start of the first block
;	     BA <- NM - WV + UT	= size of the second block
;	     UT <- UT + BA	= start of the second block (after the first reversal)
;	     NM <- NM - BA	= size of the first block

	LP REG_A
	LIQ REG_V
	MVB			; BA <- WV
	;LP REG_X		; assert P == REG_X
	LIQ REG_M
	MVB			; X <- NM
	LP REG_X
	SBB			; X <- X - BA = NM - WV
	LP REG_A
	;LIQ REG_T		; assert Q == REG_T
	MVB			; BA <- UT = start of the first block
	;LP REG_X		; assert P == REG_X
	ADB			; X <- X + BA = NM - WV + UT
	LP REG_A
	LIQ REG_X
	EXB			; X <-> BA
	LP REG_M
	SBB			; NM <- NM - BA = WV - UT = size of the first block
	LP REG_T
	ADB			; UT <- UT + BA = UT + NM - WV + UT = start of the second block
	CALL blk_reverse

;	3. reverse block (Y..X+BA-(Y-X)-1) of size BA-(Y-X) (first block)

	LP REG_A
	LIQ REG_M
	MVB			; BA <- NM = size of the first block
	MVB			; X <- UT = start of the second block
	; FALL THROUGH 

; ------------------------------------------------------------------------------
; reverse memory in place
; start address in X, size in BA
; chages A,B,X,Y,K,L
; ------------------------------------------------------------------------------

blk_reverse:
	LP REG_Y
	LIQ REG_X
	MVB			; Y <- X = start
	LP REG_Y
	ADB			; Y <- end = start + size
	;RC			; assert C=0
	EXAB
	SR
	EXAB
	SR			; BA <- size/2
	DECA
	JRNCP 1$
	DECB			; BA = size/2 - 1
	JRCP blk_reverse_exit	; if BA < 0 then return
1$:	LP REG_K
	EXAM			; BK <- size/2 - 1
	LP REG_L
	DX			; X <- start - 1

blk_reverse_loop:		; repeat
	DY
	MVMD			;   L <- (--Y)
	IXL			;   A <- (++X)
	MVDM			;   [X] <- L
	IY
	DYS			;   [Y] <- A
	DECK
	JRNCM blk_reverse_loop	; loop until --K == 0xff
	DECB
	JRNCM blk_reverse_loop	; loop until --B == 0xff

blk_reverse_exit:
	RTN

; ------------------------------------------------------------------------------
; data section
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; BASIC area
; ------------------------------------------------------------------------------

basic:
	.db 255,255		; BASIC START and END markers (empty program)

; ------------------------------------------------------------------------------
; installer moves BASIC program area up in memory after the machine code area
; then removes itself, replacing it with a RTN
; ------------------------------------------------------------------------------

installer:
.if __PC_1360__
	LIDP RAM_CARD_START_H
	LDD
	ORIA >basic		; A <- [RAM_CARD_START_H] | (basic>>8) = new BASIC start high order byte
	EXAB			; B <- high order byte new BASIC start
	LIA <basic		; A <- low order byte new BASIC start
.endif
.if __PC_1350__
	LIAB basic		; BA <- new address of BASIC programs after installation
.endif
	LII 6-1
	LP REG_X
	LIQ REG_A
	MVW			; X,Y,* <- BA
	IX			; ++X because [BASIC_END] = [BASIC_START] + 1
	LIDP BASIC_START_L
	LP REG_A
	EXWD			; [BASIC_START] <-> BA, [BASIC_END] <-> X, [BASIC_MERGE] <-> Y
	LIDP install
	LIA 0x37
	STD                     ; (install) <- RTN
	JRM sync_basic

; ------------------------------------------------------------------------------
; end
; ------------------------------------------------------------------------------
