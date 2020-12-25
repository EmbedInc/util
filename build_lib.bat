@echo off
rem
rem   BUILD_LIB [-dbg]
rem
rem   Build the UTIL library.
rem
setlocal
call build_pasinit

call src_insall %srcdir% %libname%

call src_pas %srcdir% %libname%_err %1
call src_pas %srcdir% %libname%_init %1
call src_pas %srcdir% %libname%_mem_context_del %1
call src_pas %srcdir% %libname%_mem_context_get %1
call src_pas %srcdir% %libname%_mem_context_top %1
call src_pas %srcdir% %libname%_mem_grab %1
call src_pas %srcdir% %libname%_mem_ungrab %1
call src_pas %srcdir% %libname%_stack_alloc %1
call src_pas %srcdir% %libname%_stack_dalloc %1
call src_pas %srcdir% %libname%_stack_last_frame %1
call src_pas %srcdir% %libname%_stack_loc_bak %1
call src_pas %srcdir% %libname%_stack_loc_end %1
call src_pas %srcdir% %libname%_stack_loc_fwd %1
call src_pas %srcdir% %libname%_stack_loc_start %1
call src_pas %srcdir% %libname%_stack_pop %1
call src_pas %srcdir% %libname%_stack_popto %1
call src_pas %srcdir% %libname%_stack_push %1

call src_lib %srcdir% %libname%
call src_msg %srcdir% %libname%
