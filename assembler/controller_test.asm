	NOP
	# R0 - VGA START LOCATION
	# R1 - VGA ROW LENTH
	# R2 - MAN LOCATION
	# R3 - USER INPUT
	# R4 -
BEGIN:	LOADLBL VGA_L1_R0, R0
	LOADLBL VGA_L1_R1, R1
	LOADLBL STACK, R15
	SUB R0, R1
	SETBEGINVGA R0	#initilize pointer to vga location
	SETROWVGA R1

	LOADLBL VGA_L1_R1, R2
	ADDI 1, R2
	XOR R10, R10
	STORE R2, R10

LOOP:	MOVI  0xF4, R11
	MOVIU 0x1, R11
	LOAD R0, R10
	
	LOADLBL MOVE_PERSON, R14
	LOADLBL WAIT, R5
	JUMP R5

	# R10 - temporary for accessing data in mem
	# R9  - temporary for storing data in mem
	# R8  - location the man may move to
MOVE_PERSON:
	READGAMEPAD R3
	# check to see button down was pressed, jump if true
#	LOAD R0, R10
#	ADDI 1, R10
	STORE R10, R3 # debug, change the start VGA square to the button being pressed
	
	LOADLBL BUTTON_DOWN, R10
	LOAD R10, R9
	CMP R3, R9
	JEQ MOVE_DOWN
	# check to see if button up is pressed
	LOADLBL BUTTON_UP, R10
	LOAD R10, R9
	CMP R3, R9
	JEQ MOVE_UP
	# check to see if button left is pressed
	LOADLBL BUTTON_LEFT, R10
	LOAD R10, R9
	CMP R3, R9
	JEQ MOVE_LEFT
	# check to see if button right is pressed
	LOADLBL BUTTON_RIGHT, R10
	LOAD R10, R9
	CMP R3, R9
	JEQ MOVE_RIGHT

	JOFFSET MOVE_PERSON_E

# r8 is the location to be moved to
MOVE_DOWN:
	MOV R2, R8
	ADD R1, R8
	JOFFSET MOVE_END
MOVE_UP:
	MOV R2, R8
	SUB R1, R8
	JOFFSET MOVE_END
MOVE_LEFT:
	MOV R2, R8
	SUBI 1, R8
	JOFFSET MOVE_END
MOVE_RIGHT:
	MOV R2, R8
	ADDI 1, R8
	JOFFSET MOVE_END
MOVE_END:
	# the new location of the person will be R8!
	# move the person tile to the new location
#	LOAD R2, R9
	XOR R9, R9 # this should create the code for a person.
	STORE R8, R9	# store R9 into location R8
	# move the passable square tile to the old location
	LOADLBL PASSABLE_SQUARE, R10
	LOAD R10, R9 
	STORE R2, R9

	MOV R8, R2
		
MOVE_PERSON_E:	
	LOADLBL LOOP, R10
	JUMP R10


# R11 - Number of milseconds to wait
WAIT:	CLOCK R10	#Get the current time
	ADD R10, R11    # calculate the time to end
WAIT_L1:
	NOP
	CLOCK R10
	CMP R10, R11
	JLS WAIT_L1

	JUMP R14
	
# R11 - number of loops before returning
#WAIT:	CMPI 0, R11
#	BEQ
#	JUMP R14
#	STORE R15, R14
#	ADDI 1, R15
#	XOR R10, R10
#	SUBI 1, R10
#	MOVIU 0xF, R10
#	MOVI 255, R10
#WAIT_L1S:
#	STORE R15, R10
#	ADDI 1, R15
#	STORE R15, R11
#	ADDI 1, R15
#	SUBI 1, R11
#	LOADLBL WAIT_R1, R14
#	LOADLBL WAIT, R9
#	JUMP R9
#WAIT_R1:
#	SUBI 1, R15
#	LOAD R15, R11
#	SUBI 1, R15
#	LOAD R15, R10
#	SUBI 1, R10
#	CMPI 0, R10
#	JEQ WAIT_L1E
#	JOFFSET WAIT_L1S
#WAIT_L1E:
#	SUBI 1, R15
#	LOAD R15, R14
#	JUMP R14
	

BUTTON_DOWN:	.fill 0x0010
BUTTON_UP:	.fill 0x0020
BUTTON_RIGHT:	.fill 0x0040
BUTTON_LEFT:	.fill 0x0080

PASSABLE_SQUARE:	.fill 0x000C

PLAYER_LOCATION: .fill 0x0000
GAME_WIDTH:	.fill 0x0000
	
STACK:	.fill 0x000
	.fill 0x000
	.fill 0x000
	.fill 0x000
	.fill 0x000
	.fill 0x000
	.fill 0x000
	.fill 0x000
	.fill 0x000
	.fill 0x000
	.fill 0x000
	.fill 0x000
	.fill 0x000
	.fill 0x000
	.fill 0x000
	.fill 0x000
	.fill 0x000
	.fill 0x000
	.fill 0x000
	.fill 0x000
	.fill 0x000
	.fill 0x000	
	.fill 0x000
	.fill 0x000
	.fill 0x000

VGA_L1_R0:
	.fill 0x0004  
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
VGA_L1_R1:
	.fill 0x0004
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x0004
VGA_L1_R2:
	.fill 0x0004
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x0004
VGA_L1_R3:
	.fill 0x0004
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x0004
VGA_L1_R4:
	.fill 0x0004
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x0004
VGA_L1_R5:
	.fill 0x0004
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x0004
VGA_L1_R6:
	.fill 0x0004
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x0004
VGA_L1_R7:
	.fill 0x0004
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x0004
VGA_L1_R8:
	.fill 0x0004
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x0004
VGA_L1_R9:
	.fill 0x0004
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x0004
VGA_L1_R10:
	.fill 0x0004
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x0004
VGA_L1_R11:
	.fill 0x0004
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x0004
VGA_L1_R12:
	.fill 0x0004
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x0004
VGA_L1_R13:
	.fill 0x0004
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x0004
VGA_L1_R14:
	.fill 0x0004
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x0004
VGA_L1_R15:
	.fill 0x0004
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x0004
VGA_L1_R16:
	.fill 0x0004
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x0004
VGA_L1_R17:
	.fill 0x0004
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x0004
VGA_L1_R18:
	.fill 0x0004
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x000C
	.fill 0x0004
VGA_L1_R19:
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004
	.fill 0x0004