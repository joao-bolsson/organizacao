#********************************************************************************************
#
#	Trabalho 2 - Organização de Computadores
#
# Descrição: Escreva um programa, em linguagem de montagem para o MIPS, que realize a multiplicação
# de dois números de 16 bits, em ponto fixo, com sinal. A multiplicação deve ser realizada com o
# algoritmo de Booth. O programa deve permitir a entrada do multiplicando e do multiplicador.
# A saída do programa deve apresentar o resultado da multiplicação
#
# Autores: 
# 	João Víctor Bolsson Marques (jvmarques@inf.ufsm.br)
#
# Assembler: MARS 4.5
#********************************************************************************************

.text

.globl      main
main:
# prologo
# corpo do programa
# epilogo
        li    $v0, 17 #serviço exit2 - termina o programa
        syscall
        
isola_bits:
# Isola bits de acordo com a mascara passada (32 bits o target e 32 bits a mascara)
# Parâmetros:
#	$a0: palavra com os bits a serem isolados (target)
#	$a1: máscara para isolar
#	$a2: número de bits a serem deslocados para a direita
# Retorno:
#	$v0: bits isolados em 32 bits
#
#------------------------------------------------------------------------------
# prólogo
# corpo do programa
	and 	$v0, $a0, $a1	# aplica a mascara para zerar bits que nao queremos	
	srlv 	$v0, $v0, $a2	# deslocamento de bits para a direita
# epílogo
	jr 	$ra		# retornarmos ao caller
###############################################################################

.data
# ----------------------------------------
# 	MASCARAS PARA ISOLAR BITS
# ----------------------------------------

	