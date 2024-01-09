_start:
    jal main

read:
    li a0, 0  # file descriptor = 0 (stdin)
    li a7, 63 # syscall read (63)
    ecall
    ret

write:
    li a0, 1            # file descriptor = 1 (stdout)
    la a1, output       # buffer
    li a2, 15           # bytes
    li a7, 64           # syscall write (64)
    ecall
    ret

toBin:
    # Retorna o binário em a0
    li t1, 2
    li t3, '\n'
    lb t0, 0(a3)
    
    beq t0, t3, end_toBin # Verificando se é \n

    addi t0, t0, -48
    mul a0, a0, t1 
    add a0, a0, t0
    addi a3, a3, 1

    j toBin
    end_toBin:
        ret

num_1bits:
    # Parâmetros s0: número, s1: parity bit (1, 2, 3) 
    # Retorna a0: numero de bits 1
    # t3 será o bit que não deve ser verificado

    li t0, 1 # mask para resto da divisão por 2 e parity bit 1
    li t2, 3 # paridade max e qnt de iteracoes
    li t5, 4 # max iter
    li t6, 0 # contador
    li a0, 0
    mv a1, s0

    loop:
        beq t6, s1, pula_bit

        and a2, a1, t0 # pegando o bit menos significativo
        add a0, a0, a2
        srli a1, a1, 1
        addi t6, t6, 1
        bne t6, t5, loop

        fim: ret

        pula_bit:
            srli a1, a1, 1
            addi t6, t6, 1
            beq t6, t5, fim
            j loop

encode:
    # Parâmetros: s0 = binário; s2 = p1; s3 = p2; s4 = p3
    # Encode: p1 p2 d1 p3 d2 d3 d4

    li t0, 0b0111 # Máscara para os digitos d2 d3 d4
    li t1, 0b1000  # Máscara para d1
    and a0, s0, t0

    slli t2, s4, 3 # colocando o digito p3
    or a0, a0, t2

    and t2, s0, t1 # colocando o digito d1
    slli t2, t2, 1 
    or a0, a0, t2

    slli t2, s3, 5 # colocando o digito p2
    or a0, a0, t2

    slli t2, s2, 6 # colocando o digito p1
    or a0, a0, t2

    ret

decode:
    # Parâmetros a3: string
    # Retorno a0: numero decodificado
    mv s11, ra
    jal toBin

    li t0, 0b0000111
    li t1, 0b0010000
    li t2, 0b1 # Máscara para os p-bits

    #P-bits
    srli t3, a0, 3
    and s4, t3, t2 # P-bit 3
    srli t3, t3, 2
    and s3, t3, t2 # P-bit 2
    srli t3, t3, 1
    and s2, t3, t2 # P-bit 1
    # Digitos
    and a1, a0, t0 # Pegando d2 a d4
    and a2, a0, t1 # Pegando d1 e colocando na posição correta
    srli a2, a2, 1
    or a0, a1, a2 # Unindo os digitos

    mv ra, s11
    ret

check_error:
    # a0 = número decodificado
    # Retorna s7, o número de erros

    mv s10, ra # Guardando ra
    li t5, 0b1 # mask
    li s7, 0 # soma
    mv a1, a0

    and a4, a1, t5 # a4 = d4
    srli a1, a1, 1
    and a5, a1, t5 # a5 = d3
    srli a1, a1, 1
    and a6, a1, t5 # a6 = d2
    srli a1, a1, 1
    and a7, a1, t5 # a7 = d1

    # verificando todos os p
    mv s9, a5
    li a5, 0 # Operador neutro de xor removendo a influencia de d3
    mv a1, s2
    jal check_p
    bnez s7, retorna_erro

    mv a5, s9
    mv s9, a6
    li a6, 0 # Operador neutro de xor removendo a influencia de d2
    mv a1, s3
    jal check_p
    bnez s7, retorna_erro

    mv a6, s9
    li a7, 0 # Operador neutro de xor removendo a influencia de d1
    mv a1, s4
    jal check_p
    bnez s7, retorna_erro
    
    mv ra, s10
    ret

    check_p:
        xor t0, a1, a4
        xor t0, t0, a5
        xor t0, t0, a6
        xor t0, t0, a7
        add s7, s7, t0
        ret

    retorna_erro:
        li s7, 1
        mv ra, s10
        ret

toStr:
    # a3: endereço do vetor, a0: valor a ser impresso, a1: tamanho str
    add t2, a3, a1 # Começando a string pelo final
    li t0, '\n'
    sb t0, 0(t2) # Colocando o \n

    addi t2, t2, -1
    li t0, 2

    l1:     # Obtendo os restos
        rem a5, a0, t0
        div a0, a0, t0
        addi a5, a5, 48
        sb a5, 0(t2)
        addi a1, a1, -1
        addi t2, t2, -1
        bnez a1, l1

    ret

get_pbits:
    # a3: string
    li t0, 1 # Máscara para pegar o resto da divisão por 2
    
    mv s11, ra
    jal toBin
    mv s0, a0

    li s1, 1
    jal num_1bits
    and s2, a0, t0 # Obtendo o bit p1

    li s1, 2 
    jal num_1bits 
    and s3, a0, t0 # Obtendo o bit p2

    li s1, 3
    jal num_1bits
    and s4, a0, t0 # Obtendo o bit p3

    mv ra, s11
    ret

store_out:
    mv s11, ra
    # Armazenando Hammington
    li a1, 7
    mv a0, s5
    la a3, output
    jal toStr
    # Armazenando decodificado
    li a1, 4
    mv a0, s6
    addi a3, a3, 8
    jal toStr
    # Armazenando check error
    li a1, 1
    mv a0, s7
    addi a3, a3, 5
    jal toStr

    mv ra, s11
    ret

main:
    # Hammington code
    la a1, in1
    li a2, 5
    jal read # Passando a2 (n bytes) e a1 (endereço)
    
    la a3, in1
    jal get_pbits
    jal encode
    mv s5, a0 

    # Decode
    la a1, in2
    li a2, 8
    jal read # Passando a2 (n bytes) e a1 (endereço)
    
    la a3, in2
    jal decode
    mv s6, a0

    # Error check
    jal check_error # Retorna em s7

    # Armezenzando e printando
    jal store_out
    jal write

.bss

in1: .skip 5

in2: .skip 8

output: .skip 15 