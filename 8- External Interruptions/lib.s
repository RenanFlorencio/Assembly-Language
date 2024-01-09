.set GPT_ADDRESS, 0xFFFF0108
.set MIDI_SYNTH, 0xFFFF0300

.globl _start

_start:

    la a0, _system_time
    lw t0, 0(a0)

    # Enable interruptions
    li t0, 0x8
    csrs mstatus, t0

    # Enable external interruptions
    li t0, 0b100000000000 
    csrs mie, t0

    # Set interrupts
    la t0, GPT_IHANDLER
    csrw mtvec, t0

    # Starting the GPT interrupt
    li t0, GPT_ADDRESS
    li t1, 100
    sw t1, 0(t0) # Configuring GPT to interrupt after 100 ms
    lw t1, 0(t0)

    jal main


GPT_IHANDLER:
    .align 2
    # Saving programs context
    csrrw sp, mscratch, sp
    addi sp, sp, -16
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw a0, 8(sp)
    sw a1, 12(sp)

    # HANDLING EXECEPTION
    # Increment global time counter 
    li t0, GPT_ADDRESS 
    li t1, 100 # Time since last interruption
    la a1, _system_time
    lw a0, 0(a1)
    add a0, a0, t1 # Adding 100 ms to the timer
    sw a0, 0(a1)
    sw t1, 0(t0)

    # Restoring program context
    lw t0, 0(sp)
    lw t1, 4(sp)
    lw a0, 8(sp)
    lw a1, 12(sp)
    addi sp, sp, 16
    csrrw sp, mscratch, sp
    
    mret

.globl play_note
play_note:
    # void play_note(a0: int ch, a1: int inst, a2: int note, a3: int vel, a4: int dur)
    # a0. ch: channel
    # a1. inst: instrument ID
    # a2. note: musical note
    # a3. vel: note velocity
    # a4. dur: note duration
    li t0, MIDI_SYNTH
    
    addi t1, t0, 2
    sh a1, 0(t1) # Instrument ID

    addi t1, t0, 4
    sb a2, 0(t1) # Note

    addi t1, t0, 5
    sb a3, 0(t1) # Velocity

    addi t1, t0, 6
    sh a4, 0(t1) # Note duration

    sb a0, 0(t0) # Play in channel a0
    ret


.data
.globl _system_time
_system_time: .word 0