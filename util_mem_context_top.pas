{   Function UTIL_MEM_CONTEXT_TOP
*
*   Returns the pointer to the top memory context.
}
module util_mem_context_top;
define util_mem_context_top;
%include 'util2.ins.pas';

function util_mem_context_top          {returns the pointer to the top memory context}
  :util_mem_context_p_t;

begin
  util_mem_context_top := addr(util_top_mem_context);
  end;
