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
    screenPixelUnits: .word 21      # Screen width and height in "unit"s
    unitWidth: .word 12             # Width of "unit"
    screenLineWidth: .word 256      # Width of pixels in a line of screen
    screenLineUnusedWidth: .word 4  # Width of pixels per line that is unused

    # Colors
    backgroundColor: .word 0x00000000
    centipedeColor: .word 0x00f7a634
    centipedeHeadColor: .word 0x00e09b3a
    blasterColor: .word 0x00ffffff

    # Objects
    centipedeLocations: .word 0, 1, 2, 3, -1, 5, 6, 7, 8, 9
    centipedeLocationEmpty: .word -1     # Location value to indicate a "dead" centipede segment
    centipedeDirections: .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1     # 1: goes right, -1: goes left
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
	li $v0, 10                              # terminate the program gracefully
	syscall

############################################################################################

##############################################
# # Logics
##############################################
# FUN move_centipede
# - Given the current state of centipede, calculate the next
# - state and store the info back to the arrays.
# ARGS:
# $a0: Address of array representing centipede locations.
# $a1: Address of array representing centipede directions.
# $a2: Length of centipede.
move_centipede:
    addi		$sp, $sp, -20			# $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    # Move arguments to saved registers
    move 		$s0, $a0			                # $s0 = $a0
    move 		$s1, $a1			                # $s1 = $a1
    move 		$s2, $a2			                # $s2 = $a2

    move_centipede_loop:
        lw			$a0, 0($s0)			            # load current centipede location
        lw			$a3, 0($s1)			            # load current centipede direction
        
        jal			move_centipede_segment			# jump to move_centipede_segment and save position to $ra
        
        addi		$s2, $s2, -1			        # decrement loop counter
        addi		$s0, $s0, 4			            # increment to next centipede segment location
        addi		$s1, $s1, 4			            # increment to next centipede segment direction
        
        bne			$s2, $zero, move_centipede_loop	# if $s2 != $zero then move_centipede_loop
    
    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			# $sp += 20

    move 		$v0, $zero			# $v0 = $zero
    jr			$ra					# jump to $ra

# END FUN move_centipede
# FUN move_centipede_segment
# ARGS:
# $a0: Current location of the centipede.
# $a3: Current direction. Has to be 1 or -1, where 1 indicates going to the right and -1 indicates
#      going to the left.
# RETURN:
# $v0: Next location
# $v1: Next direction
move_centipede_segment:
    addi		$sp, $sp, -20			            # $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    # If location is empty, then do not do anything
    lw			$t5, centipedeLocationEmpty			# $t5 = centipedeLocationEmpty
    beq			$a0, $t5, end_mcs	                # if $a0 == $t5 then end_mcs
    
    # Main idea: continue the current direction if "turning conditions" are not met

    lw			$t0, screenPixelUnits
    subi		$t1, $t0, 1		                    # $t1 = $t0 - 1, the column number for the edge	
    
    # --- Identify if the centipede is about to hit the border
    # Check the column # at which the centipede segment is currently located
    div			$a0, $t0			                # $a0 / $t0
    mfhi	    $t3					                # $t3 = $a0 mod $t0, stores the current column num.

    # Load definitions
    addi		$s0, $zero, 1			            # $s0 = 1, the right direction indicator
    addi		$s1, $zero, -1			            # $s1 = -1, the left direction indicator
    
    beq			$a3, $s0, mcs_goes_right	        # if $a3 == $s0 then mcs_goes_right
    mcs_goes_left:
    bne			$t3, $zero, mcs_direction_end_if    # if $t3 != $zero then mcs_direction_end_if

    # If the column number is 0, then the next location is to the bottom of the current cell
    # and the direction should change to 1 (i.e., goes to right).
    addi		$v0, $a0, $t0			            # $v0 = $a0 + $t0, the next location
    move 		$v1, $s0			                # $v1 = $s1, set next direction to right
    
    j			end_mcs	    # jump to mcs_direction_end_if
    mcs_goes_right:
    bne			$t3, $t1, msc_direction_end_if	    # if $t3 != $t1 then msc_direction_end_if
    
    # If the column number corresponds to the right edge, then the next location is to the bottom of the current
    # cell and the direction should change to -1 (i.e., goes to left).
    addi		$v0, $a0, $t0			            # $v0 = $a0 + $t0, the next location
    move 		$v1, $s1			                # $v1 = $s1, set next direction to left
    
    j			end_mcs				                # jump to end_mcs
    mcs_direction_end_if:
    
    # --- END Identify if the centipede is about to hit the border

    # TODO Identify if the centipede is about to hit a mushroom

    # --- END Identify if the centipede is about to hit a mushroom

    # If none of the above turning conditions are met
    end_turning_condition_checks:
    # Continue moving along the original direction
    addi		$v0, $a0, $a3			            # $v0 = $a0 + $a3
    move 		$v1, $a3			                # $v1 = $a3

    end_mcs:

    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			            # $sp += 20

    move 		$v0, $zero			                # $v0 = $zero
    jr			$ra					                # jump to $ra

# END FUN move_centipede_segment

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
        lw			$a0, 0($a1)			                # load current segment to draw
        addi		$a2, $a2, -1			            # decrement loop counter

        # If the centipede segment is marked "dead", then skip draw
        lw			$t0, centipedeLocationEmpty     	# $t0 = centipedeLocationEmpty
        beq			$a0, $t0, dc_skip_draw_segment	    # if $a0 == $t0 then dc_skip_draw_segment
        
        # Color the head of centipede with a different color
        beq			$a2, $zero, dc_load_head_color	    # if we reach the end of array, then this is a head
        lw			$t1, 4($a1)			                # load the next element in the location array
        beq			$t1, $t0, dc_load_head_color	    # if the next segment is marked "dead", then this is a head
        
        dc_load_segment_color:
        lw			$a3, centipedeColor			        # load regular centipede segment color
        j			dc_end_load_color				    # jump to dc_end_load_color
        
        dc_load_head_color:
        lw			$a3, centipedeHeadColor			    # load head color for centipede segment
        
        dc_end_load_color:
        jal			draw_centipede_segment	            # jump to draw_centipede_segment and save position to $ra
        
        dc_skip_draw_segment:

        addi 		$a1, $a1, 4			                # increment index to next element
        bgt			$a2, $zero, draw_centipede_loop	    # if $a2 > $zero then draw_centipede_loop
        
    lw			$ra, 0($sp)
    addi		$sp, $sp, 4			# $sp += 4

    move 		$v0, $zero			# $v0 = $zero
    jr			$ra					# jump to $ra

# END FUN draw_centipede

# FUN draw_centipede_segment
# ARGS:
# $a0: Location of centipede. Should be a number from 0 to screenPixelUnits.
# $a3: Color of this segment
draw_centipede_segment:
    addi		$sp, $sp, -4			    # $sp -= 4
    sw			$ra, 0($sp)
    
    jal			calc_display_address	    # jump to calc_display_address and save position to $ra
    move 		$t2, $v0			        # $t2 = $v0
    
    move 		$t0, $a3			        # $t0 = $a3
    lw			$t1, screenLineWidth	    # $t1 = screenLineWidth
    lw			$t4, screenLineUnusedWidth  # $t4 = screenLineUnusedWidth

    # Draw a segment of centipede (3x3 block)
    # First line
    sw			$t0, 0($t2)
    sw			$t0, 4($t2)
    sw			$t0, 8($t2)
    
    # Second line
    add		    $t2, $t2, $t1			    # $t2 = $t2 + $t1, goes to the next line at this location
    sw			$t0, 0($t2)
    sw			$t0, 4($t2)
    sw			$t0, 8($t2)

    # Third line
    add		    $t2, $t2, $t1			    # $t2 = $t2 + $t1, goes to the next line at this location
    sw			$t0, 0($t2)
    sw			$t0, 4($t2)
    sw			$t0, 8($t2)

    lw			$ra, 0($sp)
    addi		$sp, $sp, 4 			    # $sp += 4

    move 		$v0, $zero			        # $v0 = $zero
    jr			$ra					        # jump to $ra

# END FUN draw_centipede_segment

# FUN draw_blaster
# ARGS:
# $a0: location of bug blaster
draw_blaster:
    addi		$sp, $sp, -4			# $sp -= 4
    sw			$ra, 0($sp)

    addi		$t2, $a0, 0			    # load location to draw blaster to $t2

    move 		$a0, $t2			    # $a0 = $t2
    jal			calc_display_address	# jump to calc_display_address and save position to $ra
    move 		$t2, $v0			    # $t2 = $v0

    lw			$t0, blasterColor		# $t0 = blasterColor
    lw			$t1, screenLineWidth	# $t1 = screenLineWidth
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
    addi		$sp, $sp, -4		# $sp -= 4
    sw			$ra, 0($sp)

    move 		$t2, $a0			# $t2 = $a0
    lw			$t1, screenPixelUnits			
    lw			$t4, screenLineUnusedWidth 

    # Calculate actual display address
    # Multiply $t2 by unit width
    lw			$t3, unitWidth			# Load width per "unit" to $t3
    mult	    $t2, $t3			    # $t2 * $t3 (unit width) = Hi and Lo registers
    mflo	    $t2					    # copy Lo to $t2

    # Since we do not use "screenLineUnusedWidth" pixels per line, 
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
