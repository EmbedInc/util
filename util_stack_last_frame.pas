{   Subroutine UTIL_STACK_LAST_FRAME (STACK_HANDLE,SIZE,FRAME_P)
*
*   Return FRAME_P to point to the start of the last stack frame pushed onto
*   the stack.  STACK_HANDLE is the user handle for this stack.  SIZE **MUST**
*   be the same as the SIZE argument to UTIL_STACK_PUSH when the
*   frame was created.  This is not checked, but can cause memory corruption
*   when not correct.
}
module util_stack_last_frame;
define util_stack_last_frame;
%include 'util2.ins.pas';

procedure util_stack_last_frame (      {get start adr of last stack frame}
  in      stack_handle: util_stack_handle_t; {user handle to stack}
  in      size: sys_int_adr_t;         {SIZE of last frame when PUSHed}
  out     frame_p: univ_ptr);          {pointer to start of last stack frame}

var
  sz: sys_int_adr_t;                   {size of region we will actually allocate}

begin
  sz :=                                {round up to mult of stack frame chunk size}
    (size + util_stack_frame_size_mask_k) & ~util_stack_frame_size_mask_k;
  with stack_handle^.last_p^: block do begin {BLOCK is current stack block}
    frame_p := univ_ptr(block.curr_adr - sz); {pass back frame start address}
    end;                               {done with BLOCK abbreviation}
  end;
