//
// Assembler program to run advent of code day 1 2021 and print the answer to
// stdout.
//
// System calls.....
// Place system call number in x16, and arguments in x0 through x6 from left to
// right, then call svc 0
// Exit = #1
// Read = #3
// Write = #4
// Open = #5


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
// As our numbers will fit into a 32 bit int (=4 bytes, or ASCII chars), we
// can freely overwrite past data without accidentally altering data we
// haven't read yet

// To do this, we need to track...
    mov x9, sp                  // 1. Read position in the buffer
    mov x10, sp                 // 2. Write position in the buffer
    mov x11, 0                  // 3. Accumulated total
    mov x12, 0                  // 4. Current byte we're reading
    mov x13, sp                 // 5. The end of our useful information. sp = 
    add x13, x13, x20           //    start of our information. x20 contains
    add x13, x13, x20           //    the amount of bytes that we read from
    add x13, x13, 1             //    the file.

_convert_loop_start:
    ldrb w12, [x9]              // Read value at x9 into x12 (1 byte)
    cmp x12, 10                 // If   x12 == 10 (= \n)
    beq _convert_loop_newline   // Then branch to newline code
    sub x12, x12, 48            // Else sub 48 to get back to real number
    mov x14, 10                 // So we can multiply by 10
    mul x11, x11, x14           // Multiply accumulated total by 10
    add x11, x11, x12           // Add new digit to accumulated total

    b _convert_loop_end         // Glorious success

_convert_loop_newline:
    str w11, [x10]              // Store x11 (accumulated total) at memory
                                // position of x10 (write position)
    add x10, x10, 4             // Increment x10 (write position) by 4 bytes
    mov x11, 0                  // Reset x11 (accumulated total)

                                // Onwards to _convert_loop_end

_convert_loop_end:
    add x9, x9, 1               // Increment x9 (read position) by 1 byte
    cmp x13, x9                 // Compare read position against end of buffer
    bne _convert_loop_start     // If not at end of buffer

    str w11, [x10]              // Store our last number

// Now we have all our numbers stored in memory consecutively, starting at sp.
// The numbers are all stored as 16-bit integers (ie, 2 bytes between the
// starting point of each digit)

// So, now we need to do our actual calculation. Lets loop through our
// numbers, comparing each number to the previous number - If it is greater
// than the previous number, we increment a counter by 1. Note, we don't need
// to compare the first number to anything.

// We need to track...
_processing_start:
    add x9, sp, 4               // 1. Read position in the buffer (start off
                                //    at sp + 2. This lets us avoid any issues
                                //    relating to the first number having
                                //    nothing to compare against)
    ldr w11, [sp]               // 2. Previous 16-bit number
    mov x12, 0                  // 3. Current 16-bit number
    mov x14, 0                  // 4. A counter tracking increases
    add x13, x10, 4             // 5. The end of our useful information

_count_loop_start:
    ldr w12, [x9]               // Load current number into x12 (use h12 to
                                // get 16 bits)
    cmp x12, x11                // Compare h12 and h11
    blt _count_loop_no_increment // If less than, don't increment counter

_count_loop_increment:
    add x14, x14, 1             // Increment x14 (counter) by 1

_count_loop_no_increment:
    mov x11, x12                // Move current number into previous number
    add x9, x9, 4               // Add 2 to read position
    cmp x9, x13                 // Compare current read position to end of
                                // useful info
    bne _count_loop_start       // If not yet at end of file, back to start of
                                // loop


// Now we have our answer in x14! Unfortunately it is a 32-bit integer, and we
// need to convert back to ASCII...
// So, we need to divide by 10 and get the remainder repeatedly until we get
// the answer, eg:
// 1709 / 10 = 170 | 9
// 170 / 10  = 17  | 0
// 17 / 10   = 1   | 7
// 1 / 10    = 0   | 1
// Reading backwards, we get our number in single integers. We can then add 48
// to each of these to get our ASCII characters, and then print to stdout.

// The only thing currently in registers that we care about is x14, which
// contains the answer
// We need to track...
_print_start:
    mov x9, 0                   // The remainder
    mov x10, x14                // Our remaining number
    mov x11, 0                  // A counter of number of digits
    mov x12, 10                 // To help divide by 10
    mov x13, sp                 // Write location for the characters to print
    add x13, x13, 3             // Cheating a bit - I know the output is 4
                                // digits, so this lets us start at a position
                                // on the stack and work backwards without
                                // running out of room.
    mov x15, 0                  // Helper
    mov x17, 0                  // Another helper

_print_loop_start:
    udiv x15, x10, x12          // Stores quotient in x15
    mov x17, x10                // Store original number in x17
    mov x10, x15                // Store quotient in x10
    mul x15, x15, x12           // Store quotient * 10 in x15
    sub x9, x17, x15            // Calculate remainder

    add x9, x9, 48              // Convert to ascii
    strb w9, [x13]              // Store character in memory

    add x11, x11, 1             // Add 1 to counter
    sub x13, x13, 1             // Decrease write location by 1

    cmp x10, 0                  // If quotient = 0, we are done
    bne _print_loop_start       // Else, back to our print loop

    add x11, x11, 1             // Add 1 to counter to print the final digit

_print_to_stdout:
    mov x0, #1                  // 1 = stdout
    mov x1, x13                 // String to print out
    mov x2, x11                 // length of string
    mov x16, #4                 // write
    svc 0                       // Call

_exit:
    mov     x0, #0              // Use 0 return code
    mov     x16, #1             // Exit program
    svc     0                   // Call
