.set SET_TO_WRITE, 0xFFFF0100
.set WRITE_SERIAL, 0xFFFF0101
.set SET_TO_READ, 0xFFFF0102
.set READ_SERIAL, 0xFFFF0103

.globl _start
_start:
    jal main
    li a7, 93
    ecall

read_byte:
    # Returns the byte read (a0)
    li t0, 1
    li t1, SET_TO_READ
    sb t0, 0(t1) # Triggering the read
    1:
        lb t0, 0(t1)
        bnez t0, 1b # Checking if read is complete
    
    li t1, READ_SERIAL
    lb a0, 0(t1)
    ret

write_byte:
    # Takes in the byte to write (a0)
    li t0, WRITE_SERIAL
    sb a0, 0(t0)

    li t0, 1
    li t1, SET_TO_WRITE
    sb t0, 0(t1) # Triggering the write
    1:
        lb t0, 0(t1)
        bnez t0, 1b # Checking if write is complete
    ret

write_back:
    addi sp, sp, -4
    sw ra, 0(sp) # Storing ra

    1: # Reading the byte and verifying if it's \n
    jal read_byte 
    li t0, '\n'
    beq t0, a0, 2f
    jal write_byte
    j 1b

    2: # Writing \n and returning
    li a0, '\n'
    jal write_byte
    lw ra, 0(sp)
    addi sp, sp, 4 # Recovering ra
    ret

get_buffer:
    addi sp, sp, -4
    sw ra, 0(sp) # Storing ra
    la a1, buffer

    1: # Reading the byte and verifying if it's \n
    jal read_byte
    li t0, '\n'
    beq t0, a0, 2f
    sb a0, 0(a1) # Storing value in buffer
    addi a1, a1, 1
    j 1b

    2: # Writing \n and returning
    li a0, '\n'
    sb a0, 0(a1)
    lw ra, 0(sp)
    addi sp, sp, 4 # Recovering ra
    ret

write_buffer:
    # a0: buffer address
    addi sp, sp, -4
    sw ra, 0(sp)
    mv s0, a0

    1:
    lb t1, 0(s0)
    li t2, '\n'
    beq t1, t2, 2f
    addi s0, s0, 1
    mv a0, t1
    jal write_byte
    j 1b

    2:
    li a0, '\n'
    jal write_byte
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

write_reverse:
    # a0: buffer address
    addi sp, sp, -4
    sw ra, 0(sp)
    li a1, 0 # Contador
    mv a5, a0

    1: # Adding buffer to stack
        li t0, '\n'
        lb t1, 0(a5)
        beq t0, t1, reverse
        addi sp, sp, -1
        sb t1, 0(sp)   # Adicionando valor na pilha
        addi a1, a1, 1 # Adicionando contador
        addi a5, a5, 1 # Adicionando endereço
        j 1b

    reverse: # Removing buffer from stack to reverse it
    mv a5, a0
    2:
        beqz a1, 3f
        lb t1, 0(sp) # Recuperando da pilha
        addi sp, sp, 1
        sb t1, 0(a5) # Guardando de volta no buffer
        addi a1, a1, -1 # Subtraindo do contador
        addi a5, a5, 1  # Adicionando o endereço
        j 2b

    # Adding '\n' and returning
    3:
    li t0, '\n'
    sb t0, 0(a5)
    
    jal write_buffer

    lw ra, 0(sp)
    addi sp, sp, 4
    ret

atoi: # Converts string to int
    # a0: buffer address
    # outputs a0: integer
    addi sp, sp, -4
    sw ra, 0(sp)

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

itoa: # Converts int to string
    # in: value (a0), output adress (a1), base (a2)
    # out: buffer adress (a0)
    mv t0, a2
    li a2, 0
    li t5, '9'
    li t6, 1 # Negative number = False
    bltz a0, negvalue
    j 1f

    negvalue:
        neg a0, a0
        li t6, 0 # Negative number = True
        j 1f

    1:
        rem t1, a0, t0
        addi t1, t1, 48
        bgt t1, t5, hex_char
        2:
        addi sp, sp, -1
        sb t1, 0(sp) # Placing them on the stack to remove them backwards
        div a0, a0, t0
        addi t1, t1, 1
        addi a2, a2, 1
        bnez a0, 1b

    # Retrieving from stack
    li t2, 0 # Count
    mv t4, a1
    beqz t6, addsign
    j 1f

    addsign:
        li t3, '-'
        sb t3, 0(a1)
        addi a1, a1, 1
        j 1f

    1:
        lb t3, 0(sp)
        addi sp, sp, 1
        sb t3, 0(a1)
        addi a1, a1, 1
        addi t2, t2, 1
        bne t2, a2, 1b

    li t0, '\n'
    sb t0, 0(a1) # Placing \n
    mv a0, t4
    ret

    hex_char:
        addi t1, t1, 7
        j 2b


write_hex:
    # a0: buffer adress
    addi sp, sp, -8
    sw ra, 0(sp)
    sw a0, 4(sp)

    jal atoi # Integer value in a0
    lw a1, 4(sp) # Retrieving the adress
    li a2, 16

    jal itoa # Buffer with hex value
    jal write_buffer

    lw ra, 0(sp)
    addi sp, sp, 8
    ret


write_expression:
    # a0: buffer address
    # Verificar o primeiro espaço, trocar por \n e depois somar 2 para o segundo número, depois é só separar os casos
    addi sp, sp, -8
    sw ra, 0(sp)
    sw a0, 4(sp)
    mv t2, a0

    # Switching first blank space for \n 
    li t3, ' '
    1:
        lb t1, 0(t2)
        addi t2, t2, 1
        bne t1, t3, 1b

    li t0, '\n'
    addi t2, t2, -1
    sb t0, 0(t2)
    
    # Sum one to the adress to get the operator
    addi t2, t2, 1
    lb s0, 0(t2)

    # Sum two more to the address to get the position of the second value (already has \n in the end)
    addi t2, t2, 2
    mv a0, t2

    jal atoi # Getting second decimal value
    mv s2, a0 # s2: Second value 

    primeiro:

    lw a0, 4(sp) # Recovering the address
    jal atoi     # Getting first Decimal value
    mv s1, a0 # s1: First value

    segundo:

    # Now to verify what is the desired operation
    li t0, '+'
    beq s0, t0, sum
    li t0, '-'
    beq s0, t0, subtract
    li t0, '*'
    beq s0, t0, mult
    li t0, '/'
    beq s0, t0, divide

    # Making the operation
    sum:
        add a0, s1, s2
        j 1f
    subtract:
        sub a0, s1, s2
        j 1f
    mult:
        mul a0, s1, s2
        j 1f
    divide:
        div a0, s1, s2
        j 1f

    1:
    lw a1, 4(sp) # Recovering the address to output
    li a2, 10
    jal itoa # Returns buffer to a0

    jal write_buffer

    lw ra, 0(sp)
    addi sp, sp, 8 # Recovering ra

main:
    addi sp, sp, -4
    sw ra, 0(sp) # Storing ra

    jal read_byte
    mv s1, a0 # Storing a0
    jal read_byte # Throwing '\n' away
    jal get_buffer # Lendo o buffer
    mv a0, s1 # Recovering a0

    # Verifying the chosen option
    li t0, '1'
    bne a0, t0, 1f
    la a0, buffer
    jal write_buffer # Option 1 
    j end

    1:
    li t0, '2'
    bne a0, t0, 1f
    la a0, buffer
    jal write_reverse # Option 2
    j end

    1:
    li t0, '3'
    bne a0, t0, 1f
    la a0, buffer
    jal write_hex # Option 3
    j end

    1: 
    la a0, buffer
    jal write_expression # Option 4

    end:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# .bss
# buffer: .skip 100

.data
buffer: .string "-673 - -302\n"
