module util_mem_context_del;
define util_mem_context_del;
%include 'util2.ins.pas';
{
********************************************************************************
*
*   Local subroutine CONTEXT_DEALLOC (C)
*
*   Deallocate all the dynamic memory in the tree of the memory context C.  This
*   routine calls itself recursively.  C itself is not deallocated.
}
procedure context_dealloc (            {deallocate memory under the context C}
  in out  c: util_mem_context_t);      {root of tree to deallocate memory of}
  val_param; internal;

var
  con_p: util_mem_context_p_t;         {pointer to curr context block to deallocate}
  new_con_p: util_mem_context_p_t;     {pointer to next context block to deallocate}
  list_p: util_mem_list_p_t;           {pointer to current mem blocks list record}
  n: sys_int_machine_t;                {number of mem blocks in current list record}
  new_list_p: util_mem_list_p_t;       {pointer to next mem blocks list in chain}
  stat: sys_err_t;

begin
  sys_thread_lock_delete (c.lock, stat); {delete the single thread interlock}
{
*   Deallocate all the subordinate contexts.
}
  con_p := c.child_p;                  {init pointer to current subordinate context}
  while con_p <> nil do begin          {once for each directly subordinate context}
    new_con_p := con_p^.next_sib_p;    {save adr of next context at same level}
    context_dealloc (con_p^);          {deallocate memory in this tree}
    sys_mem_dealloc (con_p);           {deallocate the top of this tree}
    con_p := new_con_p;                {make next context the current context}
    end;                               {back and delete new current context}
{
*   Deallocate all the memory blocks that were directly allocated at this
*   context.
}
  list_p := c.first_list_p;            {init pointer to current list record}
  n := c.n_in_first;                   {init number mem blocks in initial record}
  while list_p <> nil do begin         {keep going until processed all list records}
    while n > 0 do begin               {once for each memory block in this list}
      sys_mem_dealloc (list_p^.list[n]); {deallocate this mem block}
      n := n - 1;                      {one less memory block left to go}
      end;                             {back for next mem block in list}
    new_list_p := list_p^.next_p;      {save address of next list record in chain}
    sys_mem_dealloc (list_p);          {deallocate this list record itself}
    list_p := new_list_p;              {make the next list record current}
    n := util_mem_list_size_k;         {set number of mem blocks in new list record}
    end;                               {back and process this new list record}
  end;
{
********************************************************************************
*
*   Subroutine UTIL_MEM_CONTEXT_DEL (CONTEXT_P)
*
*   Delete the memory context pointed to by CONTEXT_P.  All memory and other
*   contexts that are subordinate to it are also deallocated.  CONTEXT_P is
*   returned NIL.
}
procedure util_mem_context_del (       {delete a memory context}
  in out  context_p: util_mem_context_p_t); {context address, returned NIL}

begin
  with context_p^: c do begin          {C is abbrev for context block}
{
*   Unlink this block from its sibling chain.
}
  sys_thread_lock_enter (c.lock);      {lock access to this block}
  if c.parent_p = nil then begin       {this is top block or already unlinked from system ?}
    sys_thread_lock_leave (c.lock);
    return;
    end;
  sys_thread_lock_enter (c.parent_p^.lock); {lock access to parent block}

  if c.prev_sib_p = nil
    then begin                         {first block in chain}
      c.parent_p^.child_p := c.next_sib_p;
      end
    else begin                         {not first block in chain}
      c.prev_sib_p^.next_sib_p := c.next_sib_p;
      end
    ;
  if c.next_sib_p <> nil then begin    {there is a following block in the chain ?}
    c.next_sib_p^.prev_sib_p := c.prev_sib_p;
    end;

  sys_thread_lock_leave (c.parent_p^.lock); {done with parent block}
  c.parent_p := nil;                   {this block no longer has a parent}
  sys_thread_lock_leave (c.lock);      {release lock on this block}
{
*   This block has been unlinked from the rest of the system.  It is a isolated
*   tree that nobody else should be trying to access since it is being deleted.
*   If a thread is trying to allocate or deallocate memory in a tree another
*   thread is trying to delete, then that is a bug at a higher level we can't
*   address here.  Therefore, thread interlocks will no longer be held while
*   trying to delete this tree.
}
  context_dealloc (c);                 {recursively deallocate memory of this tree}
  end;                                 {done with C abbreviation}

  sys_mem_dealloc (context_p);         {deallocate this context block itself}
  end;
