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
    li t2, 0b1100000000000
    and t1, t1, t2
    csrw mstatus, t1    # Sets mstatus to user-mode (00 on bit 11 and 12)

    # Feeding program's addres
    la t0, user_main
    csrw mepc, t0       # Loads the user code address to mepc
    
    mret    # PC <= MEPC; mode <= MPP;

int_handler:

isr_stack:

user_stack:

user_main: