.data
    displayAddress:   .word 0x10008000  # $gp

.text
    lw		$t0, displayAddress		# $t0 stores the base address for display
    li		$t1, 0xff0000		    # $t1 = 0xff0000 (red)
    li		$t2, 0x00ff00		    # $t2 = 0x00ff00 (green)
    li		$t3, 0x0000ff		    # $t3 = 0x0000ff (blue)
    
    sw		$t1, 0($t0)		        # Paint the first unit in display red
    sw		$t2, 4($t0)		        # Paint the second unit in display green
    sw		$t3, 128($t0)		    # Paint the first unit in second row blue

exit:
    li		$v0, 10		            # $v0 = 10
    syscall
    
    
    
    
    
    
