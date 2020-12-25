{   Error handling.
}
module util_err;
define util_mem_context_err;
define util_mem_grab_err;
%include 'util2.ins.pas';
{
********************************************************************************
*
*   Function UTIL_MEM_CONTEXT_ERR (MEM_P, STAT)
*
*   Check for error getting a new memory context, and set STAT accordingly.  The
*   function returns TRUE on error, FALSE otherwise.
}
function util_mem_context_err (        {check for err getting context, set STAT}
  in      mem_p: util_mem_context_p_t; {pointer returned by CONTEXT_GET}
  out     stat: sys_err_t)             {set according to error, if any}
  :boolean;                            {TRUE for error, FALSE no error}
  val_param;

begin
  util_mem_context_err := false;       {init to returning with error}

  if mem_p = nil then begin            {didn't get the memory context ?}
    sys_stat_set (util_subsys_k, util_stat_nomemcont_k, stat); {set STAT accordingly}
    return;                            {return indicating error}
    end;

  sys_error_none (stat);               {indicate no error}
  util_mem_context_err := false;
  end;
{
********************************************************************************
*
*   Function UTIL_MEM_GRAB_ERR (DYN_P, SIZE, STAT)
*
*   Check for error trying to allocate dynamic memory, and set STAT accordingly.
*   DYN_P is the pointer to the new dynamic memory, returned by one of the GRAB
*   routines.  SIZE is the size of the memory that was attempted to allocate.
*
*   The function returns TRUE on error, FALSE otherwise.
}
function util_mem_grab_err (           {check for error allocating dynamic memory}
  in      dyn_p: univ_ptr;             {pointer to new mem from alloc routine}
  in      size: sys_int_adr_t;         {size of mem attempted to allocate}
  out     stat: sys_err_t)             {set according to error, if any}
  :boolean;                            {TRUE for error, FALSE no error}
  val_param;

begin
  util_mem_grab_err := false;          {init to returning with error}

  if dyn_p = nil then begin            {didn't get the dynamic memory ?}
    sys_stat_set (util_subsys_k, util_stat_nomem_k, stat); {set STAT accordingly}
    sys_stat_parm_int (size, stat);
    return;                            {return indicating error}
    end;

  sys_error_none (stat);               {indicate no error}
  util_mem_grab_err := false;
  end;
