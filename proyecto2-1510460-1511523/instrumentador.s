#Intrumentador
# Neil Villamizar   (15-11523)
# Samuel Fagundez   (15-10460)

# Supongamos que para cada programa tenemos sus datos en la etiqueta PROG_DATA
# 1 era posicion de la PROG_DATA:  i = numero del programa (1-N)
# 2 da posicion de la PROG_DATA:   direccion de la ultima instruccion del programa i
# 3 era posicion de la PROG_DATA:  Pseudo $pc del programa i.
# demas posiciones de la PROG_DATA: los otros registros del programa i. (por ahora vacias)
.data

.text
###################### Instrumentador (instruccion * program)  #######################
#####################                           $a0,           ######################
instrumentador:

#convenciones:
addi $sp $sp -8	
sw $ra 4($sp)
sw $fp ($sp)
move $fp $sp
addiu   $sp,$sp, -20
sw      $s0, 4($sp)
sw      $s1, 8($sp)
sw      $s2, 12($sp)
sw      $s3, 16($sp)
sw      $s4, 20($sp)
#

move $s0, $a0         # En a0 esta la direccion de la primera instruccion del programa program. 
		     # s0 iterara sobre las instrucciones del programa program.

loop_instrumentador:
	
	lw $s1, ($s0)	# En s1 esta el codigo de la instruccion.
	
	beq $s1, 0x2402000a, found_li_10  # reviso si es un li v0
	
	andi $s1, $s1, 0xfc0007ff # reviso si es un add
	beq $s1, 0x00000020, found_add    
	
	addi $s0, $s0, 4
	b loop_instrumentador
	

found_add:
	
	lw $s1, PROG_DATA    # Direccion donde esta guardada la data del programa
	addi $s1, $s1, 4     # Direccion donde esta guardada la direccion de la ultima instruccion del programa.
	lw $s1, ($s1)
		
	loop_shift_inst:
	
		beq $s1, $s0, put_break20       # Llegue al add, pongo un break 0x20 debajo de el
		
		lw $s2, ($s1)			# En s2 esta el codigo de la instruccion
		andi $s3, $s2, 0xfc000000	#Extraigo el codigo de operacion
		beq $s3, 0x10000000, found_beq	# reviso si es un beq
		
		sw $s2, 4($s1)			# muevo hacia abajo la instruccion
		
		addi $s1, $s1, -4
		b loop_shift_inst
		
		
found_beq:

	lw $s3, ($s1)			# Codigo de la instruccion beq
	andi $s3, $s3, 0x0000ffff	# Extraigo el inmediato (offset)
	
	andi $s4, $s3, 0x00008000	# Verifico si el offset era negativo
	
	bne $s4, 0x00008000, continue	# Si era positivo no es necesario extender el signo del offset
	ori $s3, $s3, 0xffff0000	# Si era negativo extiendo el signo.
	continue:
	
	addi $s3, $s3, 1
	mul $s3, $s3, 4			# Desplazamiento en memoria es (offset+1)*4
	add $s3, $s3, $s1		# Direccion de la etiqueta del branch ahora esta en s3
	
	ble $s3, $s0, fixOffset
	
	sw  $s2, 4($s1)			# Muevo hacia abajo la instruccion
	addi $s1, $s1, -4
	b loop_shift_inst
	
fixOffset:

	lw $s3, ($s1)		# Codigo de la instruccion beq a arreglar
	addi $s3, $s3, -1	# Arreglo el offset. (Se mueve una posicion mas arriba)
	
	sw $s3, 4($s1)		# Pongo la instruccion arreglada en su nuevo lugar
	addi $s1, $s1, -4
	b loop_shift_inst

put_break20:

	li $s2, 0x0000080d	# En s2 esta el codigo de la instruccion break 0x20
	sw $s2, 4($s0)		# Insertamos el break debajo del add
	
	lw $s1, PROG_DATA    	# Direccion donde esta guardada la data del programa
	addi $s1, $s1, 4     	# Direccion donde esta guardada la direccion de la ultima instruccion del programa.
	lw $s2, ($s1)
	addi $s2, $s2, 4
	sw $s2, ($s1)		# Actualizamos la direccion de la ultima instruccion del programa
	
	add $s0, $s0, 4
	b loop_instrumentador
	
found_li_10:

	li $s1, 0x0000040d	# Cargo el codigo del break 0x10
	sw $s1, ($s0)		# Sustituyo el li $v0 10 por el break0x10
	sw $zero, 4($s0)	# Elimino el syscall reemplazandolo por nop.
	
	#convenciones
	lw      $s0, 4($sp)
	lw      $s1, 8($sp)
	lw      $s2, 12($sp)
	lw      $s3, 16($sp)
	lw      $s4, 20($sp)
	addiu   $sp,$sp, 20
	lw $fp ($sp)
	lw $ra 4($sp)
	addi $sp $sp 8
	#
	
	jr $ra
		
