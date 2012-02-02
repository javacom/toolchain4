pkg:setup
rm -f include/libkern/OSByteOrder.h
rm -f include/mach/{task,thread_act,thread_status}.h
rm -f include/mach/machine/{boolean,exception,kern_return,processor_info,rpc,thread_state,thread_status,vm_param,vm_types}.h
pkg:configure --enable-ld64 ac_cv_header_objc_objc_runtime_h=no CPPFLAGS="-I/toolchain4/sys/usr/include/c++ -I/toolchain4/sys/usr/include/c++/4.2.1/armv7-apple-darwin10" CFLAGS="-I/toolchain4/sys/usr/include"
make
pkg:install
pkg: mv /usr/bin/ld{,_classic}
pkg: ln -s ld64 /usr/bin/ld
