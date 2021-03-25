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
    screenWidth: .word 21          # Screen width in "unit"s
    unitWidth: .word 12             # Width of "unit"
    screenLinePixels: .word 256     # Width of pixels in a line of screen
    screenLineUnusedPixels: .word 4 # Width of pixels per line that is unused

    # Colors
    backgroundColor: .word 0x00000000
    centipedeColor: .word 0x00ff0000
    blasterColor: .word 0x00ffffff

    # Objects
    centipedeLocations: .word 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
    centipedeLength: .word 10
    blasterLocation: .word 1060

    sampleString: .asciiz "a"

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
    la			$a1, centipedeLocations		# 
    lw			$a2, centipedeLength		# 
    jal			draw_centipede				# jump to draw_centipede and save position to $ra
    lw			$a0, blasterLocation		# 
    jal			draw_blaster				# jump to draw_blaster and save position to $ra
    
    jal			sleep				        # jump to sleep and save position to $ra
    
    j			game_loop_main				# jump to game_loop_main


############################################################################################

program_exit:
	li $v0, 10 # terminate the program gracefully
	syscall

############################################################################################

##############################################
# # Graphics
##############################################

# FUN draw_centipede
# ARGS:
# $a1: Address of locations of centipede segments
# $a2: Length of centipede array
draw_centipede:
    addi		$sp, $sp, -4			# $sp -= 4
    sw			$ra, 0($sp)		

    draw_centipede_loop:
        lw			$a0, 0($a1)			                # Load current segment to draw

        jal			draw_centipede_segment	            # jump to draw_centipede_segment and save position to $ra
        
        addi 		$a1, $a1, 4			                # Increment index to next element
        addi		$a2, $a2, -1			            # Decrement loop counter
        bgt			$a2, $zero, draw_centipede_loop	    # if $a2 > $zero then draw_centipede_loop
        
    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 4			# $sp += 4

    move 		$v0, $zero			# $v0 = $zero
    jr			$ra					# jump to $ra

# END FUN draw_centipede

# FUN draw_centipede_segment
# ARGS:
# $a0: Location of centipede. Should be a number from 0 to screenWidth.
draw_centipede_segment:
    addi		$sp, $sp, -4			# $sp -= 4
    sw			$ra, 0($sp)

    addi		$t2, $a0, 0			    # Load location to draw centipede to $t2
    
    move 		$a0, $t2			    # $a0 = $t2
    jal			calc_display_address	# jump to calc_display_address and save position to $ra
    move 		$t2, $v0			# $t2 = $v0
    
    lw			$t0, centipedeColor		# $t0 = centipedeColor
    lw			$t1, screenLinePixels	# $t1 = screenLinePixels
    lw			$t4, screenLineUnusedPixels

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

    lw			$ra, 0($sp)
    addi		$sp, $sp, 4 			# $sp += 4

    move 		$v0, $zero			    # $v0 = $zero
    jr			$ra					    # jump to $ra

# END FUN draw_centipede_segment

# FUN draw_blaster
# ARGS:
# $a0: location of bug blaster
draw_blaster:
    addi		$sp, $sp, -4			# $sp -= 4
    sw			$ra, 0($sp)

    addi		$t2, $a0, 0			    # Load location to draw blaster to $t2

    move 		$a0, $t2			    # $a0 = $t2
    jal			calc_display_address	# jump to calc_display_address and save position to $ra
    move 		$t2, $v0			    # $t2 = $v0

    lw			$t0, blasterColor		# $t0 = blasterColor
    lw			$t1, screenLinePixels	# $t1 = screenLinePixels
    lw			$t9, backgroundColor	# $t9 = backgroundColor

    # Draw bug blaster
    # First line
    sw			$t9, 0($t2)
    sw			$t0, 4($t2)
    sw			$t9, 8($t2)

    # Second line
    add 		$t2, $t2, $t1			# $t2 = $t2 + $t1, goes to the next line at this location
    sw			$t0, 0($t2)
    sw			$t0, 4($t2)
    sw			$t0, 8($t2)

    # Third line
    add 		$t2, $t2, $t1			# $t2 = $t2 + $t1, goes to the next line at this location
    sw			$t0, 0($t2)
    sw			$t9, 4($t2)
    sw			$t0, 8($t2)

    lw			$ra, 0($sp)
    addi		$sp, $sp, 4			    # $sp += 4

    move 		$v0, $zero			    # $v0 = $zero
    jr			$ra					    # jump to $ra

# END FUN draw_blaster


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

# FUN calc_display_address
# ARGS:
# $a0: position
# RETURN $v0: display address to be used
calc_display_address:
    addi		$sp, $sp, -4			# $sp -= 4
    sw			$ra, 0($sp)

    move 		$t2, $a0			# $t2 = $a0
    lw			$t1, screenWidth			
    lw			$t4, screenLineUnusedPixels 

    # Calculate actual display address
    # Multiply $t2 by unit width
    lw			$t3, unitWidth			# Load width per "unit" to $t3
    mult	    $t2, $t3			    # $t2 * $t3 (unit width) = Hi and Lo registers
    mflo	    $t2					    # copy Lo to $t2

    # Since we do not use "screenLineUnusedPixels" pixels per line, 
    # we need to account for these values in for accurate positioning.
    
    # Account for the last position
    # There is 1 pixel unused in the end. I hard coded this for now.
    # Change this line when unused pixels per line changes.
    addi 		$t6, $a0, 1		    	# $t6 = $a0 + 1

    # $t5 stores the number of previous lines that we should account for
    div			$t6, $t1			    # $t6 / $t1
    mflo	    $t5					    # $t5 = floor($t2 / $t1)
    
    # We will therefore add $t5 * $t4 (unused pixels for every line) to $t2.
    mult	    $t5, $t4			    # $t5 * $t4 = Hi and Lo registers
    mflo	    $t5					    # copy Lo to $t5
    add			$t2, $t2, $t5		    # $t2 = $t2 + $t5

    add			$t2, $t2, $s7		    # $t2 = $t2 + $s7 (display address)

    lw			$ra, 0($sp)
    addi		$sp, $sp, 4			    # $sp += 4

    move 		$v0, $t2			    # $v0 = $t2
    jr			$ra					    # jump to $ra

# END FUN calc_display_address
