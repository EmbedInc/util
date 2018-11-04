{   Subroutine UTIL_STACK_DALLOC (STACK_HANDLE)
*
*   Deallocate a stack allocated by UTIL_STACK_ALLOC.  STACK_HANDLE is the
*   handle to the stack that is to be deallocated.  STACK_HANDLE
*   is returned as NIL.
}
module util_stack_dalloc;
define util_stack_dalloc;
%include 'util2.ins.pas';

procedure util_stack_dalloc (          {deallocate stack allocated by util_stack_alloc}
  in out  stack_handle: util_stack_handle_t); {handle to stack to be deallocated}

var
  con_p: util_mem_context_p_t;         {pointer to top mem context for stack}

begin
  con_p := stack_handle^.mem_context_p; {get adr of top mem context for this stack}
  util_mem_context_del (con_p);        {delete all memory for stack}
  stack_handle := nil;                 {return stack handle as invalid}
  end;
