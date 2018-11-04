{   Subroutine UTIL_STACK_POP (STACK_HANDLE,SIZE)
*
*   Pop space on stack after application is through with data.  STACK_HANDLE is the
*   handle to the stack that is to have data popped.  SIZE is the amount of
*   data that will be popped off of stack.
*
*   NOTE:  Sizes should be popped in the reverse order they were pushed.
*          This routine does not check for this and thus if done incorrectly,
*          memory not on the stack maybe scribbled on.
*
}
module util_stack_pop;
define util_stack_pop;
%include 'util2.ins.pas';

procedure util_stack_pop (             {pop data off of stack and release space}
  in      stack_handle: util_stack_handle_t; {user handle to stack}
  in      size: sys_int_adr_t);        {size of region to pop}

var
  sz: sys_int_adr_t;                   {size of region we will actually allocate}
  b_p: util_stack_block_p_t;           {points to block to remove}

begin
  sz :=                                {round up to mult of stack frame chunk size}
    (size + util_stack_frame_size_mask_k) & ~util_stack_frame_size_mask_k;
  with stack_handle^.last_p^: block do begin {BLOCK is current stack block}
    block.curr_adr := block.curr_adr - sz; {back up stack pointer over popped frame}
    block.len_left := block.len_left + sz; {update space left in this block}

    if block.curr_adr <= block.start_adr then begin {curr block now empty ?}
      with stack_handle^: admin do begin {ADMIN is administration block}
        b_p := admin.last_p;           {save pointer to block to get rid of}
        admin.last_p := block.prev_p;  {make previous block current}
        util_mem_ungrab (              {deallocate old block}
          b_p,                         {pointer to old stack block to deallocate}
          admin.mem_context_p^);       {memory context block for this stack}
        if admin.last_p = nil
          then begin                   {block chain is now empty}
            admin.first_p := nil;
            end
          else begin                   {block chain is not empty}
            admin.last_p^.next_p := nil;
            end
          ;
        end;                           {done with ADMIN abbreviation}
      end;                             {done handling old block became empty}

    end;                               {done with BLOCK abbreviation}
  end;
