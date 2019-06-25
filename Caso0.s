#Programa:	 myprogs.s
#Autor:	 profs del taller de organizaciòn del computador
#Fecha:	11 Nov 2017

# Obs: Esto es un ejemplo de como podría ser un programa principal a
#	usarse en el proyecto.
# Para la corrida de los proyectos el grupo profesoral generara
# varios archivos con características similares
# Asegurese de crear varios casos de prueba para verificar sus
# implementaciones
		
	.data
	.globl PROGS
	.globl NUM_PROGS
	.globl QUANTUM

NUM_PROGS:	.word 1
PROGS:		.word p1
QUANTUM: 	.word 5   # En segundos (aproximadamente)
	
m1:	.asciiz "p1 "
m2:	.asciiz "p2 " 
m3:	.asciiz "p3 "
	
	.text

p1:	
	add $t0, $t0, 1
	
	li $v0 4
	la $a0 m1
	syscall
	
	add $s0, $s1, $s2
	
	li $v0 3
	li $v0 3
	li $v0 3
		
	beq $t0, 1, p1

	li $v0 3
	li $v0 3
	li $v0 3

	li $v0, 10
	syscall
	nop
	nop
	nop
	nop
	nop
	nop

	

	
	.include "myexceptions.s"
