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
	    move  $t1, $v1 # preserva a palavra lida
            move  $a0, $v1 # carregamos a palavra lida
            jal   processa_palavra_lida # processamos a palavra lida do arquivo de entrada
            move  $a0, $t1 # passa a palavra lida para isolar o opcode
            jal   isola_opcode
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

processa_palavra_lida:
# Este procedimento imprime em binário uma palavra lida do arquivo de entrada binário
# Argumento
#           $a0 : palavra que será impressa
#
# Sem valores de retorno
#------------------------------------------------------------------------------
# prólogo
# corpo do programa
            # imprime a palavra lida. Usamos o serviço 35
            li    $v0, 35
            syscall
            # imprimimos uma nova  linha com o serviço 11
            li    $a0,'\n' # caracter nova linha
            li    $v0, 11
            syscall
# epílogo
            jr    $ra # retorna ao procedimento chamador
###############################################################################

isola_opcode:
# Isola 6 bits mais significativos da palavra: opcode: [31, 26]
# Argumento:
#		$a0: instrução dada
#
# Retorno:
# 	$v0: os 6 bits do opcode da instrução dada
#
# Funcionamento:
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
	lw  $t1, maskOPCODE 	# armazena em $t1 a másca para isolar os bits do opcode
	and $t2, $a0, $t1	# faz uma operação and com a instrução e a máscara
	srl $t2, $t2, 26	# deslocamento de 26 bits para a direita, isso dará o opcode em 32 bits
	
	move $a0, $t2 		# coloca o opcode como argumento para a syscall
	li $v0, 35		# imprime o opcode com o serviço 35
	syscall
	li $a0, '\n'
	li $v0, 11
	syscall 		# imprime uma nova linha
	# retorno
	move  $v0, $t2 		# retorna em $v0 o opcode
# epílogo
	jr  $ra 		# retorna para o precedimento chamador
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
            # imprimimos a mensagem do endereço mensagemErroLeituraArquivo
            # usando o serviço 4
            la    $a0, mensagemErroLeituraArquivo
            li    $v0, 4
            syscall
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
            # imprimimos a mensagem do endereço mensagemErroAberturaArquivo
            # usando o serviço 4
            la    $a0, mensagemErroAberturaArquivo
            li    $v0, 4
            syscall
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
        # imprimimos a mensagem do endereço mensagemFimLeituraArquivo 
        # usando o serviço 4
        la $a0, mensagemFimLeituraArquivo
        li $v0, 4
        syscall
# epílogo
        jr  $ra # retornamos ao procedimento chamador
###############################################################################

.data

# ----------------------------------------
# 	MASCARAS PARA ISOLAR BITS
# ----------------------------------------
maskOPCODE:
.word 		0xFC000000

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
.align 2
descritor_arquivo_binario: .space 4  
