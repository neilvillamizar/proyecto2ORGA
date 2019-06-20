
	
	
.data
prog: .word p1, p2
n: .word 3
.text

p1:
la $a0, n # a0 == 0x10010000
p2:
lw $a1, n # a1 == 3

lw $t0, prog

lw $t1, p1

la $t2, prog

la $t3, p1
