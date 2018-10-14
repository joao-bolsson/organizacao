#********************************************************************************************
#
#	Trabalho 1 - Organização de Computadores
#
# Descrição: Programa que faz a leitura de um arquivo binário contendo instruções em 
# linguagem de máquina e imprime no console a correspondência de cada linha em 
# linguagem Assembly
#
# Autores: 
# 	João Víctor Bolsson Marques (jvmarques@inf.ufsm.br)
#
# Assembler: MARS 4.5
#********************************************************************************************
.text

# Imprime uma string que está em memória
# Parâmetros:
#	%label: endereço contendo a string a ser impressa
.macro  print(%label)
	la 	$a0, %label
	li 	$v0, 4
	syscall
.end_macro

# Imprime uma string seguida por um valor binário
# Parâmetros:
#	%label: endereço contendo a string a ser impressa
#	%value: valor inteiro
.macro 	print(%label, %value)
	print(%label)
	move 	$a0, %value
	li 	$v0, 35
	syscall
	li	$a0, '\n'
	li	$v0, 11
	syscall 
.end_macro

.globl      main
main:    
# prólogo    
            # armazenamos a variável local descritor_arquivo_binário na pilha
            addiu $sp, $sp, -4  # reservamos 4 bytes para o descritor de arquivo
# corpo do programa
            # abertura do arquivo de leitura
            la    $a0, arquivoEntrada # $a0 <- endereço da string com o nome do arquivo
            jal abra_arquivo_binario # chamamos o procedimento para abrir o arquivo binário
            # armazenamos o descritor do arquivo
            move  $t0, $sp      # $t0 <- endereço da variável local descritor_arquivo_binario
            sw    $v0, 0($t0)   # atualizamos a variável local do descritor do arquivo binário
            # Verificamos se o arquivo foi aberto com sucesso.
            # Se foi aberto corretamente, lemos as palavras e processamos, senão tratamos o erro
testa_se_arquivo_aberto:
            bgez  $v0, arquivo_aberto_com_sucesso # se $v0 >= 0, o arquivo de entrada foi aberto
            j     arquivo_nao_aberto_falha        # se $v0 < 0, o arquivo não pôde ser aberto
arquivo_aberto_com_sucesso:
leitura_palavra_arquivo_binario:
            # carregamos o descritor do arquivo
            move  $t0, $sp
            lw    $a0, 0($t0)
            jal   leia_palavra_arquivo
            # Se uma palavra foi lida, processamos, senão verificamos se o arquivo chegou ao fim ou se houve um erro de leitura
verifica_se_fim_arquivo_binario:
            beq   $v0, $zero, fim_arquivo_binario   # se $v0 = 0 chegamos ao final do arquivo
verifica_se_erro:
            li    $t0, 4                # $t0 <- número de bytes lidos
            slt   $t1, $v0, $t0         # $t1 = 1 se $v0 (número de bytes lidos) < 4
            bne   $t1, $zero, erro_leitura_arquivo # erro de leitura se o número de bytes é menor que 4
            # uma palavra com 4 bytes foi lida do arquivo de entrada. Fazemos o seu processamento.
palavra_lida_com_sucesso:
	    # vai processar cada linha do arquivo (instrução) e imprimir um separador no final
	    print(txtInstrucao, $v1)
            # leitura do opcode
            move  $a0, $v1 		# restaura a palavra lida em $a0
            lw	  $a1, maskOPCODE
            li 	  $a2, 26
            jal   isola_bits
            print(txtOPCODE, $v0)	# imprime o opcode
            print(txtSeparador)		# imprime o separador
            j     leitura_palavra_arquivo_binario # fazemos a leitura da próxima palavra do aquivo de entrada
fim_arquivo_binario:
            jal   trata_fim_arquivo_binario
            # termina o programa
            li    $a0, 0 # valor igual a 0: o programa terminou com sucesso
            j     fim_programa            
erro_leitura_arquivo:
            # trata o erro de leitura
            jal   trata_erro_leitura_arquivo
            # termina o programa
            li    $a0, 0 # valor iguala 0: o programa terminou com sucesso
            j     fim_programa
arquivo_nao_aberto_falha:
            jal   trata_erro_aquivo_nao_aberto
            li    $a0, 1 # valor diferente de 0: o programa terminou com erros
            # termina o programa
fim_programa:    
# epílogo
            addiu $sp, $sp, 4 # restaura a pilha
            li    $v0, 17 #serviço exit2 - termina o programa
            syscall
###############################################################################


#******************************************************************************
#
#			OPERAÇÕES COM O ARQUIVO E PALAVRAS
#
#******************************************************************************

abra_arquivo_binario:
# Faz a abertura do arquivo de entrada.
# Argumentos
#           $a0 : endereço da string com o nome do arquivo
# Valor de retorno:
#           $v0 : descrito do arquivo. Se ocorrer um erro na abertura do aqruivo,
#                 será retornado um valor negativo
#------------------------------------------------------------------------------
# prólogo
# corpo do programa
            li    $a1, 0    # flags: 0  - leitura
            li    $a2, 0    # modo - atualmente é ignorado pelo serviço
            #chamamos o serviço 13 para a abertura do arquivo
            li    $v0, 13
            syscall
# epílogo
            jr    $ra
###############################################################################

leia_palavra_arquivo:
# Este procedimento faz a leitura de uma palavra de um arquivo de entrada.
# Argumento:
#           $a0 : descritor do arquivo
# Valores de retorno:
#           $v0 : número de bytes lido. Se a operação de leitura for bem sucedida,
#                 este número estará no intervalo de 0 a 4. Se ocorrer uma falha,
#                 será retornado um valor negativo.
#           $v1 : a palavra lida do arquivo, se a operação de leitura foi bem sucedida.
#
#------------------------------------------------------------------------------
# prólogo
            # criamos um buffer na pilha, para receber a palavra lida do arquivo binário
            addiu  $sp, $sp, -4
# corpo do programa
            # Fazemos a leitura de uma palavra do aquivo binário. Veja o serviço 14
            # $a0 contém o descritor do arquivo
            # carregamos em $a1 o endereço do buffer de entrada
            move  $a1, $sp
            # carregamos em $a2 o número de bytes máximo a ser lido (4)
            li    $a2, 4
            # escolhemos o serviço 14
            li    $v0, 14
            # executamos o serviço 14 com uma chamada ao sistema
            syscall
            # $v0 contém o número de bytes lidos ou negativo se erro
            # vamos retornar em $v1 a palavra lida
            lw    $v1, 0($sp)
# epílogo
            addiu $sp, $sp, 4 # restauramos a pilha
            jr    $ra         # retornamos ao procedimento chamador
###############################################################################

isola_bits:
# Isola bits de acordo com a mascara passada (32 bits o target e 32 bits a mascara)
# Parâmetros:
#	$a0: palavra com os bits a serem isolados (target)
#	$a1: máscara para isolar
#	$a2: número de bits a serem deslocados para a direita
# Retorno:
#	$v0: bits isolados em 32 bits
#
# Exemplo de Funcionamento:
#
#	001000 01010010010000000011101010  (instrução)
#	111111 00000000000000000000000000  (máscara)
#
#	aplica and entre a instrução e a máscara
#
#	001000 00000000000000000000000000 (zerou todos os bits que não queremos)
#
#	shift para a direita de 26 bits
#
# 	00000000000000000000000000 001000 (opcode)
#------------------------------------------------------------------------------
# prólogo
# corpo do programa
	and 	$v0, $a0, $a1	# aplica a mascara para zerar bits que nao queremos	
	srlv 	$v0, $v0, $a2	# deslocamento de bits para a direita
# epílogo
	jr 	$ra		# retornarmos ao caller
###############################################################################

#******************************************************************************
#
#			TRATAMENTO DE ERROS
#
#******************************************************************************

trata_erro_leitura_arquivo:
# Este procedimento imprime uma mensagem de erro quando houver um erro de
# leitura do aquivo de entrada.
# Sem argumentos
# Sem valores de retorno
#------------------------------------------------------------------------------
# prólogo
# corpo do programa
            print(mensagemErroLeituraArquivo)
# epílogo
            jr    $ra # retornamos ao procedimento chamador
###############################################################################

trata_erro_aquivo_nao_aberto:
# Este procedimento imprime uma mensagem de erro quando o arquivo não pode ser aberto
# Sem argumentos
# Sem valores de retorno
#------------------------------------------------------------------------------
# prólogo
# corpo do programa
	    print(mensagemErroAberturaArquivo)
# epílogo
            jr    $ra # retornamos ao procedimento chamador
###############################################################################

trata_fim_arquivo_binario:   
# Este procedimento imprime uma mensagem, dizendo que terminamos a leitura do
# arquivo de entrada
# Sem argumentos de entrada
# Sem valores de retorno
#------------------------------------------------------------------------------
# prólogo
# corpo do programa
        print(mensagemFimLeituraArquivo)
# epílogo
        jr  $ra # retornamos ao procedimento chamador
###############################################################################

.data
# ----------------------------------------
# 	MASCARAS PARA ISOLAR BITS
# ----------------------------------------
maskOPCODE:
.word 		0xFC000000
maskRS:
.word		0x3E00000
maskRT:
.word		0x1F0000
maskRD:
.word		0xF800
maskSHAMT:
.word		0x7C0
maskFUNCT:
.word		0x3F

# ----------------------------------------
# 		MENSAGENS
# ----------------------------------------

arquivoEntrada: 
.asciiz           "/home/joao/organizacao/trabalho1/teste.bin"
mensagemErroAberturaArquivo: 
.asciiz           "Erro na abertura do arquivo de entrada.\n"
mensagemErroLeituraArquivo: 
.asciiz           "Erro na leitura do arquivo.\n"
mensagemFimLeituraArquivo: 
.asciiz           "Terminamos a leitura do arquivo binário de entrada.\n"
txtInstrucao:
.asciiz 	  "Instrução: "
txtOPCODE:
.asciiz		  "Opcode:    "
txtSeparador:
.asciiz	  	  "-------------------------------------------------\n"
.align 2
descritor_arquivo_binario: .space 4  
