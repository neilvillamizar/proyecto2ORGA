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

# This is the exception handler code that the processor runs when
# an exception occurs. It only prints some information about the
# exception, but can server as a model of how to write a handler.
#
# Because we are running in the kernel, we can use $k0/$k1 without
# saving their old values.


# This is the exception vector address for MIPS32:
	.ktext 0x80000180
# Select the appropriate one for the mode in which MIPS is compiled.

	move $k1 $at		# Save $at
	
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
	bne $a0 0 ret		# 0 means exception was an interrupt
	nop

# Interrupt-specific code goes here!
# Don't skip instruction at EPC since it has not executed.


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
	
	.globl main	

###################################################################################

########################### main ##################################################

	.text
	
main:
	
sw $zero, 0xffff0000	# Prohibo interrupciones de teclado

li $t0, 0x00
mtc0 $t0, $12	# Ignoro interrupciones  #es esto necesario?

lw $t0, NUM_PROGS	# En t1 esta la cantidad de programas.

mul $t0, $t0, 136
li $v0, 9
syscall	

lw $t0 ($s0)
sw $t0 ($v0)			# La dir del primer programa queda en su pagina
sw $v0 RegActual		# La pagina actual (RegActual) es del primer programa
sw $v0 PrimeroDeTodos

move $t1 $v0			# Preparo al iterador de la estructura
move $s1 $s0			# s1 = PROGS, preparo al iterador del loopInstrumentador
lw $t2 NUM_PROGS		# Preparo al contador del main
lw $s2 NUM_PROGS		# Preparo al contador del loopInstrumentador

addi $s3 $zero 1	# Preparo al contador de numProg


# Comienzo a instrumentar y 
# armar las paginas de cada programa
#

loopLista:
addi $t1 $t1 136		# Voy a donde quedaran los registros del siguiente programa
addi $s0 $s0 4			
lw $t3 ($s0)			# dirPrograma en t3
sw $t3 ($t1)			# Guardo la direccion del programa en su pagina
sw $s3 4($t1)			# Asigno numero de programa
sw $t3 8($t1)			# Guardo PC en pagina
addi $s3 $s3 1			# Aumento numero de programa
addi $t2 $t2 -1			# Decremento el contador del main
beq $t2 1 loopInstru		# Termine de guardar cada uno en su pagina? Instrumento
b loopLista

loopInstru:
lw $a0 ($s1)			# Carga en a0 el programa a instrumentar
lw $a1 4($s1)			# Y en a1 el segundo, para finalizar ciclos

addi $sp $sp -16		# Guardo registros dependientes del llamador			
sw $s0 4($sp)
sw $s1 8($sp)
sw $s2 12($sp)

move $s0 $zero			# Necesitamos estos dos registros limpios
move $s1 $zero

jal instrumentador		# Instrumento
lw $s2 12($sp)
lw $s1 8($sp)
lw $s0 4($sp)
addi $sp $sp 16			# Recupero registros

addi $s1 $s1 4			# s1 tiene al siguiente programa
addi $s2 $s2 -1			# Decremento el contador hasta llegar a 1

lw $s3 RegActual		# Actualizo RegActual con la pagina del programa siguiente
addi $s3 $s3 136
sw $s3 RegActual

beq $s2 0 planificador		# Si ya instrumente todos, paso al planificador
b loopInstru
