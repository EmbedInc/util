{   Subroutine UTIL_STACK_LOC_START (STACK_HANDLE,STACK_LOC,P)
*
*   Set the location indicated by the stack location handle, STACK_LOC to the
*   start of the stack indicated by STACK_HANDLE.  P is returned as the pointer
*   to the first stack frame on the stack.  P is returned as NIL, and STACK_HANDLE
*   will be set to invalid if no frame exists on the stack.
*
*   Stack location handles are only valid so long as the frame at or before the
*   the position they specify is not popped.
}
module util_stack_loc_start;
define util_stack_loc_start;
%include 'util2.ins.pas';

procedure util_stack_loc_start (       {move stack location handle to stack start}
  in      stack_handle: util_stack_handle_t; {user handle to this stack}
  out     stack_loc: util_stack_loc_handle_t; {stack loc handle, will be set to start}
  out     p: univ_ptr);                {will point to first frame on stack}

begin
  with
      stack_handle^: admin             {ADMIN stands for stack administration block}
      do begin

    if admin.first_p = nil then begin  {no stack frames exist on this stack ?}
      p := nil;                        {indicate we are at end of stack}
      stack_loc.admin_p := nil;        {set stack handle to invalid values}
      stack_loc.block_p := nil;
      stack_loc.adr := sys_int_adr_t(nil);
      return;
      end;                             {done handling stack is empty}

    stack_loc.admin_p := addr(admin);  {fill in location handle}
    stack_loc.block_p := admin.first_p;
    stack_loc.adr := stack_loc.block_p^.start_adr;
    p := univ_ptr(stack_loc.adr);      {pass back pointer to first stack frame}
    end;                               {done with ADMIN and LOC abbreviations}
  end;
