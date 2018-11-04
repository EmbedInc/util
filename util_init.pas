{   Subroutine UTIL_INIT
*
*   Performs one-time initialization of the UTIL library.  This routine is not
*   externally declared since it should never be deliberately by applications or
*   other UTIL routines.  It is called only from STRING_CMLINE_SET.
*
*   A call to STRING_CMLINE_SET is required to be the first executable statement
*   of every top level program.  This is guaranteed by SST.  It must be done
*   manually if SST is not used.
}
module util_init;
define util_init;
define util_common;
%include 'util2.ins.pas';

procedure util_init;

var
  stat: sys_err_t;

begin
{
*   Create the thread interlock for the root memory context.  This memory
*   context is statically defined.  All the others, if any, are created
*   dynamically and can therefore be initialized at the time of creation.
}
  sys_thread_lock_create (util_top_mem_context.lock, stat);
  sys_error_abort (stat, '', '', nil, 0);
  end;
