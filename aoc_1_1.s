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
.align 4

.text
filename:     .ascii "/Users/james/github/assembly/test_input.txt"

.align 4
_start: 
// Open the file to read input
    adr x0, filename     // Filename
    mov x1, #0           // Read only
    mov x16, #5          // Open
    svc 0                // Call

    mov x19, x0          // Save file descriptor 
                         // (non-negative integer == success) to x19

// Read from file
    sub sp, sp, 0x10000  // Allocate 2^16 bits on the stack
    mov x1, sp           // Buffer address (on the stack)
    mov x2, 0x10000      // Buffer size
    mov x16, #3          // Read
    svc 0                // Call

    mov x20, x0          // Returns the amount of bytes read. Store in x20

// Close file
    mov x0, x19          // Move file descriptor back to x0
    mov x16, #6          // Close
    svc 0                // Call

// Write file contents to stdout
    mov x0, #1           // 1 = stdout
    mov x1, sp           // String to print out
    mov x2, x20          // length of string
    mov x16, #4          // write
    svc 0

// We now have our file contents in memory at sp. They are stored as ascii
// characters, so we need to convert them into numbers.
// For example, we will have something like:
// int   | 1  9  9  \n 2  0  0  \n 
// ASCII | 49 57 57 10 50 48 48 10

// To convert, we need to run through memory starting at sp, and then:
// 1. Check for a newline - If there is one, we are at the end of the number
// 2. Convert to an integer
// 3. Multiple previous total by 10
// 4. Add new number to previous total
// Repeat until you hit a newline

// So, if we are reading 199\n (from the example above), we will do:
// Previous total | New digit
// 0              | 49 -> 1
// 1 (x10 = 10)   | 57 -> 9
// 19 (x10 = 190) | 59 -> 9
// 199            | \n -> Done

// Once we have our number, we can overwrite the digit in the stack
// As our numbers will fit into a 16 bit int (=2 bytes, or ASCII chars), we
// can freely overwrite past data without accidentally altering data we
// haven't read yet

// To do this, we need to track...
    mov x9, sp           // 1. Read position in the buffer
    mov x10, sp          // 2. Write position in the buffer
    mov x11, 0           // 3. Accumulated total
    mov x12, 0           // 4. Current byte we're reading
    mov x13, sp          // 5. The end of our useful information. sp = start
    add x13, x13, x20    //     of our information. x20 contains the amount of
                         //     bytes that we read from the file.

_convert_loop_start:
    ldrb w12, [x9]        // Read value at x9 into x12 (1 byte)
    cmp x12, 10         // If   x12 == 10 (= \n)
    beq _convert_loop_newline   // Then branch to newline code
    sub x12, x12, 48     // Else sub 48 to get back to real number
    mov x14, 10          // So we can multiply by 10
    mul x11, x11, x14     // Multiply accumulated total by 10
    add x11, x11, x12    // Add new digit to accumulated total

    b _convert_loop_end  // Glorious success

_convert_loop_newline:
    str w11, [x10]       // Store x11 (accumulated total) at memory position
                         // of x10 (write position)
    add x10, x10, 2           // Increment x10 (write position) by 2 bytes
    mov x11, 0           // Reset x11 (accumulated total)

                         // Onwards to _convert_loop_end

_convert_loop_end:
    add x9, x9, 1        // Increment x9 (read position) by 1 byte
    cmp x13, x9          // Compare read position against end of buffer
    bne _convert_loop_start  // If not at end of buffer
    b _exit              // Exit if we are at the end of the buffer



_exit:
// Exit
    mov     x0, #0       // Use 0 return code
    mov     x16, #1      // Service command code 1 terminates this program
    svc     0            // Call MacOS to terminate the program

