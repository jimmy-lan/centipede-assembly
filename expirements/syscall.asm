# Syscall sample file
.data
    newLine: .asciiz "\n"

.text
# Produce a random number
main:
    addi	$t0, $zero, 0			# $t0 = $zero + 0
    
loop_rnd_number:
    addi	$sp, $sp, -4			# $sp = $sp + -4
    sw		$t0, 0($sp)		        # 
    
    jal		print_random_number		# jump to print_random_number and save position to $ra
    
    lw		$t0, 0($sp)		        # 
    addi	$sp, $sp, 4			    # $sp = $sp + 4

    addi	$t0, $t0, 1			    # $t0 = $t0 + 1

    ble		$t0, 5, loop_rnd_number	# if $t0 <= 15 then loop_rnd_number

end:
    li 		$v0, 10		            # terminate the program gracefully
	syscall
    
# Start print random number
print_random_number:
    addi	$sp, $sp, -4			# $sp = $sp + -4
    sw		$ra, 0($sp)		        # 
    
    li		$v0, 42		            # $v0 = 42
    li		$a0, 0		            # $a0 = 0
    li		$a1, 100		        # $a1 = 100
    syscall
    addi	$t0, $a0, 0			    # $t0 = $a0 + 0
    
print_result:
    li		$v0, 1		            # system call #1 - print int
    addi	$a0, $t0, 0			    # $a0 = $t0 + 0
    syscall				            # execute

    la		$a0, newLine			# $a0 = newLine
    li		$v0, 4				    # syscall print str
    syscall							# execute

    lw		$ra, 0($sp)		        # 
    addi	$sp, $sp, 4			    # $sp = $sp + 4
    jr		$ra					    # jump to $ra

# End print random number
    
