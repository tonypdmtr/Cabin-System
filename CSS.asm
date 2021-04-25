;*******************************************************************************
; Current version:
;      1-Feb-2011  5:00 pm
CSBUILD             equ       51                  ; system build version
;*******************************************************************************
;        OPT     cre             A cross reference is a good thing to have
;*******************************************************************************

; Cabin Software - Copyright 1996-2011     H. Bruce Stephens
; Cabin Software - This is the main module which is downloaded into
;       the Cabin System 68HC11 for execution.   The Cabin Software
;       provides a basis for remotely monitoring the Cabin Sensors.
;       In addition, the Cabin Software provides a transparent
;       interface to the CP290 for direct power control of lights,
;       equipment, etc via the X10 system.   The Cabin Software also
;       provides a history of the weather information collected by
;       the Cabin System.    Local display operations are provided
;       using a LCD panel which can monitor the sensors directly.

; The Cabin System Software will be refered to as CSS

; Second generation build date: Wednesday, August 25, 1993

; Modification History

;   Version   Who          When         Why
;    FT1.0    hbs      25-Aug-1993    Initial Release for 1st field test
;     V1.x    hbs      14-Jul-1996    Revision history begins
;     V1.37   hbs      15-Jul-1996    Must delay a few seconds on startup
;                                     to give the CP290 time to come online
;     V1.38   hbs      18-Jul-1996    Improved display characteristics and
;                                     corrected modem hangup sequence
;     V1.39   hbs      19-Jul-1996    Minor home/clear cleanup
;     V1.40   hbs      22-Jul-1996    Limit the history days to 25
;     V1.41   hbs      13-Aug-1996    Cabin deployment, added extra timing
;                                     delay to temp bus, fixed sensor names
;                                     to match location
;     V1.42   hbs      25-Dec-1996    Correction to history logic, fix rel
;                                     light lcd negative display, bumped
;                                     the birthday: Sunday, 25Aug96
;     V1.43   hbs      27-Dec-1996    Continue to correct history logic
;                                     and non negative high/low display
;     V1.44   hbs      31-Dec-1996    Open/close door count fix for non
;                                     negitive numbers and added stops to
;                                     the end of the code for power down
;     V1.45   hbs      13-Nov-2000    Remove the Y2K problems.
;     V1.50   hbs      11-Dec-2001    Bumped the birth date and added a new
;                                     command at the USERNAME: prompt for
;                                     a PC to dump just the first of the RAM
;     V1.51   hbs       1-Feb-2011    Added to public repository

;**************************************************************************
; EVB memory assignments
;**************************************************************************

BUFFALO             equ       $E000               ; Buffalo begins here
BUFISIT             equ       $E00A               ; Buffalo bypass the PORTE bit 0 check
RAMSTRT             equ       $C000               ; Starting RAM location
EEPROMS             equ       $6000               ; Starting EEPROM

;*******************************************************************************
; Equates into BUFFALO ROM locations for calling routines
;*******************************************************************************

HOSTCO              equ       $E330               ; Host connect routine
HOSTINI             equ       $EF3F               ; Host init routine
INPUT               equ       $E387               ; Input from the PeeCee
OUTPUT              equ       $E3B3               ; Output to the PeeCee
UPCASE              equ       $E18F               ; Upper case routine
ONACIA              equ       $E46E               ; Master reset the ACIA
OUTCRLF             equ       $E4ED               ; Output a LF/CR sequence to the PeeCee
DUMP1               equ       $E7E4               ; Dump memory...used for UPLOAD function
VECINIT             equ       $E340               ; Interupt vector init routine
BPCLR               equ       $E19A               ; Breakpoint clear routine
INIT                equ       $E361               ; RS-232 init routine
ONSCI               equ       $E24F               ; Setup the SCI routine
ACIA                equ       $9800               ; ACIA master address location

;*******************************************************************************
; 68HC11 Equates RAM locations for control/status registers used by CSS
;*******************************************************************************

PORTA               equ       $1000               ; Address of PORT A
PORTB               equ       $1004               ; Address of PORT B
PORTC               equ       $1003               ; Address of PORT C
DDRC                equ       $1007               ; Data direction for PORT C
PORTD               equ       $1008               ; Address of PORT D
DDRD                equ       $1009               ; Data direction for PORT D
PORTE               equ       $100A               ; Address of PORT E
PACTL               equ       $1026               ; Pulse Accumulator control register
PACNT               equ       $1027               ; Pulse Accumulator (Wind speed counter)
BAUD                equ       $102B               ; SCI Baud rate register
SCSR                equ       $102E               ; SCI Status register
SCDAT               equ       $102F               ; SCI Data Register
OPTION              equ       $1039               ; System configuration/option register
ADCTL               equ       $1030               ; A/D Control/Status Register
TFLG1               equ       $1023               ; Main timer flag register
TCNT                equ       $100E               ; Timer Counter Register
TOC4                equ       $101C               ; Timer Output Compare Register 4
TOC5                equ       $101E               ; Timer Output Compare Register 5
TMSK2               equ       $1024               ; Timer mask two

;*******************************************************************************
; Equates into BUFFALO RAM locations used by CSS
;*******************************************************************************

PTR1                equ       $00B2               ; Starting dump memory pointer
PTR2                equ       $00B4               ; Ending dump memory pointer
AUTOLF              equ       $00A9               ; Auto Line feed flag location
HOSTDEV             equ       $00AC               ; 0=sci 1=acia Used by CPINIT
EXTDEV              equ       $00AB               ; External device address location
STACK               equ       $0068               ; The stack location
IODEV               equ       $00AA               ; RS-232 I/O Device

;*******************************************************************************
; Equate definitions used by CSS
;*******************************************************************************

TOC4F               equ       $10                 ; Timer 4 compare output flag
TOC5F               equ       $08                 ; Timer 5 compare output flag
REQDATA             equ       $06                 ; CP290 Request graphics data command
REQCLK              equ       $04                 ; CP290 Request clock command
DNLOAD              equ       $03                 ; CP290 Download event command
DNTIME              equ       $02                 ; CP290 Download time command
DCDFLAG             equ       $04                 ; Bit 2 of PORT A is the DCD flag (LOW=ACTIVE)
LCDRSD              equ       $08                 ; Bit 3 of PORT A is the LCD RS 0=reg 1=data
RDFLAG              equ       $20                 ; SCI status register Data Ready (RDRF) flag
WINDON              equ       $10                 ; Sets the wind direction bit for PORT A
HORZTAB             equ       $09                 ; ASCII TAB
CRETURN             equ       $0D                 ; ASCII Carriage Return
LINFEED             equ       $0A                 ; ASCII Line Feed
BACKSP              equ       $08                 ; ASCII Backspace
EOTEXT              equ       $04                 ; ASCII End of Text
ASPACE              equ       $20                 ; ASCII Space
CAPTOLY             equ       $59                 ; ASCII Capital 'Y'
ASCII0              equ       $30                 ; ASCII 0
ESCAPE              equ       $1B                 ; ASCII Escape
ACOLON              equ       $3A                 ; ASCII :
APLUS               equ       $2B                 ; ASCII +
APERIOD             equ       $2E                 ; ASCII .
ALLONES             equ       $FF                 ; Blank out the LED display
ASMALLA             equ       $61                 ; ASCII a
ASMALLP             equ       $70                 ; ASCII p
ASMALLM             equ       $6D                 ; ASCII m
AMINUS              equ       $2D                 ; ASCII -

;*******************************************************************************
; The following information describes some of the timing and housekeeping
; structures used by the CSS.

BDYR                equ       1                   ; The year we take as a starting point (2001)
BDWDAY              equ       7                   ; Saturday HB Stephens birthday on 8/25/2001
BDDAY               equ       25                  ; 25th day
BDMON               equ       8                   ; August
BDLEAP              equ       1                   ; 2001 was not a leap year

;*******************************************************************************
; These are commands used by the DS1820 Temp devices
;*******************************************************************************

READROM             equ       $33                 ; Read ROM sends the DS1820 ROM back to master
MACHROM             equ       $55                 ; Match ROM tell only this DS1820 to talk
SKIPROM             equ       $CC                 ; Skip the ROM sequence and do the command
TAKETMP             equ       $44                 ; Initiate the temperature conversion
READTMP             equ       $BE                 ; Read the temperature

;*******************************************************************************
                    #ROM
;*******************************************************************************
                    org       EEPROMS             ; Begin our code section

CSSTART             equ       *                   ; Cabin System Start of our RAM

          ; We begin by doing what BUFFFALO does.   Setting up the system

                    lda       #$93                ; ADPU, DLY, IRQE, COP
                    sta       OPTION              ; Turn on these options
                    clra                          ; Clear A
                    sta       TMSK2               ; Timer pre = %1 for trace
                    lds       #STACK              ; Setup our stack
                    jsr       VECINIT             ; Setup the interrupt vectors
                    jsr       BPCLR               ; Clear this table
                    clr       AUTOLF              ; Setup this flag
                    inc       AUTOLF              ; CR/LF is ON

          ; Here we initialize the ACIA and get it ready for action

                    lda       #$01                ; 0=SCI 1=ACIA
                    sta       EXTDEV              ; Save it here
                    sta       IODEV               ; Ditto
                    jsr       ONACIA              ; Initialize the ACIA

          ; Now we setup the SCI device which handles the CP290

                    jsr       HOSTCO              ; Conntect the host to the EVB
                    jsr       ONSCI               ; Initialize the CP290 port
                    jmp       STARTUP             ; Jump over the data section into the start

                    lda       #$50                ; To enable the stop command
                    tap                           ; Put it in the CC register
                    stop                          ; This is here to halt the CPU on runaway

          ; Here begins the constants

VERSION             fcb       CSBUILD             ; Save area for system build version

;*******************************************************************************
; Here we begin the static data area
;*******************************************************************************

VMSMSG              fcb       CRETURN
                    fcb       HORZTAB
                    fcc       'Unauthorized access to this system is prohibited.'
                    fcb       CRETURN
                    fcb       EOTEXT

VMSMSG1             fcc       'Username: '
                    fcb       EOTEXT

VMSMSG2             fcc       'Password: '
                    fcb       EOTEXT

VMSMSG3             fcb       CRETURN
                    fcb       CRETURN
                    fcb       HORZTAB
                    fcb       HORZTAB
                    fcc       'Welcome to the Cabin System V1.'
                    fcb       EOTEXT

VMSMSG4             fcb       CRETURN
                    fcc       'User authorization failure'
                    fcb       EOTEXT

VMSMSG5             fcb       ESCAPE              ; Setup VT100 command sequence
                    fcc       '[61"p'
                    fcb       EOTEXT

CWORD               fcs       'CQ'                ; Short command to dump lower memory
PWORD               fcs       'HBSTEPHENS'

DSPMSG1             fcc       'Unsuccessful attempts:'
                    fcb       HORZTAB
                    fcb       EOTEXT

DSPMSG2             fcb       CRETURN
                    fcb       CRETURN
                    fcb       HORZTAB
                    fcb       HORZTAB
                    fcc       'Cabin Software Command Menu'
                    fcb       CRETURN
                    fcb       CRETURN
                    fcb       HORZTAB
                    fcc       '1 - Display current conditions'
                    fcb       CRETURN
                    fcb       HORZTAB
                    fcc       '2 - Display max/min history'
                    fcb       CRETURN
                    fcb       HORZTAB
                    fcc       '3 - Display Door status'
                    fcb       CRETURN
                    fcb       HORZTAB
                    fcc       '4 - Display CSS status'
                    fcb       CRETURN
                    fcb       HORZTAB
                    fcc       '5 - Upload history data'
                    fcb       CRETURN
                    fcb       HORZTAB
                    fcc       '6 - Enter X10 conversation'
                    fcb       CRETURN
                    fcb       HORZTAB
                    fcc       '7 - Set CSS time'
                    fcb       CRETURN
                    fcb       HORZTAB
                    fcc       '8 - Maintenance mode'
                    fcb       CRETURN
                    fcb       HORZTAB
                    fcc       '0 - Exit the Cabin System'
                    fcb       CRETURN
                    fcb       CRETURN
                    fcb       HORZTAB
                    fcc       'Enter Selection: '
                    fcb       EOTEXT

DSPMSG3             fcb       CRETURN
                    fcb       CRETURN
                    fcb       HORZTAB
                    fcc       'WARNING! WARNING! WARNING!'
                    fcb       CRETURN
                    fcb       CRETURN
                    fcb       HORZTAB
                    fcc       'Control must be returned to the Cabin System after using'
                    fcb       CRETURN
                    fcb       HORZTAB
                    fcc       'BUFFALO or remote access will be lost!  Type the command:'
                    fcb       CRETURN
                    fcb       HORZTAB
                    fcc       'G B600   to return to the Cabin System'
                    fcb       CRETURN
                    fcb       EOTEXT

ASKYSNO             fcb       CRETURN
                    fcb       CRETURN
                    fcb       HORZTAB
                    fcc       'Are you sure? Y/<N> '
                    fcb       EOTEXT

DSPMSG4             fcb       CRETURN
                    fcc       'Upload History Data.  Ready PC for ASCII Upload in 10 sec.'
                    fcb       EOTEXT

DSPMSG5             fcb       CRETURN
                    fcc       'Function complete.  <Enter> to continue.'
                    fcb       EOTEXT

DSPMSG6             fcc       'Entering CP290 transparant mode.  Use BREAK to return to CSS'
                    fcb       CRETURN
                    fcb       EOTEXT

DSPMSG7             fcc       'Max/Min history'
                    fcb       CRETURN
                    fcb       CRETURN
                    fcb       HORZTAB
                    fcc       'Location'
                    fcb       HORZTAB
                    fcc       'Low'
                    fcb       HORZTAB
                    fcc       'Date'
                    fcb       HORZTAB
                    fcb       HORZTAB
                    fcc       'High'
                    fcb       HORZTAB
                    fcc       'Date'
                    fcb       CRETURN
                    fcb       EOTEXT

DSPMSG8             fcb       CRETURN
                    fcc       'Current Cabin Conditions'
                    fcb       CRETURN
                    fcb       CRETURN
                    fcb       HORZTAB
                    fcc       'Location'
                    fcb       HORZTAB
                    fcc       'Temperature'
                    fcb       CRETURN
                    fcb       EOTEXT

DSPMSG9             fcc       'Until next time...goodbye from colorful Colorado'
                    fcb       EOTEXT

DSPMSGB             fcc       'ATH0'
                    fcb       CRETURN
                    fcb       EOTEXT

DSPMSGC             fcc       'Successful logins: '
                    fcb       HORZTAB
                    fcb       EOTEXT

DSPMSGD             fcb       CRETURN
                    fcc       'Warning - CP290 has lost all data'
                    fcb       EOTEXT

DSPMSGE             fcb       CRETURN
                    fcc       'Cabin System time:'
                    fcb       HORZTAB
                    fcb       EOTEXT

DSPMSGF             fcc       'Functional since:'
                    fcb       HORZTAB
                    fcb       EOTEXT

DSPMSGG             fcc       'Power restored:  '
                    fcb       HORZTAB
                    fcb       EOTEXT

DSPMSGH             fcc       'Last user login time:'
                    fcb       HORZTAB
                    fcb       EOTEXT

DSPMSGI             fcb       CRETURN
                    fcb       HORZTAB
                    fcc       'Cabin System Door Status'
                    fcb       EOTEXT

DSPMSGJ             fcc       'Number history days:'
                    fcb       HORZTAB
                    fcb       EOTEXT

DSPMSGK             fcc       '<none>'
                    fcb       EOTEXT

DSPMSGL             fcc       'Power fail scan: '
                    fcb       HORZTAB
                    fcb       EOTEXT

DSPMSGM             fcb       CRETURN
                    fcc       'NOTE: History upload will take ~ 2min 40sec @ 2400 baud'
                    fcb       CRETURN
                    fcb       EOTEXT

DNWAIT              fcb       CRETURN
                    fcb       HORZTAB
                    fcc       'Loading CP290...wait 30 sec'
                    fcb       EOTEXT

HACMSG1             fcb       ESCAPE              ; VT100 escape sequence to home and clear screen
                    fcc       '[2J'
                    fcb       EOTEXT

HACMSG2             fcb       ESCAPE              ; VT100 escape sequence to home cursor
                    fcc       '[H'
                    fcb       EOTEXT

ASKTDAY             fcb       CRETURN             ; Ask time/date
                    fcb       LINFEED
                    fcc       'Please enter the time as follows: YY-MM-DD:HH:MM '
                    fcb       EOTEXT

; This table is used for the display of the door information

MDOOR               fcb       CRETURN
                    fcc       'Front'             ; Main door
                    fcb       EOTEXT
BDOOR               fcb       CRETURN
                    fcc       'Basement'          ; Basement door
                    fcb       EOTEXT
NDOOR               fcb       CRETURN
                    fcc       'N Garage'          ; North Garage door
                    fcb       EOTEXT
SDOOR               fcb       CRETURN
                    fcc       'S Garage'          ; South Garage door
                    fcb       EOTEXT

DOORTBL             fdb       MDOOR
                    fdb       BDOOR
                    fdb       NDOOR
                    fdb       SDOOR

DOORATE             fdb       SMDOOR              ; Index table into the door status area
                    fdb       SBDOOR
                    fdb       SNDOOR
                    fdb       SSDOOR

DCLOSED             fcc       ' door is closed',EOTEXT
DOPENED             fcc       ' door is OPEN!!',EOTEXT
DCYCLED             fcb       HORZTAB
                    fcc       'Open/Close count: ',EOTEXT
DLOPEND             fcb       HORZTAB
                    fcc       'Last opened: ',EOTEXT
DLCLOSE             fcb       HORZTAB
                    fcc       'Last closed: ',EOTEXT

DAYMON              equ       *                   ; Day of Month table
                    fcb       0                   ; We index from 1 so first is blank
                    fcb       31                  ; January
                    fcb       28                  ; February
                    fcb       31                  ; March
                    fcb       30                  ; April
                    fcb       31                  ; May
                    fcb       30                  ; June
                    fcb       31                  ; July
                    fcb       31                  ; August
                    fcb       30                  ; September
                    fcb       31                  ; October
                    fcb       30                  ; November
                    fcb       31                  ; December

;       Month Text Table

MONTH1              fcc       'January ',EOTEXT
MONTH2              fcc       'February ',EOTEXT
MONTH3              fcc       'March ',EOTEXT
MONTH4              fcc       'April ',EOTEXT
MONTH5              fcc       'May ',EOTEXT
MONTH6              fcc       'June ',EOTEXT
MONTH7              fcc       'July ',EOTEXT
MONTH8              fcc       'August ',EOTEXT
MONTH9              fcc       'September ',EOTEXT
MONTH10             fcc       'October ',EOTEXT
MONTH11             fcc       'November ',EOTEXT
MONTH12             fcc       'December ',EOTEXT

MTABLE              equ       *                   ; Month Table for indexing
                    fdb       0                   ; We index from 1 - 12
                    fdb       MONTH1
                    fdb       MONTH2
                    fdb       MONTH3
                    fdb       MONTH4
                    fdb       MONTH5
                    fdb       MONTH6
                    fdb       MONTH7
                    fdb       MONTH8
                    fdb       MONTH9
                    fdb       MONTH10
                    fdb       MONTH11
                    fdb       MONTH12

; Week days text table
WKDAY1              fcc       'Sunday ',EOTEXT
WKDAY2              fcc       'Monday ',EOTEXT
WKDAY3              fcc       'Tuesday ',EOTEXT
WKDAY4              fcc       'Wednesday ',EOTEXT
WKDAY5              fcc       'Thursday ',EOTEXT
WKDAY6              fcc       'Friday ',EOTEXT
WKDAY7              fcc       'Saturday ',EOTEXT

DAYOFWK             equ       *                   ; Day of Week table
                    fdb       0                   ; This table is indexed from 1-7
                    fdb       WKDAY1              ; Sunday
                    fdb       WKDAY2              ; Monday
                    fdb       WKDAY3              ; Tuesday
                    fdb       WKDAY4              ; Wednesday
                    fdb       WKDAY5              ; Thursday
                    fdb       WKDAY6              ; Friday
                    fdb       WKDAY7              ; Saturday

DAYMAP              equ       *                   ; Maps the Actual Day to the CP290
                    fcb       0                   ; We index from 1
                    fcb       $40                 ; Sunday
                    fcb       $01                 ; Monday
                    fcb       $02                 ; Tuesday
                    fcb       $04                 ; Wednesday
                    fcb       $08                 ; Thursday
                    fcb       $10                 ; Friday
                    fcb       $20                 ; Saturday

SHOWT20             equ       *
                    fcc       ', 20'
                    fcb       EOTEXT

LCDSIP              equ       *                   ; This is the init sequence for the LCD
                    fcb       $38
                    fcb       $38
                    fcb       $38
                    fcb       $0F
                    fcb       $01
                    fcb       $06
                    fcb       EOTEXT

LCDWEL              equ       *                   ; Welcome messasge for the LCD
;                1234567890123456
                    fcc       'Cabin System Up!'
                    fcb       EOTEXT

LCDISOK             fcc       'Normal Operation',EOTEXT

LCDCPAS             equ       *                   ; Sending data between the PeeCee & CP290
                    fcc       'CP290 - Passthru',EOTEXT

LCDRMT              equ       *                   ; In progress with remote system
                    fcc       'Servicing Remote',EOTEXT

CPDOWN              fcc       'CP290 - failure!',EOTEXT

LCDSCAN             equ       *                   ; We are in a event scan from the CP290
                    fcc       'Sensor Data Scan'
                    fcb       EOTEXT

LCDSAVE             equ       *                   ; We are saving data into the CP290
                    fcc       'Saving VitalData',EOTEXT

LCDREST             equ       *                   ; We are restoring data from the CP290
                    fcc       'Restor VitalData',EOTEXT

STATBLE             equ       *                   ; State table for LCD display
                    fdb       TMPDSP1             ; S Attic
                    fdb       TMPDSP2             ; East Outside
                    fdb       TMPDSP3             ; North Outside
                    fdb       TMPDSP4             ; Pump Area
                    fdb       TMPDSP5             ; Basement
                    fdb       TMPDSP6             ; South Bedroom
                    fdb       TMPDSP7             ; Kitchen
                    fdb       TMPDSP8             ; Internal
                    fdb       CURDSP1             ; Pressure
                    fdb       CURDSP2             ; Rain Fall
                    fdb       CURDSP3             ; Relative light
                    fdb       CURDSP4             ; Wind Speed
                    fdb       CURDSP5             ; Direction

; These states are special informational events

                    fdb       LCDISOK             ; 13 - I'm in my main service loop
                    fdb       LCDWEL              ; 14 - I'm up and running
                    fdb       LCDCPAS             ; 15 - I'm in pass thru with the CP290
                    fdb       LCDRMT              ; 16 - The modem is now in control
                    fdb       CPDOWN              ; 17 - The CP290 is not responding
                    fdb       LCDSCAN             ; 18 - History data scan from CP290
                    fdb       LCDSAVE             ; 19 - Saving data to the CP290
                    fdb       LCDREST             ; 20 - Restoring data from CP290

;**************************************************************************
;  The equates describe the state of the LCD display

STMAIN              equ       13                  ; I'm in my main service loop
STRUN               equ       14                  ; I'm up and running
STPASS              equ       15                  ; I'm in pass thru with the CP290
STMODEM             equ       16                  ; The modem is now in control
STCPDN              equ       17                  ; The CP290 is not responding
STSCAN              equ       18                  ; We are gathering sensor data
STSAVE              equ       19                  ; We are saving data into the CP290
STREST              equ       20                  ; We are restoring data from the CP290

; The following table is used as a JSR table for the user commands
; NOTE: The order here must match the user's selection.

CMDTBLE             equ       *
                    fdb       DODSPBY             ; 0 - Hang up the phone...user is leaving
                    fdb       DODSPCC             ; 1 - Do Display Current Conditions
                    fdb       DODSPMM             ; 2 - Do Display Max and Min Values
                    fdb       SHODOOR             ; 3 - Display Door status and time
                    fdb       SHOWCSS             ; 4 - Display CSS status and time
                    fdb       DODSPUD             ; 5 - Do History data upload
                    fdb       DODSPTM             ; 6 - Enter transparent mode with CP290
                    fdb       SETUPCP             ; 7 - Setup the time and CP290
                    fdb       DODEBUG             ; 8 - Go to BUFFALO
MAXCMDS             equ       $38                 ; In ASCII - Maximum number of user commands

; The following tables are used to printout the wind direction.
; When enabled, PORT C contains one or more of the values WINVAL

WINDIR              fcc       'E S W N SESWNWNE'

WINVAL              fcb       $80                 ; East
                    fcb       $20                 ; South
                    fcb       $08                 ; West
                    fcb       $02                 ; North
                    fcb       $40                 ; South East
                    fcb       $10                 ; South West
                    fcb       $04                 ; North West
                    fcb       $01                 ; North East
                    fcb       $00                 ; End of table

DS18201             equ       *                   ; 64 bit ROM code for DS1820 #1
                    fcb       $10
                    fcb       $4A
                    fcb       $2B
                    fcb       $02
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $CE
DS18202             equ       *                   ; 64 bit ROM code for DS1820 #2
                    fcb       $10
                    fcb       $85
                    fcb       $2B
                    fcb       $02
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $75
DS18203             equ       *                   ; 64 bit ROM code for DS1820 #3
                    fcb       $10
                    fcb       $2F
                    fcb       $2B
                    fcb       $02
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $E6
DS18204             equ       *                   ; 64 bit ROM code for DS1820 #4
                    fcb       $10
                    fcb       $5B
                    fcb       $2C
                    fcb       $02
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $F3
DS18205             equ       *                   ; 64 bit ROM code for DS1820 #5
                    fcb       $10
                    fcb       $07
                    fcb       $2C
                    fcb       $02
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $A0
DS18206             equ       *                   ; 64 bit ROM code for DS1820 #6
                    fcb       $10
                    fcb       $5E
                    fcb       $0C
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $E7
DS18207             equ       *                   ; 64 bit ROM code for DS1820 #7
                    fcb       $10
                    fcb       $A3
                    fcb       $2B
                    fcb       $02
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $71
DS18208             equ       *                   ; 64 bit ROM code for DS1820 #8
                    fcb       $10
                    fcb       $A4
                    fcb       $06
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $E7

; These are the pointers to the ROM codes for the temperature sensors

TMPIDX              fdb       DS18201             ; South Attic
                    fdb       DS18202             ; East Outside
                    fdb       DS18203             ; North Outside
                    fdb       DS18204             ; Pump Area
                    fdb       DS18205             ; Basement
                    fdb       DS18206             ; South Bedroom
                    fdb       DS18207             ; Kitchen
                    fdb       DS18208             ; Internal

TMPDSP1             equ       *
                    fcc       'South Attic '
                    fcb       EOTEXT
TMPDSP2             equ       *
                    fcc       'East Outsid '
                    fcb       EOTEXT
TMPDSP3             equ       *
                    fcc       'North Deck  '
                    fcb       EOTEXT
TMPDSP4             equ       *
                    fcc       'Pump Area   '
                    fcb       EOTEXT
TMPDSP5             equ       *
                    fcc       'Basement    '
                    fcb       EOTEXT
TMPDSP6             equ       *
                    fcc       'South Bedrm '
                    fcb       EOTEXT
TMPDSP7             equ       *
                    fcc       'Kitchen     '
                    fcb       EOTEXT
TMPDSP8             equ       *
                    fcc       'Internal    '
                    fcb       EOTEXT

TMPCTAB             equ       *                   ; Printout adjustment
                    fcb       CRETURN
TMPHORZ             equ       *
                    fcb       HORZTAB
                    fcb       EOTEXT

CURDSP1             equ       *
                    fcc       'Presssure   '
                    fcb       EOTEXT
CURDSP2             equ       *
                    fcc       'Rain Fall   '
                    fcb       EOTEXT
CURDSP3             equ       *
                    fcc       'Rel Light   '
                    fcb       EOTEXT
CURDSP4             equ       *
                    fcc       'Wind Speed  '
                    fcb       EOTEXT
CURDSP5             equ       *
                    fcc       'Wind Dir    '
                    fcb       EOTEXT

; This is the temperature conversion table.   From what we are given
; from the DS1820 which measures the temp in .5 increments of Centigrade
; We make the conversion between this and Fahrenheit (1.8 * C) + 32
; The value given from the DS1820 is taken, we add 124 which give our
; index into this table.

;      Reported          T oC    T oF   1820  Index
;        T oF                           Value  -1

TMPTTBL             equ       *
                    fcb       -79                 ; -62.00 -79.60 FF84 1
                    fcb       -78                 ; -61.50 -78.70 FF85 2
                    fcb       -77                 ; -61.00 -77.80 FF86 3
                    fcb       -76                 ; -60.50 -76.90 FF87 4
                    fcb       -76                 ; -60.00 -76.00 FF88 5
                    fcb       -75                 ; -59.50 -75.10 FF89 6
                    fcb       -74                 ; -59.00 -74.20 FF8A 7
                    fcb       -73                 ; -58.50 -73.30 FF8B 8
                    fcb       -72                 ; -58.00 -72.40 FF8C 9
                    fcb       -71                 ; -57.50 -71.50 FF8D 10
                    fcb       -70                 ; -57.00 -70.60 FF8E 11
                    fcb       -69                 ; -56.50 -69.70 FF8F 12
                    fcb       -68                 ; -56.00 -68.80 FF90 13
                    fcb       -67                 ; -55.50 -67.90 FF91 14
                    fcb       -67                 ; -55.00 -67.00 FF92 15
                    fcb       -66                 ; -54.50 -66.10 FF93 16
                    fcb       -65                 ; -54.00 -65.20 FF94 17
                    fcb       -64                 ; -53.50 -64.30 FF95 18
                    fcb       -63                 ; -53.00 -63.40 FF96 19
                    fcb       -62                 ; -52.50 -62.50 FF97 20
                    fcb       -61                 ; -52.00 -61.60 FF98 21
                    fcb       -60                 ; -51.50 -60.70 FF99 22
                    fcb       -59                 ; -51.00 -59.80 FF9A 23
                    fcb       -58                 ; -50.50 -58.90 FF9B 24
                    fcb       -58                 ; -50.00 -58.00 FF9C 25
                    fcb       -57                 ; -49.50 -57.10 FF9D 26
                    fcb       -56                 ; -49.00 -56.20 FF9E 27
                    fcb       -55                 ; -48.50 -55.30 FF9F 28
                    fcb       -54                 ; -48.00 -54.40 FFA0 29
                    fcb       -53                 ; -47.50 -53.50 FFA1 30
                    fcb       -52                 ; -47.00 -52.60 FFA2 31
                    fcb       -51                 ; -46.50 -51.70 FFA3 32
                    fcb       -50                 ; -46.00 -50.80 FFA4 33
                    fcb       -49                 ; -45.50 -49.90 FFA5 34
                    fcb       -49                 ; -45.00 -49.00 FFA6 35
                    fcb       -48                 ; -44.50 -48.10 FFA7 36
                    fcb       -47                 ; -44.00 -47.20 FFA8 37
                    fcb       -46                 ; -43.50 -46.30 FFA9 38
                    fcb       -45                 ; -43.00 -45.40 FFAA 39
                    fcb       -44                 ; -42.50 -44.50 FFAB 40
                    fcb       -43                 ; -42.00 -43.60 FFAC 41
                    fcb       -42                 ; -41.50 -42.70 FFAD 42
                    fcb       -41                 ; -41.00 -41.80 FFAE 43
                    fcb       -40                 ; -40.50 -40.90 FFAF 44
                    fcb       -40                 ; -40.00 -40.00 FFB0 45
                    fcb       -39                 ; -39.50 -39.10 FFB1 46
                    fcb       -38                 ; -39.00 -38.20 FFB2 47
                    fcb       -37                 ; -38.50 -37.30 FFB3 48
                    fcb       -36                 ; -38.00 -36.40 FFB4 49
                    fcb       -35                 ; -37.50 -35.50 FFB5 50
                    fcb       -34                 ; -37.00 -34.60 FFB6 51
                    fcb       -33                 ; -36.50 -33.70 FFB7 52
                    fcb       -32                 ; -36.00 -32.80 FFB8 53
                    fcb       -31                 ; -35.50 -31.90 FFB9 54
                    fcb       -31                 ; -35.00 -31.00 FFBA 55
                    fcb       -30                 ; -34.50 -30.10 FFBB 56
                    fcb       -29                 ; -34.00 -29.20 FFBC 57
                    fcb       -28                 ; -33.50 -28.30 FFBD 58
                    fcb       -27                 ; -33.00 -27.40 FFBE 59
                    fcb       -26                 ; -32.50 -26.50 FFBF 60
                    fcb       -25                 ; -32.00 -25.60 FFC0 61
                    fcb       -24                 ; -31.50 -24.70 FFC1 62
                    fcb       -23                 ; -31.00 -23.80 FFC2 63
                    fcb       -22                 ; -30.50 -22.90 FFC3 64
                    fcb       -22                 ; -30.00 -22.00 FFC4 65
                    fcb       -21                 ; -29.50 -21.10 FFC5 66
                    fcb       -20                 ; -29.00 -20.20 FFC6 67
                    fcb       -19                 ; -28.50 -19.30 FFC7 68
                    fcb       -18                 ; -28.00 -18.40 FFC8 69
                    fcb       -17                 ; -27.50 -17.50 FFC9 70
                    fcb       -16                 ; -27.00 -16.60 FFCA 71
                    fcb       -15                 ; -26.50 -15.70 FFCB 72
                    fcb       -14                 ; -26.00 -14.80 FFCC 73
                    fcb       -13                 ; -25.50 -13.90 FFCD 74
                    fcb       -13                 ; -25.00 -13.00 FFCE 75
                    fcb       -12                 ; -24.50 -12.10 FFCF 76
                    fcb       -11                 ; -24.00 -11.20 FFD0 77
                    fcb       -10                 ; -23.50 -10.30 FFD1 78
                    fcb       -9                  ; -23.00 -9.40 FFD2 79
                    fcb       -8                  ; -22.50 -8.50 FFD3 80
                    fcb       -7                  ; -22.00 -7.60 FFD4 81
                    fcb       -6                  ; -21.50 -6.70 FFD5 82
                    fcb       -5                  ; -21.00 -5.80 FFD6 83
                    fcb       -4                  ; -20.50 -4.90 FFD7 84
                    fcb       -4                  ; -20.00 -4.00 FFD8 85
                    fcb       -3                  ; -19.50 -3.10 FFD9 86
                    fcb       -2                  ; -19.00 -2.20 FFDA 87
                    fcb       -1                  ; -18.50 -1.30 FFDB 88
                    fcb       0                   ; -18.00 -0.40 FFDC 89
                    fcb       0                   ; -17.50 0.50 FFDD 90
                    fcb       1                   ; -17.00 1.40 FFDE 91
                    fcb       2                   ; -16.50 2.30 FFDF 92
                    fcb       3                   ; -16.00 3.20 FFE0 93
                    fcb       4                   ; -15.50 4.10 FFE1 94
                    fcb       5                   ; -15.00 5.00 FFE2 95
                    fcb       6                   ; -14.50 5.90 FFE3 96
                    fcb       7                   ; -14.00 6.80 FFE4 97
                    fcb       8                   ; -13.50 7.70 FFE5 98
                    fcb       9                   ; -13.00 8.60 FFE6 99
                    fcb       9                   ; -12.50 9.50 FFE7 100
                    fcb       10                  ; -12.00 10.40 FFE8 101
                    fcb       11                  ; -11.50 11.30 FFE9 102
                    fcb       12                  ; -11.00 12.20 FFEA 103
                    fcb       13                  ; -10.50 13.10 FFEB 104
                    fcb       14                  ; -10.00 14.00 FFEC 105
                    fcb       15                  ; -9.50 14.90 FFED 106
                    fcb       16                  ; -9.00 15.80 FFEE 107
                    fcb       17                  ; -8.50 16.70 FFEF 108
                    fcb       18                  ; -8.00 17.60 FFF0 109
                    fcb       18                  ; -7.50 18.50 FFF1 110
                    fcb       19                  ; -7.00 19.40 FFF2 111
                    fcb       20                  ; -6.50 20.30 FFF3 112
                    fcb       21                  ; -6.00 21.20 FFF4 113
                    fcb       22                  ; -5.50 22.10 FFF5 114
                    fcb       23                  ; -5.00 23.00 FFF6 115
                    fcb       24                  ; -4.50 23.90 FFF7 116
                    fcb       25                  ; -4.00 24.80 FFF8 117
                    fcb       26                  ; -3.50 25.70 FFF9 118
                    fcb       27                  ; -3.00 26.60 FFFA 119
                    fcb       27                  ; -2.50 27.50 FFFB 120
                    fcb       28                  ; -2.00 28.40 FFFC 121
                    fcb       29                  ; -1.50 29.30 FFFD 122
                    fcb       30                  ; -1.00 30.20 FFFE 123
                    fcb       31                  ; -0.50 31.10 FFFF 124
                    fcb       32                  ; 0.00 32.00 0000 125
                    fcb       33                  ; 0.50 32.90 0001 126
                    fcb       34                  ; 1.00 33.80 0002 127
                    fcb       35                  ; 1.50 34.70 0003 128
                    fcb       36                  ; 2.00 35.60 0004 129
                    fcb       36                  ; 2.50 36.50 0005 130
                    fcb       37                  ; 3.00 37.40 0006 131
                    fcb       38                  ; 3.50 38.30 0007 132
                    fcb       39                  ; 4.00 39.20 0008 133
                    fcb       40                  ; 4.50 40.10 0009 134
                    fcb       41                  ; 5.00 41.00 000A 135
                    fcb       42                  ; 5.50 41.90 000B 136
                    fcb       43                  ; 6.00 42.80 000C 137
                    fcb       44                  ; 6.50 43.70 000D 138
                    fcb       45                  ; 7.00 44.60 000E 139
                    fcb       45                  ; 7.50 45.50 000F 140
                    fcb       46                  ; 8.00 46.40 0010 141
                    fcb       47                  ; 8.50 47.30 0011 142
                    fcb       48                  ; 9.00 48.20 0012 143
                    fcb       49                  ; 9.50 49.10 0013 144
                    fcb       50                  ; 10.00 50.00 0014 145
                    fcb       51                  ; 10.50 50.90 0015 146
                    fcb       52                  ; 11.00 51.80 0016 147
                    fcb       53                  ; 11.50 52.70 0017 148
                    fcb       54                  ; 12.00 53.60 0018 149
                    fcb       54                  ; 12.50 54.50 0019 150
                    fcb       55                  ; 13.00 55.40 001A 151
                    fcb       56                  ; 13.50 56.30 001B 152
                    fcb       57                  ; 14.00 57.20 001C 153
                    fcb       58                  ; 14.50 58.10 001D 154
                    fcb       59                  ; 15.00 59.00 001E 155
                    fcb       60                  ; 15.50 59.90 001F 156
                    fcb       61                  ; 16.00 60.80 0020 157
                    fcb       62                  ; 16.50 61.70 0021 158
                    fcb       63                  ; 17.00 62.60 0022 159
                    fcb       63                  ; 17.50 63.50 0023 160
                    fcb       64                  ; 18.00 64.40 0024 161
                    fcb       65                  ; 18.50 65.30 0025 162
                    fcb       66                  ; 19.00 66.20 0026 163
                    fcb       67                  ; 19.50 67.10 0027 164
                    fcb       68                  ; 20.00 68.00 0028 165
                    fcb       69                  ; 20.50 68.90 0029 166
                    fcb       70                  ; 21.00 69.80 002A 167
                    fcb       71                  ; 21.50 70.70 002B 168
                    fcb       72                  ; 22.00 71.60 002C 169
                    fcb       72                  ; 22.50 72.50 002D 170
                    fcb       73                  ; 23.00 73.40 002E 171
                    fcb       74                  ; 23.50 74.30 002F 172
                    fcb       75                  ; 24.00 75.20 0030 173
                    fcb       76                  ; 24.50 76.10 0031 174
                    fcb       77                  ; 25.00 77.00 0032 175
                    fcb       78                  ; 25.50 77.90 0033 176
                    fcb       79                  ; 26.00 78.80 0034 177
                    fcb       80                  ; 26.50 79.70 0035 178
                    fcb       81                  ; 27.00 80.60 0036 179
                    fcb       81                  ; 27.50 81.50 0037 180
                    fcb       82                  ; 28.00 82.40 0038 181
                    fcb       83                  ; 28.50 83.30 0039 182
                    fcb       84                  ; 29.00 84.20 003A 183
                    fcb       85                  ; 29.50 85.10 003B 184
                    fcb       86                  ; 30.00 86.00 003C 185
                    fcb       87                  ; 30.50 86.90 003D 186
                    fcb       88                  ; 31.00 87.80 003E 187
                    fcb       89                  ; 31.50 88.70 003F 188
                    fcb       90                  ; 32.00 89.60 0040 189
                    fcb       90                  ; 32.50 90.50 0041 190
                    fcb       91                  ; 33.00 91.40 0042 191
                    fcb       92                  ; 33.50 92.30 0043 192
                    fcb       93                  ; 34.00 93.20 0044 193
                    fcb       94                  ; 34.50 94.10 0045 194
                    fcb       95                  ; 35.00 95.00 0046 195
                    fcb       96                  ; 35.50 95.90 0047 196
                    fcb       97                  ; 36.00 96.80 0048 197
                    fcb       98                  ; 36.50 97.70 0049 198
                    fcb       99                  ; 37.00 98.60 004A 199
                    fcb       99                  ; 37.50 99.50 004B 200
                    fcb       100                 ; 38.00 100.40 004C 201
                    fcb       101                 ; 38.50 101.30 004D 202
                    fcb       102                 ; 39.00 102.20 004E 203
                    fcb       103                 ; 39.50 103.10 004F 204
                    fcb       104                 ; 40.00 104.00 0050 205
                    fcb       105                 ; 40.50 104.90 0051 206
                    fcb       106                 ; 41.00 105.80 0052 207
                    fcb       107                 ; 41.50 106.70 0053 208
                    fcb       108                 ; 42.00 107.60 0054 209
                    fcb       108                 ; 42.50 108.50 0055 210
                    fcb       109                 ; 43.00 109.40 0056 211
                    fcb       110                 ; 43.50 110.30 0057 212
                    fcb       111                 ; 44.00 111.20 0058 213
                    fcb       112                 ; 44.50 112.10 0059 214
                    fcb       113                 ; 45.00 113.00 005A 215
                    fcb       114                 ; 45.50 113.90 005B 216
                    fcb       115                 ; 46.00 114.80 005C 217
                    fcb       116                 ; 46.50 115.70 005D 218
                    fcb       117                 ; 47.00 116.60 005E 219
                    fcb       117                 ; 47.50 117.50 005F 220
                    fcb       118                 ; 48.00 118.40 0060 221
                    fcb       119                 ; 48.50 119.30 0061 222
                    fcb       120                 ; 49.00 120.20 0062 223
                    fcb       121                 ; 49.50 121.10 0063 224
                    fcb       122                 ; 50.00 122.00 0064 225
                    fcb       123                 ; 50.50 122.90 0065 226
                    fcb       124                 ; 51.00 123.80 0066 227
                    fcb       125                 ; 51.50 124.70 0067 228
                    fcb       126                 ; 52.00 125.60 0068 229
                    fcb       126                 ; 52.50 126.50 0069 230
                    fcb       127                 ; 53.00 127.40 006A 231
                    fcb       128                 ; 53.50 128.30 006B 232
                    fcb       129                 ; 54.00 129.20 006C 233
                    fcb       130                 ; 54.50 130.10 006D 234
                    fcb       131                 ; 55.00 131.00 006E 235
                    fcb       132                 ; 55.50 131.90 006F 236
                    fcb       133                 ; 56.00 132.80 0070 237
                    fcb       134                 ; 56.50 133.70 0071 238
                    fcb       135                 ; 57.00 134.60 0072 239
                    fcb       135                 ; 57.50 135.50 0073 240
                    fcb       136                 ; 58.00 136.40 0074 241
                    fcb       137                 ; 58.50 137.30 0075 242
                    fcb       138                 ; 59.00 138.20 0076 243
                    fcb       139                 ; 59.50 139.10 0077 244
                    fcb       140                 ; 60.00 140.00 0078 245
                    fcb       141                 ; 60.50 140.90 0079 246
                    fcb       142                 ; 61.00 141.80 007A 247
                    fcb       143                 ; 61.50 142.70 007B 248
                    fcb       144                 ; 62.00 143.60 007C 249
                    fcb       144                 ; 62.50 144.50 007D 250
                    fcb       145                 ; 63.00 145.40 007E 251
                    fcb       146                 ; 63.50 146.30 007F 252
                    fcb       147                 ; 64.00 147.20 0080 253
                    fcb       148                 ; 64.50 148.10 0081 254
                    fcb       149                 ; 65.00 149.00 0082 255
                    fcb       150                 ; 65.50 149.90 0083 256

;**************************************************************************
; START - Cabin System Software (CSS) begins execution
;**************************************************************************

STARTUP             proc                          ; In the beginning...
                    bsr       CSSINIT             ; Initialize the system and variables

; Here is our major loop:

;       1) Look for Modem activity
;       2) Look for CP290 activity
;       3) Look for Local activity

MAJLOOP             equ       *
                    jsr       CKMODEM             ; See if anyone is calling
                    bcc       MAJLOO1             ; No...jump
                    jsr       DOMODEM             ; Do modem activity

MAJLOO1             jsr       CKCP290             ; See if we need to do something
                    bcc       MAJLOO2             ; No...jump
                    jsr       DOCP290             ; Do the CP290 activity

MAJLOO2             jsr       CKLOCAL             ; See if someone local needs information.
                    bcc       MAJLOO3             ; No...jump
                    jsr       DOLOCAL             ; Do the Local activity

MAJLOO3             jsr       KEEPTIM             ; Make realtime display updates
                    bra       MAJLOOP             ; Continue major loop

                    lda       #$50                ; To enable the stop command
                    tap                           ; Put it in the CC register
                    stop                          ; This is here to halt the CPU on runaway

;**************************************************************************
; CSSINIT - CSS Initialization routine
;**************************************************************************
; Routine: This routine assumes we are just starting from power up.
;       RAM initialization, setup, and communication/health checks
;       are made.  We want to recognize a power failure by looking to
;       the CP290 for information.
;       There are two type of starts: COLD and WARM.   We inquire the
;       time of the the CP290.    If it is up and happy, then we assume
;       a WARM start, retrieve the stored data in the NVRAM of the CP290
;       and begin our execution.
;       If the CP290 does not have a good time, then we cold start the
;       system.   This implies restarting the CP290 from a fixed time,
;       and reinitialization of all data structures.

CSSINIT             proc
          ; Setup the system options to turn on the A/D converter

                    lda       #$90                ; Power up the A/D
                    sta       OPTION              ; ADPU + DLY
                    ldx       #PORTA              ; Address of port A
                    bset      ,x,#WINDON          ; Turn off the wind enable bit - LOW ACTIVE

          ; Next  we make sure the RAM is clean for startup

                    ldx       #STRRAM             ; Starting RAM address to clear
                    ldy       #NUMRAM             ; How many locations we must do
                    clra                          ; This is what we will load
                    coma                          ; All ones
CSSINI2             sta       ,x                  ; Store the value
                    inx                           ; Go to the next address
                    dey                           ; Count it down
                    bne       CSSINI2             ; Continue till we are done

                    clr       UNSIGN              ; Flag to ITOA conversion
                    clr       UNPAD               ; Flag to ITOA padding
                    jsr       CPINIT              ; Setup the host port for the CP290
                    jsr       LCDINIT             ; Setup the LCD

          ; Here we wait 10 seconds to give the CP290 a chance to get started

                    lda       #10                 ; Wait 10 seconds
CSCINI4             sta       PORTB               ; Just as an indication we are alive
                    jsr       WAITONE             ; Delay
                    deca                          ; Count down
                    bne       CSCINI4             ; Continue till we are done

          ; Now get the data and time from the CP290...if unit has lost all
          ; data then assume a cold start and reset everything

                    jsr       GETDATE             ; Fetch the CP290 time first to see if OK
                    bcc       CSSINI5             ; The date is bad...this is a cold start
                    ldy       #WRMDATE            ; Location to save into
                    jsr       SAVTIME             ; Temporary save...just need CURHR/MIN time
                    jsr       UPSAVED             ; Get the saved data from the CP290
                    bcc       CSSINI5             ; Jump...data is gone we have a cold start!
                    ldy       #SCNDATE            ; Save area for last scan before power fail
                    jsr       SAVTIME             ; Move the CURTIM here for the printout
                    ldy       #WRMDATE            ; Here we adjust the CURHR/MIN for warm start
                    lda       1,y                 ; Get CURHR
                    sta       CURHR               ; Save it back
                    lda       3,y                 ; Get CURMIN
                    sta       CURMIN              ; Save it back
                    jsr       SAVTIME             ; Copy the time we began from powerfail
                    ldy       #DSPTIM             ; Copy the current time into the display time
                    jsr       SAVTIME             ; This is to setup display time for WHATDAY
                    jsr       WHATDAY             ; All of this to just set the WKWDAY value
                    bra       CSSINI8             ; The date is good...this is a warm start

          ; Here we have a cold start...data in the CP290 is gone
          ; So we must reload and begin from scratch and setup some defaults
          ; Here we start from our given birthday from power up condition

CSSINI5             lda       #BDYR               ; Birthday year
                    sta       CURYR               ; Save it
                    lda       #BDMON              ; Birthday month
                    sta       CURMON              ; Save it
                    lda       #BDDAY              ; Birthday day
                    sta       CURDAY              ; Save it
                    lda       #BDWDAY             ; Birthday day of the week
                    sta       WKWDAY              ; Save it
                    lda       #59                 ; Sixty seconds we count down
                    sta       CURSEC              ; Save it away
                    clr       CURHR               ; Starting from midnight
                    clr       CURMIN              ; The clock has chimed.

                    ldy       #WRMDATE            ; Location to save into
                    jsr       SAVTIME             ; Copy the time we began from powerfail
                    ldy       #SCNDATE            ; Save area for last scan before power fail
                    jsr       SAVTIME             ; Reset this date value as well
                    lda       #1                  ; One signon
                    sta       SIGNONG             ; Good signon count increment (NOTE: CP290 err)
                    jsr       SETUPC4             ; Save it all so we can come up clean

CSSINI8             equ       *
                    ldx       #HISTOP             ; Must reset the history forward link
                    stx       HFLINK              ; Save it for the next scan
                    clra                          ; Clear
                    clrb                          ; Ditto
                    std       NUMSCAN             ; Store zero in the number of scans
                    clr       CURDPTR             ; This is our history index...we start over
                    clr       NUMDPTR             ; We start over with number of history days
                    clr       DSPOINT             ; This is our display counter
                    clr       RAINFAL             ; This is our rainfall counter

          ; Here we setup the initial state of the MAX/MIN history values

                    jsr       SGATHER             ; Get the initial sensor conditions
                    jsr       HISETUP             ; Setup the values

                    lda       #40                 ; This will be a one second delay
                    jsr       DELAYIT             ; Setup the delay timer
                    rts                           ; Return to the main loop

;**************************************************************************
; SNDSNC - Sends the 16 byte sync bytes the CP290
;**************************************************************************
; Routine: Sends to the CP290 16 sync bytes to begin command transfer

SNDSNC              proc                          ; Send the 16byte sync to the CP290
                    ldb       #16                 ; We will do this 16 times
                    lda       #$FF                ; What to send

          ; Wait for the transmitter to finish any work already in progress

Loop@@              bsr       CPUT290             ; Send it out to the CP290
                    decb                          ; Count it down
                    bne       Loop@@              ; Do it again...until it is over
                    rts                           ; Back to the caller

;**************************************************************************
; CPUT290 - Sends a byte to the CP290
;**************************************************************************
; Routine: Sends the byte in A to the CP290
; All registers are saved

CPUT290             proc                          ; sends a byte the CP290
                    psha                          ; save the register

          ; Wait for the transmitter to finish any work already in progress

Loop@@              lda       SCSR                ; Get the SCI status register
                    bita      #$80                ; Check to see if we are still in transmit mode
                    beq       Loop@@              ; Continue to wait for transmitter to clear

          ; The transmitter is clear, now send the sync byte to the CP290

                    pula                          ; Restore the data value we are to send
                    sta       SCDAT               ; Send it to the CP290
                    rts                           ; Back to the caller

;**************************************************************************
; GETDATE - Routine to get the time/date from the CP290
;**************************************************************************
; Routine: Sends the sync bytes, then the command to get the date
;       from the CP290.
; Carry flag is set if date is fetched OK
; Carry flag is clear if we failed for some reason

GETDATE             proc                          ; Get the time/date from the CP290
                    ldx       #PCFIFO             ; Get the FIFO address
                    clr       6,x                 ; Clear the status value to assume failure.
                    bsr       SNDSNC              ; Send the sync bytes
                    lda       #REQCLK             ; Request Clock command
                    bsr       CPUT290             ; Send it to the CP290
                    lda       #12                 ; We expect to get these bytes back
                    bsr       GETCPD              ; Get the data from the CP290
                    tst       PCFPTR              ; Get the PC forward pointer
                    beq       Fail@@              ; Bad...we should have something

                    ldx       #PCFIFO             ; Get the FIFO address
                    lda       6,x                 ; Get the value
                    beq       Fail@@              ; Bad...we should have something

          ; Here we just want the hours and minutes and day

                    lda       7,x                 ; Get the value
                    sta       CURMIN              ; Minutes
                    lda       8,x                 ; Get the value
                    sta       CURHR               ; Hours
                    lda       9,x                 ; Get the value
                    sta       CURWDAY             ; Day of the week
                    sec                           ; Set carry to say we have date
                    bra       Done@@              ; Jump and return

Fail@@              clc                           ; We failed...
Done@@              rts                           ; Back to the caller

;**************************************************************************
; GETCPD - Receives a data message from the CP290
;**************************************************************************
; Routine: GETCPD is a general purpose routine to get information from
;       the CP290 and put the data into the buffer indicated by the index
;       register.   We don't want to get stuck waiting on the CP290
;       in case it dies for some reason, so we use the DELAY function
;       to serve as our exit point.   When the timer goes off we assume
;       we got all the data we were going to get, then we return to the
;       caller.
;       Register A contains the number of bytes we expect to receive back
; Output - The PCFIFO will contain the message from the CP290.   This is
;       because we are using a shared routine which places the data into
;       this buffer to be shipped to the PeeCee.

GETCPD              proc                          ; Get data from the CP290
                    psha                          ; save A
                    clr       PCFPTR              ; Clear PeeCee FIFO forward pointer
                    clr       PCFIFO              ; Clear first data byte in the FIFO
                    lda       #60                 ; This is 1 1/2 seconds (25msec * 60)
                    jsr       DELAYIT             ; Initialize the wait loop
                    pula                          ; Bring A back

Loop@@              psha                          ; save it for our looping
                    jsr       CP290IN             ; Get any data from the CP290
                    pula                          ; Get A back
                    cmpa      PCFPTR              ; See if we have done enough
                    beq       Done@@              ; Yes...jump and exit
                    jsr       DELAY               ; Check for time out
                    bcc       Loop@@              ; Continue to loop
Done@@              rts                           ; Back to the caller

;**************************************************************************
; CPTMPC - Transparent communication with CP290 and the PeeCee
;**************************************************************************
; Routine: This code places the CSS in transparent mode with the CP290
;       to allow the communication from the PeeCee.   The purpose is to
;       use standard X10 software when making setup changes with the
;       CP290.
; The BREAK transmitted from the PeeCee, or the modem dropping carrier
;       will get us out of the transparent loop

CPTMPC              proc                          ; Begin Transparent mode
                    clr       TFLAG               ; This will be our break counter
                    clr       CPFPTR              ; Clear CP290 FIFO forward pointer
                    clr       PCFPTR              ; Clear PeeCee FIFO forward pointer
                    clr       CPBPTR              ; Clear CP290 FIFO back pointer
                    clr       PCBPTR              ; Clear PeeCee FIFO back pointer

          ; This is the character exchange loop

Loop@@              bsr       PCIN                ; See if we have a character from the PeeCee

          ; Each time thru the loop we check to see if we got a BREAK
          ; OR the DCD went away meaning that the MODEM user has gone.

                    bvs       Done@@              ; Exit back to the caller

                    jsr       CP290OUT            ; Send the char to the CP290
                    jsr       CP290IN             ; See if the CP290 has anything to say
                    bsr       PCOUT               ; CP290 has a char...send it to the PeeCee
                    bra       Loop@@              ; And then continue looking for data
Done@@              rts                           ; Either we got a BREAK, or DCD went away, so return to the caller

;**************************************************************************
; CPINIT - Initialize the SCI port for CP290 communication
;**************************************************************************
; Routine:  This short routine does the setup on the SCI port and sets
;       the baud rate to 600 for the CP290.

CPINIT              proc
                    clr       HOSTDEV             ; Make sure we point to the SCI device
                    jsr       HOSTCO              ; Connect the CP290 using the SCI port
                    jsr       HOSTINI             ; Initialize the port
                    lda       #$34                ; Set for 600 baud of the CP290
                    sta       BAUD                ; Put it in the BAUD register...and begin
                    lda       SCSR                ; Read the SCI status register
                    lda       SCDAT               ; Get the data
                    rts                           ; Back to the caller

;**************************************************************************
; PCIN - This routine gets data from the PeeCee and puts it in the FIFO
;**************************************************************************
; Routine: This routine is the almost the same as the INPUT routine, however
;       it does not AND off the parity bit and it sets the carry bit when
;       there is data.
;       Output: Data is returned in A if carry is set, plus the data
;       is placed in the CPFIFO for transmit out to the CP290
;       If a BREAK is given, then the Overflow flag is set
;       If DCD is not there, then the Overflow flag is set

PCIN                proc
                    lda       PORTA               ; Get PORTA value
                    anda      #DCDFLAG            ; See if we are still have DCD from the MODEM
                    bne       Gone@@              ; Clear is active...jump if user is gone

                    ldx       #ACIA               ; Address the ACIA
                    lda       ,x                  ; Get the CSR
                    psha                          ; save the CSR
                    anda      #$70                ; Check PE, OV, FE
                    pula                          ; Restore the CSR
                    beq       PCIN2               ; No error, then jump look for data

                    bita      #$10                ; Check just the frame error flag
                    beq       PCIN1               ; Not a frame error...jump
                    lsra                          ; Check RDRF - do we have data?
                    bcc       PCIN1               ; No data...but could be another error
                    lda       1,x                 ; Get the data into A
                    bne       PCIN1               ; Then reset the ACIA
                    jsr       WAITONE             ; Wait a second...
                    inc       TFLAG               ; We have a break...check to see if double
                    lda       TFLAG               ; Get the value
                    cmpa      #2                  ; See if we have double
                    bne       PCIN1               ; No...continue to look for data
Gone@@              jsr       ONACIA              ; Master Reset the ACIA
                    sev                           ; Set the overflow flag...we have a BREAK
                    sec                           ; Turn on the carry as well
                    bra       Done@@              ; Go back to the caller and get us out of here

; Here we made some kind of ACIA error...reset the device and start over.

PCIN1               jsr       ONACIA              ; Master Reset the ACIA
                    bra       PCIN                ; Continue to look for data

; No errors, now look for receive data

PCIN2               lsra                          ; Check RDRF - do we have data?
                    bcc       Done@@              ; No data...jump and exit
                    lda       1,x                 ; Get the data into A
                    ldx       #CPFIFO             ; Address of the transmit fifo
                    ldb       CPFPTR              ; Get the fifo forward pointer
                    abx                           ; Add the pointer to the X reg
                    sta       ,x                  ; Save the data byte in the FIFO
                    incb                          ; Bump the pointer
                    cmpb      #FIFOMAX            ; See if we are in wrap around condition
                    bne       PCIN3               ; No wrap around...jump
                    clrb                          ; Start the forward pointer over
PCIN3               stb       CPFPTR              ; Save the forward pointer back
                    clr       TFLAG               ; Reset the break counter since we have data
                    sec                           ; Set the carry to say we have data
                    clv                           ; Clear the overflow flag - No break given
Done@@              rts                           ; Back to the caller

;**************************************************************************
; PCOUT - Sends data from the FIFO to the PeeCee
;**************************************************************************
; Routine: This routine is the same as OUTACIA except that it does
;       sent out the LF/CR sequence and does not AND off the parity
;       All data is put in the FIFO for the CP290.

PCOUT               proc
                    ldb       PCFPTR              ; Get the forward FIFO pointer
                    cmpb      PCBPTR              ; See if there is anything to send
                    beq       Done@@              ; Nothing to send...exit

          ; We have data to send, now check to see if we are busy transmitting

                    ldx       #ACIA               ; Address the ACIA
                    lda       ,x                  ; Get the CSR register
                    bita      #$2                 ; Check the transmitter
                    beq       Done@@              ; We are still busy...exit

          ; We have data and the transmitter is clear, get the data and send it

                    ldx       #PCFIFO             ; Address of the transmit fifo
                    ldb       PCBPTR              ; Get the fifo backward pointer
                    abx                           ; Add the pointer to the X reg
                    lda       ,x                  ; Get the data byte out of the FIFO
                    incb                          ; Bump the pointer
                    cmpb      #FIFOMAX            ; See if we are in wrap around condition
                    bne       Cont@@              ; No wrap around...jump
                    clrb                          ; Start the backward pointer over
Cont@@              stb       PCBPTR              ; Save the backward pointer back
                    ldx       #ACIA               ; Address the ACIA
                    sta       1,x                 ; Store the data ... at last
Done@@              rts

;**************************************************************************
; CP290IN - Gets data from the CP290 and places it in the PC FIFO
;**************************************************************************
; Routine: This routine is used by the transparent mode with the CP290
;       The routine is the same as HOSTIN, however it does not
;       strip off the parity bit before returning the data
; The value read is returned in the A register and carry is set

CP290IN             proc
                    lda       SCSR                ; Read the SCI status register
                    anda      #$20                ; Check the RDRF flag
                    beq       Fail@@              ; Nothing to read
                    lda       SCDAT               ; Get the data
                    ldx       #PCFIFO             ; Address of the transmit fifo
                    ldb       PCFPTR              ; Get the fifo forward pointer
                    abx                           ; Add the pointer to the X reg
                    sta       ,x                  ; Save the data byte in the FIFO
                    incb                          ; Bump the pointer
                    cmpb      #FIFOMAX            ; See if we are in wrap around condition
                    bne       Cont@@              ; No wrap around...jump
                    clrb                          ; Start the forward pointer over
Cont@@              stb       PCFPTR              ; Save the forward pointer back
                    sec                           ; Set the carry flag
                    bra       Done@@              ; Jump and exit out

Fail@@              clc                           ; Flag that nothing was read
Done@@              rts                           ; Back to the caller

;**************************************************************************
; CP290OUT - Sends data from the FIFO to the CP290
;**************************************************************************
; Routine: This routine is used by the transparent mode with the CP290
;       The routine is the same as HOSTOUT, however not clearing
;       the parity and doing the LF/CR things.  Also we send only from
;       the FIFO.

CP290OUT            proc
                    ldb       CPFPTR              ; Get the forward FIFO pointer
                    cmpb      CPBPTR              ; See if there is anything to send
                    beq       Done@@              ; Nothing to send...exit

          ; We have data to send, now check to see if we are busy transmitting

                    ldb       SCSR                ; Get the SCI status
                    bitb      #$80                ; Are we busy transmitting?
                    beq       Done@@              ; Yes...exit and do something else

          ; We have data and the transmitter is clear, get the data and send it

                    ldx       #CPFIFO             ; Address of the transmit fifo
                    ldb       CPBPTR              ; Get the fifo backward pointer
                    abx                           ; Add the pointer to the X reg
                    lda       ,x                  ; Get the data byte out of the FIFO
                    incb                          ; Bump the pointer
                    cmpb      #FIFOMAX            ; See if we are in wrap around condition
                    bne       Cont@@              ; No wrap around...jump
                    clrb                          ; Start the backward pointer over
Cont@@              stb       CPBPTR              ; Save the backward pointer back
                    sta       SCDAT               ; Send the data
Done@@              rts                           ; Back to the caller

;******************************************************************************
; SIGNON - Validate the remote user of CSS
;******************************************************************************
; Routine: This routine is entered when the DCD line goes active indicating
;       a user has dialed the modem and is ready to begin dialog with the
;       CSS.   The design of this module is to 'look and feel' like a VMS
;       system, however looks are oft time deceiving.  The purpose is to
;       limit access to the system except to authorized folks, i.e. who
;       know the password.   Only the password is validated.
;       To get a string of characters from the
;       user and place them in the CBUF until a CR or ^Z, with correct
;       handling of DEL char.   The CR or ^Z terminates the string with
;       a zero.   The case is convered to upper.
; Function: This is called anyone communication with the outside world.
;       The ECHOIT variable is tested to determin if we echo the input
;       back to the output.
; Returns: The Carry is set if there is valid data in the CBUF.
;       If Carry is clear, then DCD is gone and we need to get back
;       to our main loop.   If Carry is set and CBUF is blank, then
;       only a CR or ^Z was read.
; Date: 27-Aug-1993
; Now we wait here for two <CR>s from the user and then display the
; signon message.

SIGNON              proc
                    clr       TFLAG               ; This will count our CR times
                    clr       AUTOLF              ; Do not give an auto line feed
                    clr       ECHOIT              ; We do not want to echo here
Loop@@              bsr       GETSTR              ; Wait for the user to enter CR
                    bcc       SIGNOFF             ; User is gone...return to main loop

                    tst       CBUFFPT             ; See if this is zero indicating just a CR
                    bne       SIGNON              ; No...coutinue to look
                    tst       TFLAG               ; Is the second time thru?
                    bne       Display@@           ; We have two CRs...now send banner
                    inc       TFLAG               ; Yes...we got a CR
                    bra       Loop@@              ; Look for another

Display@@           inc       AUTOLF              ; We want to LF now
                    ldx       #VMSMSG             ; Load up the banner message
                    jsr       OUTSTRG             ; Send it out
SIGNON3             ldx       #VMSMSG1            ; Load up the username request message
                    jsr       OUTSTRG             ; Send it out
                    inc       ECHOIT              ; Echo the input
                    bsr       GETSTR              ; See who it is
                    bcc       SIGNOFF             ; User is gone...return to main loop
                    tst       CBUFFPT             ; See if this is zero indicating just a CR
                    beq       SIGNON3             ; No...continue to look

          ; Now see if the user is a PC giving the special command for quick dump

                    ldx       #CBUFF              ; This is what the user provided
                    ldy       #CWORD              ; Check it against the desired value.
                    jsr       STRCMP              ; Compare the data
                    bcc       SIGNON4             ; This is valid...do the quick dump

          ; Here we have been given the short dump command, so we do a sensor scan
          ; then dump out the first part of memory, and return to the username
          ; prompt and continue looking for a valid signon.

                    jsr       SGATHER             ; Poll the sensor devices
                    ldx       #ADSCAN             ; Load the sensor value index to move from
                    stx       PTR1                ; Save it here for the dump
                    ldx       #ADSCANX            ; End address of the RAM
                    stx       PTR2                ; Save it here for the dump
                    jsr       DUMP1               ; Do it
                    bra       SIGNON3             ; Back to username and look for another

          ; Now we have a user name, we don't care who it is as long as they
          ; know the magic password!

SIGNON4             ldx       #VMSMSG2            ; Load up the password request message
                    jsr       OUTSTRG             ; Send it out
                    clr       ECHOIT              ; No Echo now
                    bsr       GETSTR              ; See who it is
                    inc       ECHOIT              ; Turn Echo back on
                    bcc       SIGNOFF             ; User is gone...return to main loop
                    ldx       #CBUFF              ; This is the user's name
                    ldy       #PWORD              ; This is what is must be.
                    jsr       STRCMP              ; Compare the data
                    bcs       SIGNON5             ; This is valid...Welcome to the Cabin system

          ; Here we handle the invalid user entry

                    ldx       #VMSMSG4            ; Load up the failure message
                    jsr       OUTSTRG             ; Send it out
                    bra       SIGNOFF             ; And let him try again if DCD continues

          ; Here we welcome the user to the system and return to the main routine

SIGNON5             sec                           ; Set the carry to say we are OK to go on
                    inc       SIGNONG             ; Good signon count increment
                    inc       ECHOIT              ; Echo the input flag back on
                    rts                           ; Return to the caller

SIGNOFF             clc                           ; Clear the carry to say the user is gone
                    inc       SIGNONB             ; Bad signon count increment
                    rts                           ; Return to the caller

;******************************************************************************
; GETSTR - Get a string of characters
;******************************************************************************
; Routine: This routine is entered to get a string of characters from the
;       user and place them in the CBUF until a CR or ^Z, with correct
;       handling of DEL char.   The CR or ^Z terminates the string with
;       a zero.   The case is convered to upper.
; Function: This is called anyone communication with the outside world.
;       The ECHOIT variable is tested to determin if we echo the input
;       back to the output.
; Returns: The Carry is set if there is valid data in the CBUF.
;       If Carry is clear, then DCD is gone and we need to get back
;       to our main loop.   If Carry is set and CBUF is blank, then
;       only a CR or ^Z was read.
; Date: 27-Aug-1993

GETSTR              proc
                    clr       CBUFF               ; Reset the first character to zero
                    clr       CBUFFPT             ; Reset the character counter to zero
                    clr       CBUFFOV             ; Clear the last byte, just in case we run over

          ; Here we wait for data from the ACIA or until DCD drops indicating
          ; the modem has lost carrier and the user has gone

Loop@@              jsr       INPUT               ; Get a character if there is one
                    tsta                          ; Anything?
                    bne       GETSTR2             ; Jump, we have input
                    ldx       #PORTA              ; No data...check DCD. Get the address of PORT A
                    brclr     ,x,DCDFLAG,Loop@@   ; We still have a carrier detect...loop
                    clc                           ; Otherwise Indicate that the user is gone.
                    bra       Done@@              ; Back to the caller

          ; We have a character now in A.   Check for a delete, then make it upper case

GETSTR2             cmpa      #$7f                ; See if it is a DELETE
                    beq       GETSTR3             ; Yes...jump
                    cmpa      #BACKSP             ; See if it is a BACKSPACE
                    bne       GETSTR5             ; No...jump

          ; We have a delete or backspace...process it

GETSTR3             tst       CBUFFPT             ; Check if we have cleared it all
                    beq       GETSTR              ; Nothing to delete...contine to input
                    tst       ECHOIT              ; Check the flag if we are to ECHO
                    beq       GETSTR4             ; Zero is no echo...jump
                    lda       #BACKSP             ; Backspace
                    jsr       OUTPUT              ; Put it back to the user
                    lda       #ASPACE             ; Space
                    jsr       OUTPUT              ; Put it back to the user
                    lda       #BACKSP             ; Backspace
                    jsr       OUTPUT              ; Put it back to the user
GETSTR4             dec       CBUFFPT             ; Back off the pointer
                    ldb       CBUFFPT             ; Get the character pointer
                    ldx       #CBUFF              ; Get the address of the buffer
                    abx                           ; Add B to the address
                    clr       ,x                  ; Clear this byte
                    bra       Loop@@              ; Continue to get input

GETSTR5             jsr       UPCASE              ; Make it into upper case
                    tst       ECHOIT              ; Check the flag if we are to ECHO
                    beq       GETSTR6             ; Zero is no echo...jump
                    clr       AUTOLF              ; No Line feed if CR
                    jsr       OUTPUT              ; Put it back to the user
                    inc       AUTOLF              ; Put LF back
GETSTR6             cmpa      #26                 ; See if it is a ^Z
                    beq       WindDown@@          ; Yes...wind down
                    cmpa      #13                 ; See if it is a RETURN
                    beq       WindDown@@          ; Yes...wind down

                    ldb       CBUFFPT             ; Get the character pointer
                    ldx       #CBUFF              ; Get the address of the buffer
                    abx                           ; Add B to the address
                    sta       ,x                  ; Save this character byte
                    clr       1,x                 ; Clear the next byte
                    incb                          ; Add one to our pointer
                    cmpb      #CBUFFMX            ; See if we are at the limit
                    beq       WindDown@@          ; Yes...exit
                    stb       CBUFFPT             ; Otherwise...save the counter
                    bra       Loop@@              ; Continue to get input
WindDown@@          sec                           ; Set the carry flag
Done@@              rts                           ; Return to the caller

;******************************************************************************
; STRCMP - Routine to compare two null terminated character strings
;******************************************************************************
; Routine: This routine does a compare on two character buffers which
;       are zero terminated strings.
;       The X register points to string 1
;       The Y register points to string 2
;       The comparison continues until either string contains a zero.
;       A,B,X,Y are saved
; Returns: The Carry is set if the compare is exact.
;       If Carry is clear, then the compare failed.
; Date: 27-Aug-1993

STRCMP              proc                          ; Null terminated string compare
                    psha                          ; save the registers
                    pshb
                    pshx
                    pshy
Loop@@              lda       ,x                  ; Get a character from S1
                    ldb       ,y                  ; Get a character from S2
                    cba                           ; Check the two bytes
                    bne       Fail@@              ; It is over...we did not compare
                    inx                           ; Go to the next byte
                    iny                           ; Ditto
                    tsta                          ; Is it a zero
                    bne       Loop@@              ; No...continue to look

                    sec                           ; Set the carry flag we are equal
                    bra       Done@@              ; Restore regs and return

Fail@@              clc                           ; Clear the carry flag to indicate we failed
Done@@              puly                          ; Restore the registers
                    pulx
                    pulb
                    pula
                    rts                           ; Return to the caller

;******************************************************************************
; CKMODEM - Check for Modem activity
;******************************************************************************
; Routine: This routine is called from the major loop to see if anyone is
;       connected remotely.
; Function: Check the DCD flag - PORT A bit 2 for activity
; Returns: Sets the carry flag if active, otherwise clear the carry flag
;******************************************************************************

CKMODEM             proc
                    ldx       #PORTA              ; No data...check DCD. Get the address of PORT A
                    brclr     ,x,DCDFLAG,Carr@@   ; We have a carrier detect...jump
                    clc                           ; Otherwise Indicate that there is no user.
                    bra       Done@@              ; No user...return with carry clear.
Carr@@              sec                           ; Set the carry flag
Done@@              rts                           ; Return to the caller

;******************************************************************************
; CKMODEM - Check for Modem activity
;******************************************************************************
; Routine: This routine is called from the major loop to see if the CP290
;       is sending us any data.   If so, then we need to check what it is
;       and act accordingly.
; Function: Check the DCD flag - PORT A bit 2 for activity
; Returns: Sets the carry flag if active, otherwise clear the carry flag
;******************************************************************************

CKCP290             proc
                    ldx       #SCSR               ; Get the address of the SCI status register
                    brset     ,x,RDFLAG,DatRdy@@  ; We have a data ready flag...jump
                    clc                           ; Otherwise Indicate that there is no CP290 data.
                    bra       Done@@              ; No data...return with carry clear.
DatRdy@@            sec                           ; Set the carry flag
Done@@              rts                           ; Return to the caller

;******************************************************************************
; CKLOCAL - Checks for Local CSS activity
;******************************************************************************
; Routine: This routine is called from the major loop to see if someone
;       local to the CSS has pressed a switch on the panel indicating
;       they want some information displayed.
; Function: Check the switches for activity
; Returns: Sets the carry flag if active, otherwise clear the carry flag
;       The first switch pressed sets DSPOINT with a value 1-10 and exits.
;******************************************************************************

CKLOCAL             proc
                    lda       #10                 ; This will be our counter
                    ldb       PORTA               ; Get the first two...0 & 1 - off and on
Loop@@              lsrb                          ; Shift down the value
                    bcc       SwitchActive@@      ; Carry is clear...switch active...jump & exit
                    deca                          ; Count it down
                    cmpa      #8                  ; Are we done?
                    bne       Loop@@              ; No...continue to loop

                    ldb       PORTC               ; Get the switch bank
Bits@@              lsrb                          ; Shift down the value
                    bcc       SwitchActive@@      ; Carry is clear...switch active...jump & exit
                    deca                          ; Count down our switch counter
                    bne       Bits@@              ; Continue to cycle thru the bits

          ; We have checked all the bits...none are set, so we clear
          ; the carry and exit

                    clc                           ; Clear the carry flag...no local user
                    bra       Done@@              ; Jump and return

SwitchActive@@      sta       DSPOINT             ; Save the switch values
                    sec                           ; Set the carry and return

Done@@              rts                           ; Return to the main loop

;******************************************************************************
; KEEPTIM - Updates the local display from the Major loop
;******************************************************************************
; Routine: This routine is called from the major loop to:
;       1) Update the time keeping functions
;       2) Update the LCD time display.
;       3) Check the door status.
;       4) Check the rain sensor.
;       5) Update the LCD mode display.
;******************************************************************************

KEEPTIM             proc
                    jsr       DELAY               ; Count down our seconds
                    bcc       KEEPTI9             ; Update the LCD and continue to wait

          ; A second is now over...update the counters

                    lda       #40                 ; This will be a one second delay
                    jsr       DELAYIT             ; Setup the delay timer
                    dec       CURSEC              ; Count down the seconds
                    lda       CURSEC              ; Get the seconds again
                    beq       KEEPTI6             ; Zero...time to change the minute...jump

          ; Here we cycle our LCD display every four seconds

                    anda      #3                  ; Every four seconds
                    cmpa      #3                  ; See if we are there
                    bne       KEEPTI7             ; Not time yet...jump
                    lda       DSPOINT             ; Get the value
                    cmpa      #DSPOMAX            ; See if we are over the max value
                    blo       KEEPTI3             ; Jump and Keep going if below the max
                    clra                          ; Zero our counter
                    clr       DSPOINT             ; Start over
KEEPTI3             jsr       SETMODE             ; Set the mode
                    inc       DSPOINT             ; Bump the next display point
                    bra       KEEPTI7             ; Keep going

          ; Now the minute is over...display the time and reset the counters

KEEPTI6             lda       #59                 ; Another minutes worth of seconds
                    sta       CURSEC              ; Save it
                    inc       CURMIN              ; Bump the minute
                    jsr       LCDTIM              ; Show the time
                    clra                          ; Clear our display counter to being the cycle
                    jsr       SETMODE             ; Begin the LCD display variables

KEEPTI7             equ       *
                    lda       PORTE               ; Here we check the door status
                    anda      #$1E                ; Just look at the four doors
                    cmpa      DSTATUS             ; See if anything has changed
                    beq       KEEPTI9             ; Nothing changed...jump and continue

          ; since it is unlikely that someone can open the door in less than
          ; second, we put the door checking inside the second time loop

                    jsr       UPDOORS             ; Update the door status

KEEPTI9             equ       *

; since the rain guage event can occur quickly, unlike the door status,
; this is in the fast loop, and is checked often.   With special debounce

                    bsr       CHKRAIN             ; Check the rain guage status
                    jsr       DSPMODE             ; Update the LCD state if necessary
                    rts                           ; Return to the main loop

;******************************************************************************
; CHKRAIN - Check the rain guage for activity
;******************************************************************************
; Routine: This routine is called from the KEEPTIM loop to handle the
;       rain guage events.
; The Rain indicator bit is PORT E bit 6
;******************************************************************************

CHKRAIN             proc
                    lda       PORTE               ; Get the status from port e
                    anda      #$40                ; Just look at the rain bit = NORMAL is HIGH
                    bne       CHKRAI4             ; It is high, check for been low

          ; Here the value is low, check to see if we have been low for a second

                    lda       CURSEC              ; Get the current seconds
                    tst       BEENLOW             ; Clear = been low, otherwise = NORMAL
                    bne       CHKRAI2             ; First time thru...jump
                    cmpa      RAINSEC             ; See if we've been here for awhile
                    beq       Done@@              ; Yes...jump and continue to wait

          ; Now we catch the timer and get ready for the return event

CHKRAI2             sta       RAINSEC             ; Save the current seconds
                    clr       BEENLOW             ; Clear our flag
                    bra       Done@@              ; Exit back to the main loop

CHKRAI4             tst       BEENLOW             ; Clear = been low, otherwise = NORMAL
                    bne       Done@@              ; Exit if NORMAL

          ; Here we've been low, now it's back high, are we still at the same second?

                    lda       CURSEC              ; Get the current second counter
                    cmpa      RAINSEC             ; Is it the same?
                    beq       Done@@              ; Yes...jump and continue to wait

          ; Now the time has passed, we can increment the rain sensor and continue

                    inc       RAINFAL             ; Bump the counter
                    inc       BEENLOW             ; Reset the flag
                    com       RAINSEC             ; Reset this indicator
Done@@              rts                           ; Return to the main loop

;******************************************************************************
; DOMODEM - Handles Remote user activity
;******************************************************************************
; Routine: This routine is called from the major loop to handle the
;       remote user activity.
;******************************************************************************

DOMODEM             proc
                    lda       #STMODEM            ; New state
                    jsr       SETMODE             ; Change it
                    jsr       SIGNON              ; Get the user logged in
                    bcc       DOMODE9             ; User gone or can't get in
;                   bra       DOMODE0             ; User is still online...jump and continue

;*******************************************************************************
; Give the user the LOGIN information and then give menu

DOMODE0             proc
                    jsr       SHOWCSS             ; Display the CSS status and time
Loop@@              ldx       #DSPMSG2            ; Load up the Menu message
                    jsr       OUTSTRG             ; Send it out
                    jsr       GETSTR              ; Get the user pick
                    bcc       DOMODE9             ; User is gone...so are we
                    tst       CBUFFPT             ; See if this is zero indicating just a CR
                    beq       Loop@@              ; Yes...just return, so loop back up

          ; Now we process what the user has entered for a choice

                    ldb       CBUFF               ; Get the first input data byte
                    cmpb      #ASCII0             ; See if it is less than 0
                    blt       Loop@@              ; Less than $30, then display menu again
                    cmpb      #MAXCMDS            ; See if we are greater than the maximum
                    bgt       Loop@@              ; Jump and give the menu again

          ; Limits have been checked...now strip off the $30 and call the routine

                    andb      #$0F                ; Just the low order nibble
                    lslb                          ; Multiply by 2
                    ldx       #CMDTBLE            ; Get the command table
                    abx                           ; Add in the offset
                    ldx       ,x                  ; Fetch the address
                    jsr       ,x                  ; Do the command
                    bra       Loop@@              ; Restore the menu

;*******************************************************************************

DOMODE9             proc
                    jsr       NORMODE             ; Return LCD state display to normal
                    rts                           ; Return to the main loop

;******************************************************************************
; DODSPUD - Upload history data file to the remote system
;******************************************************************************
; Routine: This routine is called from the remote/modem command menu to
;       upload the history data to the PeeCee system
;******************************************************************************

DODSPUD             proc
                    ldx       #DSPMSGM            ; This will take awhile...are you sure?
                    jsr       OUTSTRG             ; Send it out
                    jsr       GETYSNO             ; Get the user response
                    bcc       Done@@              ; User is gone...so are we
                    bvc       Done@@              ; No...it is not OK...jump back to main menu

                    ldx       #DSPMSG4            ; Display Upload History Data message
                    jsr       OUTSTRG             ; Send it out
                    lda       #10                 ; This is our counter
                    sta       TFLAG               ; This will be our delay counter
Loop@@              jsr       WAITONE             ; Wait a second.
                    dec       TFLAG               ; Count it back
                    lda       TFLAG               ; Get the counter
                    beq       DODSPU2             ; We are done...jump and UPLOAD
                    ora       #$30                ; Make it a ASCII char
                    jsr       OUTPUT              ; Send it out
                    bra       Loop@@              ; Continue to wait

DODSPU2                                           ; Here we setup for the UPLOAD
                    ldx       #STRRAM             ; Starting RAM location
                    stx       PTR1                ; Save it here for the dump
                    ldx       #ENDRAM             ; End address of the RAM
                    stx       PTR2                ; Save it here for the dump
                    jsr       DUMP1               ; Do it

                    ldx       #DSPMSG5            ; Display Function complete.
                    jsr       OUTSTRG             ; Send it out
                    jsr       GETSTR              ; Wait for CR before we continue
Done@@              rts                           ; Return to the main loop

;******************************************************************************
; DODSPTM - Enter transparant mode with CP290
;******************************************************************************
; Routine: This routine is called from the remote/modem command menu to
;       begin transparant mode with the CP290 and the PeeCee.
; Note: We must monitor for a BREAK condition from the ACIA to get us out
;       of this loop.
;******************************************************************************

DODSPTM             proc
                    ldx       #DSPMSG6            ; Display Transparant mode message
                    jsr       OUTSTRG             ; Send it out
                    lda       #STPASS             ; CP290 Pass thru mode
                    jsr       SETMODE             ; Send it out
                    jsr       CPTMPC              ; Begin Transparent mode
                    ldx       #DSPMSG5            ; Display Function complete.
                    jsr       OUTSTRG             ; Send it out
                    jsr       GETSTR              ; Wait for CR before we continue
                    rts                           ; Return to the main loop

;******************************************************************************
; DODSPMM - Display Max/Min values to the remote system
;******************************************************************************
; Routine: This routine is called from the remote/modem command menu to
;       display Max/Min history values to the PeeCee system
;******************************************************************************

DODSPMM             proc
                    jsr       HOMECLR             ; Home and Clear the screen
                    ldx       #DSPMSG7            ; Display Max/Min History Data message
                    jsr       OUTSTRG             ; Send it out

                    clr       TFLAG               ; This will be our counter
Loop@@              ldx       #TMPCTAB            ; CR/TAB for format purposes
                    jsr       OUTSTRN             ; Send it out

; Now we print the location of the sensor

                    ldx       #STATBLE            ; Address of the location text
                    ldb       TFLAG               ; Get the counter
                    lslb                          ; *2 our offset
                    abx                           ; Add in the offset
                    ldx       ,x                  ; Get the next location printout
                    jsr       OUTSTRN             ; Send it out
                    jsr       JUSTAB              ; Send it out just a tab

; Now we reference the HIGHVAL and LOWSVAL array for the history data

                    ldb       TFLAG               ; Get the counter
                    lslb                          ; *2 our offset
                    lslb                          ; *4 our offset
                    ldx       #LOWSVAL            ; Address of the low values
                    abx                           ; Add in the offset
                    lda       ,x                  ; Get the sensor low value
                    pshx                          ; save our index value

; Here we check for non negative display for rel light/wind speed/etc

                    cmpb      #$20                ; Is this a pressure value
                    blt       DODSPM2             ; No...jump and continue
                    inc       UNSIGN              ; No negative numbers please

; We check here to see if this is a pressure, which we do special printout

                    cmpb      #$20                ; Is this a pressure
                    bne       DODSPM2             ; No...jump and print as usual
                    sta       CURBP               ; Save the BP in the printout place
                    jsr       BPRINT              ; Format the BP
                    ldx       #BPRESSC            ; This is the place to print from
                    jsr       OUTSTRN             ; Send it out
                    bra       DODSPM3             ; Jump over and continue

DODSPM2             jsr       PRINTA              ; Convert it to ASCII and print it out
                    clr       UNSIGN              ; Normal +/- display
DODSPM3             jsr       JUSTAB              ; Send it out just a tab
                    pulx                          ; Restore the index value
                    bsr       HIS2TIM             ; Move and print the correct time
                    jsr       HISTIM              ; Print out the time
                    jsr       JUSTAB              ; Send it out just a tab

                    ldb       TFLAG               ; Get the counter
                    lslb                          ; *2 our offset
                    lslb                          ; *4 our offset
                    ldx       #HIGHVAL            ; Address of the high values
                    abx                           ; Add in the offset
                    lda       ,x                  ; Get the sensor high value
                    pshx                          ; save our index value

          ; Here we check for non negative display for rel light/wind speed/etc

                    cmpb      #$20                ; Is this a pressure value
                    blt       DODSPM4             ; No...jump and continue
                    inc       UNSIGN              ; No negative numbers please

          ; We again check here to see if this is a pressure...special printout

                    cmpb      #$20                ; Is this a pressure
                    bne       DODSPM4             ; No...jump and print as usual
                    sta       CURBP               ; Save the BP in the printout place
                    jsr       BPRINT              ; Format the BP
                    ldx       #BPRESSC            ; This is the place to print from
                    jsr       OUTSTRN             ; Send it out
                    bra       DODSPM5             ; Jump over and continue

DODSPM4             jsr       PRINTA              ; Convert it to ASCII and print it out
                    clr       UNSIGN              ; Normal +/- display
DODSPM5             jsr       JUSTAB              ; Send it out just a tab
                    pulx                          ; Restore the index value
                    bsr       HIS2TIM             ; Move and print the correct time
                    jsr       HISTIM              ; Print out the time

          ; Do the housekeeping and printout all values

                    inc       TFLAG               ; Increment our counter
                    ldb       TFLAG               ; Get the value
                    cmpb      #HLBYTES            ; See if we are done (Windir is not used)
                    beq       Done@@              ; We are done...exit
                    jmp       Loop@@              ; Continue to loop

Done@@              ldx       #DSPMSG5            ; Display Function complete.
                    jsr       OUTSTRG             ; Send it out
                    jsr       GETSTR              ; Wait for CR before we continue
                    rts                           ; Return to the main loop

;******************************************************************************
; HIS2TIM - Helper routine for moving the history time
;******************************************************************************
; Routine: This routine is called from above to move the correct history time

HIS2TIM             proc                          ; Move history time
                    lda       1,x                 ; Get the DSPMON
                    sta       DSPMON              ; Save it
                    lda       2,x                 ; Get the DSPDAY
                    sta       DSPDAY              ; Save it
                    lda       3,x                 ; Get the DSPHR
                    sta       DSPHR               ; Save it
                    rts                           ; Return to the upper loop

;******************************************************************************
; SHODOOR - Show the door status
;******************************************************************************
; Routine: This routine is called from the main loop to update the
;       display the current door status: open/close/count/time
;******************************************************************************

SHODOOR             proc
                    jsr       HOMECLR             ; Home and Clear the screen
                    ldx       #DSPMSGI            ; Display door header message
                    jsr       OUTSTRG             ; Send it out

          ; Now we begin a loop of 4 cycles to display the door conditions

                    clrb                          ; B is our index value
Loop@@              pshb                          ; Save it on the Stack
                    lslb                          ; *2 for the double index value
                    ldx       #DOORTBL            ; Get the index printout pointers
                    abx                           ; Add in the current day pointer
                    ldx       ,x                  ; Get this new index value
                    jsr       OUTSTRG             ; Send it out - Name of the door

          ; Now we want to printout if it is currently open or closed

                    pula                          ; Get our index Back
                    psha                          ; save it on the Stack
                    clrb                          ; B will be our mask for port E
                    incb                          ; Make it a one
SHODOO3             lslb                          ; Shift it up one
                    deca                          ; Minus one
                    bpl       SHODOO3             ; Continue to loop till we have correct mask
                    andb      PORTE               ; AND PORT E which has the door status
                    beq       SHODOO4             ; Zero means door is open
                    ldx       #DCLOSED            ; Door is closed
                    bra       SHODOO5             ; Print it out

SHODOO4             ldx       #DOPENED            ; Door is open
SHODOO5             jsr       OUTSTRN             ; Print it out

          ; Now we printout the cycle count value

                    ldx       #DCYCLED            ; Display door cycled message
                    jsr       OUTSTRG             ; Send it out
                    pulb                          ; Get our index Back
                    pshb                          ; Save it on the Stack
                    lslb                          ; *2 for the double index value
                    ldy       #DOORATE            ; Get the index history pointers
                    aby                           ; Add in the current day pointer
                    ldx       ,y                  ; Get the value at the pointer
                    lda       DCOUNT,x            ; Get this new index value
                    inc       UNSIGN              ; No negative numbers
                    jsr       PRINTA              ; Convert it to ASCII and print it out
                    clr       UNSIGN              ; Back to normal

          ; Now we printout the Last open/closed times

                    ldx       #DLOPEND            ; Display door last opened message
                    jsr       OUTSTRG             ; Send it out
                    ldx       ,y                  ; Get this new index value Date OPEN
                    jsr       SHOWTIM             ; Give the value
                    ldx       #DLCLOSE            ; Display door last closed message
                    jsr       OUTSTRG             ; Send it out
                    ldx       ,y                  ; Get this new index value Date OPEN
                    ldb       #6                  ; Offset into the Date CLOSED
                    abx                           ; Add it into the X reg
                    jsr       SHOWTIM             ; Give the value

          ; Now go to the next door and loop

                    pulb                          ; Get our index Back
                    incb                          ; Bump to next door
                    cmpb      #4                  ; Only 4 doors
                    bne       Loop@@              ; We are not done

          ; We are done

                    ldx       #DSPMSG5            ; Display Function complete.
                    jsr       OUTSTRG             ; Send it out
                    jsr       GETSTR              ; Wait for CR before we continue
                    rts                           ; Return to the main loop

;******************************************************************************
; UPDOORS - Update door status
;******************************************************************************
; Routine: This routine is called from the main loop to update the
;       door status in the event of a change...ie door open/closed
; PORTE contains the current door status register
;                     PortE
;       DOOR CLOSED = HIGH = SWITCH OPEN
;       DOOR OPEN   = LOW  = SWITCH CLOSED
;       7 6 5 4 3 2 1 0
;       x x x N S B F x         Where NSBF are:
;                               Front Door
;                               Basement Door
;                               South Garage Door
;                               North Garage Door
; We enter this routine with A already masked PORTE from the main loop
;******************************************************************************

UPDOORS             proc                          ; Update door open/close status
                    psha                          ; save the masked door status
                    lda       #2                  ; This will be our counter/index
                    sta       TFLAG               ; We use this general purpose location
Loop@@              lda       DSTATUS             ; Get the old door status
                    anda      TFLAG               ; Check just the one door in question
                    pulb                          ; Get the masked E back
                    pshb                          ; Save it back on the stack
                    andb      TFLAG               ; Check just the one door in question

          ; at this point, A=old door status, B=new door status (for just one door)

                    cba                           ; Check to see if they are different
                    beq       Cont@@              ; They are the same...jump and do the next one

          ; now we update the date/time of the occurance and the cycle count

                    ldy       #DOORATE            ; Index into the door table
                    tstb      Test                ; the current door condition
                    beq       Open@@              ; Jump...the door is OPEN

          ; Here the door is closed...save the time

                    bsr       MKINDEX             ; Make B into an offset
                    aby                           ; Add B into Y for the correct offset
                    ldy       ,y                  ; Get the proper index into the door status
                    inc       DCOUNT,y            ; Since door is now closed...but the cycle cnt
                    ldb       #6                  ; Offset into the door closed time area
                    aby                           ; Adjust the Y index value
                    bra       Save@@              ; Save the time

Open@@              tab                           ; Door is OPEN, put A->B so we can index
                    bsr       MKINDEX             ; Make B into an offset
                    aby                           ; Add B into Y for the correct offset
                    ldy       ,y                  ; Get the proper index into the door status
Save@@              jsr       SAVTIME             ; Save the time

Cont@@              lsl       TFLAG               ; Shift to the next door bit location
                    lda       TFLAG               ; Get this value
                    cmpa      #$20                ; See if we are finished with all four doors
                    bne       Loop@@              ; No...jump and continue to loop

                    pula                          ; Clean off the stack...this is our new status
                    sta       DSTATUS             ; Save it for next time
                    rts                           ; Return to the main loop

;******************************************************************************
; MKINDEX - Special purpose routine for UPDOOR
;******************************************************************************
; This routine take B and makes in into a index
;       input   output
;       2       0
;       4       2
;       8       4
;       16      6

MKINDEX             proc                          ; Make an index value from B
                    lsrb:2                        ; Shift it down twice
                    cmpb      #4                  ; This is a special case
                    bne       Done@@              ; OK to return
                    decb                          ; Back it off one
Done@@              lslb                          ; *2
                    rts                           ; Return to the caller

;******************************************************************************
; DODSPCC - Display Current conditions to the remote system
;******************************************************************************
; Routine: This routine is called from the remote/modem command menu to
;       display the current sensor values to the PeeCee system
;******************************************************************************

DODSPCC             proc                          ; Display current conditions
                    jsr       HOMECLR             ; Home and Clear the screen
DODSPC0             ldx       #DSPMSG8            ; Display Current Sensor conditions message
                    jsr       OUTSTRG             ; Send it out
                    jsr       SGATHER             ; Poll the sensor devices

          ; Now display what we have found as current data

                    clr       TFLAG               ; This will be our counter

          ; Top of TEMPERATURE display loop

Loop@@              ldx       #TMPCTAB            ; CR/TAB for format purposes
                    jsr       OUTSTRN             ; Send it out

          ; Now we print the location of the temp sensor

                    ldx       #STATBLE            ; Address of the location text
                    ldb       TFLAG               ; Get the counter
                    lslb                          ; *2 our offset
                    abx                           ; Add in the offset
                    ldx       ,x                  ; Get the next location printout
                    jsr       OUTSTRN             ; Send it out
                    bsr       JUSTAB              ; Send it out just a tab

          ; Here we print the value of the sensor - going thru the table conversion

                    ldx       #TMPDATA            ; Address of the DS1820 results save area
                    ldb       TFLAG               ; Get the counter
                    abx                           ; Add in the offset
                    lda       ,x                  ; Get the real temperature value
                    bsr       PRINTA              ; Convert it to ASCII and print it out

          ; Do the housekeeping and printout all values

                    inc       TFLAG               ; Increment our counter
                    ldb       TFLAG               ; Get the value
                    cmpb      #TMPSENS            ; See if we are done
                    bne       Loop@@              ; Continue to loop

          ; Now printout the rest of the information
          ;--- Pressure
                    ldx       #CURDSP1            ; Load the character address
                    bsr       LFCRSAY             ; Send it out a CR/TAB
                    lda       BPRESUR             ; Get the barometric pressure
                    sta       CURBP               ; Save it away for the printout
                    jsr       BPRINT              ; Print the pressure in standard format
                    ldx       #BPRESSC            ; Load the character address
                    jsr       OUTSTRN             ; Send it out without doing LF/CR first
          ;--- Rainfall
                    ldx       #CURDSP2            ; Load the character address
                    bsr       LFCRSAY             ; Send it out a CR/TAB
                    lda       RAINFAL             ; Get the rainfall count
                    inc       UNSIGN              ; No negative numbers
                    bsr       PRINTA              ; Convert it to ASCII and print it out
          ;--- Relative Light
                    ldx       #CURDSP3            ; Load the character address
                    bsr       LFCRSAY             ; Send it out a CR/TAB
                    lda       RELIGHT             ; Get the relative light
                    bsr       PRINTA              ; Convert it to ASCII and print it out
          ;--- Wind speed
                    ldx       #CURDSP4            ; Load the character address
                    bsr       LFCRSAY             ; Send it out a CR/TAB
                    lda       WINDSPD             ; Get the wind speed
                    bsr       PRINTA              ; Convert it to ASCII and print it out
                    clr       UNSIGN              ; Return flag to normal +/-
          ;--- Wind direction
                    ldx       #CURDSP5            ; Load the character address
                    bsr       LFCRSAY             ; Send it out a CR/TAB
                    ldx       #WINDIRC            ; Load the character address
                    jsr       OUTSTRN             ; Send it out without doing LF/CR first

          ; We are done

                    ldx       #DSPMSG5            ; Display Function complete.
                    jsr       OUTSTRG             ; Send it out
                    jsr       PCIN                ; Wait for any character before we continue
                    bcs       Done@@              ; anything entered...exit back to main loop
                    jsr       HOMEIT              ; Jump back to the top of the screen
                    jmp       DODSPC0             ; Do it again

Done@@              rts                           ; Return to the main loop

;******************************************************************************
; LFCRSAY - Issue a LF / CR / Say wait is given
;******************************************************************************
; Routine: This routine used for more screen formatting
;       X is the pointer to what to say

LFCRSAY             proc
                    pshx                          ; save X for the moment
                    bsr       LFCRTAB             ; Send it out a CR/TAB
                    pulx                          ; Load the character address
                    jsr       OUTSTRN             ; Send it out without doing LF/CR first
                    bsr       JUSTAB              ; Send it out just a tab
                    rts                           ; Return to the caller

;******************************************************************************
; LFCRTAB - Issue a LF / CR / TAB to the user
;******************************************************************************
; Routine: This routine used for screen formatting

LFCRTAB             proc
                    ldx       #TMPCTAB            ; CR/TAB for format purposes
                    bra       JUSTAB9             ; Send it out

;*******************************************************************************

JUSTAB              proc
                    ldx       #TMPHORZ            ; Just a TAB for format purposes
JUSTAB9             jsr       OUTSTRN             ; Send it out
                    rts                           ; Return to the caller

;******************************************************************************
; PRINTA - Prints the value of A to the user
;******************************************************************************
; Routine: This will convert A into ASCII and print it out

PRINTA              proc                          ; Print the value of A to the user
                    jsr       ITOA                ; Convert it to ASCII
                    ldx       #ITOAC              ; Load the character address
                    jsr       OUTSTRN             ; Send it out without doing LF/CR first
                    rts                           ; Return to the caller

;******************************************************************************
; SGATHER - Scan the sensor devices
;******************************************************************************
; Routine: This routine used to gather the current conditions and place
;       them in the CUR locations for each value
;******************************************************************************

SGATHER             proc
                    lda       #STSCAN             ; We are entering scan state
                    jsr       SETMODE             ; Set the LCD state

          ; While we gather the other sensors, we can begin to count pulses from
          ; the wind boom, so that when we are done, we can get a relative value

                    jsr       WSETUP              ; Setup to begin counting wind pulses

          ; Now gather all of the DS1820 values for temperature

                    jsr       SCANTP              ; Get the temperature sensors

          ; Now get the A/D registers for Light/Barometric pressure

                    ldx       #ADCTL              ; Address the A/D control register
                    lda       #$14                ; MULT + CC to get the second 4 values
                    sta       ,x                  ; Do it, begin the conversion

          ; Wait for the A/D to complete

Loop@@              lda       ,x                  ; Get the status register back
                    lsla                          ; Check if conversion is complete
                    bcc       Loop@@              ; Continue to wait

          ;  E5 - The relative light sensor
          ;  E7 - The barometric pressure sensor

                    lda       2,x                 ; Get the E5 value for Light
                    sta       RELIGHT             ; Save it away
                    lda       4,x                 ; Get the E7 value for BP
                    sta       BPRESUR             ; Save it away

                    jsr       GOWIND              ; Get the wind direction
                    jsr       WSPEED              ; Get the wind speed
                    rts                           ; Return to the caller

;******************************************************************************
; DODSPBY - Hangup the phone the use is leaving
;******************************************************************************
; Routine: This routine is called from the remote/modem command menu to
;       get off the system
;******************************************************************************

DODSPBY             proc
                    ldx       #DSPMSG9            ; Display Good Bye message
                    jsr       OUTSTRG             ; Send it out
                    jsr       WAITONE             ; Wait two seconds
                    jsr       WAITONE             ; Till the modem goes to command mode

          ; We have waited the guard time from the work sending to the CP290
          ; Now we can send the attention +++

                    lda       #APLUS              ; Set the attention character
                    jsr       OUTPUT              ; Send it out
                    lda       #APLUS              ; Set the attention character
                    jsr       OUTPUT              ; Send it out
                    lda       #APLUS              ; Set the attention character
                    jsr       OUTPUT              ; Send it out
                    jsr       WAITONE             ; Wait two seconds
                    jsr       WAITONE             ; Till the modem goes to command mode
                    ldx       #DSPMSGB            ; Tell the modem to hang up with ATH0
                    jsr       OUTSTRN             ; Send it out...DCD should drop

          ; Now we save the current date and time as our last valid user signon

                    ldy       #USRDATE            ; Location to save into
                    jsr       SAVTIME             ; Copy the time the last user was here
                    jsr       DNSAVE              ; Save the vital data back to the CP290
                    rts                           ; Return to the main loop

;******************************************************************************
; DOCP290 - Handles CP290 activity
;******************************************************************************
; Routine: This routine is called from the major loop to execute commands
;       for scan from the CP290.   If there is any CP290 activity, then
;       this routine gets it, however it must check to see if the command
;       is for us, meaning it is one of the special hourly events.
;******************************************************************************

DOCP290             proc                          ; Handle CP290 activity
                    lda       #12                 ; We expect to get these bytes back
                    jsr       GETCPD              ; Get any data from the CP290 in PCFIFO
                    ldx       #PCFIFO             ; Address the data
                    lda       7,x                 ; Get the Housecode value and function
                    cmpa      #$F3                ; We check this value 'J' and 'OFF'
                    bne       Done@@              ; No...this is not us...exit
                    lda       6,x                 ; Get the current status
                    deca                          ; Back it off one
                    bne       Done@@              ; No...this is not us...exit
                    bsr       SCANTIM             ; This is for us...do a sensor scan
Done@@              rts                           ; Return to the main loop

;******************************************************************************
; SCANTIM - Handles the housekeeping related to a hourly scan
;******************************************************************************
; Routine: This routine is called from the DOCP290 to execute
;       the sensor scan and do the related housekeeping
;       This is our event...Now gather the hourly observations

SCANTIM             proc                          ; Do the sensor data scan
                    bsr       SGATHER             ; Get the conditions
                    jsr       HIGLOWS             ; Find the high/low values

          ; We resync our time with the CP290
          ; We clear the minutes, and then get the hour and set it

                    clr       CURMIN              ; The clock has chimed.
                    lda       #59                 ; Sixty seconds we count down
                    sta       CURSEC              ; Save it away
                    ldx       #PCFIFO             ; Address the data from the CP290
                    lda       8,x                 ; It is coded in the unit codes.
                    deca                          ; Back it off by one
                    sta       CURHR               ; Save the hour
                    beq       SCANTI1             ; Jump if midnight...0 indicates a new day

          ; In the beginning, BHISTHR is set to -1, so we begin by saving the
          ; CHRHR in BHISTHR and start saving scans in the first (0) CURDPTR
          ; location.   When the first midnight rolls around, then we bump to
          ; the next day.  NOTE: CURDPTR is cleared on startup.

                    lda       BHISTHR             ; Get the special first hour flag
                    bge       SCANTI5             ; We have been here before..jump and continue
                    bra       SCANTI2             ; Jump, initial startup, start as if new day

          ; It must be the start of a new day...so do the calender housekeeping

SCANTI1             jsr       BUMPDAY             ; Go to the next working day
                    lda       WKDAY               ; Load the working day
                    sta       CURDAY              ; Save it here
                    lda       WKMON               ; Load the working month
                    sta       CURMON              ; Save it here
                    lda       WKYR                ; Load the working year
                    sta       CURYR               ; Save it here
                    clr       RAINFAL             ; Restart our rain guage counter
                    inc       CURDPTR             ; Bump our history index pointer

          ; Now bump the history number of days...only to a max of MAXDPTR

                    lda       #MAXDPTR            ; This is our maximum value
                    ldb       NUMDPTR             ; Get the number of history days already
                    incb                          ; Bump it up one
                    cba                           ; See how we're doing
                    bge       SCANTIA             ; Jump if less or equal
                    tab                           ; Move MAXDPTR into B
SCANTIA             stb       NUMDPTR             ; Save it back

          ; Now bump the history index pointer to the next days of data.
          ; CURDPTR is cleared on startup, so this is to check for the first
          ; midnight, or it was a wrap around.

SCANTI2             ldb       CURDPTR             ; Get the value
                    bne       SCANTI3             ; This is special...zero = must save the CURHR
                    lda       CURHR               ; Get the current hour
                    sta       BHISTHR             ; Save this indicator when we first start

SCANTI3             cmpb      #MAXDPTR            ; Are we over the limit
                    bne       SCANTI4             ; We are OK...jump and continue
                    clr       CURDPTR             ; Max'ed out...we must start over
SCANTI4             lslb                          ; *2 for the double index value
                    lslb                          ; *4 since this is an four byte array
                    ldx       #HISIDX             ; Get the index history pointers
                    abx                           ; Add in the current day pointer
                    lda       CURMON              ; And the current month
                    sta       ,x                  ; Save it
                    lda       CURDAY              ; Get the current day
                    sta       1,x                 ; Save it
                    ldy       HFLINK              ; Get the next history pointer to put the data
                    sty       2,x                 ; Save it also

          ; Now save the sensor data in HFLINK which is in Y.

SCANTI5             lda       #SNBYTES            ; How many sensor bytes are we saving
                    ldy       HFLINK              ; Get the next history pointer to put the data
                    ldx       #ADSCAN             ; Load the sensor value index to move from
                    jsr       MEMCPY              ; Copy the current into the history area

          ; Now we must adjust the HFLINK for the next scan time, being careful
          ; not to run off the end of the buffer, but wrap back around to the top

                    ldx       HFLINK              ; Get the history forward link back
                    ldb       #SNBYTES            ; How many sensor bytes are we saving
                    abx                           ; Add in the sensor count
                    pshx                          ; save the intermediate value
                    abx                           ; Do it again, to see if we run off the end
                    cpx       #ENDRAM             ; Are we over the top of our RAM?
                    bcs       SCANTI6             ; Jump if HISEND is larger...don't wrap yet
                    pulx                          ; Pop the stack of X, but we don't need it
                    ldx       #HISTOP             ; Must reset the value
                    bra       SCANTI7             ; Exit and save the value

SCANTI6             pulx                          ; Yank of our new index value
SCANTI7             stx       HFLINK              ; Save it for the next scan

          ; Now bump the number of scan values till we reach the max

                    ldx       NUMSCAN             ; Get the number of scans
                    cpx       #MAXSCAN            ; Are we over?
                    beq       Done@@              ; We are done...jump and exit
                    inx                           ; We did yet another
                    stx       NUMSCAN             ; Save the current scan counter

Done@@              jsr       DNSAVE              ; Save the vital data back to the CP290
                    jsr       NORMODE             ; Return LCD state to normal
                    rts                           ; Return to the main loop

;******************************************************************************
; DOLOCAL - Handles Local switch activity
;******************************************************************************
; Routine: This routine is called from the major loop to execute commands
;       from the local switches
; Switch Panel is connected as follows:
;       PC0 - Load/Rew
;       PC1 - Online
;       PC2 - Unload
;       PC3 - Reset
;       PC4 - Test
;       PC5 - Step
;       PC6 - Execute
;       PC7 - CE
;       PA0 - On
;       PA1 - Off
;******************************************************************************

DOLOCAL             proc
                    bcc       Done@@              ; Nothing to do...jump
                    jsr       SGATHER             ; Fetch the current conditions
                    lda       DSPOINT             ; Get switch to display
                    jsr       SETMODE             ; Show what is requested by the user
Done@@              clc                           ; Clear the carry flag for the main loop
                    rts                           ; Return to the main loop

;******************************************************************************
; ITOA - Converts a byte a ASCII string
;******************************************************************************
; Routine: This routine takes a byte given in A and converts it to its
;       ASCII representation.     $80 (-128) -> $7F (127)
; Inputs:       A       - is the byte to convert
;               UNSIGN  - is a flag value to indicate we want an unsigned
;                       conversion i.e. 0 -> $FF = 255
;               UNPAD   - is a flag value to indicate we do NOT want to
;                       pad the end of the number with spaces
; Outputs:      ITOAC   - is a 5 byte character string.   The last char
;                       will contain a 04 to terminate the string.  The
;                       string will be padded with spaces at the end.
; All registers are saved
;******************************************************************************

ITOA                proc                          ; byte -> ASCII
                    pshx                          ; save the registers
                    pshy
                    pshb
                    psha                          ; save A last because we use it again
                    tab                           ; Put A in the B reg

                    ldy       #ITOAC              ; Get the address of the character buffer
                    lda       #ASPACE             ; This is an ASCII space
                    sta       1,y                 ; Save it
                    sta       2,y                 ; Save it
                    sta       3,y                 ; Save it
                    lda       #EOTEXT             ; EOT value for the end of the string
                    sta       4,y                 ; Save it
                    tst       UNSIGN              ; See if we are doing an unsigned convert
                    bne       ITOA1               ; Jump and do a unsigned conversion

                    tstb      See                 ; if the given value is negative
                    bpl       ITOA1               ; If it is positive...then don't worry with sign
                    lda       #45                 ; The number is negative so store a "-"
                    sta       ,y                  ; Store the negative
                    iny                           ; Point to the next value
                    comb                          ; Complement B
                    incb                          ; One's complement so add 1

ITOA1               equ       *                   ; Here B has the value we want to convert
                    clra                          ; Clear the upper bits for the D register
                    ldx       #10                 ; This is our divisor
                    idiv                          ; make the first conversion
                    pshb                          ; Save the 'ones' value on the stack
                    xgdx                          ; Put the whole number back in the D register
                    ldx       #10                 ; This is our divisor again
                    idiv                          ; make the second conversion
                    pshb                          ; Save the 'tens' value on the stack
                    xgdx                          ; Get the 'hundreds' back into the D register
                    tstb      See                 ; if there are any 'hundreds' (1xx or 2xx)
                    beq       ITOA2               ; No...it is zero, go on to the tens
                    orb       #$30                ; Make it a ASCII number
                    stb       ,y                  ; Save the value
                    iny                           ; Point to the next value
ITOA2               pulb                          ; Get the 'tens' value
                    tstb      See                 ; if there are any 'tens' (xNx)
                    beq       ITOA3               ; No...it is zero, go on to the ones
                    orb       #$30                ; Make it a ASCII number
                    stb       ,y                  ; Save the value
                    iny                           ; Point to the next value
ITOA3               pulb                          ; Get the 'ones' value
                    orb       #$30                ; Make it a ASCII number...it will be at least 0
                    stb       ,y                  ; Save the value
                    tst       UNPAD               ; See if we are not to pad the number
                    beq       ITOA4               ; Jump, already paded, and exit
                    lda       #EOTEXT             ; End of Text marker
                    sta       1,y                 ; End the string without space padding

ITOA4               pula                          ; Restore the registers
                    pulb
                    puly
                    pulx
                    rts                           ; Return to the caller

;******************************************************************************
; ITWOA - Converts a value in A to 2 ASCII chars returned in D
;******************************************************************************
; Routine: This routine takes a byte given in A and converts it into
;       two ASCII characters.   This is used for date and time display.
; Inputs:       A       - is the byte to convert
; Outputs:      D       - is two bytes of ASCII between 00 and 99
; NOTE:         X is saved
;******************************************************************************

ITWOA               proc                          ; byte -> ASCII 00-99
                    pshx                          ; save the X register
                    tab                           ; Put A in the B reg
                    clra                          ; Clear the upper bits for the D register
                    ldx       #10                 ; This is our divisor
                    idiv                          ; make the first conversion
                    pshb                          ; Save the 'ones' value on the stack
                    xgdx                          ; Put the whole number back in the D register
                    ldx       #10                 ; This is our divisor again
                    idiv                          ; make the second conversion
                    tba                           ; Save the 'tens' value in A
                    ora       #$30                ; Make it a ASCII number
                    pulb                          ; Restore B as our 'ones' value
                    orb       #$30                ; Make it a ASCII number
                    pulx                          ; Restore the X register
                    rts                           ; Return to the caller

;******************************************************************************
; HOMECLR - Sends the home & clear screen commands to the PeeCee
;******************************************************************************
; Function: This routine sends the VT100 escape sequence to home and then
;       clear the screen.

HOMECLR             proc                          ; Home and Clear the screen
                    ldx       #HACMSG1            ; This is the escape sequence
                    bsr       OUTSTRN             ; Send it out.
                    bsr       HOMEIT              ; Send it out.
                    bsr       WAIT500             ; Delay one half second
                    rts                           ; Return to the main loop

;******************************************************************************
; HOMEIT  - Sends the home the cursor screen commands to the PeeCee
;******************************************************************************
; Function: This routine sends the VT100 escape sequence to home the
;       cursor

HOMEIT              proc                          ; Home the curson
                    ldx       #HACMSG2            ; This is the escape sequence
                    bsr       OUTSTRN             ; Send it out.
                    rts                           ; Return to the main loop

;******************************************************************************
; OUTSTRG - Sends a string to the PeeCee
;******************************************************************************
; Function: This function will send a character string to the PeeCee.
;       The string is terminated by an EOT (End of Text) character.
;       This routine is the same as BUFFALO except this one does not
;       pause for ^W
; Note: There are two entry points for this routine, the first OUTSTRG
;       does a LF/CR sequence before the string is output and  OUTSTRN
;       just sends the text without the carriage control

OUTSTRG             proc                          ; Sends a character string to the PeeCee
                    jsr       OUTCRLF             ; Send a carriage return
;                   bra       OUTSTRN

;*******************************************************************************

OUTSTRN             proc                          ; Just send the string
                    lda       ,x                  ; Get the next character in the string
                    cmpa      #EOTEXT             ; See if we are at the end
                    beq       Done@@              ; Yes...jump and exit
                    jsr       OUTPUT              ; Send it out
                    inx                           ; Bump the index to the next char
                    bra       OUTSTRN             ; Continue to loop
Done@@              rts                           ; Return to the caller

;******************************************************************************
; LCDINIT - Sends a setup string to the LCD
;******************************************************************************
; Function: This function will send the init sequence to the LCD and
;       then display the Welcome message.

LCDINIT             proc
                    bsr       LCDRSEL             ; Select for register output
                    ldx       #LCDSIP             ; This is the init string
                    bsr       LCDLOOP             ; Send it out
                    lda       #2                  ; This is a 2*25msec delay
                    bsr       DELAYIT             ; Initialize the wait loop
Loop@@              bsr       DELAY               ; Wait here
                    bcc       Loop@@              ; Until it is over
                    ldx       #LCDWEL             ; Welcome message
                    bsr       LCDTOP              ; Send it out
                    rts

;******************************************************************************
; LCDTOP - Sends a string to the LCD top line
;******************************************************************************
; Function: This function will send a character string to the LCD
;       The string is terminated by an EOT (End of Text) character.

LCDTOP              proc                          ; Sends a character string to the top LCD line
                    pshx                          ; save the index of the string
                    bsr       LCDRSEL             ; Register select
                    lda       #$80                ; Top line of the LCD
                    bra       LCDDOIT             ; Send it out

;******************************************************************************
; LCDBOT - Sends a string to the LCD bottom line
;******************************************************************************

LCDBOT              proc                          ; Sends a character string to the bottom line
                    pshx                          ; save the index of the string
                    bsr       LCDRSEL             ; Register select
                    lda       #$C0                ; Bottom line of the LCD
;                   bra       LCDDOIT

;*******************************************************************************

LCDDOIT             proc                          ; Send it out
                    sta       PORTB               ; Set the correct address
                    fdiv                          ; Wait for the LCD
                    fdiv                          ; Wait for the LCD
                    bsr       LCDDSEL             ; Put is back in data mode
                    pulx                          ; Get the data address back
;                   bra       LCDLOOP

;*******************************************************************************

LCDLOOP             proc
Loop@@              lda       ,x                  ; Get the next character in the string
                    cmpa      #EOTEXT             ; See if we are at the end
                    beq       Done@@              ; Yes...jump and exit
                    sta       PORTB               ; Send it out
                    inx                           ; Bump the index to the next char
                    pshx                          ; save the register
                    fdiv:2                        ; Wait for the LCD
                    pulx                          ; Restore the register
                    bra       Loop@@              ; Continue to loop

Done@@              clra                          ; This last command just clears the HEX display
                    coma                          ; On the front of the cabin monitor
                    sta       PORTB               ; Send it out
                    rts                           ; Return to the caller

;******************************************************************************
; LCDDSEL - Selects LCD data input
;******************************************************************************

LCDDSEL             proc                          ; Setup the LCD for data output
                    ldx       #PORTA              ; Get the A port register
                    bset      ,x,LCDRSD           ; Set the RS flag for data
                    rts                           ; Return to caller

;******************************************************************************
; LCDRSEL - Selects LCD register input
;******************************************************************************

LCDRSEL             proc                          ; Setup the LCD for register input
                    ldx       #PORTA              ; Get the A port register
                    bclr      ,x,LCDRSD           ; Clear the RS flag for register input
                    rts                           ; Return to caller

;******************************************************************************
; WAITONE - Delays one second
;******************************************************************************
; Function: This routine simply returns to the user after one second

WAITONE             proc                          ; Waits one second
                    psha                          ; save this register
                    lda       #40                 ; This will be a one second delay
                    bsr       DELAYIT             ; Setup the delay timer
Loop@@              bsr       DELAY               ; This is our loop
                    bcc       Loop@@              ; Continue to wait
                    pula                          ; Restore this register
                    rts                           ; Return to the main loop

;******************************************************************************
; WAIT500 - Delays 500 msec
;******************************************************************************
; Function: This routine simply returns to the user after a half second

WAIT500             proc                          ; Waits one half second
                    psha                          ; save this register
                    lda       #20                 ; This will be a 500 msec delay
                    bsr       DELAYIT             ; Setup the delay timer
Loop@@              bsr       DELAY               ; This is our loop
                    bcc       Loop@@              ; Continue to wait
                    pula                          ; Restore this register
                    rts                           ; Return to the main loop

;**************************************************************************
; DELAY - Wait/delay loop
;**************************************************************************
; Routine:  This routine will provide a variable delay.   It will use
;       the DELAYIT to set the value to determine how much delay
;       should be provided.    This routine is intended to be called
;       in conjunction with the routine that is being timed.
;       DELAYIT - This is the initialization/setup routine which must
;       be called to ready the DELAY routine for operation
; Inputs: DELAYWS is a byte value of the number of milliseconds to
;       delay.
; Outputs: The carry flag is set when the delay is completed, otherwise
;       the carry is cleared.
; All registers are saved

DELAY               proc                          ; Delay the given number of MS
                    psha                          ; save the register
                    clc                           ; Assume we have not exausted the timer
                    lda       TFLG1               ; Get the main timer interrupt flag register
                    anda      #TOC5F              ; Looking for output compare on timer 5 flag
                    beq       Done@@              ; It is not time yet...jump

          ; Here the timer has gone off so we have waited 25 msec.
          ; Now check the working register to see if there is more to do.

                    tst       DELAYWK             ; See if there is more time to wait
                    beq       Timeout@@           ; No...we are timed out...jump
                    dec       DELAYWK             ; Count it down
                    bsr       DELAYUP             ; Reset the timer compare register
                    clc                           ; Clear the carry in case it was set by the ADDD
                    bra       Done@@              ; Continue to wait

Timeout@@           sec                           ; Yes...we have a timeout
Done@@              pula                          ; Restore the register
                    rts                           ; Return to the caller

;**************************************************************************
; DELAYIT - Setup Routine for DELAY
;**************************************************************************

DELAYIT             proc                          ; Setup routine for the DELAY function
                    pshd                          ; save the registers
                    sta       DELAYWK             ; Put it in our working area
                    bsr       DELAYUP             ; Setup the timer for the compare
                    puld                          ; Restore the registers
                    rts                           ; Return to the caller

;**************************************************************************
; DELAYUP - Setup the timer compare for DELAY
;**************************************************************************

DELAYUP             proc                          ; Reset the timer for action
                    ldd       TCNT                ; Get the timer counter
                    addd      #$C350              ; This is 25 ms (2Mh/1) 0.5 usec ticks
                    std       TOC5                ; Put it in the output compare
                    lda       #TOC5F              ; Reset the TOC5 compare
                    sta       TFLG1               ; By writing it back with a 1
                    rts                           ; Return to the caller

;**************************************************************************
; SETUPCP - Setup Routine for the CP290
;**************************************************************************
; Routine: This module is used when the CP290 has been powered down
;       and needs to be reloaded with the time, date, housecode and
;       timer event information.

SETUPCP             proc                          ; Setup routine for the CP290
                    bsr       WHATIME             ; Get the date and time from the user
                    bcc       SETUPC9             ; The user is gone...exit
                    ldx       #DNWAIT             ; Load the information message to wait
                    jsr       OUTSTRG             ; Send it out
;                   bra       SETUPC4

;*******************************************************************************
; This entry point is from the CSSINIT routine which will load the
; CP290 from the preset values...the battery backup has failed in
; the CP290

SETUPC4             proc
                    jsr       SETIME              ; Set the housecode and time into the CP290

          ; Now we save the date and time as our cold start value

                    ldy       #COLDATE            ; Location to save into
                    jsr       SAVTIME             ; Copy the time we began from scratch

          ; Here we clear out some of the data structures to act as a soft reset

                    clr       SMDOOR+DCOUNT       ; Clear the open/closed counts
                    clr       SBDOOR+DCOUNT       ; Ditto
                    clr       SNDOOR+DCOUNT       ; Ditto
                    clr       SSDOOR+DCOUNT       ; Ditto

                    jsr       DNSCAN              ; Download the scan events
                    jsr       DNSAVE              ; Save the necessary data
                    jsr       SGATHER             ; Gather the inital scan data
                    jsr       HISETUP             ; Restart our history data
SETUPC9             rts                           ; Return to the caller

;**************************************************************************
; WHATIME - Get the date and time from the user
;**************************************************************************
; Routine:

WHATIME             proc
                    clr       TFLAG               ; This is the counter for two defaults
Loop@@              ldx       #ASKTDAY            ; Load up the time request message
                    jsr       OUTSTRG             ; Send it out
                    inc       ECHOIT              ; Make sure the user sees this
                    jsr       GETSTR              ; See what we get back
                    bcc       Done@@              ; The user is gone...exit

          ; Now we parse out the time and date as given by the user
          ; In the input buffer we should have DD-MM-YY:HH:MM

                    ldx       #CBUFF              ; Address the input buffer
                    tst       CBUFFPT             ; See if this is zero indicating just a CR
                    bne       Go@@                ; We have something...go see what it is
                    inc       TFLAG               ; Ask again the same question...twice
                    lda       TFLAG               ; Load the counter
                    cmpa      #2                  ; Are we done?
                    bne       Loop@@              ; NO...jump and ask again
                    clc                           ; We have had enough
                    bra       Done@@              ; Get out

Go@@                ldy       #CURTIM             ; This is where we store the information
                    clr       TFLAG               ; This is the counter of for char parsed
DLoop@@             ldd       ,x                  ; Get the two ASCII characters
                    jsr       ATOI                ; Convert it to a number
                    bvs       WHATIME             ; Conversion error...ask date again
                    sta       ,y                  ; Save the value
                    inx:3                         ; Bump the index 3 times
                    iny:2                         ; Step to the next save value YR (HR) MON (MIN) DAY
                    inc       TFLAG               ; Increment the loop counter
                    lda       TFLAG               ; Load the counter
                    cmpa      #3                  ; Are we done with YR MON DAY ?
                    bne       Cont@@              ; No...jump and continue
                    ldy       #CURHR              ; Reset the index value
Cont@@              cmpa      #5                  ; Are we done?
                    bne       DLoop@@             ; Continue to process the data

          ; Now we have converted all the data.
          ; Give the user the chance to change it if we did not get it right

                    ldx       #DSPMSGE            ; The 'the current time' header message
                    jsr       OUTSTRG             ; Send it out
                    ldx       #CURTIM             ; Current time location
                    jsr       SHOWTIM             ; Display the time
                    jsr       GETYSNO             ; Ask if this is correct
                    bcc       Done@@              ; User is gone...return to the main
                    bvc       WHATIME             ; Jump and ask the user the time again
Done@@              rts                           ; Return to the caller

;**************************************************************************
; SETIME - Set the housecode and time into the CP290
;**************************************************************************
; Routine: This routine takes the time values in the CURxx and loads
;       them to the CP290.   This routine is called from the DOMODEM
;       loop when we notice that the CP290 has been powered down.
;       NOTE: Before we set the time we load down the housecode

SETIME              proc                          ; Set the housecode and time into the CP290
                    ldx       #CPFIFO             ; This is where we will place the commands
                    clra                          ; Command is download base housecode
                    sta       ,x                  ; Save it
                    lda       #$10                ; Housecode E
                    sta       1,x                 ; Save it
                    lda       #2                  ; Just two bytes...nochecksum
                    jsr       SENDCP              ; Send it out

          ; Now make the time command and send it down

                    ldx       #CPFIFO             ; This is where we will place the commands
                    lda       #DNTIME             ; Command the CP290 to download the time
                    sta       ,x                  ; Save it
                    clra                          ; This will be our checksum
                    ldb       CURMIN              ; Get the current minutes
                    aba                           ; Add in the checksum
                    stb       1,x                 ; Save it
                    ldb       CURHR               ; Get the current hour
                    aba                           ; Add in the checksum
                    stb       2,x                 ; Save it
                    ldy       #DAYMAP             ; Address the map between CP290 days
                    ldb       WKWDAY              ; Get the weekday value
                    aby                           ; Bump the index
                    ldb       ,y                  ; Fetch the day in CP290 bitmap format
                    aba                           ; Add in the checksum
                    stb       3,x                 ; Save it
                    sta       4,x                 ; Save it...last is the checksum

          ; Now we have built the command...send it to the CP290

                    lda       #5                  ; Bytes to send
                    jsr       SENDCP              ; Send it to the device
                    rts                           ; Return to the caller

;**************************************************************************
; DNSCAN - Download the scan events
;**************************************************************************
; Routine: This routine is used to download the events into the CP290
;       which are used to signal the CSS that a SCAN event is to occur.
;       There are 24 scan events, one per hour.   Each event is coded
;       using the upper bits of the unit code (units 12-16) as the
;       indicator for which event.   The events are stored in the CP290
;       at locations starting with 101 - 124.   The lower order events
;       can still be used by the CP290 for actual timer events.

DNSCAN              proc                          ; Download the scan events
                    clr       TFLAG               ; This will be our event counter

; Here we begin our main loop to load down the timer events

Loop@@              ldx       #CPFIFO             ; This will be our send buffer
                    lda       #DNLOAD             ; CP290 command to download events
                    sta       ,x                  ; 17 - Save the command
                    lda       TFLAG               ; Load the loop counter
                    cmpa      #24                 ; If we have done a days worth then
                    beq       Done@@              ; Jump and we are done

                    clra                          ; Clear the top of the D register
                    ldb       TFLAG               ; Load the loop counter
                    lsld:3                        ; Shift it up 3 times
                    stb       1,x                 ; 18, Low order first
                    sta       2,x                 ; 19 - Save it away

          ; Now we have to keep a checksum, which will be in the A register

                    clra                          ; Clear the checksum
                    ldb       #$08                ; Mode is NORMAL, everyday
                    stb       3,x                 ; 20 - Store the MODE
                    aba                           ; Add the checksum
                    ldb       #$7F                ; Bit map of days...all days
                    stb       4,x                 ; 21 - Store the DAYS
                    aba                           ; Add the checksum
                    ldb       TFLAG               ; Get the event counter
                    stb       5,x                 ; 22 - Save the HOUR
                    aba                           ; Add the checksum
                    clrb                          ; The minutes will always be zero
                    stb       6,x                 ; 23 - Save the MINUTE
                    stb       7,x                 ; 24 - Bit map of units is also zero
                    ldb       TFLAG               ; Get event number, this will be saved here
                    incb                          ; This will be indexed from 1 not 0
                    stb       8,x                 ; 25 - Unit codes 9-16
                    aba                           ; Add the checksum
                    ldb       #$F0                ; House code 'J'
                    stb       9,x                 ; 26 - Load dummy housecode
                    aba                           ; Add the checksum
                    ldb       #$03                ; This function is OFF
                    stb       10,x                ; 27 - Load the level/function
                    aba                           ; Add the checksum
                    sta       11,x                ; 28 - Save the checksum

          ; The message has been created, now send it off to the CP290

                    lda       #12                 ; Twelve bytes to send
                    jsr       SENDCP              ; Send the command
                    inc       TFLAG               ; Increment the loop counter
                    bra       Loop@@              ; Continue to loop

Done@@              rts                           ; Return to the caller

;**************************************************************************
; DNSAVE - Download the save area
;**************************************************************************
; Routine: This routine is used to download the save area to the CP290
;       We use this as a way to save our volitle memory into the CP290
;       so if we loose power, we can come back up, reload an be ready.
;       Location CP2SAVE is where we begin to save data till we are done.
;       Location CP2QUIT is where we end the transfer
;       The CP290 command saves two bytes, so we loop through here enough
;       times to transfer the data < 512 bytes

DNSAVE              proc                          ; Download the save area
                    jsr       CPINIT              ; Setup the host port for the CP290
                    lda       #STSAVE             ; New state
                    jsr       SETMODE             ; Change it
                    ldy       #CP2SAVE            ; Address to start saving data
                    clr       TFLAG               ; This will be used in our CP290 address

          ; Here we begin our main loop to load down the 'graphics' events

Loop@@              ldx       #CPFIFO             ; This will be our send buffer
                    lda       #DNLOAD             ; CP290 command to download events
                    sta       ,x                  ; 17 - Save the command
                    ldb       TFLAG               ; Load the loop counter
                    clra                          ; We will use a double register
                    lsld                          ; Shift it up one
                    stb       1,x                 ; 18 - lower address
                    ora       #$04                ; Turn on D2
                    sta       2,x                 ; 19 - Save the upper address byte
                    clra                          ; This will be our checksum
                    ldb       ,y                  ; Get the data byte
                    iny                           ; Bump to the next address
                    aba                           ; Add in the checksum
                    stb       3,x                 ; 20 - Save the data in the command
                    ldb       ,y                  ; Get the data byte
                    iny                           ; Bump to the next address
                    aba                           ; Add in the checksum
                    stb       4,x                 ; 21 - Save the data in the command
                    sta       5,x                 ; 22 - Store the checksum

          ; The message has been created, now send it off to the CP290

                    lda       #6                  ; Half a dozen bytes to send
                    bsr       SENDCP              ; Send the command
                    inc       TFLAG               ; Bump our CP290 address
                    cpy       #CP2QUIT            ; See if we have done enough
                    bls       Loop@@              ; Continue to loop

                    jsr       NORMODE             ; Return LCD state to normal
                    rts                           ; Return to the caller

;**************************************************************************
; UPSAVED - Upload the save area from the CP290
;**************************************************************************
; Routine: Sends the request graphics command to the CP290 which will
; start sending our saved data, which we load back into memory.
; We start at CP2SAVE location and end with CP2QUIT.   The rest of the
; data from the CP290 is ignored.
; A good upload will set the carry flag.
; A bad upload then carry is clear.

UPSAVED             proc                          ; Restore the save area from CP290
                    jsr       CPINIT              ; Setup the host port for the CP290
                    lda       #STREST             ; New state
                    jsr       SETMODE             ; Change it
                    jsr       SNDSNC              ; Send the sync bytes
                    lda       #REQDATA            ; Request the data download
                    jsr       CPUT290             ; Send the command to the CP290

          ; Get ready...here comes the data...six bytes of sync,
          ; status, then data

                    lda       #6                  ; This is number of sync bytes to throw away
UPSAVE0             psha                          ; save it for our looping
                    bsr       UPREST              ; Reset the watch dog timer
UPSAVE1             jsr       CP290IN             ; Get any data from the CP290
                    bcs       UPSAVE2             ; We got a character
                    jsr       DELAY               ; See if we should abort this loop
                    bcc       UPSAVE1             ; Continue to loop...
                    pula                          ; We failed...exit
                    bra       Fail@@              ; Signal failure and return

UPSAVE2             pula                          ; Get A back
                    deca                          ; Count it down
                    bne       UPSAVE0             ; Continue to look for data

          ; The next data word will tell us if the CP290 has valid data

                    bsr       UPREST              ; Reset the watch dog timer
UPSAVE3             jsr       CP290IN             ; Get any data from the CP290
                    bcs       UPSAVE4             ; We got a character
                    jsr       DELAY               ; See if we should abort this loop
                    bcc       UPSAVE3             ; Continue to loop...
                    bra       Fail@@              ; Signal failure and return

UPSAVE4             deca                          ; A should equal 1 and a decrement be zero
                    bne       Fail@@              ; This is bad...jump and get out

          ; Now we begin our restore loop

                    ldy       #CP2SAVE            ; Address to start restoring data
UPSAVE5             bsr       UPREST              ; Reset the watch dog timer
UPSAVE6             jsr       CP290IN             ; Get any data from the CP290
                    bcs       UPSAVE7             ; We got a character
                    jsr       DELAY               ; See if we should abort this loop
                    bcc       UPSAVE6             ; Continue to loop...
                    bra       Fail@@              ; Signal failure and return

UPSAVE7             sta       ,y                  ; Restore the data
                    iny                           ; Bump the index
                    cpy       #CP2QUIT            ; See if we have done enough
                    bls       UPSAVE5             ; Continue to loop
                    sec                           ; We are done...set carry and exit
                    bra       Done@@              ; Get out

Fail@@              lda       #STCPDN             ; New state
                    jsr       SETMODE             ; Change it
                    clc                           ; Bad return...clear the carry flag
Done@@              rts                           ; Return to the caller

;**************************************************************************
; UPREST - Reset watch dog timer, support routine for UPSAVED
;**************************************************************************

UPREST              proc                          ; Reset the watch timer
                    psha                          ; save A
                    clr       PCFPTR              ; Clear PeeCee FIFO forward pointer
                    lda       #40                 ; This is 1 second (25msec * 40)
                    jsr       DELAYIT             ; Initialize the wait loop
                    pula                          ; Bring A back
                    rts                           ; Return to the caller

;**************************************************************************
; SENDCP - Send the command to the CP290
;**************************************************************************
; Routine: Send a data/command to the CP290 from the CPFIFO
; The A register contains the number of bytes to send following
;       the 16byte sync.   The data is contained in the CPFIFO.

SENDCP              proc
                    sta       CPFPTR              ; Save it in the forward pointer
                    clr       CPBPTR              ; Clear the backward FIFO pointer
                    lda       SCSR                ; Read the SCI status register
                    lda       SCDAT               ; To clear any left over data in the read reg
                    jsr       SNDSNC              ; Send the sync bytes

          ; Here we loop until all the data has been sent

Loop@@              jsr       CP290OUT            ; Do the send
                    ldb       CPFPTR              ; Get the forward FIFO pointer
                    cmpb      CPBPTR              ; See if there is anything to send
                    bne       Loop@@              ; Continue to loop until FIFO is empty

          ; See if we get an ACK back from the CP290

                    lda       #7                  ; We expect to get these bytes back
                    jsr       GETCPD              ; Give the CP290 a chance
                    lda       PCFPTR              ; See if we got anything back
                    beq       SendError@@         ; Send error message
                    cmpa      #7                  ; Should be seven bytes
                    beq       Done@@              ; This is good

SendError@@         ldx       #CPDOWN             ; Load the bad news
                    jsr       OUTSTRG             ; Send it out
                    lda       #STCPDN             ; New state
                    jsr       SETMODE             ; Change it
Done@@              rts                           ; Return to the caller

;**************************************************************************
; GETYSNO - As the user if this is OK
; Routine: Get the user to say Yes or No.
;       If Carry is Clear, then the user is gone
;       If Overflow is Clear, then the user's answer is NO
;               Overflow set is YES

GETYSNO             proc
                    ldx       #ASKYSNO            ; Is this OK message
                    jsr       OUTSTRG             ; Send it out
                    jsr       GETSTR              ; Get the user pick
                    bcc       Gone@@              ; User is gone...so are we
                    lda       CBUFF               ; Get the first character
                    cmpa      #CAPTOLY            ; It must be a 'Y'
                    bne       Gone@@              ; No...jump and get out
                    sev                           ; Yes...we have an YES
                    sec                           ; And set the carry flag as well
                    bra       Done@@              ; Jump and exit
Gone@@              clv                           ; Clear the overflow flag
Done@@              rts                           ; Return to the user

;**************************************************************************
; MEMCPY - Copy a string of bytes
;**************************************************************************
; CPYDATE - Copy the X time into location Y
;**************************************************************************
; SAVTIME - Copy the current time into location Y
;**************************************************************************
; This routine copies a string of bytes
; The registers:
;       X - Input string address
;       Y - Output string address
;       A - Count of bytes to copy
; A, B and X registers are saved and restored

SAVTIME             proc                          ; Save the current date/time 6 bytes
                    psha                          ; save A on the stack
                    lda       #6                  ; Six date bytes
                    pshx                          ; save X on the stack
                    ldx       #CURTIM             ; This is the current time location
                    bra       MEMCPY1             ; Continue with the copy

;*******************************************************************************

CPYDATE             proc                          ; Save the X date in the Y location
                    psha                          ; save A on the stack
                    lda       #6                  ; Six date bytes
                    pshx                          ; save X on the stack
                    bra       MEMCPY1             ; Continue with this copy

;*******************************************************************************
; MEMCPY - Copy memory bytes

MEMCPY              proc                          ; Copy A bytes from X -> Y
                    psha                          ; save A on the stack
                    pshx                          ; save X on the stack
;                   bra       MEMCPY1

;*******************************************************************************

MEMCPY1             proc
                    pshb                          ; Save B on the stack
Loop@@              ldb       ,x                  ; Get the value
                    inx                           ; Bump the input index
                    stb       ,y                  ; Save the value
                    iny                           ; Bump the output index
                    deca                          ; Decrement our count
                    bne       Loop@@              ; Continue till count is exausted
                    pulb                          ; Pull them off the stack
                    pulx                          ; In backward order
                    pula                          ; Restore the registers
                    rts                           ; Return to the user

;*******************************************************************************
; SHOWTIM - Display the time
;*******************************************************************************

; Routine: This routine displays the date/time to the user.

; Input:
;       X - Points to the date/time values to print

; All registers are saved

SHOWTIM             proc                          ; Display the time
                    psha                          ; save A on the stack
                    pshb                          ; Save B on the stack
                    pshx                          ; save X register
                    pshy                          ; Save Y as well

                    ldy       #DSPTIM             ; Display time location
                    bsr       CPYDATE             ; Copy the time

          ; This check was added to see if the date was valid.
          ; We look at the year

                    lda       DSPYR               ; Get the display year
                    cmpa      #BDYR               ; See if we are in the correct range
                    bge       Go@@                ; This is valid...jump and continue
                    ldx       #DSPMSGK            ; Address the string <none> for the date
                    jsr       OUTSTRN             ; Send it out
                    jmp       Done@@              ; Get out

          ; Printout Sunday, etc.

Go@@                jsr       WHATDAY             ; What is the day of the week
                    ldy       #DAYOFWK            ; Address the day table
                    ldb       WKWDAY              ; Get the weekday
                    lslb                          ; Multiply by 2 to get the offset
                    aby                           ; Offset into the table
                    ldx       ,y                  ; Get the day's address
                    jsr       OUTSTRN             ; Send it out

                    ldy       #MTABLE             ; Address of the month
                    ldb       DSPMON              ; Get the display month
                    lslb                          ; Multiply by 2 to get the offset
                    aby                           ; Offset into the table
                    ldx       ,y                  ; Get the month's address
                    jsr       OUTSTRN             ; Send it out

                    inc       UNPAD               ; No padding on this value
                    lda       DSPDAY              ; Get the display day
                    jsr       PRINTA              ; Convert it to ASCII and print it out
                    clr       UNPAD               ; We can have padding now

                    ldx       #SHOWT20            ; Address the string ,20
                    jsr       OUTSTRN             ; Send it out
                    lda       DSPYR               ; Get the year again
                    jsr       ITWOA               ; Two char only
                    pshb                          ; Save the 'ones' number
                    jsr       OUTPUT              ; Send it out the 10s
                    pula                          ; Get the 'ones' back
                    jsr       OUTPUT              ; Send it out
                    lda       #ASPACE             ; Send a space
                    jsr       OUTPUT              ; Send it out

          ; Now we print the hour and minutes

                    lda       DSPHR               ; Hours
                    jsr       ITWOA               ; Two char only
                    pshb                          ; Save the 'ones' number
                    jsr       OUTPUT              ; Send it out
                    pula                          ; Get the 'ones' back
                    jsr       OUTPUT              ; Send it out

                    lda       #ACOLON             ; Send a :
                    jsr       OUTPUT              ; Send it out

                    lda       DSPMIN              ; Minutes
                    jsr       ITWOA               ; Two char only
                    pshb                          ; Save the 'ones' number
                    jsr       OUTPUT              ; Send it out
                    pula                          ; Get the 'ones' back
                    jsr       OUTPUT              ; Send it out

                    lda       #ACOLON             ; Send a :
                    jsr       OUTPUT              ; Send it out

                    lda       DSPSEC              ; Seconds
                    sta       CBUFFOV             ; Save it here
                    lda       #59                 ; Sixty seconds
                    suba      CBUFFOV             ; We count down from 59 so we must subtract
                    jsr       ITWOA               ; Two char only
                    pshb                          ; Save the 'ones' number
                    jsr       OUTPUT              ; Send it out
                    pula                          ; Get the 'ones' back
                    jsr       OUTPUT              ; Send it out

Done@@              puly                          ; In
                    pulx                          ; Backward
                    pulb                          ; Order we
                    pula                          ; Restore the registers
                    rts                           ; Return to the caller

;**************************************************************************
; ATOI - Converts ASCII to Integer
;**************************************************************************
; Routine: This routine converts the two character ASCII number
;       that is in the D register to a integer and returns it
;       in the A register.     The ASCII number should be between
;       30-39 hex.   If it is not then we force the value to zero,
;       and set the OVERFLOW flag

ATOI                proc                          ; Converts ASCII to Integer
                    andb      #$0F                ; Strip off the upper bits
                    cmpb      #09                 ; See if we have a conversion problem
                    bgt       Fail@@              ; Bad...something greater than 9
                    anda      #$0F                ; Strip off the upper bits
                    cmpa      #09                 ; See if we have a conversion problem
                    bgt       Fail@@              ; Bad...something greater than 9
                    pshb                          ; Save B ONEs for the moment
                    ldb       #10                 ; This is for the TENs value
                    mul                           ; Multiply A by 10
                    pula                          ; Get the ONEs value back
                    aba                           ; Add them together
                    clv                           ; Clear the overflow flag...good number
                    bra       Done@@              ; Good exit

Fail@@              clra                          ; Error...return zero
                    sev                           ; Set the overflow flag...bad number
Done@@              rts                           ; Return to the caller

;**************************************************************************
; BUMPDAY - Count the days go by
;**************************************************************************
; Routine: This routine simply counts from it's designated birthday
;       Howard B. Stephens, August 25, and uses this as its birthday
;       (the Cabin System) in 1995 which was a Friday.
;       Note: it was also a Friday for 25Aug2000

BUMPDAY             proc                          ; Go to the next day
                    ldx       #DAYMON             ; Get the days of the month table
                    ldb       WKMON               ; Get the working month
                    abx                           ; This is our offset into the table
                    lda       ,x                  ; Get the number of days this month

          ; Now we check to see if it is leap year...then if it is February

                    ldb       WKLEAP              ; Get the Leap Year value
                    cmpb      #4                  ; Every 4th year is leap year
                    bne       Cont@@              ; No...continue as normal
                    ldb       WKMON               ; Get the working month
                    cmpb      #2                  ; Is it February?
                    bne       Cont@@              ; No...jump and continue
                    inca                          ; OK, Leap Year! There are 29 days this month.
Cont@@              cmpa      WKDAY               ; Are we at the end of the month?
                    bne       Done@@              ; No...jump and continue to count
                    clr       WKDAY               ; We must start over...end of the month
                    bsr       NEXTMON             ; Bump the working month
Done@@              inc       WKDAY               ; Go to the next day
                    bsr       NEXTDAY             ; Go to the next weekday
                    rts                           ; Return to the caller

;**************************************************************************
; NEXTDAY - Moves the week day value
;**************************************************************************
; Routine: This routine simply moves the working weekday counter
; NOTE: Counter is indexed from 1

NEXTDAY             proc                          ; Go to the next weekday
                    inc       WKWDAY              ; Next day of the week
                    lda       WKWDAY              ; Get the value
                    cmpa      #8                  ; See if we have turned a new week
                    bne       Done@@              ; No...jump and return to the caller
                    lda       #1                  ; Start over
                    sta       WKWDAY              ; It is a new week...Sunday
Done@@              rts                           ; Return to the caller

;**************************************************************************
; NEXTMON - Moves the month value
;**************************************************************************
; Routine: This routine simply moves the working month counter
; NOTE: Counter is indexed from 1

NEXTMON             proc                          ; Go to the next month
                    inc       WKMON               ; Next month
                    lda       WKMON               ; Get the value
                    cmpa      #13                 ; See if we have turned a new year
                    bne       Done@@              ; No...jump and return to the caller
                    lda       #1                  ; Start over
                    sta       WKMON               ; It is a new year...January
                    inc       WKYR                ; Bump year 0,1...2000,2001
                    inc       WKLEAP              ; And leap year counters
                    lda       WKLEAP              ; Get the leap year counter
                    cmpa      #5                  ; Only every four years
                    bne       Done@@              ; No...jump and return to caller
                    lda       #1                  ; Start over
                    sta       WKLEAP              ; With a new set of four years
Done@@              rts                           ; Return to the caller

;**************************************************************************
; WHATDAY - Finds Day of the Week
;**************************************************************************
; Routine: The output of this routine is to determine the day of the
;       week from the given current date.   The result is the correct
;       day left in the WKWDAY location.

WHATDAY             proc                          ; Finds the Day of the Week
                    lda       #BDYR               ; Birthday year
                    sta       WKYR                ; Save it
                    lda       #BDMON              ; Birthday month
                    sta       WKMON               ; Save it
                    lda       #BDDAY              ; Birthday day
                    sta       WKDAY               ; Save it
                    lda       #BDWDAY             ; Birthday Weekday
                    sta       WKWDAY              ; Save it
                    lda       #BDLEAP             ; Birthday Leap Year
                    sta       WKLEAP              ; Save it

          ; Now here is the loop, counting days till we make a match

Loop@@              bsr       CHKDAY              ; Check first to see if we have make it yet
                    bcs       Done@@              ; Jump if equal otherwise watch the days go by
                    bsr       BUMPDAY             ; Go to the next day
                    bra       Loop@@              ; Continue to loop
Done@@              rts                           ; Return to the caller

;**************************************************************************
; CHKDAY - Compares the Current day with the work day
;**************************************************************************
; Routine: This routine compares the working day registers to the current
;       day registers and when they are equal, then the carry flag is
;       set, otherwise carry is clear

CHKDAY              proc                          ; Finds the Day of the Week
                    lda       DSPYR               ; Get the current year
                    cmpa      WKYR                ; See if we match
                    bne       Fail@@              ; No...jump an return to the caller

                    lda       DSPMON              ; Get the current month
                    cmpa      WKMON               ; See if we match
                    bne       Fail@@              ; No...jump an return to the caller

                    lda       DSPDAY              ; Get the current day
                    cmpa      WKDAY               ; See if we match
                    bne       Fail@@              ; No...jump an return to the caller

                    sec                           ; Match located
                    bra       Done@@              ; Exit

Fail@@              clc                           ; Clear the carry...not a match
Done@@              rts                           ; Return to the caller

;**************************************************************************
; LCDTIM - Displays the time on the LCD
;**************************************************************************
; Routine: This routine displays the current time on the LCD
;       in the format HH:MM WWW DD MMM
;       0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15
;       H  H  :  M  M  s  M  O  N  s  1  2  s  O  C  T
;       We use CBUFF as our string construction area

LCDTIM              proc                          ; Display the current time
                    ldx       #CBUFF              ; Index the string area for the display
                    lda       CURHR               ; Get the current hour
                    cmpa      #12                 ; Make it into standard time
                    blt       Normal@@            ; Normal time...jump and convert
                    suba      #12                 ; 24 hour time to normal time
Normal@@            bne       Go@@                ; Not zero...jump
                    lda       #12                 ; Special case between 12:00 -> 12:59
Go@@                jsr       ITWOA               ; Convert the data to ASCII
                    std       ,x                  ; Save it
                    lda       #ACOLON             ; ASCII :
                    sta       2,x                 ; Save it
                    lda       CURMIN              ; Get the current minute
                    jsr       ITWOA               ; Convert the data to ASCII
                    std       3,x                 ; Save it
                    lda       #ASPACE             ; Put in the spaces
                    sta       5,x                 ; Save it
                    sta       9,x                 ; Save it
                    sta       12,x                ; Save it

                    lda       CURDAY              ; Get the current day
                    jsr       ITWOA               ; Convert the data to ASCII
                    std       10,x                ; Save it

          ; Now we put in three characters from the Weekday date

                    ldb       WKWDAY              ; Get the current week day
                    lslb                          ; Multiply it by two
                    ldy       #DAYOFWK            ; Table of day text
                    aby                           ; Add in the index
                    ldy       ,y                  ; Get the new address in Y
                    lda       ,y                  ; Get the first Char
                    sta       6,x                 ; Save it
                    lda       1,y                 ; Get the first Char
                    sta       7,x                 ; Save it
                    lda       2,y                 ; Get the first Char
                    sta       8,x                 ; Save it

                    ldb       CURMON              ; Get the current month
                    lslb                          ; Multiply it by two
                    ldy       #MTABLE             ; Table of month text
                    aby                           ; Add in the index
                    ldy       ,y                  ; Get the new address in Y
                    lda       ,y                  ; Get the first Char
                    sta       13,x                ; Save it
                    lda       1,y                 ; Get the first Char
                    sta       14,x                ; Save it
                    lda       2,y                 ; Get the first Char
                    sta       15,x                ; Save it

                    lda       #EOTEXT             ; Put in the terminator
                    sta       16,x                ; Save it
                    jsr       LCDTOP              ; Put this on the top line
                    rts                           ; Return to the caller

;**************************************************************************
; HISTIM - Displays the time for the history display
;**************************************************************************
; Routine: This routine displays the history time
;       in the format HH:MM WWW DD MMM
;       0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15
;       1  2  p  m  s  1  0  -  M  A  Y  EOT
; Input:  DSPHR, DSPMON, DSPDAY
; Output: CBUFF as our string construction area

HISTIM              proc                          ; History time
                    clr       CBUFFOV             ; Buffer overflow flag - zero=am
                    lda       DSPHR               ; Get the current hour
                    cmpa      #12                 ; Make it into standard time
                    blt       HISTIM1             ; Normal time...jump and convert
                    inc       CBUFFOV             ; This is pm
                    suba      #12                 ; 24 hour time to normal time
HISTIM1             bne       HISTIM2             ; Not zero...jump
                    clr       CBUFFOV             ; Buffer overflow flag - zero=am
                    lda       #12                 ; Special case between 12:00 -> 12:59
HISTIM2             jsr       ITWOA               ; Convert the data to ASCII
                    ldx       #CBUFF              ; Index the string area for the display
                    std       ,x                  ; Save it
                    tst       CBUFFOV             ; See if we are AM or PM
                    beq       HISTIM3             ; Zero = AM
                    lda       #ASMALLP            ; For PM
                    bra       HISTIM4             ; Jump and save it

HISTIM3             lda       #ASMALLA            ; For AM
HISTIM4             ldb       #ASMALLM            ; For the rest
                    std       2,x                 ; Save it
                    lda       #ASPACE             ; Put in the spaces
                    sta       4,x                 ; Save it
                    lda       DSPDAY              ; Get the current day
                    jsr       ITWOA               ; Convert the data to ASCII
                    std       5,x                 ; Save it
                    lda       #AMINUS             ; Put in the -
                    sta       7,x                 ; Save it

                    ldb       DSPMON              ; Get the current month
                    lslb                          ; Multiply it by two
                    ldy       #MTABLE             ; Table of month text
                    aby                           ; Add in the index
                    ldy       ,y                  ; Get the new address in Y
                    ldd       ,y                  ; Get the two char
                    std       8,x                 ; Save it
                    lda       2,y                 ; Get the last char
                    sta       10,x                ; Save it

                    lda       #EOTEXT             ; Put in the terminator
                    sta       11,x                ; Save it
                    jsr       OUTSTRN             ; Send it out
                    rts                           ; Return to the caller

;**************************************************************************
; DSPMODE - Display the current state of the CSS
;**************************************************************************
; Routine: This routine checks the current mode, and if it is the same
;       is does nothing, but if changed, then it displays the current
;       machine state to the LCD bottom line

NORMODE             proc                          ; Sets up for normal display mode
                    lda       #STMAIN             ; Back in the main loop
;                   bra       SETMODE

;*******************************************************************************

SETMODE             proc                          ; Sets the new state and then falls thru
                    sta       NEWMODE             ; Save the new state
;                   bra       DSPMODE

;*******************************************************************************

DSPMODE             proc                          ; Display the current CSS state
                    ldb       NEWMODE             ; Get the new mode
                    cmpb      OLDMODE             ; See if we have changed state
                    beq       Done@@              ; No change...jump and exit

          ; The state has changed...fetch the text from the index
          ; value of the mode and send it out to the LCD

                    stb       OLDMODE             ; Save our current state
                    cmpb      #STMAIN             ; Are we just doing standard information?
                    bge       DSPMOD7             ; Jump and continue

          ; Here we copy the text into a temporary buffer

                    lslb                          ; Multiply it by two
                    ldy       #STATBLE            ; State table index
                    aby                           ; Point into the table
                    ldx       ,y                  ; Fetch the index
                    ldy       #CBUFF              ; This will be our text build area
                    lda       #12                 ; Copy this many characters
                    jsr       MEMCPY              ; Move the data
                    ldb       OLDMODE             ; Get our value back
                    cmpb      #DIRSENS            ; Is this wind direction?
                    bne       Cont@@              ; No...continue to look

          ; Here we handle the wind direction printout

                    ldx       #WINDIRC            ; This is where we get the data
                    bra       DSPMOD5             ; Jump and do the display

Cont@@              cmpb      #BPRSENS            ; Is this a pressure printout request?
                    bne       DSPMOD4             ; No...jump and just printout the value

          ; Here we handle the BP printout

                    lda       BPRESUR             ; Get the barometric pressure
                    sta       CURBP               ; Save it away for the printout
                    jsr       BPRINT              ; Print the pressure in standard format
                    ldx       #BPRESSC            ; Load the character address
                    ldy       #CBUFFAX            ; This will be our text/data build area
                    dey                           ; Back off one space
                    lda       #6                  ; Copy this many characters
                    bra       DSPMOD6             ; Jump and do the display

; It's a temp value...now fetch it, convert it to ascii and move it
; If it is not a temp value, then we do an unsigned convert

DSPMOD4             cmpb      #BPRSENS            ; See if we are past the temp values
                    ble       DSPMODA             ; No...must be a temp sensor...jump
                    inc       UNSIGN              ; Yes...no negative numbers please

DSPMODA             ldx       #TMPDATA            ; Address of the DS1820 results save area
                    abx                           ; Add in the offset
                    lda       ,x                  ; Get the real temperature value
                    jsr       ITOA                ; Convert it to ASCII
                    clr       UNSIGN              ; We do +/- normal display
                    ldx       #ITOAC              ; Load the character address
DSPMOD5             ldy       #CBUFFAX            ; This will be our text/data build area
                    lda       #5                  ; Copy this many characters
DSPMOD6             jsr       MEMCPY              ; Move the data
                    ldx       #CBUFF              ; This will be our text build area
                    bra       Write@@             ; Jump and do the display

; Normal format for the state

DSPMOD7             lslb                          ; Multiply it by two
                    ldy       #STATBLE            ; State table index
                    aby                           ; Point into the table
                    ldx       ,y                  ; Fetch the index
Write@@             jsr       LCDBOT              ; Put this on the bottom line
Done@@              rts                           ; Return to the caller

;**************************************************************************
; SHOWCSS - Display the current state of the CSS
;**************************************************************************
; Routine: This routine is used to show the login and time conditions
;       of CSS to the user.

SHOWCSS             proc                          ; Display the CSS time and status information
                    ldx       #VMSMSG5            ; Load up the VT100 setup message
                    jsr       OUTSTRG             ; Send it out
                    jsr       HOMECLR             ; Home and Clear the screen
                    ldx       #VMSMSG3            ; Load up the welcome message
                    jsr       OUTSTRG             ; Send it out
                    lda       VERSION             ; Get the build version number
                    jsr       PRINTA              ; Convert it to ASCII and print it out

                    jsr       CPINIT              ; Setup the host port for the CP290
                    jsr       GETDATE             ; Fetch the CP290 time
                    bcc       SHOWCS1             ; Jump if we have problems...print a message
                    ldx       #DSPMSGE            ; The 'the current time' header message
                    jsr       OUTSTRG             ; Send it out
                    ldx       #CURTIM             ; Current time location
                    jsr       SHOWTIM             ; Print day and time
                    bra       SHOWCS2             ; Continue operation

SHOWCS1             equ       *                   ; CP290 is not communicating
                    ldx       #DSPMSGD            ; Load up the CP290 down message
                    jsr       OUTSTRG             ; Send it out
                    jsr       SETUPCP             ; Setup the CP290 with time and scan events
                    bcc       Done@@              ; User gone...jump, it will exit

SHOWCS2             equ       *
                    ldx       #DSPMSGF            ; The 'the cold time' header message
                    jsr       OUTSTRG             ; Send it out
                    ldx       #COLDATE            ; Cold time location
                    jsr       SHOWTIM             ; Print day and time

                    ldx       #DSPMSGG            ; The 'the warm time' header message
                    jsr       OUTSTRG             ; Send it out
                    ldx       #WRMDATE            ; Warm time location
                    jsr       SHOWTIM             ; Print day and time

                    ldx       #DSPMSGL            ; The date of the last scan before powerfail
                    jsr       OUTSTRG             ; Send it out
                    ldx       #SCNDATE            ; Current time location
                    jsr       SHOWTIM             ; Print day and time

                    ldx       #DSPMSGH            ; The last date of user login
                    jsr       OUTSTRG             ; Send it out
                    ldx       #USRDATE            ; Current time location
                    jsr       SHOWTIM             ; Print day and time

                    ldx       #DSPMSGC            ; Load up the good LOGIN count message
                    jsr       OUTSTRG             ; Send it out
                    lda       SIGNONG             ; Get the good signon count
                    inc       UNSIGN              ; No negative numbers please
                    jsr       PRINTA              ; Convert it to ASCII and print it out

                    ldx       #DSPMSG1            ; Load up the unsuccessful LOGIN info message
                    jsr       OUTSTRG             ; Send it out
                    lda       SIGNONB             ; Get the number of signon attempts
                    jsr       PRINTA              ; Convert it to ASCII and print it out
                    clr       SIGNONB             ; Clear the bad signon counter

                    ldx       #DSPMSGJ            ; Load up the number of history days
                    jsr       OUTSTRG             ; Send it out
                    lda       NUMDPTR             ; Get the number of history days
                    jsr       PRINTA              ; Convert it to ASCII and print it out

                    clr       UNSIGN              ; Return flag to normal +/-
                    ldx       #DSPMSG5            ; Display Function complete.
                    jsr       OUTSTRG             ; Send it out
                    jsr       GETSTR              ; Wait for CR before we continue
Done@@              rts                           ; Return to the main menu

;**************************************************************************
; GODEBUG - Jumps back to BUFFALO on the user's request
;**************************************************************************
; Routine: This routine asks the user if you're sure you want to do this
;       along with the warning to call CSS back to restart us back when
;       done with debug.   Then we jump off...

DODEBUG             proc                          ; Jump to BUFFALO
                    ldx       #DSPMSG3            ; Load up the BUFFALO warning message
                    jsr       OUTSTRG             ; Send it out
                    jsr       GETYSNO             ; Get the user response
                    bcc       Done@@              ; User is gone...so are we
                    bvc       Done@@              ; No...it is not OK...jump back to main menu
                    jmp       BUFISIT             ; Here we go, bypass the porte bit 0 check
;                   jmp       BUFFALO             ; Here we go...we are out of control...
Done@@              rts                           ; Back to the main menu

;**************************************************************************
;  GOWIND - Get the current wind direction and build the ASCII string
;**************************************************************************
; Routine: This routine gets the wind direction information from PORTC
;       and translates the value into ASCII text for printing.  The
;       resulting EOT terminated string is in WINDIRC

GOWIND              proc                          ; Create the wind ASCII string
                    ldx       #WINDIRC            ; This will be where we put the ASCII string
                    pshx                          ; save X
                    lda       #ASPACE             ; Pad out the display
                    sta       2,x                 ; Space out the string before we start
                    sta       3,x                 ; ditto

                    clr       TFLAG               ; This will be our offset into the WINDIRC
                    ldx       #PORTA              ; Address of port A
                    bclr      ,x,#WINDON          ; Turn down the wind enable bit - LOW ACTIVE
                    fdiv                          ; Take some time for line to go stable
                    fdiv                          ; ditto
                    ldx       #WINVAL             ; Get index of bit table to check against
                    ldy       #WINDIR             ; This is our string of characters
                    clr       DDRC                ; Turn C port into input data
                    lda       PORTC               ; Get the wind direction value
                    coma                          ; Invert the bits
                    sta       WINDDIR             ; Save the direction
Loop@@              bita      ,x                  ; See if we are ON
                    beq       Cont@@              ; Continue...nothing is set here

          ; Ok, we have a match, now we want to put the correct string in WINDIRC
          ; so we can print it when requested.

                    psha                          ; save the registers
                    pshx
                    ldx       #WINDIRC            ; This will be where we put the ASCII string
                    ldb       TFLAG               ; This is our offset value
                    abx                           ; Add in the offset to the index
                    addb      #2                  ; Bump our offset value
                    stb       TFLAG               ; Save it back for later use
                    ldd       ,y                  ; Get the ASCII text
                    std       ,x                  ; Save it in the WINDIRC
                    pulx                          ; Restore the registers
                    pula
                    ldb       TFLAG               ; Get out offset back
                    cmpb      #4                  ; Have we filled up the character buffer?
                    beq       Done@@              ; Jump and exit...we are done

Cont@@              iny:2                         ; Bump to the next direction string
                    inx                           ; Go to the next direction value
                    tst       ,x                  ; Are we done? Zero gets us out.
                    bne       Loop@@              ; Continue the effort

          ; Now we turn off PORTC wind direction enable

Done@@              lda       #EOTEXT             ; Get the termination character
                    pulx                          ; Restore the X register
                    sta       4,x                 ; Zero out the string before we start
                    ldx       #PORTA              ; Address of port A
                    bset      ,x,#WINDON          ; Turn off the wind enable bit - LOW ACTIVE
                    rts                           ; Back to who called us

;*******************************************************************************
;  WSETUP - Wind Speed Setup routine
;*******************************************************************************
; Routine: This routine sets up the pulse accumulator for gathering
;       pulses from the weather boom.

WSETUP              proc                          ; Setup the pulse accumulator
                    lda       PACTL               ; Get the current PA control values
                    anda      #$03                ; Keep just the RTL adjustment count
                    ora       #$50                ; Put in our values:
                                                  ; 0=DDRA7 for input
                                                  ; 1=PAEN enable pulse accumulator
                                                  ; 0=PAMOD count pulses
                                                  ; 1=PEDGE rising edge
                    sta       PACTL               ; Save the value
                    clr       PACNT               ; Start the count from zero
                    rts                           ; Back to who called us

;*******************************************************************************
;  WSPEED - Take the value of the pulse accumulator as the wind spped
;*******************************************************************************
; Routine: This routine get the pulse accumulator and converts it to
;       a string for printout

WSPEED              proc                          ; Get the pulse accumulator
                    lda       PACNT               ; Get the current PA control values
                    sta       WINDSPD             ; Save the counter
                    clr       PACNT               ; Clear the value
                    inc       UNSIGN              ; Do a unsigned conversion
                    jsr       ITOA                ; Convert to a ascii string
                    clr       UNSIGN              ; Return flag to normal +/-
                    rts                           ; Back to who called us

;*******************************************************************************
; BONEIS - Bus One Wire Initialization Sequence
;*******************************************************************************
; The initialization/reset sequence for the one wire bus is as follows:
;       a) Transmit a low for 480-960 usec
;       b) Release the bus
;       c) Wait for 240 usec for the 1820s to issue their 'presence'
;               signal indicating the bus is active
; Register A&B are saved
; Carry Clear = BAD - The 'presence' pulse did not come back
; Carry Set = GOOD - Bus is active and ready to go
;*******************************************************************************

BONEIS              proc                          ; Bus One Initialization seqnence
                    psha                          ; save the A register
                    pshb                          ; Save the B register
                    bsr       BONELO              ; Turn the bus low

; Now we get the current timer counter and add in our wait count
; then save it back in the timer compare register 4

                    ldd       TCNT                ; Get the current timer counter
                    addd      #1000               ; 500 usec of ticks
                    std       TOC4                ; Save it in timer compare register 4
                    lda       #TOC4F              ; Write a one for the compare register
                    sta       TFLG1               ; Resets the compare register flag

; Now we can bit spin waiting for the timer to expire

Wait1@@             lda       TFLG1               ; Get the timer flag register
                    anda      #TOC4F              ; Just look at the timer compare 4
                    beq       Wait1@@             ; Continue to wait

                    bsr       BONEHI              ; Release the one wire bus

; Now we can bit spin waiting for either the timer to expire or the
; 'presence' pulse to come back on the one wire bus.   If the 'presence'
; pulse comes back first, we still wait the entire time.

                    ldd       TCNT                ; Get the current timer counter
                    addd      #1000               ; 500 usec of ticks
                    std       TOC4                ; Save it in timer compare register 4
                    lda       #TOC4F              ; Write a one for the compare register
                    sta       TFLG1               ; Resets the compare register flag

Loop@@              lda       PORTD               ; Get the PORT D value
                    anda      #$20                ; Did we get a 'presence' pulse?
                    bne       Wait2@@             ; Yes...branch and get out
                    lda       TFLG1               ; Get the timer flag register
                    anda      #TOC4F              ; Just look at the timer compare 4
                    beq       Loop@@              ; Continue to wait

          ; We waited the specified time, and nothing came back.   This is bad
          ; so we clear the carry and get out.

                    clc                           ; Clear the carry flag...this is an error
                    bra       Done@@              ; Get out

          ; Now we wait the rest of the time allocated for the 'reset' signal

Wait2@@             lda       TFLG1               ; Get the timer flag register
                    anda      #TOC4F              ; Just look at the timer compare 4
                    beq       Wait2@@             ; Continue to wait
                    sec                           ; Set the carry...this is good

Done@@              pulb                          ; Restore the B register
                    pula                          ; Restore the A register
                    rts                           ; Return to the caller

;*******************************************************************************
; BONELO - Drive the Bus One Wire Low
;*******************************************************************************

BONELO              proc                          ; Drive the one write bus low
          ; Here we set the D5 bit low in the Output register

                    lda       PORTD               ; Get the current contents of PORT D
                    anda      #$DF                ; Save everything but bit 5
                    sta       PORTD               ; Put it back in the output register

          ; Now we set the D5 bit in the data direction register to be output
          ; which will drive the one wire bus low

                    lda       DDRD                ; Get the data direction register for PORT D
                    ora       #$20                ; Add in bit 5
                    sta       DDRD                ; Drive the one wire bus low
                    rts                           ; Return to the caller

;*******************************************************************************
; BONEHI - Releae the Bus One Wire to go back to the high state
;*******************************************************************************

BONEHI              proc                          ; Release the one write bus to go back high
          ; Now we clear the D5 bit in the data direction register which
          ; will release the drive on the one wire bus and let it go high

                    lda       DDRD                ; Get the data direction register for PORT D
                    anda      #$DF                ; Clear bit 5
                    sta       DDRD                ; Release the one wire bus back high
                    rts                           ; Return to the caller

;*******************************************************************************
; BONEW0 - Writes a zero to the one wire bus
;*******************************************************************************

; To write a zero on the one wire bus we hold the line down for the
; entire period.

BONEW0              proc                          ; Write a zero to the bus
                    psha                          ; save A register
                    pshb                          ; save B register
                    bsr       BONELO              ; Turn the bus low
                    ldd       TCNT                ; Get the current timer counter
                    addd      #120                ; 60 usec of ticks
                    std       TOC4                ; Save it in timer compare register 4
                    lda       #TOC4F              ; Write a one for the compare register
                    sta       TFLG1               ; Resets the compare register flag

          ; Now we can bit spin waiting for the timer to expire

BONEW2              lda       TFLG1               ; Get the timer flag register
                    anda      #TOC4F              ; Just look at the timer compare 4
                    beq       BONEW2              ; Continue to wait

                    bsr       BONEHI              ; Release the bus
                    pulb                          ; Restore B
                    pula                          ; Restore A
                    rts                           ; Return to the caller

;*******************************************************************************
; BONEW1 - Writes a one to the one wire bus
;*******************************************************************************
; To write a one on the one wire bus, we pulse the bus low for
; 6 usec, then release the bus to go back high

BONEW1              proc                          ; Write a one to the bus
                    psha                          ; save A register
                    pshb                          ; Save B register
                    bsr       BONELO              ; Turn the bus low
                    bsr       BONEHI              ; Release the bus
                    ldd       TCNT                ; Get the current timer counter
                    addd      #120                ; 60 usec of ticks
                    std       TOC4                ; Save it in timer compare register 4
                    lda       #TOC4F              ; Write a one for the compare register
                    sta       TFLG1               ; Resets the compare register flag

          ; Now we can bit spin waiting for the timer to expire

BONEW3              lda       TFLG1               ; Get the timer flag register
                    anda      #TOC4F              ; Just look at the timer compare 4
                    beq       BONEW3              ; Continue to wait
                    pulb                          ; Restore B
                    pula                          ; Restore A
                    rts                           ; Return to the caller

;*******************************************************************************
; BONERB - Reads a bit from the one wire bus
;*******************************************************************************
; To read a bit from the bus, we pulse the bus, and wait to see
; what comes back.
;  Carry Set = bit is read HIGH
;  Carry Clear = bit is read LOW

BONERB              proc                          ; Reads a bit from one wire bus
                    psha                          ; save the A register
                    pshb                          ; Save the B register

          ; In order to maxmize our master sample time, we move the timer setup
          ; ahead of the bus read command.   This will give us a few more cycles.
          ; We sample the bus for only 15 usec after the falling edge of the read.

                    ldd       TCNT                ; Get the current timer counter
                    addd      #140                ; 70 usec of ticks
                    std       TOC4                ; Save it in timer compare register 4
                    lda       #TOC4F              ; Write a one for the compare register
                    sta       TFLG1               ; Resets the compare register flag

          ; Now we issue a read command

                    bsr       BONELO              ; Turn the bus low
                    bsr       BONEHI              ; Release the bus
                    mul:3                         ; Give the wire a chance to recover
                    nop:2

          ; Now we quickly wait for the sample window...no time to do anything else

BONER1              lda       PORTD               ; (4) Get the PORT D value
                    anda      #$20                ; (2) Did we read a pulse?
                    bne       BONER3              ; (3) Yes...branch and get out
                    clc                           ; Clear the carry flag
                    bra       BONER8              ; Continue to wait the required time

BONER3              sec                           ; The bus went high...we have a one
                    lda       TFLG1               ; Get the timer flag register
                    anda      #TOC4F              ; Just look at the timer compare 4
                    beq       BONER1              ; Continue to wait
                    bra       BONER9              ; Wait is over..exit

          ; Our sample is over, but we must wait the rest of the time

BONER8              lda       TFLG1               ; Get the timer flag register
                    anda      #TOC4F              ; Just look at the timer compare 4
                    beq       BONER8              ; Continue to wait the remainder time

BONER9              pulb                          ; Restore the B register
                    pula                          ; Restore the A register
                    rts                           ; Return to the caller

;*******************************************************************************
; BONEBW - Writes a byte to the one wire bus
;*******************************************************************************
; This routine will writes the A register byte to the one wire bus.
; Register A is what we write and it is saved
; Register B is also saved

BONEBW              proc                          ; write A to the bus
                    psha                          ; save A on the stack
                    pshb                          ; save B on the stack
                    ldb       #$7F                ; this is our shift bit counter
Loop@@              lsra                          ; shift A right into the carry
                    bcc       Write@@             ; jump if carry is clear and write a zero
                    bsr       BONEW1              ; carry set...write a one
                    bra       Done@@              ; jump and continue

Write@@             bsr       BONEW0              ; write out a zero to the bus

          ; Do the book keeping to keep track of how many we have written

Done@@              lsrb                          ; now put a bit from B into the carry
                    bcs       Loop@@              ; continue to send out bits
                    pulb                          ; until we are done...
                    pula                          ; restore the registers
                    rts                           ; return to the caller

;**************************************************************************
; BONEBR - Reads a byte from the one wire bus
;**************************************************************************

; This routine will read a byte from the one wire bus and return it
; in the A register.

; Register A is what we read from the bus
; Register B is also saved

BONEBR              proc                          ; Read a byte from the bus into A
                    pshb                          ; Save B on the stack
                    clra                          ; Wipe out A
                    ldb       #$7F                ; This is our shift bit counter
Loop@@              bsr       BONERB              ; Read a bit from the bus
                    rora                          ; Shift it into A top > down

          ; Do the book keeping to keep track of how many we have written

                    lsrb                          ; Now put a bit from B into the carry
                    bcs       Loop@@              ; Continue to send out bits
                    pulb                          ; Until we are done...
                    rts                           ; Return to the caller

;**************************************************************************
; BONEXR - Reads the ROM address from the DS1820
;**************************************************************************
; This routine reads the ROM value from the DS1820 connected to the
; one wire bus.
; NOTE: This is a diagnostic test routine, and assumes that there is
; only one device on the bus.    It is used to identify a DS1820 so that
; its ROM code can be entered into the system.

BONEXR              proc                          ; Read the ROM from the DS1820
                    ldx       #DSDATA             ; Address for the communication area
                    ldb       #$7F                ; This is our shift bit counter
                    lda       #$5A                ; Test pattern
Loop@@              sta       ,x                  ; Plug this value
                    inx                           ; Bump to the next index location
                    lsrb                          ; Now put a bit from B into the carry
                    bcs       Loop@@              ; Continue to send out bits

                    jsr       BONEIS              ; Reset the bus...ready for action
                    bcc       Done@@              ; Jump if we do not get the 'presence'
                    lda       #READROM            ; Command to Read the ROM on the DS1820
                    bsr       BONEBW              ; Send it out

                    ldx       #DSDATA             ; Address for the communication area
                    ldb       #$7F                ; This is our shift bit counter
Loop2@@             bsr       BONEBR              ; Read a byte from the bus
                    sta       ,x                  ; Save it in the communication area

          ; Do the book keeping to keep track of how many we have written

                    inx                           ; Bump to the next index location
                    lsrb                          ; Now put a bit from B into the carry
                    bcs       Loop2@@             ; Continue to send out bits
Done@@              rts                           ; Return to the caller

;*******************************************************************************
; BONETR - Reads a temperature value from one of the DS1820 devices
;*******************************************************************************
; This routine will command the DS1820 to take its temperature and
; converts the value into oF from the table lookup then saves it
; back into the desired location
; Register X points to the ROM address of the desired DS1820
; Register Y points to the address to place the temperature
; Register A and B are saved

BONETR              proc                          ; Reads a temperature value from a DS1820
                    psha                          ; save A on the stack
                    pshb                          ; Save B on the stack
                    pshx                          ; save X on the stack
                    pshy                          ; Save Y on the stack
                    jsr       BONEIS              ; Reset the bus
                    lda       #MACHROM            ; Command to match this ROM value
                    bsr       BONEBW              ; Send it out
                    ldb       #$7F                ; This is our shift bit counter
Loop@@              lda       ,x                  ; Get the ROM byte
                    bsr       BONEBW              ; Send it out
                    inx                           ; Bump the counter
                    lsrb                          ; Now put a bit from B into the carry
                    bcs       Loop@@              ; Continue to send out bits

          ; At this point we have the attention of one of the DS1802 devices.
          ; Now we can ask the DS1820 to send us the temperature value
          ; We only want the first two bytes of data, and we terminate the read

                    lda       #READTMP            ; Command to read the temperature value
                    bsr       BONEBW              ; Send it out
                    ldb       #$7F                ; This is our shift bit counter
                    bsr       BONEBR              ; Read the first byte in
                    tab                           ; Put it in the B register for now
                    bsr       BONEBR              ; Read the second byte in

          ; Now we have a 16 bit temp value from the DS1820 in the D register

                    addd      #124                ; Add our magic offset to make it into an index
                    ldx       #TMPTTBL            ; Get address the temp conversion table
                    abx                           ; Add in the index value
                    lda       ,x                  ; Get the converted value
                    sta       ,y                  ; Save it in the desired location

          ; We are done

                    puly                          ; Until we are done...
                    pulx                          ; Restore the registers
                    pulb                          ; Restore the registers
                    pula                          ; Restore the registers
                    rts                           ; Return to the caller

;*******************************************************************************
; SCANTP - Scans one wire bus collecting the temperature values
;*******************************************************************************
; This routine will spin through the DS1820s connected to the one wire
; bus commanding them to take their temperature and report it back to
; the desired location.
; Registers A and B are saved

SCANTP              proc                          ; Scans temperature values from one wire bus
                    psha                          ; save A on the stack
                    pshb                          ; Save B on the stack
                    jsr       BONEIS              ; Reset the bus
                    lda       #SKIPROM            ; Command everybody to listen up
                    bsr       BONEBW              ; Send it out
                    lda       #TAKETMP            ; Command to take your temperature
                    jsr       BONEBW              ; Send it out
                    jsr       WAITONE             ; Wait a second
                    jsr       WAITONE             ; And another...

          ; Now everyone has the temperature in their scratchpad
          ; area...now fetch it

                    ldy       #TMPDATA            ; This is where we want to store the data
                    clr       TFLAG               ; This is our index offset
                    clrb                          ; Clear out B

Loop@@              lslb                          ; Shift *2 for a two byte pointer value
                    ldx       #TMPIDX             ; Get the pointer to the list of pointers
                    abx                           ; Adjust the offset
                    ldx       ,x                  ; This is the ROM code for the DS1820 device
                    bsr       BONETR              ; Fetch the temperature from the device

          ; Now we do the housekeeping to adjust to the next device

                    iny                           ; Bump to the next store location
                    inc       TFLAG               ; Bump our counter
                    ldb       TFLAG               ; Get the value
                    cmpb      #TMPSENS            ; See if we have more to do
                    bne       Loop@@              ; Continue to scan for temp data

                    pulb                          ; Until we are done...
                    pula                          ; Restore the registers
                    rts                           ; Return to the caller

;**************************************************************************
; BPRINT - Printout the barometric pressure
;**************************************************************************
; This routine will convert the given pressure into a standard format
; It uses CURBP as the value to convert and print.   The data is converted
; into BPRESSC buffer for output.
; Here's the plan:  The A/D converts a voltage between 2.50 and 3.80
; to a value between 0-255, which represents 28.00 - 33.00 inches of Hg
; so we assign a range of values as follows:
;       0 -  51 = 28.xx
;      52 - 102 = 29.xx
;     103 - 153 = 30.xx
;     154 - 204 = 31.xx
;     205 - 255 = 32.xx

BPRINT              proc                          ; Printout the title and version
                    lda       #28                 ; First value
                    sta       SFLAG               ; Save it here
                    ldb       #51                 ; First cutoff range
                    lda       CURBP               ; Get the value to compare
Loop@@              cba                           ; See where we are
                    bls       Found@@             ; We have found the range
                    suba      #51                 ; Back off the value
                    inc       SFLAG               ; Go up the scale
                    bra       Loop@@              ; Continue to loop

          ; Here TFLAG contains a value between 28-32 and B has
          ; a value 51 for compare

Found@@             psha                          ; save our count
                    ldy       #BPRESSC            ; Save the character address
                    lda       SFLAG               ; Print this value out
                    inc       UNPAD               ; Do not pad our value!
                    jsr       ITOA                ; Convert it to ASCII
                    clr       UNPAD               ; We can have padding now
                    ldx       #ITOAC              ; Load the character address
                    ldd       ,x                  ; Get the two characters
                    std       ,y                  ; Save them
                    lda       #APERIOD            ; Send out a period
                    sta       2,y                 ; Save a dot

          ; Now convert the final two digits

                    pula                          ; Get our value back
                    lsla                          ; *2
                    cmpa      #100                ; See if we are over the top
                    blo       Cont@@              ; No...jump and continue
                    lda       #99                 ; Take the maximum value
Cont@@              cmpa      #10                 ; See if we must add an ascii zero
                    bhs       Asciz@@             ; No need...just jump and continue
                    ldb       #ASCII0             ; Send out a zero for looks
                    stb       3,y                 ; xx.0
                    ora       #$30                ; Make it ASCII by hand
                    stb       4,y                 ; xx.0x
                    bra       Done@@              ; End it off

Asciz@@             jsr       ITOA                ; Convert it to ascii
                    ldx       #ITOAC              ; Load the character address
                    ldd       ,x                  ; Get the value
                    std       3,y                 ; Save it

Done@@              lda       #EOTEXT             ; Mark the end of the string
                    sta       5,y                 ; Save it
                    rts                           ; Return to the caller

;**************************************************************************
; HISETUP - Setup the history data structure
;**************************************************************************
; This routine will take the ADSCAN values and load them into both the
; high and low (HIGHVAL and LOWSVAL) structures to act as our starting
; point for comparison.

HISETUP             proc                          ; History data structure setup
                    clr       TFLAG               ; This will be our counter
                    clrb                          ; This will be our offset
Loop@@              ldy       #HIGHVAL            ; This is where we want to save them
                    ldx       #ADSCAN             ; Get the index to the sensor values
                    abx                           ; Add in the offset
                    lda       ,x                  ; Get the sensor value
                    lslb                          ; *4 for our history data
                    lslb                          ; ditto
                    aby                           ; Add in our index
                    sta       ,y                  ; Save the value
                    lda       CURMON              ; Get the current month
                    sta       1,y                 ; Save the value
                    lda       CURDAY              ; Get the current day
                    sta       2,y                 ; Save the value
                    lda       CURHR               ; Get the current hour
                    sta       3,y                 ; Save the value
                    inc       TFLAG               ; Bump to the next sensor
                    ldb       TFLAG               ; Get the offset back
                    cmpb      #HLBYTES            ; Number of high/low bytes
                    bne       Loop@@              ; Loop back and do some more

          ; Now we just copy the data from the high -> lows

                    ldx       #HIGHVAL            ; This is where we copy from
                    ldy       #LOWSVAL            ; This is where we want to save them
                    lda       #HLHSIZE            ; This is the count
                    jsr       MEMCPY              ; Copy the data
                    rts                           ; Return to the caller

;**************************************************************************
; HIGLOWS - Make the necessary comparisons for high/low values
;**************************************************************************
; This routine will take the ADSCAN values and compare them with the
; high and low (HIGHVAL and LOWSVAL).

HIGLOWS             proc                          ; High/Low comparison
                    clr       TFLAG               ; This will be our counter
                    clrb                          ; This will be our offset

          ; First we do the high values

Loop@@              ldy       #HIGHVAL            ; This is where we want to save them
                    ldx       #ADSCAN             ; Get the index to the sensor values
                    abx                           ; Add in the offset
                    lda       ,x                  ; Get the sensor value
                    lslb                          ; *4 for our history data
                    lslb                          ; ditto
                    aby                           ; Add in our index
                    ldb       ,y                  ; Get the value

          ; At this point A contains the current value
          ; and B contains last high value

                    cba                           ; See how they match (A-B)
                    beq       HIGLOW3             ; Equal means we have a new high value
                    bmi       HIGLOW4             ; Current is lower...jump and go to the next
HIGLOW3             sta       ,y                  ; Save the new high value
                    bsr       TIM2HIS             ; Save the time

HIGLOW4             inc       TFLAG               ; Bump to the next sensor
                    ldb       TFLAG               ; Get the offset back
                    cmpb      #HLBYTES            ; Number of high/low bytes
                    bne       Loop@@              ; Loop back and do some more

          ; Now we do the low values values

                    clr       TFLAG               ; This will be our counter
                    clrb                          ; This will be our offset
HIGLOW6             ldy       #LOWSVAL            ; This is where we want to save them
                    ldx       #ADSCAN             ; Get the index to the sensor values
                    abx                           ; Add in the offset
                    lda       ,x                  ; Get the sensor value
                    lslb:2                        ; *4 for our history data
                    aby                           ; Add in our index
                    ldb       ,y                  ; Get the value

          ; At this point A contains the current value
          ; and B contains last low value

                    cba                           ; See how they match (A-B)
                    beq       HIGLOW7             ; Equal means we have a new low value
                    bpl       HIGLOW8             ; Current is higher...jump and go to the next
HIGLOW7             sta       ,y                  ; Save the new high value
                    bsr       TIM2HIS             ; Save the time

HIGLOW8             inc       TFLAG               ; Bump to the next sensor
                    ldb       TFLAG               ; Get the offset back
                    cmpb      #HLBYTES            ; Number of high/low bytes
                    bne       HIGLOW6             ; Loop back and do some more
                    rts                           ; Return to the caller

;******************************************************************************
; TIM2HIS - Helper routine for moving the history time
;******************************************************************************
; Routine: This routine is called from above to move the correct history time

TIM2HIS             proc                          ; Move history time
                    lda       CURMON              ; Get it
                    sta       1,y                 ; Save the CURMON
                    lda       CURDAY              ; Get it
                    sta       2,y                 ; Save the CURDAY
                    lda       CURHR               ; Get it
                    sta       3,y                 ; Save the CURHR
                    rts                           ; Return to the upper loop
          #ifdef
                    lda       #$50                ; To enable the stop command
                    tap                           ; Put it in the CC register
                    stop                          ; This is here to halt the CPU on runaway
          #endif
;******************************************************************************
                    #RAM                          ; RAM starting address
;******************************************************************************
                    org       RAMSTRT             ; Begin our data section

STRRAM              equ       *                   ; Starting RAM location used for clear routine

; CP2SAVE pointer is the beginning of a contigious area of less than 512
; byte area that is mirrored into the CP290 at the end of every scan period
; for powerfail backup.   NOTE: we do not copy everything...just from the
; CP2SAVE to the CP2QUIT (since it takes so long to communicate with the
; CP290, over a minute to download 512 bytes, we just do a small amount

; NOTE: 29OCT95 - Another unexpected problem with the CP290, in that it
; has a quirk if the upper byte to be saved is zero, then it assumes
; (which is hard to understand why the makers of the CP290 would do this)
; that the area is blank, and skips over it.   So to compensate for this
; wonderful feature, we have carefully arranged the values below so that
; we are sure that zero will not be seen in the leading byte!

; Note: (14Nov2000) since we are just about ready to deploy this unit
; back at the cabin, I made the decision to keep the year starting from
; zero to indicate 2000, knowing that it will fail to load down to the
; CP290 correctly due to the above error, but this will be OK once we
; hit the next century, for 1 will be 2001 and things will work fine.
; This was simply easier than to put a bunch of checks in for zero.

CP2SAVE             equ       *                   ; Starting address to save important data

; The CURxxx are the current values used by the CABIN SYSTEM

CURTIM              equ       *                   ; Current time values
CURYR               rmb       1                   ; Current Year 0 = year 2000
CURHR               rmb       1                   ; Current Hour (0-23)
CURMON              rmb       1                   ; Current Month (1-12)
CURMIN              rmb       1                   ; Current Minute (0-59)
CURDAY              rmb       1                   ; Current Day (1-31)
CURSEC              rmb       1                   ; Current Second (0-59) seconds we count down!

COLDATE             rmb       6                   ; Date cabin system cold started CP290 was off
USRDATE             rmb       6                   ; Last time someone logged into the system

; These values are used to maintain the DOOR information:

; The first 6 bytes are the open date, mirrored from the information above
; The next 6 bytes are the close date, mirrored from the information above
; The next byte is a count of open/close cycles

; Door status register is a copy of the E register.   We use this copy
; whenever a change has occured the last time we checked the door status

DCOUNT              equ       13                  ; Door open/close count
DTOTAL              equ       14                  ; Total number of door date bytes

SMDOOR              rmb       DTOTAL              ; Save area for Main door status
SBDOOR              rmb       DTOTAL              ; Save area for Basement door status
SNDOOR              rmb       DTOTAL              ; Save area for North Garage door status
SSDOOR              rmb       DTOTAL              ; Save area for South Garage door status

SIGNONG             rmb       1                   ; Number of good signons since booted
SIGNONB             rmb       1                   ; Number of aborted signons since booted

CP2QUIT             equ       *                   ; Ending address to save important data

WRMDATE             rmb       6                   ; Power fail date warm started CP290 was OK
SCNDATE             rmb       6                   ; Date of the last scan time before power fail
CBUFFMX             equ       20                  ; Maximum number of input characters
NEWMODE             rmb       1                   ; New State - Used for LCD display
OLDMODE             rmb       1                   ; Old State
TFLAG               rmb       1                   ; General flag field
ECHOIT              rmb       1                   ; Echo the input back.
DELAYWK             rmb       1                   ; Delay routine # of 25msec intervals to wait
DSTATUS             rmb       1                   ; Last changed door status
CURBP               rmb       1                   ; Current BP for printout subroutine

CURWDAY             rmb       1                   ; Current Week Day in CP290 format

; Here's a bit of documentation concerning the history data area:
; The history area is a single block of memory divided into scan layers.
; Each scan represents SNBYTES of data.   The master pointer to this history
; block is HFLINK,   The start of the buffer is HISTOP, and the end
; is HISEND.   The init routine sets HFLINK to HISTOP, and after every
; scan, we bump the HFLINK to the next scan location, up to HISEND, then
; we wrap back around.   We also keep a scan count NUMSCAN, which is cleared
; on startup and then incremented each scan until MAXSCAN is reached, meaning
; a full history buffer.

; Now to keep track of where the days are in the history buffer, there is
; a structure HISIDX, which contains CURDAY, CURMON, and HFLINK (four bytes).
; one for each day.   The CURDPTR is the offset into the HISIDX structure.
; The day we begin will not be a 24 hour day, therefore we keep a BHISHR,
; which contains CURHR of the time we began the history.   We also keep a
; NUMDPTR which is incremented each day to MAXDPTR, which is the maximum
; number of history days we can hold

NUMDPTR             rmb       1                   ; Number of history days <= MAXDPTR
CURDPTR             rmb       1                   ; Current history index (number history days)
BHISTHR             rmb       1                   ; Beginning history hour (when CURDPTR = 0)
NUMSCAN             rmb       2                   ; Number of history scan values

MAXDPTR             equ       25                  ; Limit to the number of history days
MAXHRDY             equ       24                  ; Maximum hours/day
MAXSCAN             equ       MAXDPTR*MAXHRDY     ; Maximum number of scan value (24*MAXDPTR)

; There is a directory area consisting of day pointers of:
;       CURMON - CURDAY - HFLINK.

HFLINK              rmb       2                   ; History pointer forward link
HISDAYC             equ       4                   ; CURMON,CURDAY,HFLINK (two bytes)
HISIDXS             equ       MAXDPTR*HISDAYC     ; Max Number of days * 4 bytes per day
HISIDX              rmb       HISIDXS             ; History index DAY pointer structure

; These structures are used for communication with the CP290

CBUFFOF             equ       12                  ; Offset into CBUFF for number
CBUFFAX             equ       *+CBUFFOF           ; Place to put the converted temp data
CBUFF               rmb       CBUFFMX             ; Input character buffer
CBUFFOV             rmb       1                   ; Overflow byte...just in case
CBUFFPT             rmb       1                   ; Character counter

FIFOMAX             equ       40                  ; Maximum size of the FIFO
PCFIFO              rmb       FIFOMAX             ; FIFO of data to be sent to the PC
                    rmb       1                   ; End of the PCFIFO
PCFPTR              rmb       1                   ; Forward offset pointer for FIFO
PCBPTR              rmb       1                   ; Backward pointer for FIFO

CPFIFO              rmb       FIFOMAX             ; FIFO of data to be sent to the CP290
SFLAG               rmb       1                   ; End of the CPFIFO
CPFPTR              rmb       1                   ; Forward offset pointer for FIFO
CPBPTR              rmb       1                   ; Backward pointer for FIFO

BEENLOW             rmb       1                   ; Flag to debounce rain guage
RAINSEC             rmb       1                   ; Save area for CURSEC to debounce rain guage
UNSIGN              rmb       1                   ; Flag to ITOA for unsigned conversion
UNPAD               rmb       1                   ; Flag to ITOA not to pad with spaces at the end
ITOAC               rmb       5                   ; Byte to ASCII converted string
WINDIRC             rmb       6                   ; Wind direction ASCII characters
BPRESSC             rmb       6                   ; Pressure ASCII characters

DSPOMAX             equ       12                  ; Maximum number of display values
DSPOINT             rmb       1                   ; Display Point for LCD

; The DSPxxx are the display values used by the SHOWTIM routine

DSPTIM              equ       *                   ; Display time values
DSPYR               rmb       1                   ; Display Year 0 = year 2000
DSPHR               rmb       1                   ; Display Hour (0-23)
DSPMON              rmb       1                   ; Display Month (1-12)
DSPMIN              rmb       1                   ; Display Minute (0-59)
DSPDAY              rmb       1                   ; Display Day (1-31)
DSPSEC              rmb       1                   ; Display Second (0-59) seconds we count down!

WKDAY               rmb       1                   ; Working Day (1-day of month)
WKMON               rmb       1                   ; Working Month (1-12)
WKYR                rmb       1                   ; Working Year (93-...)
WKLEAP              rmb       1                   ; Working Leap indicator (1-4) 4=leap
WKWDAY              rmb       1                   ; Working Week Day (1=Sunday, 2=Monday...)
DSDATA              rmb       10                  ; Data area for DS1820 communication

; This section defines the number and location of the area to store
; the data from the DS1820 temperature sensors and other weather data

SNBYTES             equ       13                  ; Number of sensor bytes of data
TMPSENS             equ       8                   ; Number of temperature sensors (1-8)
BPRSENS             equ       8                   ; Pressure sensor offset number (0 index)
DIRSENS             equ       12                  ; Wind direction sensor offset number (0 index)
HLBYTES             equ       SNBYTES-1           ; Number of high/low bytes of data (not WINDIR)

ADSCAN              equ       *                   ; The current temperature/sensor values
TMPDATA             rmb       TMPSENS             ; The number of converted DS1820 values
BPRESUR             rmb       1                   ; Barometric pressure
RAINFAL             rmb       1                   ; Rain fall count
RELIGHT             rmb       1                   ; Relative Light
WINDSPD             rmb       1                   ; Wind speed
WINDDIR             rmb       1                   ; Wind direction
ADSCANX             equ       *                   ; End current temperature/sensor values

; Here we store the High and Lows for each of the sensors, except wind dir
; We keep the VALUE, CURMON, CURDAY, CURHR for each sensor - four bytes.

HLXSTR              equ       4                   ; VALUE,CURMON,CURDAY,CURHR
HLHSIZE             equ       HLXSTR*HLBYTES      ; Size of high/low array
HIGHVAL             rmb       HLXSTR*HLBYTES      ; High values + date/hr 12 * 4
LOWSVAL             rmb       HLXSTR*HLBYTES      ; Low value + date/hr 12 * 4

SOMEPAD             rmb       10                  ; A bit of padding

;-------------------------------------------------------------------------------
; This is the history data block which takes the remaining area of RAM

HISTOP              equ       *                   ; History begins here
ENDRAM              equ       $E000               ; End of the History data
HISIZE              equ       ENDRAM-HISTOP       ; Take what we can
;-------------------------------------------------------------------------------
NUMRAM              equ       ENDRAM-STRRAM       ; Number of RAM location used for clear routine
