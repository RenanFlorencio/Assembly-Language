.set CAR_GPS_TRIGGER, 0xFFFF0100
.set CAR_ENGINE, 0xFFFF0121
.set CAR_X_COD, 0xFFFF0110
.set CAR_Y_COD, 0xFFFF0114
.set CAR_Z_COD, 0xFFFF0118
.set CAR_HANDBREAK, 0xFFFF0122
.set CAR_STEERING, 0xFFFF0120

.align 4
int_handler:
    ###### Syscall and Interrupts handler ######
    # a7: syscall code

    # Store the context
    csrrw sp, mscratch, sp
    addi sp, sp, -16
    sw t0, 0(sp)
    sw t1, 4(sp)

    # Syscalls implemented:
    # 10: set_engine_steering; a0: direction, a1: steering wheel angle.
    # 11: set_handbrake; a0: 1 to use handbrake.
    # 15: get_position; a0: address of x, a1: address of y, a1: address of z.ẑ
    li t0, 10
    beq a7, t0, set_engine_steering
    li t0, 11
    beq a7, t0, set_handbrake
    li t0, 15
    beq a7, t0, get_position


    set_engine_steering:
        li t0, CAR_STEERING
        sb a1, 0(t0) # Steering the car
        li t0, CAR_ENGINE
        sb a0, 0(t0) # Setting the engine
        j 1f
    
    set_handbrake:
        li t0, CAR_HANDBREAK
        sb a0, 0(t0) # Setting the handbrake
        j 1f

    get_position:
        li t0, CAR_GPS_TRIGGER
        
        # Triggering the GPS and waiting for the read
        li t1, 1
        sb t1, 0(t0) # Lendo o GPS
        wait:
            lw t1, 0(t0)
            bnez t1, wait
        
        li t0, CAR_X_COD
        lw t1, 0(t0)
        sw t1, 0(a0)
        li t0, CAR_Y_COD
        lw t1, 0(t0)
        sw t1, 0(a1)
        li t0, CAR_Z_COD
        lw t1, 0(t0)
        sw t1, 0(a2)
        
        j 1f

    1:
    csrr t0, mepc  # load return address (address of 
                    # the instruction that invoked the syscall)
    addi t0, t0, 4 # adds 4 to the return address (to return after ecall) 
    csrw mepc, t0  # stores the return address back on mepc

    # Restore the context
    lw t0, 0(sp)
    lw t1, 4(sp)
    addi sp, sp, 16
    csrrw sp, mscratch, sp

    mret # Recover remaining context (pc <- mepc)
  

.globl _start
_start:

    la t0, int_handler  # Load the address of the routine that will handle interrupts
    csrw mtvec, t0      # (and syscalls) on the register MTVEC to set
                        # the interrupt array.

    # Initializing the stacks
    la t0, isr_stack
    csrw mscratch, t0 # ISR stack
    la sp, user_stack # User stack

    # Changing the privilege to User mode
    csrr t1, mstatus
    li t2, ~0x1800
    and t1, t1, t2
    csrw mstatus, t1    # Sets mstatus to user-mode (00 on bit 11 and 12)

    # Feeding program's addres
    la t0, user_main
    csrw mepc, t0       # Loads the user code address to mepc
    
    mret    # PC <= MEPC; mode <= MPP;


.globl control_logic
control_logic:
    # implement your control logic here, using only the defined syscalls
    
    # Acelerando o carro
    li a0, 1
    li a1, 0
    li a7, 10
    ecall

    li t0, -70
    frente:
        addi sp, sp, -4
        # Lendo a coordenada z do GPS
        li a0, 0
        li a1, 0
        mv a2, sp
        li a7, 15
        ecall

        lw a2, 0(sp)
        addi sp, sp, 4

        blt a2, t0, frente
    
    li t0, 165
    virando: 
        # Virando o carro
        li a0, 1
        li a1, -90
        li a7, 10
        ecall

        # Lendo a coordenada x do GPS
        addi sp, sp, -4
        mv a0, sp
        li a1, 0
        li a2, 0
        li a7, 15
        ecall

        lw a0, 0(sp)
        addi sp, sp, 4

        blt t0, a0, virando

    # Ajustando o volante
    li a0, 1
    li a1, 0
    li a7, 10
    ecall 

    li t0, 130
    esperando:
        # Lendo a coordenada x do GPS
        addi sp, sp, -4
        mv a0, sp
        li a1, 0
        li a2, 0
        li a7, 15
        ecall

        lw a0, 0(sp)
        addi sp, sp, 4

        blt t0, a0, esperando

    # Desligando o motor
    li a0, 0
    li a1, 0
    li a7, 10
    ecall

    # Puxando o freio de mão
    li a0, 1
    li a7, 11
    ecall

    ret

.bss
.align 4
    .skip 1024
    user_stack:
    .skip 1024
    isr_stack:

teste_x: .skip 4
teste_y: .skip 4
teste_z: .skip 4