# Retorna la ultima instruccion de un programa (syscall 10)
# Neil Villamizar   (15-11523)
# Samuel Fagundez   (15-10460)

##################### instruccion  LastInstruccion(instruccion * program) ############################
####################     ($v0)                                   ($a0)    ############################

LastInstruccion:

#convenciones:
addi $sp $sp -8	
sw $ra 4($sp)
sw $fp ($sp)
move $fp $sp
addiu   $sp,$sp, -8
sw      $s0, 4($sp)
sw      $s1, 8($sp)
#

move $s0, $a0		# En a0 esta la direccion de la primera instruccion del programa, usamos s0 para iterar sobre las instrucciones.

loop_LastInst:
	
	lw $s1, ($s0)	# En s1 esta el codigo de la instruccion.
	
	beq $s1, 0x2402000a, returnLastInst  # reviso si es un li v0
	
	addi $s0, $s0, 4
	b loop_LastInst 
	

returnLastInst:

addi $s0, $s0, 4	# Apunta a la ultima direccion (syscall, con $v0 == 10)
move $v0, $s0		# Ponemos la ultima instruccion en $v0 para retornar

#convenciones
lw      $s0, 4($sp)
lw      $s1, 8($sp)
addiu   $sp,$sp, 8
lw $fp ($sp)
lw $ra 4($sp)
addi $sp $sp 8
#

jr $ra
