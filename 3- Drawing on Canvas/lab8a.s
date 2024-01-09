_start:
    jal main

read:
    # Recebe o fd em a0
    la a1, file # file to write
    li a2, 262519  # size (reads only 1 byte)
    li a7, 63 # syscall read (63)
    ecall
    ret

open:
    la a0, input_file    # address for the file path
    li a1, 0             # flags (0: rdonly, 1: wronly, 2: rdwr)
    li a2, 0             # mode
    li a7, 1024          # syscall open 
    ecall
    ret

setPixel:
    # a0: pixel's x coordinate
    # a1: pixel's y coordinate
    # a2: concatenated pixel's colors: R|G|B|A
    li a7, 2200     # (syscall number)
    ecall
    ret

setCanvasSize:
    # a0: canvas width (value between 0 and 512)
    # a1: canvas height (value between 0 and 512)
    li a7, 2201      # (syscall number)
    ecall
    ret

getInfo:
    # Recebe endereço do arquivo (a0)
    # Retorna width (a0), height (a1), maxValue (a2), Início das linhas (a3)
    li t0, ' '
    li t1, 10 # '\n'
    mv t3, a0
    li a0, 0
    li a1, 0

    # Width
    width:
        lb t2, 3(t3)
        beq t2, t0, height
        beq t2, t1, height
        mul a0, a0, t1
        addi t2, t2, -'0'
        add a0, a0, t2
        addi t3, t3, 1
        j width

    # Height
    height:
        addi t3, t3, 1
    1: 
        lb t2, 3(t3)
        beq t2, t0, max
        beq t2, t1, max
        mul a1, a1, t1
        addi t2, t2, -'0'
        add a1, a1, t2
        addi t3, t3, 1
        j 1b

    # Max Value
    max:
        addi t3, t3, 1
    1: 
        lb t2, 3(t3)
        beq t2, t0, retorno
        beq t2, t1, retorno
        mul a2, a2, t1
        addi t2, t2, -'0'
        add a2, a2, t2
        addi t3, t3, 1
        j 1b

    retorno: 
    add a3, t3, 4 # Endereço da primeira linha
    ret

RGBconcat:
    # Recebe o valor do byte (a2)
    # Retorna o RGB concatenado em a2
    rgb:
    li t1, 3
    li t0, 0
    1:
        add t0, t0, a2
        slli t0, t0, 8
        addi t1, t1, -1
        bnez t1, 1b
    
    addi t0, t0, 0xFF
    mv a2, t0
    ret

printImage:
    # a0: endereço da primeira linha
    # s0: width; s1: height
    mv s10, ra
    mv t3, a0
    li a0, 0 # Posição x
    li a1, 0 # Posição y

    # Pintando as posicoes
    1:
        li a0, 0
        2: 
            lbu a2, 0(a3)
            jal RGBconcat
            jal setPixel
            addi a0, a0, 1
            addi a3, a3, 1 # Somando o endereço e a posição
            bne a0, s0, 2b
        
        addi a1, a1, 1
        bne a1, s1, 1b

    mv ra, s10
    ret

main:
    jal open
    jal read

    la a0, file
    jal getInfo
    mv s0, a0 # Width
    mv s1, a1 # Height
    mv s2, a2 # MaxValue = 255
    mv s3, a3 # Endereço da primeira linha
    jal setCanvasSize

    mv a0, s3
    jal printImage


.bss
file: .skip 200000

.data
input_file: .asciz "image.pgm"
