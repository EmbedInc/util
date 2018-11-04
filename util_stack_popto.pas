{   Subroutine UTIL_STACK_POPTO (STACK_HANDLE,P)
*
*   Pop the stack back to a given address.  This should be one of the addresses
*   obtained from UTIL_STACK_PUSH or UTIL_STACK_LAST_FRAME.  STACK_HANDLE is the
*   user handle to this stack.  P points to the location to pop the stack to.
*   This subroutine will restore the stack to the state it had right before the
*   last call to UTIL_STACK_PUSH that returned the same stack frame address
*   as is in P.  Nothing will be done if P is NIL.  This makes it compatible
*   with UTIL_STACK_LOC_START, since it will return NIL if the stack is completely
*   empty.
}
module util_stack_popto;
define util_stack_popto;
%include 'util2.ins.pas';

procedure util_stack_popto (           {pop stack back to specific location}
  in      stack_handle: util_stack_handle_t; {user handle to stack}
  in      p: univ_ptr);                {pointer to last stack frame to remove}

var
  bl_p: util_stack_block_p_t;          {pointer to current stack block}

begin
  if p = nil then return;              {nothing to do ?}
  with stack_handle^: admin do begin   {ADMIN is stack administration block}
    bl_p := admin.last_p;              {init curr block to last in chain}
    while                              {deallocate blocks until block where P points}
        (sys_int_adr_t(p) < bl_p^.start_adr) or {before start ?}
        (sys_int_adr_t(p) > bl_p^.start_adr + bl_p^.stack_len) {after end ?}
        do begin
      admin.last_p := bl_p^.prev_p;    {make previous block the current block}
      util_mem_ungrab (                {deallocate old block}
        admin.last_p^.next_p,          {pointer to old block}
        admin.mem_context_p^);         {memory context allocated under}
      bl_p := admin.last_p;            {make pointer to new block at end of chain}
      end;                             {back and test new curr block for address}
{
*   The current end of chain block is pointed to by BL_P and is the block that
*   contains the stack frame pointed to by P.
}
    if sys_int_adr_t(p) = bl_p^.start_adr
      then begin                       {stack frame starts at start of this block}
        admin.last_p := bl_p^.prev_p;  {make previous block the current block}
        util_mem_ungrab (              {deallocate old block}
          bl_p,                        {pointer to old block}
          admin.mem_context_p^);       {memory context allocated under}
        if admin.last_p = nil
          then begin                   {no more blocks left in chain ?}
            admin.first_p := nil;      {indicate no blocks chain anymore}
            end
          else begin                   {there is at least one block left in chain}
            admin.last_p^.next_p := nil; {new current block is last in chain}
            end
          ;
        end
      else begin                       {stack frame is not at start of this block}
        bl_p^.curr_adr := sys_int_adr_t(p); {set new end of stack adr}
        bl_p^.len_left :=              {set amount of memory left in this block}
          bl_p^.start_adr + bl_p^.stack_len - sys_int_adr_t(p);
        end
      ;
    end;                               {done with ADMIN abbreviation}
  end;
