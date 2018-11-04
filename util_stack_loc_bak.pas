{   Subroutine UTIL_STACK_LOC_BAK (STACK_LOC,SIZE,P)
*
*   Move one stack frame backwards.  STACK_LOC is the user handle to a stack
*   position.  It will be updated to the new position.  P will be returned pointing
*   to the start of the new stack frame.  P will be returned NIL if backing up
*   past the start of the stack.
}
module util_stack_loc_bak;
define util_stack_loc_bak;
%include 'util2.ins.pas';

procedure util_stack_loc_bak (         {move stack loc handle backward one frame}
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
    stack_loc.adr := stack_loc.adr - sz; {make prev adr, assuming normal case}
    if stack_loc.adr < block.start_adr then begin {new stack frame is in previous block ?}
      if block.prev_p = nil
        then begin                     {old block was first in chain ?}
          p := nil;                    {pass back invalid address}
          stack_loc.adr := stack_loc.adr + sz; {restore old position handle state}
          return;
          end
        else begin                     {old block was not first in chain}
          stack_loc.block_p := block.prev_p; {make previous block the current block}
          stack_loc.adr := stack_loc.block_p^.curr_adr - sz; {adr of last frame in new block}
          end
        ;
      end;                             {done handling before start of current block}
    p := univ_ptr(stack_loc.adr);      {pass back address of new stack frame}
    end;                               {done with LOC and BLOCK abbreviations}
  end;
