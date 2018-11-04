{   Subroutine UTIL_STACK_PUSH (STACK_HANDLE,SIZE,START_P)
*
*   Make space available on stack to push data.  STACK_HANDLE is the
*   handle to the stack that is to have data pushed.  SIZE the amount of
*   data that will be pushed and START_P is a pointer to the start of
*   the newly created data area.  SIZE may be any number, but the actual amount
*   of space created will be SIZE rounded up to the nearest multiple of
*   UTIL_STACK_FRAME_SIZE_MULT_K.
}
module util_stack_push;
define util_stack_push;
%include 'util2.ins.pas';

procedure util_stack_push (            {make space available on stack to push data}
  in      stack_handle: util_stack_handle_t; {user handle to stack}
  in      size: sys_int_adr_t;         {size of region to push}
  out     start_p: univ_ptr);          {pointer to where data starts on stack}

var
  sz: sys_int_adr_t;                   {size of region we will actually allocate}
  stack_size: sys_int_adr_t;           {size of new stack data area}
  block_size: sys_int_adr_t;           {size of whole new stack block}
  block_p: util_stack_block_p_t;       {pointer to new stack block}

begin
  sz :=                                {round up to mult of stack frame chunk size}
    (size + util_stack_frame_size_mask_k) & ~util_stack_frame_size_mask_k;
  with stack_handle^: admin do begin   {ADMIN stands for stack administration block}
    if                                 {need to create a new stack block ?}
        (admin.last_p = nil) or else   {no current stack block exists ?}
        (sz > admin.last_p^.len_left)  {not enough room in current block ?}
        then begin
      stack_size := max(sz, admin.stack_len); {make size of new stack data area}
      block_size :=                    {size of whole region to allocate}
        stack_size + sizeof(block_p^);
      util_mem_grab (                  {allocate memory for new stack block}
        block_size,                    {amount of memory to allocate}
        admin.mem_context_p^,          {mem context block to allocate memory from}
        true,                          {allow individual deallocation of new block}
        block_p);                      {pointer to new stack block}
      block_p^.prev_p := admin.last_p; {save pointer to previous stack block}
      block_p^.next_p := nil;          {indicate this is last block in chain}
      block_p^.curr_adr :=             {init to start of new stack data region}
        sys_int_adr_t(block_p) + sizeof(block_p^);
      block_p^.start_adr := block_p^.curr_adr; {set starting adr for data region}
      block_p^.stack_len := stack_size; {save size of stack data region}
      block_p^.len_left := stack_size; {init to whole data region is available}
      if admin.last_p = nil
        then begin                     {new block is first block in chain}
          admin.first_p := block_p;    {save pointer to first block in chain}
          end
        else begin                     {new block is not first block in chain}
          admin.last_p^.next_p := block_p; {point previous block to new block}
          end
        ;
      admin.last_p := block_p;         {we now have new current stack block}
      end;                             {done creating new stack block}
{
*   Whether we just created it, or it was already there, the current stack block
*   is now guaranteed to have room for the new stack frame.
}
    with stack_handle^.last_p^: block do begin {BLOCK is current stack block}
      start_p :=                       {pass back pointer to new stack frame}
        univ_ptr(block.curr_adr);
      block.curr_adr :=                {update address of after last stack frame}
        block.curr_adr + sz;
      block.len_left := block.len_left - sz; {update space left in this block}
      end;                             {done with BLOCK abbreviation}
    end;                               {done with ADMIN abbreviation}
  end;
