# Syscalls to Drive a Car #

This code uses the **Car peripheral** provided by the ALE simulator and **syscalls** implements syscalls and a simple cotrol logic to drive the car.

Here, the *main.s* code is run on user mode, which means that the code must use syscalls to control the car. All this is done by **switching the user mode** before on the *_start* routine.