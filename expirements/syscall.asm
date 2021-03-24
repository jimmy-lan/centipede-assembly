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

# FUN foo
# ARGS:
# $a0: arg1
# $a1: arg2
# $a2: arg3
# RETURN $v0: 0
foo:
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

# END FUN foo
    