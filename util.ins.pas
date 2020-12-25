{   Public include file to declare data types and entry points of the UTIL
*   library.
*
*   This library contains general utilities that can be implemented in
*   a system independent way.  Any system dependencies are handled in the
*   SYS library.
}
%natural_alignment;

const
  util_mem_default_pool_size_k = 32768; {default size for each memory pool}
  util_mem_default_pchunk_size_k = 2048; {default size for max chunk from pool}
  util_stack_data_size_k = 32768;      {default stack size in each stack block}
  util_stack_frame_size_mult_k = 4;    {all stack frames will be multiple of this
                                        size, **MUST** be power of 2}

  util_stack_frame_size_mask_k =       {used internally for rounding to size}
    util_stack_frame_size_mult_k - 1;

  util_subsys_k = -4;                  {Embed subsystem ID for UTIL library}
  util_stat_nomemcont_k = 1;           {unable to create new memory context}
  util_stat_nomem_k = 2;               {unable to allocate dynamic memory}

type
  util_stack_block_p_t = ^util_stack_block_t;
  util_stack_block_t = record          {stack block, these are chained to form stack}
    prev_p: util_stack_block_p_t;      {pointer to previous stack block in chain}
    next_p: util_stack_block_p_t;      {pointer to next stack block in chain}
    curr_adr: sys_int_adr_t;           {adr just after last stack frame}
    start_adr: sys_int_adr_t;          {starting address of this stack data}
    stack_len: sys_int_adr_t;          {length of allocated stack memory area}
    len_left: sys_int_adr_t;           {length left after last stack frame}
    end;

  util_stack_admin_p_t = ^util_stack_admin_t;
  util_stack_admin_t = record          {stack administration, only one per stack}
    mem_context_p: util_mem_context_p_t; {pointer to memory context}
    first_p: util_stack_block_p_t;     {pointer to first stack block in chain}
    last_p: util_stack_block_p_t;      {pointer to last stack block in chain}
    stack_len: sys_int_adr_t;          {min data size for new stack blocks}
    end;

  util_stack_handle_t =                {stack handle}
    util_stack_admin_p_t;

  util_stack_loc_p_t = ^util_stack_loc_t;
  util_stack_loc_t = record            {data about a particular stack location}
    admin_p: util_stack_admin_p_t;     {pointer to admin block for the stack}
    block_p: util_stack_block_p_t;     {pointer to block containing current adr}
    adr: sys_int_adr_t;                {machine adr of current location}
    end;

  util_stack_loc_handle_t =            {user handle to a stack location}
    util_stack_loc_t;

var (util_common)
  util_top_mem_context: util_mem_context_t := [ {global top level context}
    parent_p := nil,
    prev_sib_p := nil,
    next_sib_p := nil,
    child_p := nil,
    first_list_p := nil,
    n_in_first := util_mem_list_size_k, {init to first list filled up}
    pool_size := util_mem_default_pool_size_k,
    max_pool_chunk := util_mem_default_pchunk_size_k,
    pool_p := nil,
    pool_left := 0
    ];
{
*   Entry point declarations.
}
procedure util_mem_context_del (       {delete a memory context}
  in out  context_p: util_mem_context_p_t); {context address, returned NIL}
  extern;

function util_mem_context_err (        {check for err getting context, set STAT}
  in      mem_p: util_mem_context_p_t; {pointer returned by CONTEXT_GET}
  out     stat: sys_err_t)             {set according to error, if any}
  :boolean;                            {TRUE for error, FALSE no error}
  val_param; extern;

procedure util_mem_context_get (       {create a subordinate memory context}
  in out  parent: util_mem_context_t;  {parent context to create new context under}
  out     context_p: util_mem_context_p_t); {pointer to new memory context}
  extern;

function util_mem_context_top          {returns the pointer to the top memory context}
  :util_mem_context_p_t;
  extern;

procedure util_mem_grab (              {allocate memory under a memory context}
  in      size: sys_int_adr_t;         {size of region to allocate}
  in out  context: util_mem_context_t; {context under which to allocate memory}
  in      ind: boolean;                {TRUE if need to individually deallocate mem}
  out     adr: univ_ptr);              {start adr of new region}
  val_param; extern;

procedure util_mem_grab_align (        {allocate memory under a memory context}
  in      size: sys_int_adr_t;         {size of region to allocate}
  in      alignment: sys_int_machine_t; {alignment rule, machine adr multiple}
  in out  context: util_mem_context_t; {context under which to allocate memory}
  in      ind: boolean;                {TRUE if need to individually deallocate mem}
  out     adr: univ_ptr);              {start adr of new region}
  val_param; extern;

function util_mem_grab_err (           {check for error allocating dynamic memory}
  in      dyn_p: univ_ptr;             {pointer to new mem from alloc routine}
  in      size: sys_int_adr_t;         {size of mem attempted to allocate}
  out     stat: sys_err_t)             {set according to error, if any}
  :boolean;                            {TRUE for error, FALSE no error}
  val_param; extern;

procedure util_mem_ungrab (            {deallocate memory grabbed with UTIL_MEM_GRAB}
  in out  adr: univ_ptr;               {starting address of region to deallocate}
  in out  context: util_mem_context_t); {context under which this memory allocated}
  extern;

procedure util_stack_alloc (           {allocate stack}
  in out  parent: util_mem_context_t;  {parent memory context}
  out     stack_handle: util_stack_handle_t); {handle to new stack}
  extern;

procedure util_stack_dalloc (          {deallocate stack allocated by util_stack_alloc}
  in out  stack_handle: util_stack_handle_t); {handle to stack to be deallocated}
  extern;

procedure util_stack_last_frame (      {get start adr of last stack frame}
  in      stack_handle: util_stack_handle_t; {user handle to stack}
  in      size: sys_int_adr_t;         {SIZE of last frame when PUSHed}
  out     frame_p: univ_ptr);          {pointer to start of last stack frame}
  extern;

procedure util_stack_loc_bak (         {move stack loc handle backward one frame}
  in out  stack_loc: util_stack_loc_handle_t; {user stack location handle}
  in      size: sys_int_adr_t;         {size of frame, 0 returns current position}
  out     p: univ_ptr);                {pointer to resulting stack frame}
  extern;

procedure util_stack_loc_end (         {move stack location handle to stack end}
  in      stack_handle: util_stack_handle_t; {user handle to this stack}
  out     stack_loc: util_stack_loc_handle_t); {stack loc handle, will be set to end}
  extern;

procedure util_stack_loc_fwd (         {move stack loc handle forward one frame}
  in out  stack_loc: util_stack_loc_handle_t; {user stack location handle}
  in      size: sys_int_adr_t;         {size of frame, 0 returns current position}
  out     p: univ_ptr);                {pointer to resulting stack frame}
  extern;

procedure util_stack_loc_start (       {move stack location handle to stack start}
  in      stack_handle: util_stack_handle_t; {user handle to this stack}
  out     stack_loc: util_stack_loc_handle_t; {stack loc handle, will be set to start}
  out     p: univ_ptr);                {will point to first frame on stack}
  extern;

procedure util_stack_pop (             {pop data off of stack and release space}
  in      stack_handle: util_stack_handle_t; {user handle to stack}
  in      size: sys_int_adr_t);        {size of region to pop}
  extern;

procedure util_stack_popto (           {pop stack back to specific location}
  in      stack_handle: util_stack_handle_t; {user handle to stack}
  in      p: univ_ptr);                {pointer to last stack frame to remove}
  extern;

procedure util_stack_push (            {make space available on stack to push data}
  in      stack_handle: util_stack_handle_t; {user handle to stack}
  in      size: sys_int_adr_t;         {size of region to push}
  out     start_p: univ_ptr);          {pointer to where data starts on stack}
  extern;
