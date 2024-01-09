_start:
    jal main

read:
    li a0, 0  # file descriptor = 0 (stdin)
    la a1, input_address #  buffer to write the data
    li a2, 32  # size (reads only 1 byte)
    li a7, 63 # syscall read (63)
    ecall
    ret

write:
    li a0, 1            # file descriptor = 1 (stdout)
    la a1, output       # buffer
    li a2, 12           # size
    li a7, 64           # syscall write (64)
    ecall
    ret

toDec:
    li t1, '\n'
    li t2, '-'
    li t3, ' '
    li t5, '+'
    lb t0, 0(a3)
    
    beq t0, t1, end_toDec # Verificando se é \n
    beq t0, t3, end_toDec # Verificando se é espaço
    beq t0, t2, neg # Verificando se é sinal de -
    beq t0, t5, pos # Verificando se é sinal de +
    j calcular

    # Tratando os sinais
    neg:
        li t4, 1
        addi a3, a3, 1
        j toDec

    pos:
        addi a3, a3, 1
        j toDec

    # Transformando no valor de ASCII
    calcular:
        addi t0, t0, -48
        mul a0, a0, t1
        add a0, a0, t0
        addi a3, a3, 1

    j toDec

    end_toDec:
    # Negativando caso haja sinal 
        li t1, 1
        beq t4, t1, negativar
        j retorno
        negativar: neg a0, a0
        li t4, 0
        retorno: ret

distancias:

    li t6, 3 # Velocidade da luz em m/ns * 10
    li t5, 10 # Divisor
    lw t0, 8(a4) # Ta
    lw t1, 12(a4) # Tb
    lw t2, 16(a4) # Tc
    lw t3, 20(a4) #Tr

    sub s1, t3, t0
    sub s2, t3, t1
    sub s3, t3, t2

    mul s1, s1, t6 
    div s1, s1, t5 # Da
    mul s2, s2, t6
    div s2, s2, t5 # Db
    mul s3, s3, t6
    div s3, s3, t5 # Dc

    ret

minha_posicao:
    # Parametros: s1 (Da), s2 (Db), s3 (Dc)
    # Output: x (a0), y (a1)
    li a0, 0
    li a1, 0
    
    lw t0, 4(a4) # Xc
    lw t1, 0(a4) # Yb
    mul t2, t1, t1 # Yb²
    mul t3, t0, t0 # Xc²

    li t4, 2
    mul t4, t1, t4 # 2 Yb
    li t5, 2 
    mul t5, t0, t5 # 2 Xc
    mul s1, s1, s1 # Da²
    mul s2, s2, s2 # Db²
    mul s3, s3, s3 # Dc²

        # Obtendo y pela equação
    add a1, s1, t2
    sub a1, a1, s2
    div a1, a1, t4

        # Obtendo x por equação simétrica
    add a0, s1, t3
    sub a0, a0, s3
    div a0, a0, t5

    ret

toStr:
    # a3: endereço do vetor, a0: valor a ser impresso
    li t1, 4 # Contador
    add t2, a3, t1 # Começando a string pelo final
    li t0, 10
    li t5, 0 # Sinal

    blt a0, x0, neg_sinal
    j l1

    neg_sinal:
        li t5, 1 # Negativo
        neg a0, a0

    l1:     # Obtendo os restos
        rem a5, a0, t0
        div a0, a0, t0
        addi a5, a5, 48
        sb a5, 0(t2)
        addi t1, t1, -1
        addi t2, t2, -1
        bnez t1, l1

    # Adicionando o sinal
    li s10, 43
    li t6, 1
    beq t5, t6, sinal
    j fim
    sinal:
        li s10, 45
    
    fim:
    sb s10, 0(a3)
    ret

leitura:
    mv s11, ra # Guardando o valor de ra
    l:
    li a0, 0 # Zerando o argumento a0
    jal toDec
    sw a0, 0(a4) # Fazendo a leitura
    addi a4, a4, 4
    addi a3, a3, 1
    addi s0, s0, -1
    bnez s0, l
    mv ra, s11
    ret

saida: 
    la a3, output
    mv s11, ra
    jal toStr
    # Adicionando o espaco
    addi a3, a3, 5
    li t0, ' '
    sb t0, 0(a3)
    addi a3, a3, 1

    # Escrevendo o segundo resultado
    mv a0, a1
    jal toStr

    # Colocando o \n
    li t0, '\n'
    sb t0, 5(a3)
    mv ra, s11
    ret

main:

    jal read
    li s0, 6
    la a3, input_address # Endereço da string
    la a4, posicoes
    
    jal leitura
    la a4, posicoes
    jal distancias # Obtendo as distâncias Da: s1, Db: s2, Dc: s3
    jal minha_posicao # Obtendo as posicoes
    jal saida # Escrevendo o vetor
    jal write

.bss

input_address: .skip 32  # buffer

output: .skip 12

.data

posicoes: .word 0
