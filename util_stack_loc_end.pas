{   Subroutine UTIL_STACK_LOC_END (STACK_HANDLE,STACK_LOC)
*
*   Set the location indicated by the stack location handle, STACK_LOC to the
*   end of the stack indicated by STACK_HANDLE.
*
*   Stack location handles are only valid so long as the frames at or before the
*   the position they specify is not popped.
}
module util_stack_loc_end;
define util_stack_loc_end;
%include 'util2.ins.pas';

procedure util_stack_loc_end (         {move stack location handle to stack end}
  in      stack_handle: util_stack_handle_t; {user handle to this stack}
  out     stack_loc: util_stack_loc_handle_t); {stack loc handle, will be set to end}

begin
  with
      stack_handle^: admin             {ADMIN stands for stack administration block}
      do begin

    if admin.last_p = nil then begin   {no stack frames exist on this stack ?}
      stack_loc.admin_p := nil;        {set stack handle to invalid values}
      stack_loc.block_p := nil;
      stack_loc.adr := sys_int_adr_t(nil);
      return;
      end;                             {done handling stack is empty}

    stack_loc.admin_p := addr(admin);  {fill in location handle}
    stack_loc.block_p := admin.last_p;
    stack_loc.adr := stack_loc.block_p^.curr_adr;
    end;                               {done with ADMIN and LOC abbreviations}
  end;
