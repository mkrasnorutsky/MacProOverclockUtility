//
//  smbus.s
//  overclock
//
//  Created by Mikhail Krasnorutskiy on 7/10/23.
//

#ifdef __x86_64__

#if 1

#define PERFORM_IN inb    %dx, %al
#define PERFORM_IN_NO_LOGS inb    %dx, %al
#define PERFORM_OUT outb    %al, %dx

#else

#define PERFORM_IN inb    %dx, %al;\
pushq    %rcx;\
movq    _pValues(%rip),%rcx;\
movq    %rax,0x00(%rcx);\
movq    %rdx,0x08(%rcx);\
addq    $0x18,%rcx;\
movq    %rcx,_pValues(%rip);\
popq    %rcx;

#define PERFORM_IN_NO_LOGS inb    %dx, %al

#define PERFORM_OUT outb    %al, %dx;\
pushq    %rcx;\
movq    _pValues(%rip),%rcx;\
movq    %rax,0x00(%rcx);\
movq    %rdx,0x08(%rcx);\
movq    %rdx,0x10(%rcx);\
addq    $0x18,%rcx;\
movq    %rcx,_pValues(%rip);\
popq    %rcx

#endif

.globl _do_read
.globl _do_overclock


_SMBus_start_session:
pushq    %rbp
movq    $0x3000, %rdx
movq    %rsp, %rbp
PERFORM_IN
movq    %rax, %rcx
PERFORM_IN
testb    %cl, %cl
movq    %rax, %rdx
leave
sete    %cl
xorq    %rax, %rax
cmpb    $0x40, %dl
sete    %al
andq    %rcx, %rax
retq


_SMBus_end_session:
movq    $0x3000, %rcx
xorq    %rax, %rax
pushq    %rbp
movq    %rsp, %rbp
leaq    0xd(%rcx), %rdx
movzwq    %dx, %rdx
PERFORM_OUT
movq    $0x40, %rax
movzwq    %cx, %rdx
PERFORM_OUT
leave
movq    $0xffffffffffffffff, %rax
retq


_SMBus_readBytes:
pushq    %rbp
movq    %rsp, %rbp
pushq    %rdi
pushq    %rsi
pushq    %rbx
    
movq    $0x3000, %rcx
movq    $0xffffffffffffffd2, %rax
    
leaq    0x4(%rcx), %rdx
movzwq    %dx, %rdx
PERFORM_OUT
    
xorq    %rbx, %rbx
leaq    0xd(%rcx), %rdx
movq    %rbx, %rax
movzwq    %dx, %rdx
PERFORM_OUT
    
leaq    0x3(%rcx), %rax
movzwq    %ax, %rdx
movq    %rbx, %rax
PERFORM_OUT
    
movq    $0x44, %rax
callq    _SMBus_runCommand
    
movq    $0x3000, %rcx
movq    $0xffffffffffffffd3, %rax
    
leaq    0x4(%rcx), %rdx
movzwq    %dx, %rdx
PERFORM_OUT
    
leaq    0xd(%rcx), %rdx
movq    $0x2, %rax
movzwq    %dx, %rdx
PERFORM_OUT
    
leaq    0x3(%rcx), %rax
movzwq    %ax, %rdx
movq    %rbx, %rax
PERFORM_OUT
    
movq    $0x54, %rax
callq    _SMBus_runCommand
    
movq    $0x3000, %rcx
leaq    0x2(%ecx), %rax
movzwq    %ax, %rax
movq    %rax, %rdx
PERFORM_IN
    
leaq    0x5(%rcx), %rdx
movzwq    %dx, %rdx
PERFORM_IN
    
movsbq    %al, %rsi
movq    %rax, %rdi
    
movq    _pBytesRead(%rip),%rcx
movq    %rsi,0x00(%rcx)
    
20:;//loc_28b
movq    $0x3000, %rdx
addq    $0x7, %rdx
movzwq    %dx, %rdx
PERFORM_IN
    
movq    _pBytesFromChip(%rip), %rdx
movzbq    %al, %rax
movb    %al, (%rbx,%rdx)
incq    %rbx
    
9:;//loc_2b3
movq    %rdi, %rax
cmpb    %bl, %al
jg    20b//->loc_28b
    
10:;//loc_2b3
popq    %rbx
popq    %rsi
popq    %rdi
leave
retq


_SMBus_writeBytes:
pushq    %rbp
movq    %rsp, %rbp
pushq    %rdi
movq    %rax, %rdi
pushq    %rsi
movq    %rcx, %rsi
pushq    %rbx
movq    $0xffffffffffffffd2, %rcx
subq    $0x4, %rsp
movq    $0x3000, %rbx
movq    %rcx, %rax
movb    %dl, -0xd(%rbp)
addq    $0x4, %rbx
movzwq    %bx, %rbx
movq    %rbx, %rdx
PERFORM_OUT
movq    $0x3000, %rbx
movq    $0x2, %rcx
movq    %rcx, %rax
addq    $0xd, %rbx
movzwq    %bx, %rbx
movq    %rbx, %rdx
PERFORM_OUT
movq    $0x3000, %rdx
movzbq    -0xd(%rbp), %rcx
addq    $0x3, %rdx
movzwq    %dx, %rdx
movq    %rcx, %rax
PERFORM_OUT
movq    %rsi, %rdx
movzbq    %dl, %rcx
movq    $0x3000, %rdx
movq    %rcx, %rax
addq    $0x5, %rdx
movzwq    %dx, %rdx
PERFORM_OUT
movq    $0x3000, %rdx
addq    $0x2, %rdx
movzwq    %dx, %rdx
PERFORM_IN
movq    $0x3000, %rax
xorq    %rbx, %rbx
addq    $0x7, %rax
movzwq    %ax, %rcx
jmp    13f//->loc_361
    
12:;//loc_359
movzbq    (%rbx,%rdi), %rax
movq    %rcx, %rdx
PERFORM_OUT
incq    %rbx
movq    %rsi, %rax
    
13:;//loc_361
cmpb    %bl, %al
jg    12b//->loc_359
    
addq    $0x4, %rsp
movq    $0x54, %rax
popq    %rbx
popq    %rsi
popq    %rdi
leave
jmp    _SMBus_runCommand


_SMBus_runCommand:
pushq    %rbp
movzbq    %al, %rax
movq    %rsp, %rbp
pushq    %rbx
subq    $0x14, %rsp
    
movq    $0x3000, %rcx
leaq    0x2(%rcx), %rdx
movzwq    %dx, %rdx
PERFORM_OUT
    
xorq    %rbx, %rbx
jmp    3f//->loc_1a3
    
1:;//loc_188:
//__asm__("movq $0x3e8,(%rsp)
//__asm__("callq    _delay
cmpq    $0xf4240, %rbx //__asm__("cmpq    $0x3e8, %rbx
je    4f//->loc_1b6:
    
2:;//loc_19c:
movq    $0x3000, %rcx
incq    %rbx
    
3:;//loc_1a3:
movq    %rcx, %rdx
PERFORM_IN_NO_LOGS
testb    $0x3e, %al
je    1b//->loc_188://MISHA
    
PERFORM_IN
testb    $0x2, %al
movq    $0xffffffffffffffff, %rcx
jne    6f//->loc_1c8
jmp    5f//->0x1c6
    
4:;//loc_1b6:
callq   _SMBus_runCommand_printf_SMBus_timed_out
xorq    %rcx, %rcx
jmp    7f//->0x1d8
    
5:;//loc_1c6:
xorq    %rcx, %rcx
    
6:;//loc_1c8:
testb    $0x1, %al
movq    $0x0, %rax
cmovneq    %rax, %rcx
movq    $0x3e, %rax
PERFORM_OUT
    
7:;//loc_1d8:
addq    $0x14, %rsp
movq    %rcx, %rax
popq    %rbx
leave
retq


_SMBus_disable_clock_updates:
movq    $0x01, %rcx
movq    $0x0a, %rdx
movq    _pLockByte(%rip), %rax
callq   _SMBus_writeBytes
retq

_SMBus_enable_clock_updates:
movq    $0x01, %rcx
movq    $0x0a, %rdx
movq    _pUnlockByte(%rip), %rax
callq   _SMBus_writeBytes
retq

_SMBus_setup_readBytes_size:
movq    $0x01, %rcx
movq    $0x08, %rdx
movq    _pReadSizeByte(%rip), %rax
callq   _SMBus_writeBytes
retq

_SMBus_overclock:
movq    $0x02, %rcx
movq    $0x0b, %rdx
movq    _pOverclockBytes(%rip), %rax
callq   _SMBus_writeBytes
retq

_do_read:
callq   _SMBus_start_session
callq   _SMBus_readBytes
callq   _SMBus_setup_readBytes_size
callq   _SMBus_readBytes
callq   _SMBus_end_session
retq

_do_overclock:
callq   _SMBus_start_session
callq   _SMBus_readBytes
callq   _SMBus_setup_readBytes_size
callq   _SMBus_readBytes
callq   _SMBus_enable_clock_updates
callq   _SMBus_overclock
callq   _SMBus_readBytes
callq   _SMBus_end_session
retq

#endif
