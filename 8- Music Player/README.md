# Music Player #

This program makes use of **external interruptions** and the **MIDI player** and **Timer** peripherals provided by the ALE simulator to play a song defined on the **midi-player.c**, a file that is provided by the exercise.

For this, the timer is set up to cause an interruption at every 100 ms and then a note is played. Furthermore, the code is able to switch between routines written in C and Assembly.

The core concepts in use are **interruption handling**, **integration to a code in C** and **program and ISR stacks**.