# SPIM S20 MIPS simulator.
# The default exception handler for spim.
#
# Copyright (C) 1990-2004 James Larus, larus@cs.wisc.edu.
# ALL RIGHTS RESERVED.
#
# SPIM is distributed under the following conditions:
#
# You may make copies of SPIM for your own use and modify those copies.
#
# All copies of SPIM must retain my name and copyright notice.
#
# You may not sell SPIM or distributed SPIM in conjunction with a commerical
# product or service without the expressed written consent of James Larus.
#
# THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE.
#

# $Header: $


# Define the exception handling code.  This must go first!

	.kdata
__m1_:	.asciiz "  Exception "
__m2_:	.asciiz " occurred and ignored\n"
__e0_:	.asciiz "  [Interrupt] "
__e1_:	.asciiz	"  [TLB]"
__e2_:	.asciiz	"  [TLB]"
__e3_:	.asciiz	"  [TLB]"
__e4_:	.asciiz	"  [Address error in inst/data fetch] "
__e5_:	.asciiz	"  [Address error in store] "
__e6_:	.asciiz	"  [Bad instruction address] "
__e7_:	.asciiz	"  [Bad data address] "
__e8_:	.asciiz	"  [Error in syscall] "
__e9_:	.asciiz	"  [Breakpoint] "
__e10_:	.asciiz	"  [Reserved instruction] "
__e11_:	.asciiz	""
__e12_:	.asciiz	"  [Arithmetic overflow] "
__e13_:	.asciiz	"  [Trap] "
__e14_:	.asciiz	""
__e15_:	.asciiz	"  [Floating point] "
__e16_:	.asciiz	""
__e17_:	.asciiz	""
__e18_:	.asciiz	"  [Coproc 2]"
__e19_:	.asciiz	""
__e20_:	.asciiz	""
__e21_:	.asciiz	""
__e22_:	.asciiz	"  [MDMX]"
__e23_:	.asciiz	"  [Watch]"
__e24_:	.asciiz	"  [Machine check]"
__e25_:	.asciiz	""
__e26_:	.asciiz	""
__e27_:	.asciiz	""
__e28_:	.asciiz	""
__e29_:	.asciiz	""
__e30_:	.asciiz	"  [Cache]"
__e31_:	.asciiz	""
__excp:	.word __e0_, __e1_, __e2_, __e3_, __e4_, __e5_, __e6_, __e7_, __e8_, __e9_
	.word __e10_, __e11_, __e12_, __e13_, __e14_, __e15_, __e16_, __e17_, __e18_,
	.word __e19_, __e20_, __e21_, __e22_, __e23_, __e24_, __e25_, __e26_, __e27_,
	.word __e28_, __e29_, __e30_, __e31_
s1:	.word 0
s2:	.word 0


msg1:	.asciiz "\nEl programa "
msg2:	.asciiz " ha terminado su ejecucion.\n"

msg3:	.asciiz "\nLa maquina ha sido apagada. Status de los programas:"
msg4:	.asciiz "\nPrograma "
msg5:	.asciiz " (Finalizado)\n"
msg6:	.asciiz " (No Finalizado)\n"
msg7:	.asciiz "\tNumero de add: "


# This is the exception handler code that the processor runs when
# an exception occurs. It only prints some information about the
# exception, but can server as a model of how to write a handler.
#
# Because we are running in the kernel, we can use $k0/$k1 without
# saving their old values.


# This is the exception vector address for MIPS32:
	.ktext 0x80000180
	
	move $k1 $at		# Save $at

	li $k0 0x00
	mtc0 $k0 $12		# Ignoro interrupciones
	sw $k0 0xffff0000
	
	sw $v0 s1		# Not re-entrant and we can't trust $sp
	sw $a0 s2		# But we need to use these registers

	mfc0 $k0 $13		# Cause register
	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f

	# Print information about exception.
	#
	li $v0 4		# syscall 4 (print_str)
	la $a0 __m1_
	syscall

	li $v0 1		# syscall 1 (print_int)
	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f
	syscall

	li $v0 4		# syscall 4 (print_str)
	andi $a0 $k0 0x3c
	lw $a0 __excp($a0)
	nop
	syscall

	bne $k0 0x18 ok_pc	# Bad PC exception requires special checks
	nop

	mfc0 $a0 $14		# EPC
	andi $a0 $a0 0x3	# Is EPC word-aligned?
	beq $a0 0 ok_pc
	nop

	li $v0 10		# Exit on really bad PC
	syscall

ok_pc:
	li $v0 4		# syscall 4 (print_str)
	la $a0 __m2_
	syscall

	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f
	
	beq $a0, 9, breakException # Si el ExcCode del 'Cause Register' es 9 entonces la excepcion fue causada por un break.
	bne $a0 0 ret		# 0 means exception was an interrupt
	nop

# Interrupt-specific code goes here!

###########################################################################

###### Interrupciones #####################################################

# Guardo los datos del programa actual
lw $a0, PROG_DATA		# Cargo en a0 la posicion donde voy a guardar los datos. a0 esta guardado en la etiqueta s2

mfc0 $k0 $14
sw $k0 8($a0)			# Guardo el pseudo PC del programa.

move $k0 $a0			# Cargo en a0 donde seguire guardando datos
lw $a0, s2
lw $v0, s1

move $at, $k1
sw $at 12($k0)
sw $v0 16($k0)
sw $v1 20($k0)
sw $a0 24($k0)
sw $a1 28($k0)
sw $a2 32($k0)
sw $a3 36($k0)
sw $t0 40($k0)
sw $t1 44($k0)
sw $t2 48($k0)
sw $t3 52($k0)
sw $t4 56($k0)
sw $t5 60($k0)
sw $t6 64($k0)
sw $t7 68($k0)
sw $s0 72($k0)
sw $s1 76($k0)
sw $s2 80($k0)
sw $s3 84($k0)
sw $s4 88($k0)
sw $s5 92($k0)
sw $s6 96($k0)
sw $s7 100($k0)
sw $t8 104($k0)
sw $t9 108($k0)
sw $gp 112($k0)
sw $sp 116($k0)
sw $fp 120($k0)
sw $ra 124($k0)
#

lb $t0 0xffff0004	# En el 'receiver data', en la posicion de memoria 0xffff0004, queda el codigo de la tecla presionada
beq $t0 0x73 teclaS	# Si el codigo es 0x00000073, enonces se presiono la tecla S
beq $t0 0x70 teclaP	# Si el codigo es 0x00000070, enonces se presiono la tecla P
beq $t0 0x1b teclaEsc	# Si el codigo es 0x0000001b, enonces se presiono la tecla Esc
b ret			# Cualquier otra tecla es ignorada. 

######## tecla P ##########################################################
teclaP:

lw $t0, PROG_DATA
lw $t0, ($t0)		# ID
beq $t0, 1, fisrtP

lw $t0, PROG_DATA	# Se mueve al programa anterior
addi $t0, $t0, -136
sw $t0, PROG_DATA
lw $t0, 132($t0)	# estatus del programa
beq $t0, 1, teclaP	# Si ya termino este proceso seguimos buscando el siguiente que no haya terminado.
lw $t0, PROG_DATA
lw $t0, 8($t0)		# Pseudo PC del programa a ejecutar esta en t0
mtc0 $t0, $14		# Acomodamos el EPC con nuestro pseudo PC
b CargarDatos

fisrtP:
lw $t0, LastProg	# Si aprete P en el primero, voy al ultimo
sw $t0, PROG_DATA
lw $t0, 132($t0)	# estatus del programa
beq $t0, 1, teclaP	# Si ya termino este proceso seguimos buscando el siguiente que no haya terminado.
lw $t0, PROG_DATA
lw $t0, 8($t0)		# Pseudo PC del programa a ejecutar esta en t0
mtc0 $t0, $14		# Acomodamos el EPC con nuestro pseudo PC
b CargarDatos

######## tecla S ##########################################################
teclaS:

lw $t0, PROG_DATA
lw $t0, ($t0)		# ID
lw $t1, NUM_PROGS	# N
beq $t0, $t1, lastS

lw $t0, PROG_DATA	# Avanzo al siguiente programa
addi $t0, $t0, 136
sw $t0, PROG_DATA
lw $t0, 132($t0)	# estatus del programa
beq $t0, 1, teclaS	# Si ya termino este proceso seguimos buscando el siguiente que no haya terminado.
lw $t0, PROG_DATA
lw $t0, 8($t0)		# Pseudo PC del programa a ejecutar esta en t0
mtc0 $t0, $14		# Acomodamos el EPC con nuestro pseudo PC
b CargarDatos

lastS:
lw $t0, FirstProg	# Si aprete S en el ultimo, voy al primero
sw $t0, PROG_DATA
lw $t0, 132($t0)	# estatus del programa
beq $t0, 1, teclaS	# Si ya termino este proceso seguimos buscando el siguiente que no haya terminado.
lw $t0, PROG_DATA
lw $t0, 8($t0)		# Pseudo PC del programa a ejecutar esta en t0
mtc0 $t0, $14		# Acomodamos el EPC con nuestro pseudo PC
b CargarDatos

######## tecla Esc ########################################################
teclaEsc:

la $a0 msg3 			# "La maquina..."
li $v0 4
syscall
	
lw $t0 FirstProg		# t0 iterara por los datos de los programas
lw $t1 NUM_PROGS		# t1 Numero de programas total
li $t2, 0			# t2 iterador para contar la cantidad de programas reportados

loopEsc:

	beq $t2 $t1 endEsc		# El ciclo termina cuando se reportaron todos los programas (t2 == t1)
	
	la $a0 msg4			# "El Programa.."
	li $v0 4
	syscall
		
	move $a0 $t2			# "... i..."
	li $v0 1
	syscall
	
			
	lw $t3 132($t0)			# Cargo el estatus del programa para verificar si ya finalizo.
	beq $t3 1 printEnded
	b printNotEnded
	
printEnded:
	la $a0 msg5			# "Finalizado"
	li $v0 4
	syscall
	b printNumberAdds

printNotEnded:	
	la $a0 msg6			# "No Finalizado"
	li $v0 4
	syscall
	b printNumberAdds
	
printNumberAdds:
	
	lw $t3 128($t0)			# t3 == numero de add's en el programa
	
	la $a0 msg7			# "Numero de add"
	li $v0 4
	syscall
	
	move $a0 $t3
	li $v0 1			# Imprimo la cantidad de add's en el programa
	syscall
	
	addi $t2 $t2 1			# reportados++;
	addi $t0 $t0 136		# Avanzo a los datos del siguiente programa para reportarlo.
	b loopEsc
	
endEsc: 

li $v0 10			# Señoras y Señores, se acaba el proyecto. Aplausos.
syscall

###########################################################################

##### Break Exception #####################################################
breakException:

mfc0 $a0 $14
lw $a0 ($a0)

beq $a0 0x0000040d break10 # Verifico si estoy en un break 0x10
beq $a0 0x0000080d break20 # Verifico si estoy en un break 0x20
b ret

######## Break 0x20 #######################################################
break20:

lw $a0, PROG_DATA
lw $v0, 128($a0)		# contador de add ' s
addi $v0, $v0, 1		# Incremento el contador
sw $v0, 128($a0)		# guardo el nuevo valor
b ret

######## Break 0x10 #######################################################
break10:

la $a0 msg1			# "El programa"
li $v0 4
syscall

lw $a0 PROG_DATA		
lw $a0 ($a0)			# "... i..."
li $v0 1			
syscall

la $a0 msg2			# "ha finalizado su ejecucion."
li $v0 4
syscall

lw $a0 PROG_DATA
addi $v0 $zero 1
sw $v0 132($a0)			# Marco el programa como terminado

lw $a0 N_RunningProg
addi $a0 $a0 -1
sw $a0 N_RunningProg		# Decremento la cantidad de programas ejecutadose

beqz $a0 teclaEsc	# Si ya no hay programas ejecutandose, se termina el Planificador.

b teclaS			# Busco el siguiente proceso sin terminar para continuar su ejecucion.

###########################################################################

CargarDatos:
# Cargo los datos del programa que se va a ejecutar
lw $k0, PROG_DATA		# Cargo en k0 la posicion donde estan guardados los datos.

lw $at 12($k0)
lw $v0 16($k0)
lw $v1 20($k0)
lw $a0 24($k0)
lw $a1 28($k0)
lw $a2 32($k0)
lw $a3 36($k0)
lw $t0 40($k0)
lw $t1 44($k0)
lw $t2 48($k0)
lw $t3 52($k0)
lw $t4 56($k0)
lw $t5 60($k0)
lw $t6 64($k0)
lw $t7 68($k0)
lw $s0 72($k0)
lw $s1 76($k0)
lw $s2 80($k0)
lw $s3 84($k0)
lw $s4 88($k0)
lw $s5 92($k0)
lw $s6 96($k0)
lw $s7 100($k0)
lw $t8 104($k0)
lw $t9 108($k0)
lw $gp 112($k0)
lw $sp 116($k0)
lw $fp 120($k0)
lw $ra 124($k0)
#

mfc0 $k0 $12		# Set Status register
ori  $k0 0x11		# Interrupts enabled and user mode on
mtc0 $k0 $12

li $k0 0x10
sw $k0 0xffff0000	# Permito interrupciones de teclado

# Return from exception on MIPS32:
eret
	

###########################################################################
ret:
# Return from (non-interrupt) exception. Skip offending instruction
# at EPC to avoid infinite loop.
#
	mfc0 $k0 $14		# Bump EPC register
	addiu $k0 $k0 4		# Skip faulting instruction
				# (Need to handle delayed branch case here)
	mtc0 $k0 $14


# Restore registers and reset processor state
#
	lw $v0 s1		# Restore other registers
	lw $a0 s2

	move $at $k1		# Restore $at

	mtc0 $0 $13		# Clear Cause register

	mfc0 $k0 $12		# Set Status register
	ori  $k0 0x1		# Interrupts enabled
	mtc0 $k0 $12

# Return from exception on MIPS32:
	eret



###################################################################################

	.globl __eoth
__eoth:

###################################################################################	
	.data

	
N_RunningProg:
	.word 0			# Numero de programas siendo ejecutados	

PROG_DATA:
	.word 0			# Direccion de los datos de registros del programa actual

FirstProg:
	.word 0			# Direccion de los datos del primer programa del arreglo PROGS
	
LastProg:
	.word  0		# Direccion de los datos del ultimo programa del arreglo PROGS
	
StartFirstProg:
	.word 0			# Direccion de la primera instruccion del primer programa
	
startInstrument:
	.asciiz "\nInstrumentando...\n"

endInstrumentStartPlan:
	.asciiz "Programas instrumentados.\n Ejecutando programas... \n"
	
	.globl main	

###################################################################################

########################### main ##################################################

	.text
	
main:
	
sw $zero, 0xffff0000		# Prohibo interrupciones de teclado

li $t0, 0x00
mtc0 $t0, $12			# Ignoro interrupciones  #es esto necesario?

lw $t0, NUM_PROGS		# En t0 esta la cantidad de programas.
sw $t0, N_RunningProg		# Inicialmente ningun programa ha terminado su ejecucion
mul $t0, $t0, 136		# Pido memoria dinamica para guardar los datos de cada programa.
li $v0, 9
syscall	

sw $v0 PROG_DATA		# Los datos de programa apuntados actualmente son del primer programa
sw $v0 FirstProg

#############

li $t0, 1			# Contador del programa por el que se va
la $t1, PROGS			# direccion donde esta la direccion del primer programa.
lw $t2, NUM_PROGS		# Numero de programas.
lw $t3, FirstProg		# Direccion para guardar datos del primer programa

# Comienzo a guardar los datos basicos de cada programa
loopProgData:

bgt $t0, $t2, instrAll		# Si ya guarde los datos basicos de cada programa, comienzo a instrumentar los programas.

lw $a0 ($t1)			# direccion de la primera instruccion del programa esta en a0

# Convenciones
addi $sp, $sp, -16				
sw $t0, 4($sp)
sw $t1, 8($sp)
sw $t2, 12($sp)
sw $t3, 16($sp)
###############

la $t0, LastInstruccion
jalr $t0		# En v0 queda la direccion de la ultima instruccion del programa

# Convenciones
lw $t3, 16($sp)
lw $t2, 12($sp)
lw $t1, 8($sp)
lw $t0, 4($sp)
addi $sp, $sp, 16
###############

sw $t0 ($t3)			# Guardo el indice del programa.
sw $v0 4($t3)			# Guardo la direccion de la ultima instruccion del programa
sw $a0 8($t3)			# Guardo PC del programa (inicialmente es igual a la direccion de la primera instruccion)
sw $zero, 128($t3)		# Inicializo el numero de add's en 0
sw $zero, 132($t3)		# 0 indica programa no finalizado 

sw $t3, LastProg		# Al final del ciclo en LastProg queda guardada la direccion de los datos del ultimo programa

addi $t0 $t0 1			# Incremento el indice del programa
addi $t3 $t3 136		# Apunta a donde se guardaran los datos del siguiente programa
addi $t1 $t1 4			# Avanzo al siguiente programa en PROGS (direccion de la primera instruccion de ese programa)
b loopProgData

###########################

la $a0, startInstrument 	# "Instrumentando"
li $v0, 4
syscall

la $t0, PROGS			# direccion donde esta la direccion del primer programa.
lw $t1, NUM_PROGS		# Numero de programas.

# Itero por los programas en PROGS para instrumentar cada uno.
instrAll:

lw $a0 ($t0)			# Cargo en a0 la direccion del programa a instrumentar

# Convenciones
addi $sp, $sp, -8				
sw $t0, 4($sp)
sw $t1, 8($sp)
###############

la $t0, instrumentador
jalr $t0		# Instrumento

# Convenciones
lw $t1, 8($sp)
lw $t0, 4($sp)
addi $sp, $sp, 8
###############

addi $t0, $t0, 4			# Avanzo al siguiente programa en PROGS (direccion de la primera instruccion de ese programa)
addi $t1, $t1, -1			# Decremento el contador.

lw $t2, PROG_DATA		# Actualizo PROG_DATA
addi $t2, $t2, 136		# Para que apunte a los datos del programa siguiente
sw $t2, PROG_DATA

beq $t1, 0, planificador		# Si ya instrumente todos los programas, llamo al planificador
b instrAll

###########################################################################

# Planificador, cambia entre los programas en ejecucion.

# Para cada programa tenemos la direccion de su primera instruccion en el arreglo PROGS
# Y sus datos en PROG_DATA

################## planificador() #########################################

planificador:

la $a0, endInstrumentStartPlan	# "Programas instrumentados. Ejecutando programas..."
li $v0, 4
syscall

lw $t3, FirstProg		# Direccion para guardar datos del primer programa
sw $t3 PROG_DATA		# En PROG_DATA esta la direccion de los datos del primer programa.

li $t0 0x10
sw $t0 0xffff0000		# Permito interrupciones de teclado
	
li $t0 0x11
mtc0 $t0 $12			# Enciendo modo usuario e interrupciones

# Limpio los registros que han sido usados previo a la ejecucion del primer programa 
li $v0, 0
li $a0, 0
li $t0, 0
li $t1, 0
li $t2, 0
li $t3, 0

j p1

##################################################################################################

.include "LastInst.s"
.include "instrumentador.s"
