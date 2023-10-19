//
//  smbus.s
//  overclock
//
//  Created by Mikhail Krasnorutskiy on 7/10/23.
//

#ifdef __i386__
    
#if 1

#define PERFORM_IN inb    %dx, %al
#define PERFORM_IN_NO_LOGS inb    %dx, %al
#define PERFORM_OUT outb    %al, %dx

#else

#define PERFORM_IN inb    %dx, %al;\
pushl    %ecx;\
movl    _pValues,%ecx;\
movl    %eax,0x00(%ecx);\
movl    %edx,0x04(%ecx);\
addl    $0x0c,%ecx;\
movl    %ecx,_pValues;\
popl    %ecx;

#define PERFORM_IN_NO_LOGS inb    %dx, %al

#define PERFORM_OUT outb    %al, %dx;\
pushl    %ecx;\
movl    _pValues,%ecx;\
movl    %eax,0x00(%ecx);\
movl    %edx,0x04(%ecx);\
movl    %edx,0x08(%ecx);\
addl    $0x0c,%ecx;\
movl    %ecx,_pValues;\
popl    %ecx

#endif

.globl _do_read
.globl _do_overclock


_SMBus_start_session:
pushl    %ebp
movl    $0x3000, %edx
movl    %esp, %ebp
PERFORM_IN
movl    %eax, %ecx
PERFORM_IN
testb    %cl, %cl
movl    %eax, %edx
leave
sete    %cl
xorl    %eax, %eax
cmpb    $0x40, %dl
sete    %al
andl    %ecx, %eax
retl


_SMBus_end_session:
movl    $0x3000, %ecx
xorl    %eax, %eax
pushl    %ebp
movl    %esp, %ebp
leal    0xd(%ecx), %edx
movzwl    %dx, %edx
PERFORM_OUT
movl    $0x40, %eax
movzwl    %cx, %edx
PERFORM_OUT
leave
movl    $0xffffffff, %eax
retl


_SMBus_readBytes:
pushl    %ebp
movl    %esp, %ebp
pushl    %edi
pushl    %esi
pushl    %ebx
    
movl    $0x3000, %ecx
movl    $0xffffffd2, %eax
    
leal    0x4(%ecx), %edx
movzwl    %dx, %edx
PERFORM_OUT
    
xorl    %ebx, %ebx
leal    0xd(%ecx), %edx
movl    %ebx, %eax
movzwl    %dx, %edx
PERFORM_OUT
    
leal    0x3(%ecx), %eax
movzwl    %ax, %edx
movl    %ebx, %eax
PERFORM_OUT
    
movl    $0x44, %eax
calll    _SMBus_runCommand
    
movl    $0x3000, %ecx
movl    $0xffffffd3, %eax
    
leal    0x4(%ecx), %edx
movzwl    %dx, %edx
PERFORM_OUT
    
leal    0xd(%ecx), %edx
movl    $0x2, %eax
movzwl    %dx, %edx
PERFORM_OUT
    
leal    0x3(%ecx), %eax
movzwl    %ax, %edx
movl    %ebx, %eax
PERFORM_OUT
    
movl    $0x54, %eax
calll    _SMBus_runCommand
    
movl    $0x3000, %ecx
leal    0x2(%ecx), %eax
movzwl    %ax, %eax
movl    %eax, %edx
PERFORM_IN
    
leal    0x5(%ecx), %edx
movzwl    %dx, %edx
PERFORM_IN
    
movsbl    %al, %esi
movl    %eax, %edi
    
movl    _pBytesRead,%ecx
movl    %esi,0x00(%ecx)
    
20:;//loc_28b
movl    $0x3000, %edx
addl    $0x7, %edx
movzwl    %dx, %edx
PERFORM_IN
    
movl    _pBytesFromChip, %edx
movzbl    %al, %eax
movb    %al, (%ebx,%edx)
incl    %ebx
    
9:;//loc_2b3
movl    %edi, %eax
cmpb    %bl, %al
jg    20b//->loc_28b
    
10:;//loc_2b3
popl    %ebx
popl    %esi
popl    %edi
leave
retl


_SMBus_writeBytes:
pushl    %ebp
movl    %esp, %ebp
pushl    %edi
movl    %eax, %edi
pushl    %esi
movl    %ecx, %esi
pushl    %ebx
movl    $0xffffffd2, %ecx
subl    $0x4, %esp
movl    $0x3000, %ebx
movl    %ecx, %eax
movb    %dl, -0xd(%ebp)
addl    $0x4, %ebx
movzwl    %bx, %ebx
movl    %ebx, %edx
PERFORM_OUT
movl    $0x3000, %ebx
movl    $0x2, %ecx
movl    %ecx, %eax
addl    $0xd, %ebx
movzwl    %bx, %ebx
movl    %ebx, %edx
PERFORM_OUT
movl    $0x3000, %edx
movzbl    -0xd(%ebp), %ecx
addl    $0x3, %edx
movzwl    %dx, %edx
movl    %ecx, %eax
PERFORM_OUT
movl    %esi, %edx
movzbl    %dl, %ecx
movl    $0x3000, %edx
movl    %ecx, %eax
addl    $0x5, %edx
movzwl    %dx, %edx
PERFORM_OUT
movl    $0x3000, %edx
addl    $0x2, %edx
movzwl    %dx, %edx
PERFORM_IN
movl    $0x3000, %eax
xorl    %ebx, %ebx
addl    $0x7, %eax
movzwl    %ax, %ecx
jmp    13f//->loc_361
    
12:;//loc_359
movzbl    (%ebx,%edi), %eax
movl    %ecx, %edx
PERFORM_OUT
incl    %ebx
movl    %esi, %eax
    
13:;//loc_361
cmpb    %bl, %al
jg    12b//->loc_359
    
addl    $0x4, %esp
movl    $0x54, %eax
popl    %ebx
popl    %esi
popl    %edi
leave
jmp    _SMBus_runCommand


_SMBus_runCommand:
pushl    %ebp
movzbl    %al, %eax
movl    %esp, %ebp
pushl    %ebx
subl    $0x14, %esp
    
movl    $0x3000, %ecx
leal    0x2(%ecx), %edx
movzwl    %dx, %edx
PERFORM_OUT
    
xorl    %ebx, %ebx
jmp    3f//->loc_1a3
    
1:;//loc_188:
movl $0x3e8,(%esp)
calll    _delay
cmpl    $0x3e8, %ebx
je    4f//->loc_1b6:
    
2:;//loc_19c:
movl    $0x3000, %ecx
incl    %ebx
    
3:;//loc_1a3:
movl    %ecx, %edx
PERFORM_IN_NO_LOGS
testb    $0x3e, %al
je    1b//->loc_188://MISHA
    
PERFORM_IN
testb    $0x2, %al
movl    $0xffffffff, %ecx
jne    6f//->loc_1c8
jmp    5f//->0x1c6
    
4:;//loc_1b6:
calll   _SMBus_runCommand_printf_SMBus_timed_out
xorl    %ecx, %ecx
jmp    7f//->0x1d8
    
5:;//loc_1c6:
xorl    %ecx, %ecx
    
6:;//loc_1c8:
testb    $0x1, %al
movl    $0x0, %eax
cmovnel    %eax, %ecx
movl    $0x3e, %eax
PERFORM_OUT
    
7:;//loc_1d8:
addl    $0x14, %esp
movl    %ecx, %eax
popl    %ebx
leave
retl


_SMBus_disable_clock_updates:
movl    $0x01, %ecx
movl    $0x0a, %edx
movl    _pLockByte, %eax
calll   _SMBus_writeBytes
retl

_SMBus_enable_clock_updates:
movl    $0x01, %ecx
movl    $0x0a, %edx
movl    _pUnlockByte, %eax
calll   _SMBus_writeBytes
retl

_SMBus_setup_readBytes_size:
movl    $0x01, %ecx
movl    $0x08, %edx
movl    _pReadSizeByte, %eax
calll   _SMBus_writeBytes
retl

_SMBus_overclock:
movl    $0x02, %ecx
movl    $0x0b, %edx
movl    _pOverclockBytes, %eax
calll   _SMBus_writeBytes
retl

_do_read:
calll   _SMBus_start_session
calll   _SMBus_readBytes
calll   _SMBus_setup_readBytes_size
calll   _SMBus_readBytes
calll   _SMBus_end_session
retl

_do_overclock:
calll   _SMBus_start_session
calll   _SMBus_readBytes
calll   _SMBus_setup_readBytes_size
calll   _SMBus_readBytes
calll   _SMBus_enable_clock_updates
calll   _SMBus_overclock
calll   _SMBus_readBytes
calll   _SMBus_end_session
retl

#endif
