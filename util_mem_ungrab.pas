{   Subroutine UTIL_MEM_UNGRAB (ADR, CONTEXT)
*
*   Deallocate a block of memory that was previously allocated under the given
*   context.  ADR is the starting address of the memory region.  The memory must
*   have been allocated using UTIL_MEM_GRAB with the IND argument set to TRUE for
*   it to be deallocatable with this routine.  Otherwise, it is only deallocated
*   when the whole context is deleted.
}
module util_mem_ungrab;
define util_mem_ungrab;
%include 'util2.ins.pas';

procedure util_mem_ungrab (            {deallocate memory grabbed with UTIL_MEM_GRAB}
  in out  adr: univ_ptr;               {starting address of region to deallocate}
  in out  context: util_mem_context_t); {context under which this memory allocated}

var
  list_p: util_mem_list_p_t;           {pointer to list record for this mem block}
  n: sys_int_machine_t;                {number of entries in curr list record}

begin
  sys_thread_lock_enter (context.lock); {acquire exclusive access to the mem context}

  list_p := context.first_list_p;      {init first list record to current}
  n := context.n_in_first;             {init number of entries this list record}
  while list_p <> nil do begin         {keep looking until end of lists chain}
    while n > 0 do begin               {once for each list entry in this record}
      if list_p^.list[n] = adr then begin {found list entry for mem block ?}
        list_p^.list[n] :=             {copy last mem block to new empty slot}
          context.first_list_p^.list[context.n_in_first];
        context.n_in_first := context.n_in_first - 1; {one fewer list entry}
        if context.n_in_first <= 0 then begin {first list record now empty ?}
          list_p := context.first_list_p; {save adr of empty list record}
          context.first_list_p := list_p^.next_p; {unchain empty list record}
          context.n_in_first := util_mem_list_size_k; {update to number in prev. block}
          sys_mem_dealloc (list_p);    {deallocate empty list record}
          end;
        sys_mem_dealloc (adr);         {deallocate memory block}
        sys_thread_lock_leave (context.lock); {release lock on mem context}
        return;
        end;                           {done handling found right list entry}
      n := n - 1;                      {one less entry left in curr list record}
      end;                             {back and try next list entry}
    n := util_mem_list_size_k;         {reset to how many entries in next block}
    list_p := list_p^.next_p;          {make next list record in chain current}
    end;                               {back and try this new list record}

  sys_thread_lock_leave (context.lock); {release lock on mem context}
  sys_message ('util', 'not_find_block');
  sys_bomb;
  end;
