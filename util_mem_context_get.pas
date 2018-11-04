{   Subroutine UTIL_MEM_CONTEXT_GET (PARENT, CONTEXT_P)
*
*   Create a new subordinate memory context.  PARENT is the existing memory context
*   block to which the new one will be subordinate.  A global context block is
*   always available, called UTIL_TOP_MEM_CONTEXT.  Look in the file UTIL.INS.PAS
*   for an overview of the memory allocation and context management scheme.
*   CONTEXT_P is returned pointing to the newly created and initialized memory
*   context block.
}
module util_mem_context_get;
define util_mem_context_get;
%include 'util2.ins.pas';

procedure util_mem_context_get (       {create a subordinate memory context}
  in out  parent: util_mem_context_t;  {parent context to create new context under}
  out     context_p: util_mem_context_p_t); {pointer to new memory context}

var
  stat: sys_err_t;

begin
  sys_mem_alloc (sizeof(context_p^), context_p); {get memory for next context block}
  if context_p = nil then begin
    sys_message ('sys', 'no_mem');
    sys_bomb;
    end;
  with context_p^: c do begin          {C stands for new context block}
{
*   Initialize the new memory context.
}
    sys_thread_lock_create (c.lock, stat); {create the mult-thread lock}
    c.parent_p := addr(parent);        {link back to parent context}
    c.prev_sib_p := nil;               {this will be start of sibling chain}
    c.child_p := nil;                  {no subordinate contexts}
    c.first_list_p := nil;             {no mem blocks lists chain}
    c.n_in_first := util_mem_list_size_k; {pretend "curr" list block all used up}
    c.pool_size := parent.pool_size;   {default to parent's pool parameters}
    c.max_pool_chunk := parent.max_pool_chunk;
    c.pool_p := nil;                   {no current pool exists}
    c.pool_left := 0;                  {no room left in current pool}
{
*   Add this block as a child of the parent.
}
    sys_thread_lock_enter (parent.lock); {lock access to the parent block}

    c.next_sib_p := parent.child_p;    {point new to previous first sibling in list}
    parent.child_p := context_p;       {new is now first child in list}
    if c.next_sib_p <> nil then begin  {next sibling on chain exists ?}
      c.next_sib_p^.prev_sib_p := context_p; {back point next sib to us}
      end;

    sys_thread_lock_leave (parent.lock); {release lock on the parent block}
    end;                               {done with C abbreviation}
  end;
