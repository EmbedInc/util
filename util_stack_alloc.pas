{   Subroutine UTIL_STACK_ALLOC (PARENT,STACK_HANDLE)
*
*   Allocate a new stack.  PARENT is the existing memory context block
*   to which the new stack memory context will be subordinate.  It is permissible
*   to use UTIL_TOP_MEM_CONTEXT for PARENT.  STACK_HANDLE is a
*   handle to the new stack.  The UTIL_STACK_xxx routines create the illusion of
*   a continuous, infinite, stack, although it will actually be fragmented
*   into blocks.  Whenever a new block is allocated, the size of the stack data
*   area will be STACK_HANDLE^.STACK_LEN.  This will be initialized to
*   UTIL_STACK_DATA_SIZE_K, but can be changed by the application program at
*   any time.
}
module util_stack_alloc;
define util_stack_alloc;
%include 'util2.ins.pas';

procedure util_stack_alloc (           {allocate stack}
  in out  parent: util_mem_context_t;  {pointer to parent memory context}
  out     stack_handle: util_stack_handle_t); {handle of new stack}

var
  context_p: util_mem_context_p_t;     {pointer to stack memory context}

begin
  util_mem_context_get (               {get stack memory context}
    parent,                            {parent context to create stack context under}
    context_p);                        {pointer to stack memory context}
  util_mem_grab (                      {grab memory for stack admin}
    sizeof(util_stack_admin_t),        {size of memory to grab}
    context_p^,                        {context to create stack admin and block(s) under}
    true,                              {allow individual deallocation}
    stack_handle);                     {handle to stack}
  stack_handle^.mem_context_p := context_p; {save pointer to memory context}
  stack_handle^.first_p := nil;        {init to no current blocks chain}
  stack_handle^.last_p := nil;         {init to no current stack block}
  stack_handle^.stack_len := util_stack_data_size_k; {init length of next stack}
  end;
