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
    framesPerSecond: .word 60       # Number of frames per second (Note: 1000 / framesPerSecond should be an int)

    # --- Colors
    backgroundColor: .word 0x00000000
    centipedeColor: .word 0x00f7a634
    centipedeHeadColor: .word 0x00e09b3a
    mushroomFullLivesColor: .word 0x004394f0
    mushroomColor: .word 0x0076c0d6
    blasterColor: .word 0x00ffffff
    dartColor: .word 0x00ffffff

    gameOverTextColor: .word 0x00fc037f
    winTextColor: .word 0x0010e858
    # --- END Colors

    # --- Objects
    # Centipede
    centipedeLocations: .word 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
    centipedeLocationEmpty: .word -1     # Location value to indicate a "dead" centipede segment
    centipedeDirections: .word 1:10      # 1: goes right, -1: goes left
    centipedeLength: .word 10
    centipedeFramesPerMove: .word 1      # Number of frames per movement of the centipede

    # Mushrooms
    mushrooms: .word 0:399               # Mushrooms will only exist in the first 19 rows (19 * 21)
    mushroomLength: .word 399
    mushroomLives: .word 4               # Number of times that a mushroom needs to be blasted before going away
    mushroomInitQuantity: .word 15       # Initial number of mushrooms to be generated on the screen (maximum)

    # Bug blaster + darts
    blasterLocation: .word 410           # Initial location of the bug blaster in object grid
    darts: .word -1:10                   # Array of dart locations where -1 means empty
    dartLength: .word 10                 # Length of the darts array (maximum number of darts that can be present on the screen)
    dartFramesPerMove: .word 1           # Number of frames per movement of the darts
    # --- END Objects

    # Personal Space for Bug Blaster
    personalSpaceStart: .word 357        # Start position of bug blaster's personal space
    personalSpaceEnd: .word 420          # End position of bug blaster's personal space
    personalSpaceLastVerticalMovement: .word 1   # 1: down, -1: up. Should not be modified, used to calculate personal space centipede movement

    # Texts On Screen
    gameOverTextLocations: .word 128, 129, 130, 131, 149, 170, 191, 212, 213, 214, 215, 233, 254, 275, 296, 297, 298, 299, 134, 138, 155, 156, 159, 176, 177, 180, 197, 198, 199, 201, 218, 220, 222, 239, 241, 242, 243, 260, 263, 264, 281, 284, 285, 302, 306, 141, 142, 143, 162, 164, 165, 183, 186, 204, 208, 225, 229, 246, 250, 267, 270, 288, 290, 291, 309, 310, 311
    gameOverTextLength: .word 67

    # Strings for logging
    newline: .asciiz "\n"
    sampleString: .asciiz "Sample String\n"

.globl main
.text

##############################################
# # Initialization
##############################################
# # Saved register allocations:
# # $s0: current frame id (only in game loop and main)
# # $s6: keyboard pressing indicator for this frame
# # $s7: display address
##############################################

main:
    # Load values
    lw			$s7, displayAddress			        #
    
    # Initialize mushrooms
    lw			$a0, mushroomInitQuantity			# Number of mushrooms to generate
    lw			$a1, mushroomLives			        # Number of "lives" per mushroom
    jal			generate_mushrooms				    # jump to generate_mushrooms and save position to $ra

##############################################
# # Game Loop
##############################################

reset_frame:
    # Frame id definition: 
    # - It is a number ranging from 1 to framesPerSecond
    # - It decrements from framesPerSecond to 1
    # - It decreases by 1 each time a frame is completed
    lw			$s0, framesPerSecond		# 
    j			game_loop_main				# jump to game_loop_main

game_loop_main:
    # Load values
    lw          $s6, 0xffff0000                 # load key-press indicator

    # Mushrooms
    la 		    $a0, mushrooms			        # $a0 = mushrooms
    lw			$a1, mushroomLength			    # 
    jal			draw_mushrooms				    # jump to draw_mushrooms and save position to $ra

    # Centipede
    move 		$a0, $s0			            # $a0 = $s0
    jal			control_centipede			    # jump to control_centipede and save position to $ra

    # Bug blaster
    jal			control_blaster				    # jump to control_blaster and save position to $ra

    # Darts
    move 		$a0, $s0			            # $a0 = $s0
    jal			control_darts				    # jump to control_darts and save position to $ra

    # Game rule
    jal			enforce_game_rules				# jump to enforce_game_rules and save position to $ra
    
    # Frame control
    jal			sleep				            # jump to sleep and save position to $ra
    subi		$s0, $s0, 1			            # $s0 = $s0 - 1
    beq			$s0, $zero, reset_frame	        # if $s0 == $zero then reset_frame
    
    j			game_loop_main				    # jump to game_loop_main

############################################################################################

program_exit:
	li $v0, 10                              # terminate the program gracefully
	syscall

############################################################################################

##############################################
# # Game Rules
##############################################

# FUN enforce_game_rules
# - This function should be ran for every cycle of the main game loop.
# - This function checks the current state of the game and mutate objects based on
# - the game rules.
# ARGS:
# RETURN $v0: 0
enforce_game_rules:
    addi		$sp, $sp, -20			            # $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    jal			detect_centipede_dart_collision		# jump to detect_centipede_dart_collision and save position to $ra
    
    jal			detect_mushroom_dart_collision	    # jump to detect_mushroom_dart_collision and save position to $ra

    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			            # $sp += 20

    move 		$v0, $zero			                # $v0 = $zero
    jr			$ra					                # jump to $ra

# END FUN enforce_game_rules

# FUN game_over
# ARGS:
game_over:
    addi		$sp, $sp, -20			# $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    

    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			# $sp += 20

    move 		$v0, $zero			# $v0 = $zero
    jr			$ra					# jump to $ra

# END FUN game_over

##############################################
# # Collision Detection
##############################################
# FUN detect_centipede_dart_collision
# - Detect and respond to collision event of the centipede with a dart.
# - This function IS INTENDED TO mutate static data if appropriate.
# ARGS:
detect_centipede_dart_collision:
    addi		$sp, $sp, -20			        # $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    li			$s0, 0				            # loop counter, correspond to index in darts array
    la			$s1, darts			            # $s1 = darts
    dcdc_loop:
        # Load current dart
        lw			$t3, 0($s1)		                    # 

        # If the current dart is empty, continue to next
        beq			$t3, -1, dcdc_loop_continue	        # if $t3 == -1 then dmdc_loop_continue

        # Convert location to object grid
        # Post-condition: $t3 = dart location in object grid
        move 		$a0, $t3			                # $a0 = $t3
        jal			display_to_object_grid_location		# jump to display_to_object_grid_location and save position to $ra
        move 		$t3, $v0			                # $t3 = $v0

        # Check if dart hits a centipede segment
        la			$t6, centipedeLocations			    #
        lw			$t8, centipedeLength			    # 
        li			$t9, 0				                # loop counter
        
        dcdc_centipede_loop:
            lw			$t0, 0($t6)			                        # load a centipede segment location
            beq			$t0, $t3, dcdc_handle_centipede_collision	# if $t0 == $t3 then dcdc_handle_centipede_collision
            addi		$t6, $t6, 4			                        # $t6 = $t6 + 4
            addi		$t9, $t9, 1			                        # $t9 = $t9 + 1
            blt			$t9, $t8, dcdc_centipede_loop	            # if $t9 < $t8 then dcdc_centipede_loop

        j			dcdc_loop_continue				    # jump to dcdc_loop_continue
        
        dcdc_handle_centipede_collision:
        # $t6 stores the pointer to the centipede segment involved in the collision
        # $t3 stores the location of dart involved in the collision

        # Remove centipede segment and dart
        lw			$t0, centipedeLocationEmpty			# $t0 = centipedeLocationEmpty
        sw			$t0, 0($t6)			                # save empty centipede location
        li			$t0, -1				                # $t0 = -1
        sw			$t0, 0($s1)			                # save empty dart location
        
        # --- Add mushroom at location if possible
        # Do not add mushroom if we are outside of mushroom area
        lw			$t1, mushroomLength			        # 
        bge			$t3, $t1, dcdc_personal_space	    # if $t3 >= $t1 then dcdc_personal_space
        # Otherwise, add mushroom
        li			$t0, 4				                # $t0 = 4
        mult	    $t3, $t0			                # $t3 * $t0 = Hi and Lo registers
        mflo	    $t0					                # copy Lo to $t0
        lw			$t1, mushroomLives			        # $t1 = mushroomLives
        sw			$t1, mushrooms($t0)			        # add mushroom at the collision location
        j			dcdc_add_mushroom_end				# jump to dcdc_add_mushroom_end

        dcdc_personal_space:
        # Since a new mushroom would not be formed in personal space
        # and rendering optimization is in place,
        # we need to manually remove the drawings in collision position
        move 		$a0, $t3			                # $a0 = $t3
        jal			fill_background_at_location		    # jump to fill_background_at_location and save position to $ra

        dcdc_add_mushroom_end:
        # --- END Add mushroom at location if possible
        
        # Increment loop counter and go to next
        dcdc_loop_continue:
        addi		$s0, $s0, 1			                # increment loop counter
        addi		$s1, $s1, 4			                # $s1 = $s1 + 4
        lw			$t5, dartLength			            # $t5 = dartLength
        blt			$s0, $t5, dcdc_loop	                # if $s0 < $s1 then dcdc_loop

    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			        # $sp += 20

    move 		$v0, $zero			            # $v0 = $zero
    jr			$ra					            # jump to $ra

# END FUN detect_centipede_dart_collision

# FUN detect_mushroom_dart_collision
# - Detect and respond to collision event of a mushroom with a dart.
# - This function IS INTENDED TO mutate static data if appropriate.
# ARGS:
detect_mushroom_dart_collision:
    addi		$sp, $sp, -20			    # $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    li 		    $s0, 0			            # loop counter, correspond to index in darts array
    la			$s1, darts			        # $s1 = address of darts
    dmdc_loop:
        lw			$t3, 0($s1)			                # load current dart

        # If the current dart is empty, continue to next
        beq			$t3, -1, dmdc_loop_continue	        # if $t3 == -1 then dmdc_loop_continue
        
        # Convert location to object grid
        # Post-condition: $t3 = dart location in object grid
        move 		$a0, $t3			                # $a0 = $t3
        jal			display_to_object_grid_location		# jump to display_to_object_grid_location and save position to $ra
        move 		$t3, $v0			                # $t3 = $v0

        # If the current dart outside of the mushroom area, skip
        lw			$t1, mushroomLength 			    # 
        bge			$t3, $t1, dmdc_loop_continue	    # if $t3 >= $t1 then dmdc_loop_continue

        # Set $t9 to array accessing index
        # Post-condition: $t9 = $s2 * 4
        li		    $t9, 4			                    # $t9 = 4
        mult	    $t3, $t9			                # $t3 * $t9 = Hi and Lo registers
        mflo	    $t9					                # copy Lo to $t9

        # Check if a mushroom exists in this location
        lw			$t0, mushrooms($t9)		            # 

        # If a mushroom exists at location, respond to collision event
        # Otherwise, continue to the next dart
        beq			$t0, $zero, dmdc_loop_continue	    # if $t0 == $zero then dmdc_loop_continue
        # --- Respond to collision

        # Subtract "lives" from the targeted mushroom
        subi		$t0, $t0, 1			                # record mushroom being shot once
        sw			$t0, mushrooms($t9)			        # save back record

        # Due to rendering optimization, mushrooms with a 0 live will be skipped
        # when painting the screen on the next game loop iteration. Therefore, here
        # we explitcitly check for it to correctly remove the target mushroom.
        beq			$t0, $zero, dmdc_remove_mushroom	# if $t0 == $zero then dmdc_remove_mushroom
        j			dmdc_remove_mushroom_end			# jump to dmdc_remove_mushroom_end
        
        dmdc_remove_mushroom:
        move 		$a0, $t3			                # $a0 = $t3 (dart object-grid location)
        jal			fill_background_at_location			# jump to fill_background_at_location and save position to $ra

        dmdc_remove_mushroom_end:
        # Remove dart
        li			$t1, -1				                # $t1 = -1
        sw			$t1, 0($s1)			            # save empty dart
        # --- END Respond to collision

        # Increment loop counter and go to next
        dmdc_loop_continue:
        addi		$s0, $s0, 1			                # increment loop counter
        addi		$s1, $s1, 4			                # $s1 = $s1 + 4
        lw			$t5, dartLength			            # 
        blt			$s0, $t5, dmdc_loop	                # if $s0 < $t5 then dmdc_loop

    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			    # $sp += 20

    move 		$v0, $zero			        # $v0 = $zero
    jr			$ra					        # jump to $ra

# END FUN detect_mushroom_dart_collision

##############################################
# # Controllers
##############################################
# FUN control_centipede
# ARGS:
# $a0: current frame number. 
#      e.g., if we have 20 frames per second, this should be a number between 0 and 19.
control_centipede:
    addi		$sp, $sp, -20			            # $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    # Load constants
    lw			$s0, centipedeFramesPerMove		    # 
    
    # Check if centipede should move
    div			$a0, $s0			                # $a0 / $s0
    mfhi	    $t3					                # $t3 = $a0 mod $s0
    bne			$t3, $zero, end_control_centipede	# if $t3 != $zero then end_control_centipede
    
    # --- Move and redraw centipede
    # Load constants
    la			$s0, centipedeLocations		        # 
    la		    $s1, centipedeDirections		    # 
    lw			$s2, centipedeLength		        #

    # Clear current centipede
    addi		$a0, $zero, 1			            # $a0 = 1, indicates clear centipede
    move 		$a1, $s0			                # $a1 = $s0
    move 		$a2, $s2			                # $a2 = $s2
    jal			draw_centipede				        # jump to draw_centipede and save position to $ra
    
    # Calculate the next centipede state
    move 		$a0, $s0			                # $a0 = $s0
    move 		$a1, $s1			                # $a1 = $s1
    move 		$a2, $s2			                # $a2 = $s2
    jal			move_centipede				        # jump to move_centipede and save position to $ra
    
    # Draw new centipede
    move 		$a0, $zero			                # $a0 = $zero
    move 		$a1, $s0			                # $a1 = $s0
    move 		$a2, $s2			                # $a2 = $s2
    jal			draw_centipede				        # jump to draw_centipede and save position to $ra
    
    # --- END Move and redraw centipede

    end_control_centipede:
    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			# $sp += 20

    move 		$v0, $zero			    # $v0 = $zero
    jr			$ra					    # jump to $ra

# END FUN control_centipede

# FUN control_blaster
control_blaster:
    addi		$sp, $sp, -20			            # $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    lw			$s0, blasterLocation			    # load current bug blaster location

    # Remove bug blaster from the old location
    move 		$a0, $s0			                # $a0 = $s0
    jal			fill_background_at_location			# jump to fill_background_at_location and save position to $ra

    # Calculate the next state of the bug blaster
    move 		$a0, $s0			                # $a0 = $s0
    jal			move_blaster_by_keystroke		    # jump to move_blaster_by_keystroke and save position to $ra
    sw			$v0, blasterLocation			    # save new bug blaster location
    
    # Draw bug blaster at the new location
    move 		$a0, $v0			                # $a0 = $v0
    jal			draw_blaster				        # jump to draw_blaster and save position to $ra

    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			            # $sp += 20

    move 		$v0, $zero			                # $v0 = $zero
    jr			$ra					                # jump to $ra

# END FUN control_blaster

# FUN control_darts
# ARGS:
# $a0: current frame number
control_darts:
    addi		$sp, $sp, -20			# $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    # Load parameters
    move 		$s0, $a0			                # $s0 = current frame number

    # Clear old darts on the screen
    la			$a0, darts			                # $a0 = address of darts
    lw			$a1, dartLength			            # $a1 = dartLength
    lw			$a2, backgroundColor			    # $a2 = backgroundColor
    jal			draw_darts				            # jump to draw_darts and save position to $ra

    # --- Determine if dart should move
    lw			$s1, dartFramesPerMove  		    # $s1 = dartFramesPerMove
    div			$s0, $s1			                # $s0 / $s1
    mfhi	    $t3					                # $t3 = $a0 mod $s1
    bne			$t3, $zero, end_darts_movement	    # if $t3 != $zero then end_darts_movement
    # --- END Determine if dart should move
    
    # Move darts
    la			$a0, darts			                # $a0 = address of darts
    lw			$a1, dartLength			            # $a1 = dartLength
    jal			move_darts				            # jump to move_darts and save position to $ra

    end_darts_movement:
    # Check for keystroke and add a new dart if appropriate
    la		    $a0, darts		                        # 
    lw		    $a1, dartLength		                    # 
    lw			$a2, blasterLocation    			    # 
    jal			shoot_dart_by_keystroke				    # jump to shoot_dart_by_keystroke and save position to $ra

    # Draw new darts
    la			$a0, darts			                # $a0 = address of darts
    lw			$a1, dartLength			            # $a1 = dartLength
    lw			$a2, dartColor      			    # $a2 = dartColor
    jal			draw_darts				            # jump to draw_darts and save position to $ra

    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			# $sp += 20

    move 		$v0, $zero			# $v0 = $zero
    jr			$ra					# jump to $ra

# END FUN control_darts

##############################################
# # Object Movement Logic
##############################################
# FUN move_blaster_by_keystroke
# - "j": move left
# - "k": move right
# - "w": move up
# - "s": move down
# ARGS:
# $a0: current blaster location (object grid)
# RETURN $v0: new location of blaster
move_blaster_by_keystroke:
    addi		$sp, $sp, -20			    # $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    # Load parameters
    move 		$s0, $a0			        # $s0 = current blaster location
    lw			$s1, screenPixelUnits		# $s1 = screenPixelUnits

    # Check if key is pressed
    move        $t9, $s6                    # load key-press indicator
    move 		$v0, $s0			        # $v0 = current blaster location, default return
	bne         $t9, 1, mbbk_end            # if key is not pressed, end the function

    # Obtain current coordinate
    move 		$a0, $s0			        # $a0 = current blaster location
    jal			calc_coordinate				# jump to calc_coordinate and save position to $ra
    move 		$s2, $v0			        # $s2 = current row
    move 		$s3, $v1			        # $s3 = current col

    # Check type of key being pressed
    lw			$t9, 0xffff0004			    # load key identifier
    beq			$t9, 0x6A, mbbk_handle_j	# if $t9 == 0x6A then mbbk_handle_j
    beq			$t9, 0x6B, mbbk_handle_k	# if $t9 == 0x6B then mbbk_handle_k
    beq			$t9, 0x77, mbbk_handle_w	# if $t9 == 0x57 then mbbk_handle_w
    beq			$t9, 0x73, mbbk_handle_s	# if $t9 == 0x53 then mbbk_handle_s

    # Produce default return
    mbbk_default_return:
    move 		$v0, $s0			        # $v0 = current blaster location, default return
    j			mbbk_key_handle_end			# jump to mbbk_key_handle_end

    # --- Handle movement keys
    mbbk_handle_j:
        # Prevent bug blaster from exiting the left border
        beq			$s3, $zero, mbbk_default_return	# if $s3 == $zero then mbbk_default_return
        subi		$v0, $s0, 1			            # $v0 = $s0 - 1
        mbbk_handle_j_end:
        j			mbbk_key_handle_end		        # jump to mbbk_key_handle_end
    mbbk_handle_k:
        # Prevent bug blaster from exiting the right border
        subi		$t0, $s1, 1			            # $t0 = $s1 - 1
        beq			$s3, $t0, mbbk_default_return	# if $s3 == $t0 then mbbk_default_return
        addi		$v0, $s0, 1			            # $v0 = $s0 + 1
        mbbk_handle_k_end:
        j			mbbk_key_handle_end		        # jump to mbbk_key_handle_end
    mbbk_handle_w:
        # Prevent bug blaster from leaving personal space
        lw			$t0, personalSpaceStart			# $t0 = personalSpaceStart
        sub		    $v0, $s0, $s1			        # $v0 = $s0 - $s1
        bge			$v0, $t0, mbbk_handle_w_end 	# if currently in personal space

        mbbk_left_personal_space_w:
        move 		$v0, $s0			            # revert location

        mbbk_handle_w_end:
        j			mbbk_key_handle_end		        # jump to mbbk_key_handle_end
    mbbk_handle_s:
        lw			$t0, personalSpaceEnd			# $t0 = personalSpaceEnd
        add			$v0, $s0, $s1		            # $v0 = $s0 + $s1
        bgt			$t0, $v0, mbbk_handle_s_end 	# if currently in personal space

        mbbk_left_personal_space_s:
        move 		$v0, $s0			            # revert location

        mbbk_handle_s_end:
        j			mbbk_key_handle_end		        # jump to mbbk_key_handle_end
    mbbk_key_handle_end:
    # --- END Handle movement keys

    mbbk_end:
    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			    # $sp += 20

    jr			$ra					        # jump to $ra

# END FUN move_blaster_by_keystroke

# FUN shoot_dart_by_keystroke
# - Modify the darts array by adding a dart with appropriate position (in display grid) to it.
# - If the maximum allowed number of darts is achieved, then do nothing.
# ARGS:
# $a0: address of the darts array
# $a1: length of darts array
# $a2: bug blaster location (object grid)
shoot_dart_by_keystroke:
    addi		$sp, $sp, -20			    # $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    # Move parameters
    move 		$s0, $a0			                # $s0 = address of the darts array
    move 		$s1, $a1			                # $s1 = length of the darts array
    move 		$s2, $a2			                # $s2 = location of the bug blaster (object grid)
    lw			$s3, screenPixelUnits			    # $s3 = screenPixelUnits

    # Convert object grid location to display grid location
    move 		$a0, $s2			                # $a0 = location of the bug blaster (object grid)
    jal			object_to_display_grid_location	    # jump to object_to_display_grid_location and save position to $ra
    move 		$s2, $v0			                # $s2 = location of the bug blaster (display grid)

    # Check if key is pressed
    move        $t9, $s6                            # load key-press indicator
	bne         $t9, 1, sdbk_end                    # if key is not pressed, end the function
    
    # Check type of key being pressed
    lw			$t9, 0xffff0004			            # load key identifier
    beq			$t9, 0x78, sdbk_handle_x	        # if $t9 == 0x78 then sdbk_handle_x
    
    j			sdbk_end				            # jump to sdbk_end

    sdbk_handle_x:
        li 		    $t0, 0			                    # $t0 = 0, the loop counter
        sdbk_handle_x_loop:
        lw			$t1, 0($s0)			                # get current element in the darts array
        bne			$t1, -1, sdbk_handle_x_loop_next	# if not empty, go to the next element

        # Position to place dart is one row above the bug blaster
        sub 		$t2, $s2, $s3			            # $t2 = $s2 - $s3
        sw			$t2, 0($s0)			            # save dart location
        j			sdbk_end				            # jump to sdbk_end
        
        # Decrement loop counter and go to the next element
        sdbk_handle_x_loop_next:
        addi		$t0, $t0, 1			                # decrement loop counter by 1
        addi		$s0, $s0, 4			                # $s0 = $s0 + 4
        bne			$t0, $s1, sdbk_handle_x_loop	    # if $t0 != $s1 (length of the darts array) then sdbk_handle_x_loop

    sdbk_end:
    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			    # $sp += 20

    move 		$v0, $zero			        # $v0 = $zero
    jr			$ra					        # jump to $ra

# END FUN shoot_dart_by_keystroke

# FUN move_darts
# - Move or remove dart on the dart array
# - Mutates the dart array directly
# ARGS:
# $a0: address of dart array
# $a1: length of dart array
move_darts:
    addi		$sp, $sp, -20			    # $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    # Load parameters
    move 		$s0, $a0			        # $s0 = address of dart array
    move 		$s1, $a1			        # $s1 = length of dart array

    li			$s3, 0				        # $s3 = 0, loop counter

    move_darts_loop:
        lw			$t0, 0($s0)			        # load current element to process
        beq			$t0, -1, move_darts_skip	    # skip if the current dart location is -1 (empty dart)
        
        lw			$t1, screenPixelUnits			# load number of pixel units per row
        sub 		$t0, $t0, $t1			        # $t0 = $t0 - $t1
        blt			$t0, 0, md_remove_dart	        # if $t0 < 0 then md_remove_dart
        j			move_darts_finally				# jump to move_darts_finally
        
        md_remove_dart:
        li			$t0, -1				            # $t0 = -1, set to empty dart location
        
        move_darts_finally:
        sw			$t0, 0($s0)                   # save the updated location back to the array

        move_darts_skip:
        addi		$s3, $s3, 1			            # $s3 = $s3 + 1
        addi		$s0, $s0, 4			            # $s0 = $s0 + 4
        bne			$s3, $s1, move_darts_loop	    # if $s3 != $s1 then move_darts_loop
        
    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			    # $sp += 20

    move 		$v0, $zero			        # $v0 = $zero
    jr			$ra					        # jump to $ra

# END FUN move_darts

# FUN generate_mushrooms
# Generate and populate the "mushrooms" array based on "mushroomLength"
# ARGS:
# $a0: number of mushrooms to generate
# $a1: highest "lives" of a mushroom (see definition)
generate_mushrooms:
    addi		$sp, $sp, -20			# $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    # Move parameters
    move 		$s0, $a0			    # $s0 = number of mushrooms to generate
    move 		$s1, $a1			    # $s1 = highest "lives" per mushroom

    # Data values
    lw			$s3, mushroomLength		# $t1 = mushroomLength
    subi		$s3, $s3, 1			    # $t1 = $t1 - 1
    
    generate_mushroom_loop:
        # Generate random position for the mushroom
        # Random number from 0 to (mushroomLength - 1)
        li			$v0, 42				                # use service 42 to generate random numbers
        li			$a0, 0				                # $a0 = 0
        move		$a1, $s3				            # $a1 = $s3
        syscall
        
        move 		$t0, $a0			                # $t0 = random number generated

        # If the generated mushroom is in the first row, then skip adding this mushroom
        lw			$t1, screenPixelUnits			    # 
        blt			$t0, $t1, gml_skip	                # if $t0 < $t1 then gml_skip

        # Multiply $t0 by 4 to get the location in mushroom array
        addi		$t1, $zero, 4			            # $t1 = $zero + 4
        mult	    $t0, $t1			                # $t0 * $t1 = Hi and Lo registers
        mflo	    $t0					                # copy Lo to $t0

        # If there exists a mushroom at this location, then skip saving the mushroom
        lw			$t9, mushrooms($t0)			        
        bne			$t9, $zero, gml_skip            	# if $t9 != $zero then gml_skip
        sw			$s1, mushrooms($t0)			        # Save highest "lives" per mushroom into the location

        gml_skip:
        subi		$s0, $s0, 1			                # $s0 = $s0 - 1
        bne			$s0, $zero, generate_mushroom_loop	# if $s0 != $zero then generate_mushroom_loop

    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			# $sp += 20

    move 		$v0, $zero			    # $v0 = $zero
    jr			$ra					    # jump to $ra

# END FUN generate_mushrooms

# FUN move_centipede
# - Given the current state of centipede, calculate the next
# - state and store the info back to the arrays.
# ARGS:
# $a0: Address of array representing centipede locations.
# $a1: Address of array representing centipede directions.
# $a2: Length of centipede.
move_centipede:
    addi		$sp, $sp, -20			            # $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    # Move arguments to saved registers
    move 		$s0, $a0			                # $s0 = centipede locations
    move 		$s1, $a1			                # $s1 = centipede directions
    move 		$s2, $a2			                # $s2 = length of centipede

    move_centipede_loop:
        lw			$a0, 0($s0)			            # load current centipede location
        lw			$a3, 0($s1)			            # load current centipede direction
        
        jal			move_centipede_segment			# jump to move_centipede_segment and save position to $ra
        # $v0 - next location, $v1 - next direction
        sw			$v0, 0($s0)			            # 
        sw			$v1, 0($s1)			            # 
        
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

    # Load parameters
    move 		$s0, $a0			                # $s0 = current location of the centipede
    move 		$s1, $a3			                # $s1 = current direction that the centipede is moving along

    # Check if the current location is empty
    lw			$t5, centipedeLocationEmpty			# $t5 = centipedeLocationEmpty
    bne			$s0, $t5, mcs_main	                # if $a0 != $t5 then mcs_main

    # If location is empty, then do not do anything
    move 		$v0, $t5			                # $v0 = $t5
    move 		$v1, $a3			                # $v1 = $a3
    j			end_mcs				                # jump to end_mcs
    
    mcs_main:
    # Main idea: continue the current direction if "turning conditions" are not met
    lw			$s2, screenPixelUnits

    # --- Identify if the centipede is about to hit the border
    # Calculate the column number for the right-edge
    subi		$t0, $s2, 1		                    # $t0 = $s2 - 1, the column number for the edge
    # Store the current column number in $t3
    div			$a0, $s2			                # $a0 / $s2
    mfhi	    $t3					                # $t3 = $a0 mod $s2, stores the current column num.
    
    beq			$s1, 1, mcs_border_goes_right	    # if $s1 == 1 then mcs_border_goes_right
    mcs_border_goes_left:
    beq			$t3, $zero, mcs_reach_border	    # if $t3 == $zero then mcs_reach_border
    j			mcs_border_end				        # jump to mcs_border_end

    mcs_border_goes_right:
    beq			$t3, $t0, mcs_reach_border  	    # if $t3 == $t0 then mcs_reach_border
    j			mcs_border_end				        # jump to mcs_border_end

    mcs_border_end:

    # --- END Identify if the centipede is about to hit the border

    # --- Identify if the centipede is about to hit a mushroom
    # Do not check for mushrooms if we are outside of the mushroom generation space
    lw			$t5, mushroomLength     			    # $t5 = mushroomLength
    bge			$s0, $t5, mcs_mushroom_end    	        # if $s0 >= $t5 then mcs_mushroom_end
    
    # Check if there is a mushroom infront of the centipede
    add			$t0, $s0, $s1		                    # $t0 = $s0 + $s1, next location
    # Multiply by 4 to access mushroom array
    addi		$t1, $zero, 4			                # $t1 = $zero + 4
    mult	    $t0, $t1			                    # $t0 * $t1 = Hi and Lo registers
    mflo	    $t9					                    # copy Lo to $t9
    # Check and branch if there is mushroom infront of the centipede
    lw			$t1, mushrooms($t9)			            # 
    beq			$t1, $zero, mcs_mushroom_end    	    # if $t1 == $zero then mcs_mushroom_end
    
    # If the centipede hits a mushroom, the logic is the same as hitting the border
    j			mcs_reach_border				        # jump to mcs_reach_border
    
    mcs_mushroom_end:
    j			mcs_reach_border_end				# jump to mcs_reach_border_end
    # --- END Identify if the centipede is about to hit a mushroom

    # --- Reach border logic
    mcs_reach_border:
    # --- Toggle direction
    beq			$s1, -1, mcs_border_change_right	# if $s1 == left then mcs_border_change_right
    
    mcs_border_change_left:
    li			$v1, -1				                # $v1 = -1
    j			mcs_border_change_end				# jump to mcs_border_change_end
    
    mcs_border_change_right:
    li			$v1, 1				                # $v1 = 1
    j			mcs_border_change_end				# jump to mcs_border_change_end
    
    mcs_border_change_end:
    # --- END Toggle direction

    # If we are in the last row of personal space, move up
    lw			$t5, personalSpaceEnd			    # $t5 = personalSpaceEnd
    sub			$t5, $t5, $s2		                # $t5 = $t5 - $s2
    bge			$s0, $t5, mcs_border_personal_up	# if $s0 >= $t5 then mcs_border_personal_up

    # If we are in personal space but not in the first row of personal space, then
    # continue the previous movement direction.
    lw			$t5, personalSpaceStart			    # $t5 = personalSpaceStart
    add			$t5, $t5, $s2		                # $t5 = $t5 + $s2
    bge			$s0, $t5, mcs_bps_middle_row	    # if $s0 >= $t5 then mcs_bps_middle_row
    j			mcs_bps_middle_row_end				# jump to mcs_bps_middle_row_end
    
    # Move based on previous vertical movement
    mcs_bps_middle_row:
    lw			$t1, personalSpaceLastVerticalMovement
    beq			$t1, -1, mcs_border_personal_up	    # if $t1 == -1 then mcs_border_personal_up
    j			mcs_border_personal_down			# jump to mcs_border_personal_down
    
    mcs_bps_middle_row_end:

    # If we are in the first row of the personal space, move down
    lw			$t5, personalSpaceStart			    # $t5 = personalSpaceStart
    bge			$s0, $t5, mcs_border_personal_down	# if $s0 >= $t5 then mcs_border_personal_down
    
    # If we are not in personal space
    j			mcs_border_personal_end			    # jump to mcs_border_personal_end

    mcs_border_personal_up:
    sub 		$v0, $s0, $s2			            # $v0 = $s0 - $s2, goes up one row
    # Save the vertical movement direction
    li			$t1, -1				                # $t1 = -1
    sw			$t1, personalSpaceLastVerticalMovement
    j			end_mcs				                # jump to end_mcs

    mcs_border_personal_down:
    add 		$v0, $s0, $s2			            # $v0 = $s0 + $s2, goes down one row
    # Save the vertical movement direction
    li			$t1, 1				                # $t1 = 1
    sw			$t1, personalSpaceLastVerticalMovement
    j			end_mcs				                # jump to end_mcs

    mcs_border_personal_end:
    add 		$v0, $s0, $s2			            # $v0 = $s0 + $s2, goes down one row
    j			end_mcs				                # jump to end_mcs
    
    mcs_reach_border_end:

    # --- END Reach border logic

    # If none of the above turning conditions are met
    end_turning_condition_checks:
    # Continue moving along the original direction
    add 		$v0, $a0, $a3			            # $v0 = $a0 + $a3
    move 		$v1, $a3			                # $v1 = $a3

    end_mcs:

    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			            # $sp += 20

    jr			$ra					                # jump to $ra

# END FUN move_centipede_segment

##############################################
# # Graphics
##############################################
# FUN draw_centipede
# ARGS:
# $a0: isClear. 
#      Set to 1 to clear centipede drawing at centipede array locations.
#      Set to 0 to draw centipede at array locations.
# $a1: Address of locations of centipede segments.
# $a2: Length of centipede array.
draw_centipede:
    addi		$sp, $sp, -20			                # $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    move 		$s0, $a0			                    # $s0 = $a0
    move 		$s1, $a1			                    # $s1 = $a1
    move 		$s2, $a2			                    # $s2 = $a2

    draw_centipede_loop:
        lw			$a0, 0($s1)			                # load current segment to draw
        addi		$s2, $s2, -1			            # decrement loop counter

        # If the centipede segment is marked "dead", then skip draw
        lw			$t0, centipedeLocationEmpty     	# $t0 = centipedeLocationEmpty
        beq			$a0, $t0, dc_skip_draw_segment	    # if $a0 == $t0 then dc_skip_draw_segment
        
        # If we are clearing centipede from locations, set color to background color
        beq			$s0, $zero, dc_is_drawing	        # if $s0 == $zero then dc_is_drawing
        
        dc_is_clearing:
        lw			$a3, backgroundColor	            # $a3 = backgroundColor
        j			dc_end_load_color				    # jump to dc_end_load_color

        dc_is_drawing:
        
        # Color the head of centipede with a different color
        beq			$s2, $zero, dc_load_head_color	    # if we reach the end of array, then this is a head
        lw			$t1, 4($s1)			                # load the next element in the location array
        beq			$t1, $t0, dc_load_head_color	    # if the next segment is marked "dead", then this is a head
        
        dc_load_segment_color:
        lw			$a3, centipedeColor			        # load regular centipede segment color
        j			dc_end_load_color				    # jump to dc_end_load_color
        
        dc_load_head_color:
        lw			$a3, centipedeHeadColor			    # load head color for centipede segment
        
        dc_end_load_color:
        jal			draw_centipede_segment	            # jump to draw_centipede_segment and save position to $ra
        
        dc_skip_draw_segment:

        addi 		$s1, $s1, 4			                # increment index to next element
        bgt			$s2, $zero, draw_centipede_loop	    # if $a2 > $zero then draw_centipede_loop
        
    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			                # $sp += 20

    move 		$v0, $zero			                    # $v0 = $zero
    jr			$ra					                    # jump to $ra

# END FUN draw_centipede

# FUN draw_centipede_segment
# ARGS:
# $a0: Location of centipede (object grid)
# $a3: Color of this segment
draw_centipede_segment:
    addi		$sp, $sp, -4			    # $sp -= 4
    sw			$ra, 0($sp)
    
    move 		$a1, $zero			        # $a1 = $zero
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
# $a0: location of bug blaster (object grid)
draw_blaster:
    addi		$sp, $sp, -4			# $sp -= 4
    sw			$ra, 0($sp)

    move 		$a1, $zero			    # $a1 = $zero
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
# FUN fill_background
# ARGS:
# $a0: location to fill background (object grid)
fill_background_at_location:
    addi		$sp, $sp, -4			    # $sp -= 4
    sw			$ra, 0($sp)

    lw			$a1, backgroundColor	    # $t9 = backgroundColor
    jal			fill_color_at_location		# jump to fill_color_at_location and save position to $ra
    
    lw			$ra, 0($sp)
    addi		$sp, $sp, 4			    # $sp += 4

    move 		$v0, $zero			        # $v0 = $zero
    jr			$ra					        # jump to $ra

# END FUN fill_background

# FUN clear_screen_drawings
# - Clear all drawings on the screen
# ARGS:
clear_screen_drawings:
    addi		$sp, $sp, -20			# $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    li			$s0, 0				    # $s0 = 0, loop counter

    # Calculate total number of positions in object grid
    lw			$t0, screenPixelUnits	# $t0 = screenPixelUnits
    mult	    $t0, $t0			    # $t0 * $t0 = Hi and Lo registers
    mflo	    $s1					    # copy Lo to $s1
    
    clear_screen_loop:
        move 		$a0, $s0			                # $a0 = $s0
        jal			fill_background_at_location			# jump to fill_background_at_location and save position to $ra

        # Increment loop counter
        addi		$s0, $s0, 1			                # $s0 = $s0 + 1
        blt			$s0, $s1, clear_screen_loop	        # if $s0 < $s1 then clear_screen_loop

    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			# $sp += 20

    move 		$v0, $zero			# $v0 = $zero
    jr			$ra					# jump to $ra

# END FUN clear_screen_drawings

# FUN fill_color_squares
# ARGS:
# $a0: address of location (object grid) to fill color in
# $a1: length of the location array
# $a2: color
fill_color_squares:
    addi		$sp, $sp, -20			# $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    move 		$s0, $a0			    # $s0 = address of location (object grid) array
    move 		$s1, $a1			    # $s1 = length of the location array
    move 		$s2, $a2			    # $s2 = color to fill in

    li			$s3, 0				    # $s3 = 0, loop counter
    
    fill_color_squares_loop:
        lw			$a0, 0($s0)			                # load current position
        move 		$a1, $s2			                # $a1 = color to fill

        jal			fill_color_at_location				# jump to fill_color_at_location and save position to $ra
    
        # Increment loop counter
        addi		$s0, $s0, 4			                # move to next element
        addi		$s3, $s3, 1			                # increment loop counter
        blt			$s3, $s1, fill_color_squares_loop	# if $s3 < $s1 then fill_color_squares_loop

    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			# $sp += 20

    move 		$v0, $zero			    # $v0 = $zero
    jr			$ra					    # jump to $ra

# END FUN fill_color_squares

# FUN fill_color_at_location
# ARGS:
# $a0: location to fill color (object grid)
# $a1: color
fill_color_at_location:
    addi		$sp, $sp, -20			    # $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    move 		$s0, $a0			        # $s0 = position to fill color (object grid)
    move 		$s1, $a1			        # $s1 = color to be filled

    # Calc address
    move 		$a1, $zero			        # $a1 = $zero
    jal			calc_display_address	    # jump to calc_display_address and save position to $ra
    move 		$t2, $v0			        # $t2 = $v0

    # Load colors
    lw			$t1, screenLineWidth	    # $t1 = screenLineWidth

    # Draw background color at requested location
    # First line
    sw			$s1, 0($t2)
    sw			$s1, 4($t2)
    sw			$s1, 8($t2)

    # Second line
    add 		$t2, $t2, $t1			# $t2 = $t2 + $t1, goes to the next line at this location
    sw			$s1, 0($t2)
    sw			$s1, 4($t2)
    sw			$s1, 8($t2)

    # Third line
    add 		$t2, $t2, $t1			# $t2 = $t2 + $t1, goes to the next line at this location
    sw			$s1, 0($t2)
    sw			$s1, 4($t2)
    sw			$s1, 8($t2)

    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			    # $sp += 20

    move 		$v0, $zero			        # $v0 = $zero
    jr			$ra					        # jump to $ra

# END FUN fill_color_at_location

# FUN draw_mushrooms
# ARGS:
# $a0: address of array storing all mushrooms
# $a1: length of the mushroom array
draw_mushrooms:
    addi		$sp, $sp, -20			# $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    move 		$s0, $a0			    # $s0 = mushrooms array address
    move 		$s1, $a1			    # $s1 = length of mushrooms

    move 		$s2, $zero			    # $s2 = 0, counter for current mushroom index

    draw_mushrooms_loop:
        move 		$a0, $s2			                # $a0 = $s2
        lw			$a1, 0($s0)			                # load current mushroom to draw
        jal			draw_mushroom_at_location			# jump to draw_mushroom_at_location and save position to $ra

        dmr_skip_draw:
        addi 		$s0, $s0, 4			                # increment index to next mushroom
        addi		$s2, $s2, 1			                # $s2 = $s2 + 1
        blt			$s2, $s1, draw_mushrooms_loop	    # if $s2 < $s1 then draw_mushrooms_loop

    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20		    # $sp += 20

    move 		$v0, $zero			    # $v0 = $zero
    jr			$ra					    # jump to $ra

# END FUN draw_mushrooms

# FUN draw_mushroom_at_location
# ARGS:
# $a0: position to draw (object grid)
# $a1: mushroom lives
draw_mushroom_at_location:
    addi		$sp, $sp, -20			    # $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    # Load parameters
    move 		$s0, $a0			                # $s0 = position (object grid)
    move 		$s1, $a1			                # $s1 = mushroom current lives

    # Calculatre display address
    move 		$a0, $s0			                # $a0 = $s0
    move 		$a1, $zero			                # $a1 = $zero
    jal			calc_display_address	            # jump to calc_display_address and save position to $ra
    move 		$t2, $v0			                # $t2 = $v0

    # Load needed values
    lw			$t0, mushroomColor		            # $t0 = mushroomColor
    lw			$t6, mushroomFullLivesColor         # $t6 = mushroomFullLivesColor
    lw			$t1, screenLineWidth	            # $t1 = screenLineWidth
    lw			$t9, backgroundColor	            # $t9 = backgroundColor

    # Jump to case based on mushroom lives
    beq			$s1, 1, draw_mushroom_lives_1	    # if $s1 == 1 then draw_mushroom_lives_1
    beq			$s1, 2, draw_mushroom_lives_2	    # if $s1 == 2 then draw_mushroom_lives_2
    beq			$s1, 3, draw_mushroom_lives_3	    # if $s1 == 3 then draw_mushroom_lives_3
    beq			$s1, 4, draw_mushroom_lives_4	    # if $s1 == 4 then draw_mushroom_lives_4
    
    j			draw_mushroom_end				    # jump to draw_mushroom_end
    
    # --- Draw mushroom
    draw_mushroom_lives_1:
    # First line
    sw			$t0, 0($t2)
    sw			$t0, 4($t2)
    sw			$t0, 8($t2)

    # Second line
    add 		$t2, $t2, $t1			            # $t2 = $t2 + $t1, goes to the next line at this location
    sw			$t9, 0($t2)
    sw			$t0, 4($t2)
    sw			$t9, 8($t2)

    # Third line
    add 		$t2, $t2, $t1			            # $t2 = $t2 + $t1, goes to the next line at this location
    sw			$t9, 0($t2)
    sw			$t9, 4($t2)
    sw			$t9, 8($t2)

    j			draw_mushroom_end		            # jump to draw_mushroom_end

    draw_mushroom_lives_2:
    # First line
    sw			$t0, 0($t2)
    sw			$t0, 4($t2)
    sw			$t0, 8($t2)

    # Second line
    add 		$t2, $t2, $t1			            # $t2 = $t2 + $t1, goes to the next line at this location
    sw			$t9, 0($t2)
    sw			$t0, 4($t2)
    sw			$t9, 8($t2)

    # Third line
    add 		$t2, $t2, $t1			            # $t2 = $t2 + $t1, goes to the next line at this location
    sw			$t9, 0($t2)
    sw			$t0, 4($t2)
    sw			$t9, 8($t2)

    j			draw_mushroom_end		            # jump to draw_mushroom_end

    draw_mushroom_lives_3:
    # First line
    sw			$t0, 0($t2)
    sw			$t0, 4($t2)
    sw			$t0, 8($t2)

    # Second line
    add 		$t2, $t2, $t1			            # $t2 = $t2 + $t1, goes to the next line at this location
    sw			$t0, 0($t2)
    sw			$t0, 4($t2)
    sw			$t0, 8($t2)

    # Third line
    add 		$t2, $t2, $t1			            # $t2 = $t2 + $t1, goes to the next line at this location
    sw			$t9, 0($t2)
    sw			$t0, 4($t2)
    sw			$t9, 8($t2)

    j			draw_mushroom_end		            # jump to draw_mushroom_end

    draw_mushroom_lives_4:
    # First line
    sw			$t6, 0($t2)
    sw			$t6, 4($t2)
    sw			$t6, 8($t2)

    # Second line
    add 		$t2, $t2, $t1			            # $t2 = $t2 + $t1, goes to the next line at this location
    sw			$t6, 0($t2)
    sw			$t6, 4($t2)
    sw			$t6, 8($t2)

    # Third line
    add 		$t2, $t2, $t1			            # $t2 = $t2 + $t1, goes to the next line at this location
    sw			$t9, 0($t2)
    sw			$t6, 4($t2)
    sw			$t9, 8($t2)

    j			draw_mushroom_end		            # jump to draw_mushroom_end
    draw_mushroom_end:
    # --- END Draw mushroom

    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			            # $sp += 20

    move 		$v0, $zero			                # $v0 = $zero
    jr			$ra					                # jump to $ra

# END FUN draw_mushroom_at_location

# FUN draw_darts
# ARGS:
# $a0: address of the darts array
# $a1: length of the darts array
# $a2: color of darts
draw_darts:
    addi		$sp, $sp, -20			# $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    # Load parameters
    move 		$s0, $a0			    # $s0 = address of the darts array
    move 		$s1, $a1			    # $s1 = length of the darts array
    move 		$s2, $a2			    # $s2 = color of darts

    li			$s3, 0				    # $s3 = 0, loop counter
    draw_darts_loop:
        lw			$t0, 0($s0)			        # the current dart location for drawing

        # Draw current dart
        move 		$a0, $t0			            # $a0 = location
        move 		$a1, $s2			            # $a1 = dart color
        jal			draw_dart				        # jump to draw_dart and save position to $ra
        
        # Increment loop counter and go to next
        addi		$s3, $s3, 1			            # $s3 = $s3 + 1
        addi		$s0, $s0, 4			            # $s0 = $s0 + 4
        bne			$s3, $s1, draw_darts_loop	    # if $s3 != $s1 then draw_darts_loop
        
    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			# $sp += 20

    move 		$v0, $zero			    # $v0 = $zero
    jr			$ra					    # jump to $ra

# END FUN draw_darts

# FUN draw_dart
# ARGS:
# $a0: location (display grid)
# $a1: dart color
draw_dart:
    addi		$sp, $sp, -20			    # $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    # Load parameter
    move 		$s0, $a0			        # $s0 = location (display grid)
    move 		$s1, $a1			        # $s1 = color of dart

    # Do not draw if dart is empty
    beq			$s0, -1, end_draw_dart	    # if $s0 == -1 then end_draw_dart

    # Calculate display address
    li 		    $a1, 1			            # $a1 = 1
    jal			calc_display_address	    # jump to calc_display_address and save position to $ra
    move 		$t2, $v0			        # $t2 = $v0

    # Load needed values
    move 		$t0, $s1			        # $t0 = color of dart
    lw			$t1, screenLineWidth	    # $t1 = screenLineWidth

    # Draw dart
    sw			$t0, 4($t2)

    end_draw_dart:
    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			    # $sp += 20

    move 		$v0, $zero			        # $v0 = $zero
    jr			$ra					        # jump to $ra

# END FUN draw_dart

##############################################
# # Utilities
##############################################

# FUN sleep
sleep:
    addi		$sp, $sp, -20			# $sp -= 20
    sw			$ra, 0($sp)

    # --- Calculate sleep amount
    lw			$t0, framesPerSecond    # $t0 = framesPerSecond
    addi		$t1, $zero, 1000		# $t1 = $zero + 1000
    
    div			$t1, $t0			    # $t1 / $t0
    mflo	    $t2					    # $t2 = floor($t1 / $t0) 
    # --- END Calculate sleep amount

    li			$v0, 32				    # $v0 = 32
    move 		$a0, $t2			    # set sleep $t2 milliseconds        
    syscall

    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			# $sp += 20

    move 		$v0, $zero			    # $v0 = $zero
    jr			$ra					    # jump to $ra

# END FUN sleep

# FUN object_to_display_grid_location
# ARGS:
# $a0: position in object grid.
# RETURN $v0: position in display grid.
object_to_display_grid_location:
    addi		$sp, $sp, -20			    # $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    # Move parameters
    move 		$s0, $a0			        # $s0 = $a0

    # Load constants
    lw			$t0, screenPixelUnits		# $t0 = screenPixelUnits
    
    # Calculate number of rows to be scaled ($t2)
    div			$s0, $t0			        # $s0 / $t0
    mflo	    $t2					        # $t2 = floor($s0 / $t0) 
    mfhi        $t3                         # $t3 = $s0 mod $t0
    
    # Number of rows to be scaled * number of pixel units per row * scaling factor (3)
    mult	    $t2, $t0			        # $t2 * $t0 = Hi and Lo registers
    mflo	    $t2					        # copy Lo to $t2
    
    addi		$t1, $zero, 3			    # $t1 = $zero + 3
    mult	    $t2, $t1			        # $t2 * $t1 = Hi and Lo registers
    mflo	    $t2					        # copy Lo to $t2
    
    # Add remainder
    add			$t2, $t2, $t3		        # $t2 = $t2 + $t3

    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			    # $sp += 20

    move 		$v0, $t2			        # $v0 = $t2
    jr			$ra					        # jump to $ra

# END FUN object_to_display_grid_location

# FUN display_to_object_grid_location
# ARGS:
# $a0: position in display grid
# RETURN $v0: position in object grid
display_to_object_grid_location:
    addi		$sp, $sp, -20			    # $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    # Save parameters
    move 		$s0, $a0			        # $s0 = $a0

    # Calculate current coordinate
    jal			calc_coordinate				# jump to calc_coordinate and save position to $ra
    move 		$t0, $v0			        # $t0 = current row
    move 		$t1, $v1			        # $t1 = current column

    # Divide current row by 3 and take the floor
    li			$t2, 3				        # $t2 = 3
    div			$t0, $t2			        # $t0 / $t2
    mflo	    $t0					        # $t0 = floor($t0 / $t2) 
    
    # Use number of rows in object grid * number of units per row
    lw			$t2, screenPixelUnits		# $t2 = screenPixelUnits
    mult	    $t0, $t2			        # $t0 * $t2 = Hi and Lo registers
    mflo	    $t0					        # copy Lo to $t0

    # Add column number
    add			$t0, $t0, $t1		        # $t0 = $t0 + $t1
    
    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			    # $sp += 20

    move 		$v0, $t0			        # $v0 = $t0
    jr			$ra					        # jump to $ra

# END FUN display_to_object_grid_location

# FUN calc_display_address
# ARGS:
# $a0: position
# $a1: grid type that `position`($a0) is measured in.
#      0 - object grid, 1 - display grid.
# RETURN $v0: display address to be used
calc_display_address:
    addi		$sp, $sp, -4			        # $sp -= 4
    sw			$ra, 0($sp)

    # Check for grid system: convert to display grid if possible.
    bne			$a1, $zero, cda_display_grid	# if $a1 != $zero then cda_display_grid
    jal			object_to_display_grid_location # jump to object_to_display_grid_location and save position to $ra
    move 		$a0, $v0			            # $a0 = $v0
    
    cda_display_grid:
    move 		$t2, $a0			            # $t2 = $a0
    lw			$t1, screenPixelUnits			
    lw			$t4, screenLineUnusedWidth 

    # Calculate actual display address
    # Multiply $t2 by unit width
    lw			$t3, unitWidth			        # Load width per "unit" to $t3
    mult	    $t2, $t3			            # $t2 * $t3 (unit width) = Hi and Lo registers
    mflo	    $t2					            # copy Lo to $t2

    # Since we do not use "screenLineUnusedWidth" pixels per line, 
    # we need to account for these values in for accurate positioning.
    
    move 		$t6, $a0		    	        # $t6 = $a0

    # $t5 stores the number of previous lines that we should account for
    div			$t6, $t1			            # $t6 / $t1
    mflo	    $t5					            # $t5 = floor($t2 / $t1)
    
    # We will therefore add $t5 * $t4 (unused pixels for every line) to $t2.
    mult	    $t5, $t4			            # $t5 * $t4 = Hi and Lo registers
    mflo	    $t5					            # copy Lo to $t5
    add			$t2, $t2, $t5		            # $t2 = $t2 + $t5

    add			$t2, $t2, $s7		            # $t2 = $t2 + $s7 (display address)

    lw			$ra, 0($sp)
    addi		$sp, $sp, 4			            # $sp += 4

    move 		$v0, $t2			            # $v0 = $t2
    jr			$ra					            # jump to $ra

# END FUN calc_display_address

# FUN calc_coordinates
# ARGS:
# $a0: current location (object/display grid)
# RETURN 
# $v0: current row
# $v1: current column
calc_coordinate:
    addi		$sp, $sp, -20			# $sp -= 20
    sw			$s0, 16($sp)
    sw			$s1, 12($sp)
    sw			$s2, 8($sp)
    sw			$s3, 4($sp)
    sw			$ra, 0($sp)

    # Load parameters
    move 		$s0, $a0			    # $s0 = current location

    # Load constants
    lw			$s1, screenPixelUnits   # $s1 = screenPixelUnits

    # Calculate current row and column
    div			$s0, $s1			# $s0 / $s1
    mflo	    $v0					# $v0 = floor($s0 / $s1) 
    mfhi	    $v1					# $v1 = $s0 mod $s1 

    lw			$s0, 16($sp)
    lw			$s1, 12($sp)
    lw			$s2, 8($sp)
    lw			$s3, 4($sp)
    lw			$ra, 0($sp)
    addi		$sp, $sp, 20			# $sp += 20

    jr			$ra					    # jump to $ra

# END FUN calc_coordinates
