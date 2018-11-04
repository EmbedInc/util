*** This is an obsolete routine. ***
This routine used to return the address directly after the last stack frame.
The application would then subtract the size of the data it pushed to get to
the start of the stack frame.  However, this could lead to bugs if the size was
not a multiple of four bytes, since the stack routines add padding if necessary.

The new preferred method of "popping" the last frame from the stack is to
first call UTIL_STACK_LAST_FRAME.  This returns a pointer to the last stack frame,
regardless of its size.  The frame can then be removed from the stack by calling
either UTIL_STACK_POPTO with the address of the frame, or UTIL_STACK_POP with
the size of the frame.
