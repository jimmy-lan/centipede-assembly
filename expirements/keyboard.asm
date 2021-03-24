# Check for keyboard pressing

.data
    displayAddress:   .word 0x10008000  # $gp
    displayColor:     .word 0x00ff0000

.text

main:
    jal		check_keystroke				# jump to check_keystroke and save position to $ra
    
    j		main				# jump to main

    
# Check keystroke function
check_keystroke:
    addi	$sp, $sp, -4			# $sp = $sp + -4
    sw		$ra, 0($sp)		# 
    
    lw		$t8, 0xffff0000		# Check for keyboard pressing indicator
    bne		$t8, 1, end_keyboard_input	# if $t8 != 1 then end_keyboard_input

    lw		$t2, 0xffff0004		# Load key code
    beq		$t2, 0x61, respond_to_a	# if $t2 == 0x89 then respond_to_a

end_keyboard_input:
    lw		$ra, 0($sp)		# 
    addi	$sp, $sp, 4			# $sp = $sp + 4
    jr		$ra					# jump to $ra
    
    
# End check keystroke

respond_to_a:
    addi	$sp, $sp, 4			# $sp = $sp + 4
    sw		$ra, 0($sp)		# 
    
    # Display a red pixel on the screen
    lw		$t0, displayAddress		# 
    lw		$t1, displayColor		# 
    sw		$t1, 0($t0)		# 

    lw		$ra, 0($sp)		# 
    addi	$sp, $sp, -4			# $sp = $sp + -4
    
    jr		$ra					# jump to $ra
    
    
    
    


