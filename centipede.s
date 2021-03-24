#####################################################################
#
# CSC258H Winter 2021 Assembly Final Project
# University of Toronto, St. George
#
# Student: Yanxiang (Jimmy) Lan, 1005463240
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4
# - Unit height in pixels: 4
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# (See the project handout for descriptions of the milestones)
# - Milestone 1/2/3/4/5 (choose the one the applies)
#
# Which approved additional features have been implemented?
# (See the project handout for the list of additional features)
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# 3. (fill in the feature, if any)
# ... (add more if necessary)
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################

.data
    # Display
    displayAddress:	 .word 0x10008000
    screenHeight: .word 21          # Screen height in "unit"s
    screenWeight: .word 21          # Screen width in "unit"s
    screenLinePixels: .word 256     # Number of pixels in a line of screen

    # Colors
    backgroundColor: .word 0x00000000
    centipedeColor: .word 0x00ff0000

    # Objects
    centipedeLocations: .word 0, 1, 2, 3, 4, 5, 6, 7, 8, 9

.globl main
.text


##############################################
# # Initialization
##############################################
# # Saved register allocations:
# # $s7: display address
##############################################

main:
    lw			$s7, displayAddress			# 
    

##############################################
# # Game Loop
##############################################

game_loop_main:
    # Do something
    addi		$a0, $zero, 0			# $a0 = $zero + 0
    
    jal			draw_centipede_segment				# jump to draw_centipede_segment and save position to $ra

    jal			sleep				# jump to sleep and save position to $ra
    
    j			game_loop_main				# jump to game_loop_main


############################################################################################
	
program_exit:
	li $v0, 10 # terminate the program gracefully
	syscall

############################################################################################

##############################################
# # Graphics
##############################################

# FUN draw_centipede_segment
# ARGS:
# $a0: Location of centipede. Should be a number from 0 to screenWidth.
draw_centipede_segment:
    addi		$sp, $sp, -20			# $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    addi		$t2, $a0, 0			    # Load location to draw centipede to $t2
    lw			$t0, centipedeColor		# $t0 = centipedeColor
    lw			$t1, screenLinePixels	# $t1 = screenLinePixels
    
    # Calculate actual display address
    sll			$t2, $t2, 2			    # $t2 = $t2 * 4, calculate offset
    add			$t2, $t2, $s7		    # $t2 = $t2 + $s7 (display address)
    
    # Draw a segment of centipede (3x3 block)
    # First line
    sw			$t0, 0($t2)
    sw			$t0, 4($t2)
    sw			$t0, 8($t2)
    
    # Second line
    add		    $t2, $t2, $t1			# $t2 = $t2 + $t1, goes to the next line at this location
    sw			$t0, 0($t2)
    sw			$t0, 4($t2)
    sw			$t0, 8($t2)

    # Third line
    add		    $t2, $t2, $t1			# $t2 = $t2 + $t1, goes to the next line at this location
    sw			$t0, 0($t2)
    sw			$t0, 4($t2)
    sw			$t0, 8($t2)

    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			# $sp += 20

    move 		$v0, $zero			    # $v0 = $zero
    jr			$ra					    # jump to $ra

# END FUN draw_centipede_segment


##############################################
# # Utilities
##############################################

# FUN sleep
sleep:
    addi		$sp, $sp, -20			# $sp -= 20
    sw			$ra, 0($sp)

    li			$v0, 32				# $v0 = 32
    li			$a0, 50				# $a0 = 50
    syscall

    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			# $sp += 20

    move 		$v0, $zero			# $v0 = $zero
    jr			$ra					# jump to $ra

# END FUN sleep

