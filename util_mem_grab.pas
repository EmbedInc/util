{   Module of routines for dynamically allocating memory in trees.
}
module util_mem_grab;
define util_mem_grab;
define util_mem_grab_align;
%include 'util2.ins.pas';

var
  mask_align: array[0..16] of sys_int_adr_t := [ {convert size to adr bit mask}
    ~0,                                {0}
    ~0,                                {1}
    ~1,                                {2}
    ~3,                                {3}
    ~3,                                {4}
    ~7,                                {5}
    ~7,                                {6}
    ~7,                                {7}
    ~7,                                {8}
    ~15,                               {9}
    ~15,                               {10}
    ~15,                               {11}
    ~15,                               {12}
    ~15,                               {13}
    ~15,                               {14}
    ~15,                               {15}
    ~15];                              {16}
{
********************************************************************************
*
*   Subroutine UTIL_MEM_GRAB (SIZE, CONTEXT, IND, ADR)
*
*   Same as UTIL_MEM_GRAB_ALIGN, except that alignment is always the maximum
*   alignment needed by the standard floating point or integer data types.
}
procedure util_mem_grab (              {allocate memory under a memory context}
  in      size: sys_int_adr_t;         {size of region to allocate}
  in out  context: util_mem_context_t; {context under which to allocate memory}
  in      ind: boolean;                {TRUE if need to individually deallocate mem}
  out     adr: univ_ptr);              {start adr of region, NIL for unavailable}
  val_param;

const
  sys_align = max(
    sizeof(sys_int_max_t),
    sizeof(sys_fp_max_t));

begin
  util_mem_grab_align (
    size,                              {amount of memory to grab}
    sys_align,                         {alignment required of system data types}
    context,                           {parent memory context}
    ind,                               {TRUE if need to individually deallocate mem}
    adr);                              {returned pointer to start of new memory}
  end;
{
********************************************************************************
*
*   Local subroutine ADD_MEM_BLOCK (CONTEXT, BLOCK_P)
*
*   Add the memory block pointed to by BLOCK_P to the list of dynamically
*   allocated memory blocks of the memory context CONTEXT.
}
procedure add_mem_block (              {add dynamic memory block to list}
  in out  context: util_mem_context_t; {the memory context to add to list of}
  in      block_p: univ_ptr);          {pointer to start of the memory block}
  val_param; internal;

var
  list_p: util_mem_list_p_t;           {pointer to new mem list record}

begin
  if context.n_in_first >= util_mem_list_size_k then begin {need new list block ?}
    sys_mem_alloc (sizeof(list_p^), list_p); {get memory for new list block}
    if list_p = nil then begin         {couldn't get more virtual memory ?}
      sys_message_bomb ('sys', 'no_mem', nil, 0);
      end;
    list_p^.next_p := context.first_list_p; {add new block to start of chain}
    context.first_list_p := list_p;
    context.n_in_first := 0;           {new list block is empty}
    end;                               {done creating new list block}
  context.n_in_first := context.n_in_first + 1; {one more entry in the current list}
  context.first_list_p^.list[context.n_in_first] := block_p; {add new adr to list}
  end;
{
********************************************************************************
*
*   Subroutine UTIL_MEM_GRAB_ALIGN (SIZE, ALIGNMENT, CONTEXT, IND, ADR)
*
*   Allocate a block of virtual memory under the memory context CONTEXT.
*   SIZE is the size of the block to allocate in machine address units.
*   ALIGNMENT is the minimum alignment required for the start of the new
*   memory region.  The starting address will be an integer multiple of
*   ALIGNMENT.  If IND is set to FALSE, then it will be assumed that the
*   new memory block does not need to be explicitly deallocated by itself,
*   but that it gets deallocated together with the whole context.  If IND
*   is set to TRUE, then it will be possible to deallocate this block
*   separately, at the expense of slightly more overhead, especially for
*   small blocks.  ADR is returned as the starting address of the new memory
*   block.
}
procedure util_mem_grab_align (        {allocate memory under a memory context}
  in      size: sys_int_adr_t;         {size of region to allocate}
  in      alignment: sys_int_machine_t; {alignment rule, machine adr multiple}
  in out  context: util_mem_context_t; {context under which to allocate memory}
  in      ind: boolean;                {TRUE if need to individually deallocate mem}
  out     adr: univ_ptr);              {start adr of new region}
  val_param;

var
  pool_p: univ_ptr;                    {start of pool area after alignment}
  a: sys_int_adr_t;                    {scratch address value}

label
  retry_pool, not_pool, no_mem;

begin
  sys_thread_lock_enter (context.lock); {acquire lock on the memory context}
  if ind or (size > context.max_pool_chunk) {can't allocate from our own pool ?}
    then goto not_pool;
{
*   The memory block is small enough, and does not need to be individually
*   deallocatable.  It will therefore be allocated from the memory pool for
*   this context.
}
retry_pool:
  a := sys_int_adr_t(context.pool_p) + alignment - 1; {make padded address}
  a := a & mask_align[min(alignment, 16)];
  pool_p := univ_ptr(a);               {make start address of new region}
  context.pool_left := context.pool_left - {update amount left in pool after alignment}
    (sys_int_adr_t(pool_p) - sys_int_adr_t(context.pool_p));
  context.pool_p := pool_p;            {update free area start pointer}
  if context.pool_left < size then begin {pool is out of room ?}
    sys_mem_alloc (context.pool_size, context.pool_p); {allocate new pool}
    if context.pool_p = nil then goto no_mem;
    context.pool_left := context.pool_size; {set remaining space in new pool}
    add_mem_block (context, context.pool_p); {add new block to list of dynamic blocks}
    goto retry_pool;                   {try again with the new pool}
    end;

  adr := context.pool_p;               {pass back address of new memory block}
  context.pool_p := univ_ptr(          {advance pointer to next available adr}
    sys_int_adr_t(context.pool_p) + size);
  context.pool_left := context.pool_left - size; {SIZE less space in this pool}

  sys_thread_lock_leave (context.lock); {release lock on the mem context}
  return;
{
*   The memory block can not be allocated from the local pool.  It must be
*   allocated from system memory and added to the list of memory blocks for
*   this context.
}
not_pool:
  sys_mem_alloc (size, adr);           {allocate new user memory block}
  if adr = nil then goto no_mem;       {virtual memory not available ?}
  add_mem_block (context, adr);        {add block to list in this context}

  sys_thread_lock_leave (context.lock); {release lock on the mem context}
  return;
{
*   We tried to allocate some virtual memory but failed.
}
no_mem:
  sys_thread_lock_leave (context.lock); {release lock on the mem context}
  sys_message ('sys', 'no_mem');
  sys_bomb;
  end;
