//
// Assembler program to run advent of code day 1 2021 and print the answer to
// stdout.
//
//
// System calls.....
// Place system call number in x16, and arguments in x0 through x6 from left to
// right, then call svc #0x80
// Read = #3
// Open = #5
// Write = #4




.global _start             // Provide program starting address to linker
.align 2

.text
filename:       .ascii "/Users/james/github/assembly/aoc_1_test_input.txt"
filename_t:     .ascii "/Users/james/github/assembly/test_input.txt"

_start: 
//sub sp, 0x10000         // Allocate 2^16 bits on the stack
//        mov X16, #3         // read(
//        adr X1, filename          //    file_descriptor
//        mov X2, 0x10000                   // length of string
//        svc 0

// Open the file to read input
//        mov x0, AT_FDCWD    // relative to current path
    adr x0, filename_t  // Filename
    mov x1, #0          // Read only
    mov x16, #5         // Open
    svc 0               // Call

    mov x19, x0      // Save file descriptor 
                    // (non-negative integer == success) to x19

// Read from file
    sub sp, sp, 0x10000  // Allocate 2^16 bits on the stack
    mov x1, sp           // Buffer address (on the stack)
    mov x2, 0x1000       // Buffer size
    mov x16, #3          // Read
    svc 0                // Call

    mov x20, x0          // Returns the amount of bytes left. Store in x20

// Close file
    mov x0, x19          // Move file descriptor back to x0
    mov x16, #6          // Close
    svc 0                // Call

// Write to stdout

    mov x0, #1           // 1 = stdout
    mov x1, sp           // String to print out
    mov x2, x20          // length of string
    mov x16, #4          // write
    svc 0

// Exit
    mov     x0, #0       // Use 0 return code
    mov     x16, #1      // Service command code 1 terminates this program
    svc     0            // Call MacOS to terminate the program

