# Recursive Tree Search #

This is the code to perform a recursive tree search on RISC-V. It looks for a single input value and returns the depth of the node which has its *VAL* corresponding to the input. If there is no such node, it returns -1.

The main concept applied here is the **storage of the ra (return address) on the program stack**, which allows the program to make multiple calls and still keep track of the return address of each recursive call.