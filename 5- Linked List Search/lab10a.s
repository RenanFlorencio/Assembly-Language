.globl linked_list_search
.globl puts
.globl gets
.globl atoi
.globl itoa
.globl exit

linked_list_search:
    # a0: endereço do head node
    # a1: int
    # Retorno a0: índice do nó
    li t0, 0 # Índice do nó
    1:  
        lw t1, 0(a0) # VAL1
        lw t2, 4(a0) # VAL2
        add a2, t1, t2 # Soma
        beq a2, a1, encontrado
        lw a0, 8(a0) # Next node
        addi t0, t0, 1
        bnez a0, 1b 

    j nao_encontrado

    encontrado:
        mv a0, t0
        j fim

    nao_encontrado:
        li a0, -1
        j fim

    fim: ret


strSize: # Tamanho da string
    # a0: endereço da string
    # Retorna a0: tamanho da string
    mv t5, a0
    li a0, 0
    li t1, 0 # '\000'
    1:
        lbu a1, 0(t5)
        beq a1, t1, 2f
        addi a0, a0, 1
        addi t5, t5, 1
        j 1b
    2: ret

puts: # Imprime a string em stdout
    # a0: endereço da string

    addi sp, sp, -8
    sw ra, 0(sp) # Guardando ra
    sw a0, 4(sp) # Guardando o endereço

    jal strSize
    mv a2, a0   # Tamanho da string em a2

    lw a1, 4(sp)    # recuperando o endereço
    add t1, a1, a2  # Somando o endereço ao tamanho
    li t0, '\n'
    sw t0, 0(t1)    # Adicionando o \n
    addi a2, a2, 1  # Adicionando 1 ao tamanho pelo \n

    li a0, 1            # file descriptor = 1 (stdout)
    # a1: buffer
    # a2: size
    li a7, 64           # syscall write (64)
    ecall
    
    lw ra, 0(sp)
    addi sp, sp, 8 # Recuperando ra
    ret

gets: # Lê string do stdin
    # a0: endereço do buffer
    # Retorna a0: endereço do buffer
    addi sp, sp, -4
    sw a0, 0(sp) # Salvando o endereço inicial
    li t1, '\n'

    mv a1, a0
    1:
        addi sp, sp, -4
        sw a1, 0(sp) # Guardando o endereço atual

        li a0, 0  # file descriptor = 0 (stdin)
        # a1: buffer to write the data
        li a2, 1  # size
        li a7, 63 # syscall read (63)
        ecall
        
        lw a1, 0(sp)
        addi sp, sp, 4 # Restaurando o endereço atual
        lw t0, 0(a1)
        addi a1, a1, 1
        bne t0, t1, 1b
    
    2:
    li t1, 0
    sw t1, 0(a1)
    lw a0, 0(sp)
    addi sp, sp, 4 # Recuperando o endereço inicial
    ret

clear_whitespace:
    # a0: endereço da string
    # Retorna endereço a partir do qual terminam os whitespaces
    li t1, ' '
    1:
        lbu t0, 0(a0)
        bne t0, t1, 2f
        addi a0, a0, 1

    2: ret

atoi: # Converte string para inteiro
    # a0: endereço do buffer
    # Retorna a0: inteiro correspondente à string
    addi sp, sp, -4
    sw ra, 0(sp)

    jal clear_whitespace

    mv a3, a0
    li a0, 0
    li t1, 10 # '\n'
    li t2, '-'
    
    1:
    lb t0, 0(a3)

    beq t0, t1, end_atoi # Verificando se é \n
    beq t0, t2, neg # Verificando se tem sinal negativo
    j continue

    neg:
        li t4, 1 # Dizendo que tem sinal negativo
        addi a3, a3, 1
        j 1b

    continue:
    addi t0, t0, -48
    mul a0, a0, t1 
    add a0, a0, t0
    addi a3, a3, 1
    j 1b
    
    end_atoi:
    lw ra, 0(sp)
    addi sp, sp, 4 # Recupeando ra
    li t0, 1
    beq t4, t0, negativar
    ret

    negativar: neg a0, a0
    ret


itoa: # Converte inteiro para string
    # in: Valor a ser transformado (a0), endereco de saida (a1), base (a2)
    # out: Endereço do vetor (a0)
    blt a0, zero, menos_um

    mv t0, a2
    li a2, 0
    li t5, '9'
    1:
        rem t1, a0, t0
        addi t1, t1, 48
        bgt t1, t5, hex_char
        2:
        addi sp, sp, -1
        sb t1, 0(sp) # Armazenando na stack para remover ao contrário
        div a0, a0, t0
        addi t1, t1, 1
        addi a2, a2, 1
        bnez a0, 1b

    # Removendo do stack pointer
    li t2, 0 # Contador
    mv t4, a1
    1:
        lb t3, 0(sp)
        addi sp, sp, 1
        sb t3, 0(a1)
        addi a1, a1, 1
        addi t2, t2, 1
        bne t2, a2, 1b

    li t0, 0
    sb t0, 0(a1) # Colocando o \000
    mv a0, t4
    ret

    hex_char:
        addi t1, t1, 7
        j 2b

    menos_um:
        li t0, '-'
        sb t0, 0(a1)
        li t0, '1'
        sb t0, 1(a1)
        li t0, 0
        sb t0, 2(a1)
        mv a0, a1
        ret

exit:
    li a7, 93
    ecall
