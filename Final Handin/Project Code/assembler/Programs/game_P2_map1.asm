	NOP

SETUP:
	LOADLBL INIT, R14
	LOADLBL BACKUP_SAVE, R5
	JUMP R5

INIT:	
	# initialize registers to zero.  This might fix a funky bug.
	XOR R0, R0
	XOR R1, R1
	XOR R2, R2
	XOR R3, R3
	XOR R4, R4
	XOR R5, R5
	XOR R6, R6
	XOR R7, R7
	XOR R8, R8
	XOR R9, R9
	XOR R10, R10
	XOR R11, R11
	XOR R12, R12
	XOR R13, R13
	XOR R14, R14
	XOR R15, R15	
	
	
	LOADLBL STACK, R15 	#initalize stack pointer
	
	LOADLBL VGA_R0, R5
	SETBEGINVGA R5	
	LOADLBL VGA_R1, R6
	SUB R5, R6	# calculate the row width
	#set VGA pointers

	SETROWVGA R6
	LOADLBL G_VGA_ROW, R5
	STORE R5, R6

# wait for a little while, this might fix another bug, but who know what but it is really
# fixing?  If I said that the game does not work unless you stand on your head would you
# also think that is true?	
	MOVI 0x64, R11
	LOADLBL WAIT_SETUP, R10
	LOADLBL INIT_R1, R14
	JUMP R10
INIT_R1:
	LOADLBL INIT_R2, R14
	LOADLBL WAIT_FINISH, R10
	JUMP R10
INIT_R2:	

	# calculate  15 * rowwidth
	LSH R6, R7
	LSH R7, R7
	LSH R7, R7
	LSH R7, R7
	SUB R6, R7
	# calculate VGA_END - 15 * rowidth.  This will be max ptr location
	LOADLBL VGA_END, R8
	SUB R7, R8
	LOADLBL G_WINDOW_PTR_MAX, R10
	STORE R10, R8

#    This can be used for testing purposes to jump over network handshake
#	LOADLBL INIT_PLAYER, R10
#	JUMP R10
	
# this is inlined because I thought I could develop it faster
# initialize multiplayer section ########################
# R10 - Used for label referenced
# R9  - Stores the key value for 'start'
# R8  - Used for gamepad input and serial input
# R7  - temp register used for short calculations
# R6  - temp register used for short calculations
	

	LOADLBL G_BUTTON_START, R10
	LOAD R10, R9
	
HAND_SHAKE_L1:
	READGAMEPAD R8
	CMP R8, R9
	JEQ HAND_SHAKE_L2_MAKE_HOST # if start was pressed, try to become the host.

	READSERIAL R8
	JOFFSET HAND_SHAKE_L1	# done if read did not work
	
	JOFFSET HAND_SHAKE_L5_MAKE_SLAVE # if it got a signal from serial, try to become slave.
# if this was signaled to be the 'host' send the signal 0xAAAA to the other board, to say
# it is going to start (signal used to filter out ongoing single player game)
# if it can not make a connection. . . go back to hand shaking?  (could start single player?)
HAND_SHAKE_L2_MAKE_HOST:	
	MOVI 0xAA, R7
	MOVIU 0xAA, R7
	WRITESERIAL R7

	# set timeout for wait to be 5000 ms, setup wait
#	MOVI 0x13, R6
#	MOVIU 0x88, R6
	MOVI 0xFF, R6
	CLOCK R7
	ADD R7, R6

HAND_SHAKE_L3_SIGNAL:
	CLOCK R7
	CMP R7, R6
	JEQ HAND_SHAKE_L1 # if timeout happend

	READSERIAL R8
	JOFFSET HAND_SHAKE_L3_SIGNAL	# if not, loop again!
	
	JOFFSET HAND_SHAKE_L4	# if it did read something. . .
	
HAND_SHAKE_L4:
	MOVI 0x77, R7
	MOVIU 0x77, R7
	CMP R7, R8	# check to see if the other board recognized
	JEQ HAND_SHAKE_L4_FINISH
	JOFFSET HAND_SHAKE_L1
HAND_SHAKE_L4_FINISH:	
	# at this point this FPGA is player 1, initalize and go
	LOADLBL G_PLAYER1_LOCATION, R10
	LOADLBL G_HOST_START, R7
	STORE R10, R7

	LOADLBL G_PLAYER2_LOCATION, R10
	LOADLBL G_SLAVE_START, R7
	STORE R10, R7

	# setup first wait loop.  I was too lazy to not inline it :(
	CLOCK R9
	LOADLBL G_WAIT_INTERVAL, R10
	LOAD R10, R8
	LOADLBL G_WAIT_UNTIL, R10
	ADD R9, R8
	STORE R10, R8	

	LOADLBL MAIN_LOOP, R0	# jump location for where to start the game
	JOFFSET INIT_PLAYER

# if it is going to be the slave
HAND_SHAKE_L5_MAKE_SLAVE:
	# check to see if the right request was sent to this board
	MOVI 0xAA, R7
	MOVIU 0xAA, R7
	CMP R7, R8
	JEQ HAND_SHAKE_L6_SIGNAL

	JOFFSET HAND_SHAKE_L1 # if wrong request sent, restart waiting
HAND_SHAKE_L6_SIGNAL:
	# respond with positive signal
	MOVI 0x77, R7
	MOVIU 0x77, R7
	WRITESERIAL R7

	# setup this player as slave
	LOADLBL G_PLAYER1_LOCATION, R10
	LOADLBL G_SLAVE_START, R7
	STORE R10, R7

	LOADLBL G_PLAYER2_LOCATION, R10
	LOADLBL G_HOST_START, R7
	STORE R10, R7

	# WAIT FOR HALF AN INTERVAL AS THE SLAVE
	CLOCK R9
	LOADLBL G_WAIT_INTERVAL, R10
	LOAD R10, R8
	RSH R8, R8	# TAKE HALF OF THE WAIT INTERVAL
	LOADLBL G_WAIT_UNTIL, R10
	ADD R9, R8
	STORE R10, R8
	
	# 'slave' player will have second turn, so it will start in wait state
	LOADLBL MAIN_LOOP_R1, R0	
	JOFFSET INIT_PLAYER


INIT_PLAYER:	
	# player location is being set by program
	LOADLBL G_PLAYER1_LOCATION, R8
	LOAD R8, R7
	LOADLBL G_PLAYER1_DOWN, R8 # put the player 1 tile at his location on the board
	LOAD R8, R8
	STORE R7, R8

	LOADLBL G_PLAYER2_LOCATION, R8
	LOAD R8, R7
	LOADLBL G_PLAYER2_DOWN, R8
	LOAD R8, R8
	STORE R7, R8

	# go to correct start possition (if 'host' their turn in first)
	JUMP R0

#	XOR R3, R3
#	MOVI 1, R3
	# goto main loop to start the game
	
MAIN_LOOP:
	LOADLBL MAIN_LOOP_R1, R14
	LOADLBL LOCAL_MOVE, R5

	JUMP R5
MAIN_LOOP_R1:
	LOADLBL MAIN_LOOP_R2, R14
	LOADLBL WAIT_GAME, R5

	JUMP R5
MAIN_LOOP_R2:
	JOFFSET MAIN_LOOP
	
#	MOVI 0xF4, R11	
#	MOVIU 0x01, R11
#	MOVI 0xff, R11
#	LOADLBL WAIT_SETUP, R5
#	LOADLBL MAIN_LOOP_R1, R14
#	JUMP R5

#MAIN_LOOP_R1:	
#	# do local move
#	LOADLBL MAIN_LOOP_R3, R14
#	LOADLBL LOCAL_MOVE, R5

#	JUMP R5
#MAIN_LOOP_R3:
#	LOADLBL WAIT_FINISH, R5
#	LOADLBL MAIN_LOOP_R3a, R14
#	JUMP R5

#MAIN_LOOP_R3a:	
	# wait setup for remote move
#	MOVI 0xff, R11
#	LOADLBL WAIT_SETUP, R5
#	LOADLBL MAIN_LOOP_R4, R14
#	JUMP R5
#MAIN_LOOP_R4:
#	# do remote move
#	LOADLBL MAIN_LOOP_R5, R14
#	LOADLBL REMOTE_MOVE, R5

#	JUMP R5
#MAIN_LOOP_R5:
#	LOADLBL WAIT_FINISH, R5
#	LOADLBL MAIN_LOOP_R6, R14
#	JUMP R5
	
#MAIN_LOOP_R6:	
	
#	MOV R13, R1
	
#	LOADLBL VGA_R0, R10
#	LOAD R10, R2
#	ADD R3, R2
#	STORE R10, R2

#	XOR R4, R4
#	SUB R3, R4
#	MOV R4, R3
	
#	JOFFSET MAIN_LOOP




############################## LOCAL_MOVE ##############################
# This method moves the local player (player 1).  The begining of this mehod
# the game input is taken and that value is sent to the other computer.
# after the input happens the local player will move and the screen will
# adjust

# Arguments:
# -- NONE --

# Variables used:
# R10 - temp register used to store addresses
#
# R0 - Game input
#
LOCAL_MOVE:
	STORE R15, R14
	ADDI 1, R15
	STORE R15, R0
	ADDI 1, R15

	# get the user input and send it to the other machine
	XOR R0, R0
	NOP
	READGAMEPAD R0
	NOP
	NOP
	WRITESERIAL R0

	# move the player
LOCAL_MOVE_L1:
	LOADLBL G_PLAYER1_LOCATION, R11
	LOADLBL G_PLAYER1_DOWN, R13
	MOV R0, R12
	LOADLBL LOCAL_MOVE_R1, R14
	LOADLBL MOVE_PERSON, R5
	JUMP R5
	
LOCAL_MOVE_R1:
	# adjust the screen for the local player	
	LOADLBL ADJUST_SCREEN, R5
	LOADLBL LOCAL_MOVE_R2, R14
	JUMP R5
	
LOCAL_MOVE_R2:
	# restore saved registers and return
	SUBI 1, R15
	LOAD R15, R0
	SUBI 1, R15
	LOAD R15, R14

	JUMP R14

############################## REMOTE_MOVE ##############################
# This method moves the remote player (player 2).  The begining of this mehod
# the game input is taken and that value is sent to the other computer.
# after the input happens the local player will move and the screen will
# adjust

# Arguments:
# -- NONE --

# Variables used:
# R11 - record the clock
# R10 - temp register used to store addresses
# R9 - temporary for short calculations
# R8 - temporary for short calculations
# R0 - Game input
#
REMOTE_MOVE:
	STORE R15, R14
	ADDI 1, R15
	STORE R15, R0
	ADDI 1, R15

	XOR R0, R0
	
	LOADLBL G_WAIT_UNTIL, R10
	LOAD R10, R9
	# loop until wait finish or input from serial.  Whatever one comes first
REMOTE_MOVE_L1:
	# check if it has waited too long
	CLOCK R8
	CMP R8, R9
	JEQ REMOTE_MOVE_R2

	# check to see if something has come accross the wire
	READSERIAL R0
	JOFFSET REMOTE_MOVE_L1 # this line is used if read Failed

	# if it grabs 0's (null) try to get another read if possible.
	XOR R8, R8
	CMP R8, R0
	JEQ REMOTE_MOVE_L1
		
	JOFFSET REMOTE_MOVE_L3_SUCCESS

	
REMOTE_MOVE_L3_SUCCESS:	

	# move the player

	LOADLBL G_PLAYER2_LOCATION, R11
	LOADLBL G_PLAYER2_DOWN, R13
	MOV R0, R12
	LOADLBL REMOTE_MOVE_R2, R14
	LOADLBL MOVE_PERSON, R5
	JUMP R5
	
# no screen adjusting for player 2
#REMOTE_MOVE_R1:
	# adjust the screen for the local player	
#	LOADLBL ADJUST_SCREEN, R5
#	LOADLBL REMOTE_MOVE_R2, R14
#	JUMP R5
	
REMOTE_MOVE_R2:
	# restore saved registers and return
	SUBI 1, R15
	LOAD R15, R0
	SUBI 1, R15
	LOAD R15, R14

	JUMP R14

	
############################## MOVE_PERSON ##############################
# This method is used to move a player square around the map.  Arguments
# given to the method are a pointer to the start of the memory blocks
# where the player tiles are stored, pointer to global of the location
# of the person being moved.
# (this will mostly be useful for multiplayer modes), and controller input
# This method will move the person, if possible, updating the memory location
# of where the person is now located


# Arguments:
# R11 - Pointer to global memory that states where the person is located
# R12 - Controller input
# R13 - Pointer to man tile (0: DOWN, 1: UP, 2: RIGHT, 3: LEFT)
# Returns: nothing.

# Variables used:
# R10 - temp register used to load values from memory
# R9 - current location of person
# R8 - potential next location of person
# R7 - Used for very short calculations (less than a few lines)
# R6 - 
# R5 - Used for short calculations (less than a few lines)
	
MOVE_PERSON:
	LOAD R11, R9	# put the current location of the man into R9
	MOV R9, R8	# put the currect location into R8, so adjustments
	                # be made directoy to R8

# Decode what button was pressed (order of presidence DOWN, UP, RIGHT, LEFT)
# check if down button was pressed
MOVE_PERSON_L1:	
	LOADLBL G_BUTTON_DOWN, R10
	LOAD R10, R7
	AND R12, R7
	CMPI 0, R7 # if it is zero the button was not pressed
	JEQ MOVE_PERSON_L2
	JOFFSET MOVE_PERSON_L6_DOWN
# check if up button was pressed
MOVE_PERSON_L2:
	LOADLBL G_BUTTON_UP, R10
	LOAD R10, R7
	AND R12, R7
	CMPI 0, R7
	JEQ MOVE_PERSON_L3
	JOFFSET MOVE_PERSON_L7_UP
# check if right button was pressed
MOVE_PERSON_L3:
	LOADLBL G_BUTTON_RIGHT, R10
	LOAD R10, R7
	AND R12, R7
	CMPI 0, R7
	JEQ MOVE_PERSON_L4
	JOFFSET MOVE_PERSON_L8_RIGHT
# check if left button was pressed
MOVE_PERSON_L4:
	LOADLBL G_BUTTON_LEFT, R10
	LOAD R10, R7
	AND R12, R7
	CMPI 0, R7
	JEQ MOVE_PERSON_L5
	JOFFSET MOVE_PERSON_L9_LEFT
# no buttons were pressed for a move, so just end function
MOVE_PERSON_L5:	
	JUMP R14

# process specific logic for directional move
# 1) find the next location the person may move
# 2) calculate the next tile to use for direction of person
MOVE_PERSON_L6_DOWN:
	# to move down, add vga row size to location
	LOADLBL G_VGA_ROW, R10
	LOAD R10, R7
	ADD R7, R8
	# man tile is already pointing to DOWN
	ADDI 0, R13
	JOFFSET MOVE_PERSON_L10
MOVE_PERSON_L7_UP:
	# to move up, subtract vga row size to location
	LOADLBL G_VGA_ROW, R10
	LOAD R10, R7
	SUB R7, R8
	# man tile for down is +1
	ADDI 1, R13
	JOFFSET MOVE_PERSON_L10
MOVE_PERSON_L8_RIGHT:
	# to move right, add 1 to currect location
	ADDI 1, R8
	# man tile for right is +2
	ADDI 2, R13
	JOFFSET MOVE_PERSON_L10
MOVE_PERSON_L9_LEFT:
	# to move left, subtract 1 from currenct location
	SUBI 1, R8
	# man tile for left if +3
	ADDI 3, R13
	JOFFSET MOVE_PERSON_L10
	
# end movement specific portion
# 1) check to see if won!
# 2) check to see if movable
#   -> if not movable R9->R8
# 3) set variables appropreatly for the move
MOVE_PERSON_L10:	
	LOAD R8, R5	# what is in the square trying to move to
	
	LOADLBL G_WIN_SQUARE, R10
	LOAD R10, R7	# load the winning square into R7
	CMP R5, R7
	JEQ MOVE_PERSON_L11_WIN

	LOADLBL G_PASSABLE_SQUARE, R10
	LOAD R10, R7
	CMP R5, R7
	JEQ MOVE_PERSON_L12

 # if trying to move to a box location, it will eventually move the box
	LOADLBL G_BOX_SQUARE, R10
	LOAD R10, R7
	CMP R5, R7
	JEQ MOVE_PERSON_L11_BOX

# otherwise, the square can not be moved to, so set so it does not move person
	MOV R9, R8
JOFFSET MOVE_PERSON_L12

# prepare to win and jump to win method
MOVE_PERSON_L11_WIN:
# the person will move onto the win square than jump to win method.  The trophy
# should appear where the exit location is located
	LOADLBL G_PASSABLE_SQUARE, R10
	LOAD R10, R7

	STORE R11, R8
	
	STORE R9, R7
	MOV R8, R11

	LOADLBL WIN_GAME, R10
	JUMP R10	# it will never return from this method

	
# run the move box method.  If the next square is no longer a box, move the
# person.  Otherwise we assume the box could not be moved so the person
# will not be moved
MOVE_PERSON_L11_BOX:
	# store R14, R13, R12, R11, R9, R8, R6 on stack
	STORE R15, R14
	ADDI 1, R15
	STORE R15, R13
	ADDI 1, R15
	STORE R15, R12
	ADDI 1, R15
	STORE R15, R11
	ADDI 1, R15
	STORE R15, R9
	ADDI 1, R15
	STORE R15, R8
	ADDI 1, R15
	STORE R15, R6
	ADDI 1, R15
	# setup argument:
	#  R11 - pointer to box being moved
	#  R12 - controller input
	#  R14 - return location
	MOV R8, R11
	LOADLBL MOVE_PERSON_L11_BOX_R, R14
	LOADLBL MOVE_BLOCK, R5
	JUMP R5
	# R12 contains controller input

MOVE_PERSON_L11_BOX_R:	
	SUBI 1, R15
	LOAD R15, R6
	SUBI 1, R15
	LOAD R15, R8
	SUBI 1, R15
	LOAD R15, R9
	SUBI 1, R15
	LOAD R15, R11
	SUBI 1, R15
	LOAD R15, R12
	SUBI 1, R15
	LOAD R15, R13
	SUBI 1, R15
	LOAD R15, R14

# check to see if the block is moved (by checking if it is a passable square
	LOAD R8, R7
	LOADLBL G_PASSABLE_SQUARE, R10
	LOAD R10, R5
	CMP R7, R5
	JEQ MOVE_PERSON_L12
# If not, don't move the person
	MOV R9, R8
	
MOVE_PERSON_L12:
	# store the passable square where the person 'used to be'
	LOADLBL G_PASSABLE_SQUARE, R10
	LOAD R10, R7
	STORE R9, R7
	# store the new tile where the person 'moved to'
	LOAD R13, R7
	STORE R8, R7
	# store the new location of the person in the global data area
	STORE R11, R8
	
MOVE_PERSON_END:
	JUMP R14

##############################   MOVE_BLOCK  ##############################
# This method is used to move a box or block around the square.  Boxes are moved
# in the same way a player is moved around.  If the block can not move in the
# direction desired, the block will not move.  If it can move it will
# be pushed into the new location.  If the new location is a lava square,
# the lava and block will be destroyed and the lava square will be turned into
# a passable square.
	
# Arguments:
# R11 - Pointer to location of box that we are trying to move
# R12 - Controller input (just like to MOVE_PERSON)
# Returns: nothing.

# Variables used:
# R10 - temp register used to load values from memory
# R9 - current location of box, used to make copy, paste easy from MOVE_PERSON
# R8 - potential next location of block
# R7 - Used for very short calculations (less than a few lines)
# R6 - 
# R5 - Used for short calculations (less than a few lines)

MOVE_BLOCK:
	# consistency check, verify it is a box being moved.  If not return
	LOADLBL G_BOX_SQUARE, R10
	LOAD R10, R7
	LOAD R11, R5
	CMP R7, R5
	JEQ MOVE_BLOCK_START # If they are not equal it is not a box being moved
	JUMP R14
	
MOVE_BLOCK_START:	
	# This is done to make COPY/PASTE easy.  MOVE_BLOCK is almost the same
	# as moving a person, with only a few minor rule differences
	MOV R11, R9	# put the current location of the block into R9.
	MOV R9, R8	# put the currect location into R8, so adjustments
	                # be made directoy to R8

# Decode what button was pressed (order of presidence DOWN, UP, RIGHT, LEFT)
# check if down button was pressed
MOVE_BLOCK_L1:	
	LOADLBL G_BUTTON_DOWN, R10
	LOAD R10, R7
	AND R12, R7
	CMPI 0, R7 # if it is zero the button was not pressed
	JEQ MOVE_BLOCK_L2
	JOFFSET MOVE_BLOCK_L6_DOWN
# check if up button was pressed
MOVE_BLOCK_L2:
	LOADLBL G_BUTTON_UP, R10
	LOAD R10, R7
	AND R12, R7
	CMPI 0, R7
	JEQ MOVE_BLOCK_L3
	JOFFSET MOVE_BLOCK_L7_UP
# check if right button was pressed
MOVE_BLOCK_L3:
	LOADLBL G_BUTTON_RIGHT, R10
	LOAD R10, R7
	AND R12, R7
	CMPI 0, R7
	JEQ MOVE_BLOCK_L4
	JOFFSET MOVE_BLOCK_L8_RIGHT
# check if left button was pressed
MOVE_BLOCK_L4:
	LOADLBL G_BUTTON_LEFT, R10
	LOAD R10, R7
	AND R12, R7
	CMPI 0, R7
	JEQ MOVE_BLOCK_L5
	JOFFSET MOVE_BLOCK_L9_LEFT
# no buttons were pressed for a move, so just end function
MOVE_BLOCK_L5:	
	JUMP R14

# process specific logic for directional move
# 1) find the next location the block may move to
MOVE_BLOCK_L6_DOWN:
	# to move down, add vga row size to location
	LOADLBL G_VGA_ROW, R10
	LOAD R10, R7
	ADD R7, R8
	JOFFSET MOVE_BLOCK_L10
MOVE_BLOCK_L7_UP:
	# to move up, subtract vga row size to location
	LOADLBL G_VGA_ROW, R10
	LOAD R10, R7
	SUB R7, R8
	JOFFSET MOVE_BLOCK_L10
MOVE_BLOCK_L8_RIGHT:
	# to move right, add 1 to currect location
	ADDI 1, R8
	JOFFSET MOVE_BLOCK_L10
MOVE_BLOCK_L9_LEFT:
	# to move left, subtract 1 from currenct location
	SUBI 1, R8
	JOFFSET MOVE_BLOCK_L10
	
# end movement specific portion
# 1) check to see if won!
# 2) check to see if movable
#   -> if not movable R9->R8
# 3) set variables appropreatly for the move
MOVE_BLOCK_L10:	
	LOAD R8, R5	# R5 = what is in the square trying to move to

	LOADLBL G_PASSABLE_SQUARE, R10
	LOAD R10, R7
	CMP R5, R7
	JEQ MOVE_BLOCK_L12_PASSABLE

	LOADLBL G_LAVA_SQUARE, R10
	LOAD R10, R7
	CMP R5, R7
	JEQ MOVE_BLOCK_L13_LAVA

# otherwise, the block can not be moved, so just jump out of method and leave
# everything as is
	JOFFSET MOVE_BLOCK_END

# If pushing the block into a normal passable location
MOVE_BLOCK_L12_PASSABLE:
	# remove the block from where it used to be
	LOADLBL G_PASSABLE_SQUARE, R10
	LOAD R10, R7
	STORE R9, R7
	# put the block in the next location
	LOADLBL G_BOX_SQUARE, R10
	LOAD R10, R7
	STORE R8, R7

	JOFFSET MOVE_BLOCK_END
# If pushing the block into a lava square
# 1) block is removed
# 2) lava square becomes passable square (blcok covers lava)
MOVE_BLOCK_L13_LAVA:	
	# remove the block from the map
	LOADLBL G_PASSABLE_SQUARE, R10
	LOAD R10, R7
	STORE R9, R7
	# store a passable square into the next location
	STORE R8, R7

	JOFFSET MOVE_BLOCK_END

MOVE_BLOCK_END:
	JUMP R14

	
############################## ADJUST_SCREEN ##############################
# This method is used to center the screen on player 1.
# global variables define how the screen will be adjusted.
#  G_WINDOW_PTR_MIN - window pointer should never be less than this value
#  G_WINDOW_PTR_MAX - window pointer hsould never be more than this value
#  G_WINDOW_W_BORDER- when man gets within this man squares of the edge
#                        the screen will be adjusted
#  G_WINDOW_H_BORDER- when the man get within this many square of the top or
#	                 bottom the screen will be adjusted.

# ALGORITHMS: The algorithm used to adjust the screen does the following:
#	find how many rows down from the VGA_PTR player 1 is.  As a byproduct
#       the column the player is in will also be calculated.
#       1) if column is out of bounds, adjust appropreatly
#	2) if row is out of bounds, adjust appropreatly
#       3) if adjusting the column and row caused the VGA pointer to be
#		out of bounds, unadjust appropreatly
	
# Arguments: None
# Return: None

# R5  - loop counter, stores how many rows down the player is from VGA_START
# R6  - column counter, stores what column the player is in from VGA_START
# R7  - VGA_POINTER value pulled from G_VGA_START
# R8  -
# R9  - Uaws to store values for temporary calculations
# R10 - Used to store memory locations of loads and stores
# R11 - Used to store values for temporary calculations
# R12 - Used to store values for temporary calculations
ADJUST_SCREEN:
	# get the VGA start pointer
	LOADLBL G_VGA_START, R10
	LOAD R10, R7
	# get the location of player1.  put into R6, will be adjusted in loop
	#  to become column counter
	LOADLBL G_PLAYER1_LOCATION, R10
	LOAD R10, R6
	# get the row width of the maze.  Used in the loop to find where the
	#  player is located
	LOADLBL G_VGA_ROW, R10
	LOAD R10, R12
	# loop counter = 0, column counter -= VGA_START
	XOR R5, R5
	SUB R7, R6

	# load how wide the window is.  This is used in the loop.
	LOADLBL G_WINDOW_WIDTH, R10
	LOAD R10, R11
	# count how many rows down the player is
ADJUST_SCREEN_L1S:
	CMP R11, R6
	JHS ADJUST_SCREEN_L1E

	ADDI 1, R5
	SUB R12, R6

	JOFFSET ADJUST_SCREEN_L1S
ADJUST_SCREEN_L1E:	

 # adjust screen horizontally, if needed
 # if location < window border, adjust screen because it is to the left
	LOADLBL G_WINDOW_W_BORDER, R10
	LOAD R10, R11
	CMP R11, R6
	JHS ADJUST_SCREEN_L2_LEFT
 # if location > window_width - boarder, adjust screen because it is to the right
	LOADLBL G_WINDOW_WIDTH, R10
	LOAD R10, R12
	SUB R11, R12
	CMP R12, R6
	JLS ADJUST_SCREEN_L3_RIGHT

 # do vertical, but for now just return if nothing was found
	JOFFSET ADJUST_SCREEN_L4

ADJUST_SCREEN_L2_LEFT:
 # if adjusting the pointer would make it smaller than the min value
 # jump to have the value adjusted vertically.
	LOADLBL G_WINDOW_PTR_MIN, R10
	LOAD R10, R12
	MOV R7, R11
	SUBI 1, R11
	MOV R11, R7
	CMP R11, R12
	JLS ADJUST_SCREEN_L6_LOW
	
#	MOV R11, R7
	JOFFSET ADJUST_SCREEN_L4
ADJUST_SCREEN_L3_RIGHT:
 # if adjusting the pointer would make it larger than the max value
 # jump to have the value adjusted vertically.  it will adjust horizontally
 # regaurdless of if it will go out of bounds.  However, it will adjust
 # verdically if it will go out of bounds.
	LOADLBL G_WINDOW_PTR_MAX, R10
	LOAD R10, R12
	MOV R7, R11
	ADDI 1, R11
	MOV R11, R7
	CMP R11, R12
	JHS ADJUST_SCREEN_L5_HIGH
	
#	ADDI R11, R7
	JOFFSET ADJUST_SCREEN_L4

ADJUST_SCREEN_L4:
	
 # if loop < G_WINDOW_H_BOARDER, adjust screen because it is too high
	LOADLBL G_WINDOW_H_BORDER, R10
	LOAD R10, R11
	CMP R11, R5
	JHS ADJUST_SCREEN_L5_HIGH
 # if loop > window_hight - border, adjust screen because it is too low
	LOADLBL G_WINDOW_HIGHT, R10
	LOAD R10, R12
	SUB R11, R12
	CMP R12, R5
	JLS ADJUST_SCREEN_L6_LOW

	JOFFSET ADJUST_SCREEN_L7

ADJUST_SCREEN_L5_HIGH:
	LOADLBL G_VGA_ROW, R10
	LOAD R10, R9
	LOADLBL G_WINDOW_PTR_MIN, R10
	LOAD R10, R12
	MOV R7, R11
	SUB R9, R11

 # if min > adjusted  Dont do anything--jump to other adjust verdical secion
	CMP R11, R12
#	JLS ADJUST_SCREEN_L6_LOW
	JLS ADJUST_SCREEN_L7

	MOV R11, R7
	JOFFSET ADJUST_SCREEN_L7
ADJUST_SCREEN_L6_LOW:
	LOADLBL G_VGA_ROW, R10
	LOAD R10, R9
	LOADLBL G_WINDOW_PTR_MAX, R10
	LOAD R10, R12
	MOV R7, R11
	ADD R9, R11

 # if max < adjusted, don't do anyting
	CMP R11, R12
	JHS ADJUST_SCREEN_L7

	MOV R11, R7
	JOFFSET ADJUST_SCREEN_L7

ADJUST_SCREEN_L7:

	# TODO: check if it is out of bounds
	SETBEGINVGA R7
	LOADLBL G_VGA_START, R10
	STORE R10, R7

	JUMP R14

############################## WIN_GAME ##############################
# In single player game, turn the player into a trophy.  In a multiplayer
# version of this game the other player will be turned into a skull, because
# they lost.

# Arguments: R11 - pointer to the location of the winning player

# Returns: does not return. . .ever

# R11 - location of winner
# R10 - used as temporary for memory references.
# R9  - stores tiles
WIN_GAME:
	LOADLBL G_SKULL_SQUARE, R10
	LOAD R10, R9
# this seems redundent because it is only a single player version
	LOADLBL G_PLAYER1_LOCATION, R10
	LOAD R10, R10
	STORE R10, R9

	LOADLBL G_PLAYER2_LOCATION, R10
	LOAD R10, R10
	STORE R10, R9
	
	LOADLBL G_TROPHY_SQUARE, R10
	LOAD R10, R9

	STORE R11, R9

	LOADLBL G_BUTTON_START, R10
	LOAD R10, R11
WIN_GAME_L1:
	READGAMEPAD R12

	CMP R12, R11
	JEQ WIN_GAME_L2
	JOFFSET WIN_GAME_L1

WIN_GAME_L2:
	LOADLBL INIT, R14
	LOADLBL BACKUP_RESTORE, R11

	JUMP R11
	

	
############################## WAIT_SETUP ##############################
# This method is used to setup the wait method.  The arument passed is
# how many millisecods from WAIT_SETUP being called, WAIT should finish
# This assumes that WAIT_FINISH is called before the time limmit is up.
# (because WAIT_FINISH tests for equals, because of integer overflow)

# THIS IS A SAFE FUNCTION (NO TEMPS ARE MODIFED), only R11, R12
# Argument: R11 - ms to wait
WAIT_SETUP:
	CLOCK R12
	ADD R12, R11
	LOADLBL G_WAIT_UNTIL, R12
	STORE R12, R11
	JUMP R14

############################## WAIT_FINISH ##############################
# Used to finish the time block defined by the WAIT_SETUP method.  No argumement
# is passed because the time to wait was already setup by WAIT_SETUP.
# The method returns the keys pressed by the user (OR of all keypress)

# THIS IS A SAFE FUNCTION (NO TEMPS ARE MODIFED), only R11, R12, R13
# Argument: None
# Return: R13 - OR of all user input entered during the wait

# R11 - keeps time to wait until
# R12 - temporary register used to store information for a little time
# Return:
# R13 - keeps OR of user input
WAIT_FINISH:
	LOADLBL G_WAIT_UNTIL, R12
	LOAD R12, R11	# load the time to wait until into R11
	XOR R13, R13	# zero R13

WAIT_FINISH_L1S:
#	READGAMEPAD R12
	OR R12, R13	# get game pad data and or with existing
	CLOCK R12
	CMP R11, R12	
	JEQ WAIT_FINISH_L1E	# if time to wait equals finish time, exit, otherwise loop again
	JOFFSET WAIT_FINISH_L1S

WAIT_FINISH_L1E:
# Some code added to test serial sending:
#	WRITESERIAL R13
	READGAMEPAD R13
	JUMP R14

############################## WAIT_GAME ##############################
# This method will wait for some amount of time, but if anything comes
# over the Serial cable, it will move the other player, then return
# and wait.  This method will set the timer for the next time this
# will be called.

# R0 - keep time to wait until
# R1 - keep the interval for timing
# R2 - protection clock

# R9 - temp for gathering data from clock
# R10 - temp register for memory addressing
WAIT_GAME:
	STORE R15, R14
	ADDI 1, R15
	STORE R15, R0
	ADDI 1, R15
	STORE R15, R1
	ADDI 1, R15

	LOADLBL G_WAIT_INTERVAL, R10
	LOAD R10, R1
	
	LOADLBL G_WAIT_UNTIL, R10
	LOAD R10, R0
WAIT_GAME_L1:
	CLOCK R9
	CMP R9, R0
	JEQ WAIT_GAME_L4_TIMEOUT

	READSERIAL R9
	JOFFSET WAIT_GAME_L1	# if nothing came across the wire, loop again

WAIT_GAME_L2_OTHER_MOVE:
	# if this part is reached, it means the other player has made a move
	LOADLBL G_PLAYER2_LOCATION, R11
	LOADLBL G_PLAYER2_DOWN, R13
	MOV R9, R12
	LOADLBL WAIT_GAME_R3, R14
	LOADLBL MOVE_PERSON, R5
	JUMP R5
WAIT_GAME_R3:
	JOFFSET WAIT_GAME_L1

WAIT_GAME_L4_TIMEOUT:
	# auto set for the next interval
	ADD R0, R1
	LOADLBL G_WAIT_UNTIL, R10
	STORE R10, R1

	SUBI 1, R15
	LOAD R15, R1
	SUBI 1, R15
	LOAD R15, R0
	SUBI 1, R15
	LOAD R15, R14

	JUMP R14
	
		
############################## BACKUP_SAVE ##############################
# Save all the data section to another portion of memory.  Everything from
# DATA_START -> DATA_END will be copied to DATA_BACKUP.  No bounds checking
# is done, so the programer must verify the data can be correctly
# stored to the memory location without any problems.

# THIS IS A SAFE FUNCTION (NO TEMPS ARE MODIFED), only R11, R12, R13
# Argument: None	

# R11 - Memory Pointer to data being copied.
# R12 - Memory Pointer to data location being copied to
# R13 - Temporary to store value temporarily

BACKUP_SAVE:
	LOADLBL DATA_START, R11
	LOADLBL DATA_BACKUP, R12

BACKUP_SAVE_L1S:
	LOAD R11, R13
	STORE R12, R13

	ADDI 1, R11
	ADDI 1, R12

	LOADLBL DATA_END, R13

	CMP R11, R13
	JEQ BACKUP_SAVE_L1E
	JOFFSET BACKUP_SAVE_L1S

BACKUP_SAVE_L1E:
	JUMP R14

############################## BACKUP_RESTORE ##############################
# Restore everything in the User memory and return to R14
#
BACKUP_RESTORE:	
	LOADLBL DATA_START, R11
	LOADLBL DATA_BACKUP, R12

BACKUP_RESTORE_L1S:
	LOAD R12, R13
	STORE R11, R13

	ADDI 1, R11
	ADDI 1, R12

	LOADLBL DATA_END, R13

	CMP R11, R13
	JEQ BACKUP_RESTORE_L1E
	JOFFSET BACKUP_RESTORE_L1S

BACKUP_RESTORE_L1E:
	JUMP R14

	
# allocated stack
STACK:	.fill 0x0000
	.fill 0x0000
	.fill 0x0000
	.fill 0x0000
	.fill 0x0000
	.fill 0x0000
	.fill 0x0000
	.fill 0x0000
	.fill 0x0000
	.fill 0x0000
	.fill 0x0000
	.fill 0x0000
	.fill 0x0000
	.fill 0x0000
	.fill 0x0000
	.fill 0x0000
	.fill 0x0000
	.fill 0x0000
	.fill 0x0000
	.fill 0x0000
	.fill 0x0000
	.fill 0x0000
	.fill 0x0000
	.fill 0x0000

	
# The G prefix defines that it is a global data field
DATA_START:

G_VGA_START:	.fill VGA_R0
G_VGA_ROW:	.fill 0x0000	#must be set programatically


G_PLAYER1_LOCATION:	.fill G_HOST_START
G_PLAYER2_LOCATION:	.fill G_SLAVE_START
	
# what bits will be set by the paddle when the move is taken
G_BUTTON_START:	.fill 0x0001
G_BUTTON_DOWN:	.fill 0x0010	
G_BUTTON_UP:	.fill 0x0020
G_BUTTON_RIGHT:	.fill 0x0040
G_BUTTON_LEFT:	.fill 0x0080

# what character will be used when the player moves in that direction
G_PLAYER1_DOWN:	.fill 0x0003
G_PLAYER1_UP:	.fill 0x0001
G_PLAYER1_RIGHT:	.fill 0x0000
G_PLAYER1_LEFT:	.fill 0x0002

G_PLAYER2_DOWN:	.fill 0x000A
G_PLAYER2_UP:	.fill 0x000B
G_PLAYER2_RIGHT:	.fill 0x0009
G_PLAYER2_LEFT:	.fill 0x0008

# global used by timing method to know when to stop waiting
G_WAIT_UNTIL:	.fill 0x0000
G_WAIT_INTERVAL:	.fill 0x01c8

# square information used by move methods
G_PASSABLE_SQUARE:	.fill 0x000C
G_LAVA_SQUARE:	.fill 0x0007
G_WIN_SQUARE:	.fill 0x0006
G_BOX_SQUARE:	.fill 0x0005
G_TROPHY_SQUARE:	.fill 0x000D
G_SKULL_SQUARE:	.fill 0x000E

# window information used by adjust screen method
G_WINDOW_PTR_MIN:	.fill VGA_L2_PRE
G_WINDOW_PTR_MAX:	.fill .fill 0x0000 # programatically as END - 15 * ROW_SIZE

G_WINDOW_W_BORDER:	.fill 3
G_WINDOW_H_BORDER:	.fill 3

G_WINDOW_WIDTH:	.fill 20	# how many tiles across the screen displays
G_WINDOW_HIGHT:	.fill 15	# how many tiles vertically the screen displays


##################################################
	###### MAP DATA #######
VGA_L2_PRE:
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

	
VGA_R0:
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

VGA_R1:
	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C


	.fill 0x000C
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 
G_HOST_START:
	.fill 0x000C
 	.fill 0x0004
 
G_SLAVE_START:
	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004


	.fill 0x0004
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C


	.fill 0x000C
 	.fill 0x0005
 	.fill 0x0007
 	.fill 0x000C
 	.fill 0x0005
 	.fill 0x0007
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0007
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C


	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0007
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0007
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x0004


	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0007
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x0005
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C


	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C


	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x0004


	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x0005
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C


	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C


	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x0004


	.fill 0x0004
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0007
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0007
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C


	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0005
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0007
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x0005
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0007
 	.fill 0x000C


	.fill 0x0005
 	.fill 0x000C
 	.fill 0x0005
 	.fill 0x000C
 	.fill 0x0007
 	.fill 0x000C
 	.fill 0x0007
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x0005
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0007
 	.fill 0x000C
 	.fill 0x0005
 	.fill 0x0007
 	.fill 0x000C
 	.fill 0x000C


	.fill 0x000C
 	.fill 0x0005
 	.fill 0x0007
 	.fill 0x000C
 	.fill 0x0005
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0007
 	.fill 0x000C
 	.fill 0x0005
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0005


	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0005
 	.fill 0x0005
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0005
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0007
 	.fill 0x000C
 	.fill 0x000C


	.fill 0x000C
 	.fill 0x0007
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0007
 	.fill 0x0007
 	.fill 0x0007
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0005
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
 	.fill 0x0005
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0007
 	.fill 0x0007
 	.fill 0x0007
 	.fill 0x000C
 	.fill 0x000C


	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0007
 	.fill 0x0007
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x0006
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0005
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0005
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C


	.fill 0x0007
 	.fill 0x000C
 	.fill 0x0007
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0007
 	.fill 0x000C
 	.fill 0x0006
 	.fill 0x000C
 	.fill 0x0006
 	.fill 0x000C
 	.fill 0x0007
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
 	.fill 0x0007
 	.fill 0x0007
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x0006
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x0005
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0005
 	.fill 0x000C


	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x0005
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0007
 	.fill 0x0004


	.fill 0x0004
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x0007
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
 	.fill 0x0005
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x0004
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0005
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
 	.fill 0x0005
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0005
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C


	.fill 0x000C
 	.fill 0x0005
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


	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0005
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x000C
 	.fill 0x0004
 	.fill 0x0005
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
VGA_END:	.fill 0x0004

DATA_END:	.fill 0x0000


##################
# This is the location in memory where a backup of all changing data is
# stored.  When a game is restarted, it pulls all the information from
# this area.
# This just assumes that there is enough room in memory to store a backup
# of the map and data.  If not you will know pretty fast because the memory
# will be currupted before the game starts.  However, since there is 16k words,
# it should not be too hard to figure out if it is too big: if the total line
# count of the output of the assembler is more than 8k, it might be too large
DATA_BACKUP:	
