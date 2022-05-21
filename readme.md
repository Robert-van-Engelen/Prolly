# Create and rotate multiple BASIC programs in your SHARP pocket computer

SHARP pocket computers of the 80s can store and run several BASIC programs
together when loaded with `MERGE` from a cassette tape.  The last MERGEd
program can be edited.  This is not convenient.  There is a better solution.

_Prolly_ is a small but powerful machine code program that manages a collection
of MERGEd BASIC programs for your SHARP pocket computer.

- allows you to create any number of BASIC programs as MERGEd and start writing
  them on the machine itself without having to `MERGE` from a cassette tape
- allows you to rotate a collection of MERGEd BASIC programs in memory, making
  the previous program the last MERGEd (the last MERGEd program can be edited)
- does not interfere with the MERGE, LOAD/CLOAD and SAVE/CSAVE commands
- _Prolly_ and the BASIC MERGEd programs reside on a RAM card, when present
- removing the RAM card retains _Prolly_ and the BASIC programs on the RAM
  card, which can be inserted to restore _Prolly_ and the programs

For example, suppose we have one program "A" already in memory:

    1 "A" REM my first program
    2 PRINT "I am program A"

To add a new program, `CALL 32818` (PC-1360) to create a new MERGEd program
consisting of one line with a quote:

    1 "A" REM my first program
    2 PRINT "I am program A"
    1 "

Note that the new line `1 "` starts a new program that is independent of the
previous programs, even when the listing appears to be continuous.  To verify,
`LIST` only lists the last merged program's first lines.  In this case:

    LIST
    1 "

Complete the new program by adding a label "B" and the rest of the code:

    1 "A" REM my first program
    2 PRINT "I am program A"
    1 "B" REM my second program
    2 PRINT "I am program B"

Executing `RUN` will run program "B", because it is the last MERGEd just as
`LIST` list program "B".

Program "A" is executed with `RUN "A"`.  Program "A" stops at line 2 and will
not run program "B".  Programs are internally separated when MERGEd.  Separate
programs can call each other using `GOTO` and `GOSUB` with labels or string
expressions.  `RESTORE` of labelled data in another program is also possible.
In this way, libraries of routines and data can be created and shared among
several programs.

`CALL 32820` (PC-1360) rotates the programs, effectively switching "A" and "B":

    1 "B" REM my second program
    2 PRINT "I am program B"
    1 "A" REM my first program
    2 PRINT "I am program A"

Program "A" can now be edited, which was not possible before the rotation:

    1 "B" REM my second program
    2 PRINT "I am program B"
    1 "A" REM my first program
    2 PRINT "I am the first program"

With _Prolly_ you can create as many programs as you like and rotate them.  To
delete the last program, use `DELETE,` (PC-1360) or just enter empty line
numbers (PC-1350).  `NEW` deletes all programs.  `SAVE` and `CSAVE` saves them
all combined.

The following instructions use a cassette interface (CE-126P or CE-124) to load
the bootloader program.  If you do not have a cassette interface, then you can
use `LOAD` with the serial port of your machine, or type-in the bootloader and
`RUN` (instead of DEF-A) to verify it.

## SHARP PC-1360 with 8KB, 16KB or 32KB RAM card

Installation:

Play the prolly.wav file and `CLOAD`.  This loads prolly.bas.  Press DEF-A.

Usage:

`CALL 32818` creates a new MERGEd BASIC program consisting of one line `1 "`.
Add a label after the quote and write the rest of the program.

`CALL 32820` rotates MERGEd BASIC programs and makes the previous program the
last MERGEd.  The last MERGEd program can be edited.

To make this easier and avoid costly mistakes when entering the calling
address, in RESERVE MODE define SHIFT-M (merge new) and SHIFT-SPC (rotate):

    RESERVE MODE
    M: CALL 32818
     : CALL 32820

## SHARP PC-1350 with 16KB RAM card

Installation:

Play the prolly16.wav file and `CLOAD`.  This loads prolly16.bas.  Press DEF-A.

Usage:

`CALL 8242` creates a new MERGEd BASIC program consisting of one line `1 "`.
Add a label after the quote and write the rest of the program.

`CALL 8244` rotates MERGEd BASIC programs and makes the previous program the
last MERGEd.  The last MERGEd program can be edited.

To make this easier and avoid costly mistakes when entering the calling
address, in RESERVE MODE define SHIFT-M (merge new) and SHIFT-SPC (rotate):

    RESERVE MODE
    M: CALL 8242
     : CALL 8244

## SHARP PC-1350 with 8KB RAM card

Installation:

Play the prolly8.wav file and `CLOAD`.  This loads prolly8.bas.  Press DEF-A.

Usage:

`CALL 16434` creates a new MERGEd BASIC program consisting of one line `1 "`.
Add a label after the quote and write the rest of the program.

`CALL 16436` rotates MERGEd BASIC programs and makes the previous program the
last MERGEd.  The last MERGEd program can be edited.

To make this easier and avoid costly mistakes when entering the calling
address, in RESERVE MODE define SHIFT-M (merge new) and SHIFT-SPC (rotate):

    RESERVE MODE
    M: CALL 16434
     : CALL 16436

## SHARP PC-1350 without RAM card

Installation:

Play the prolly0.wav file and `CLOAD`.  This loads prolly0.bas.  Press DEF-A.

Usage:

`CALL 24626` creates a new MERGEd BASIC program consisting of one line `1 "`.
Add a label after the quote and write the rest of the program.

`CALL 24628` rotates MERGEd BASIC programs and makes the previous program the
last MERGEd.  The last MERGEd program can be edited.

To make this easier and avoid costly mistakes when entering the calling
address, in RESERVE MODE define SHIFT-M (merge new) and SHIFT-SPC (rotate):

`RESERVE MODE`
`M: CALL 24626`
` : CALL 24628`

## Converting BAS to WAV files

I used the excellent [PocketTools](https://www.peil-partner.de/ifhe.de/sharp/)
to convert BASIC source code to wav files:

    bas2img --pc=1350 --level=8 prolly16.bas
    bin2wav --pc=1350 prolly16.img

## For developers

The target machine and RAM card choice is defined in `target.h`, for example
the PC-1350 with 16KB card:

    __RAM_SLOT1__ =  16
    .include "pc1350.h"

To assemble the code, you need the AS61860 assembler and linker, see:
- <https://www.qsl.net/yt2fsg/pocket/pocket_asm.html>
- <http://shop-pdp.net/ashtml/asxxxx.php>

The ihx2bas tool included with this project converts IHX format to a BASIC
bootloader program.

The `pc1350.h` file is sourced and extended from the PShell project:
- <https://edgar-pue.tripod.com/sharp/pshell.html>
