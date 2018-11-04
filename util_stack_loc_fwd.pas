{   Subroutine UTIL_STACK_LOC_FWD (STACK_LOC,SIZE,P)
*
*   Move one stack frame forwards.  The STACK_LOC is the user handle to a stack
*   position.  It will be updated to the new position.  P will be returned pointing
*   to the start of the new stack frame.  P will be returned NIL if the end of
*   the stack is reached.
}
module util_stack_loc_fwd;
define util_stack_loc_fwd;
%include 'util2.ins.pas';

procedure util_stack_loc_fwd (         {move stack loc handle forward one frame}
  in out  stack_loc: util_stack_loc_handle_t; {user stack location handle}
  in      size: sys_int_adr_t;         {size of frame, 0 returns current position}
  out     p: univ_ptr);                {pointer to resulting stack frame}

var
  sz: sys_int_adr_t;                   {size of region we will actually allocate}

begin
  sz :=                                {round up to mult of stack frame chunk size}
    (size + util_stack_frame_size_mask_k) & ~util_stack_frame_size_mask_k;
  with
      stack_loc.block_p^: block        {BLOCK is stack block of old position}
      do begin
    stack_loc.adr := stack_loc.adr + sz; {make next adr, assuming normal case}
    if stack_loc.adr >= block.curr_adr then begin {new stack frame is in next block ?}
      if block.next_p = nil
        then begin                     {old block was last block in chain}
          p := nil;                    {return end of stack indication}
          stack_loc.adr := stack_loc.adr - sz; {restore old position handle state}
          return;
          end
        else begin                     {old block was not last in chain}
          stack_loc.block_p := block.next_p; {switch curr block to next block in chain}
          stack_loc.adr := stack_loc.block_p^.start_adr; {set to first data in new block}
          end
        ;
      end;                             {done handling past end of current block}
    p := univ_ptr(stack_loc.adr);      {pass back address of new stack frame}
    end;                               {done with LOC and BLOCK abbreviations}
  end;
