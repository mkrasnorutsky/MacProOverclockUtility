//
//  overclock.c
//  overclock
//
//  Created by Mikhail Krasnorutskiy on 10/3/23.
//  Copyright (c) 2023 Mikhail Krasnorutskiy. All rights reserved.
//

#include <libkern/libkern.h>
#include <mach/mach_types.h>

uint64_t values[1000000];
uint64_t* pValues = values;

uint64_t bytesRead = 0;
uint64_t* pBytesRead = &bytesRead;

uint8_t bytesFromChip[100];
uint8_t* pBytesFromChip = bytesFromChip;

uint8_t lockByte = 0x43;
uint8_t* pLockByte = &lockByte;

uint8_t unlockByte = 0xC3;
uint8_t* pUnlockByte = &unlockByte;

uint8_t readSizeByte = 0x16;
uint8_t* pReadSizeByte = &readSizeByte;

uint8_t overclockBytes[2] = {0xCD, 0xB1};
uint8_t* pOverclockBytes = overclockBytes;

void SMBus_runCommand_printf_SMBus_timed_out(void);
void SMBus_runCommand_printf_SMBus_timed_out(void)
{
    printf("SMBus timed out.\n");
}

void do_overclock(void);

kern_return_t overclock_start(kmod_info_t * ki, void *d);
kern_return_t overclock_stop(kmod_info_t *ki, void *d);

kern_return_t overclock_start(kmod_info_t * ki, void *d)
{
    printf("overclock.kext version %s\n", ki->version);
    
    for (int j=0; j<10000; ++j)
    {
        values[j] = 0;
    }
    
    do_overclock();

    int bytes = (int)(pValues - values);
    
    printf("Origin: %p current: %p Bytes: %d READ: %d\n", values, pValues, bytes, (int)bytesRead);
    
    for (int i=0; i<bytesRead; ++i)
    {
        printf("Byte[%d] = %02x\n", i, (uint32_t)(bytesFromChip[i]));
    }
    
#if 0
    
    for (int i=0; i<bytes; i += 3)
    {
        uint32_t eax = values[i + 0];
        uint32_t edx = values[i + 1];
        uint32_t type = values[i + 2];
        
        if (!type)
        {
            printf("IN al=%02x,dx=%04x\n", (uint8_t)(eax & 0x000000ff), (uint16_t)(edx & 0x0000ffff));
        }
        else
        {
            printf("OUT dx=%04x,al=%02x\n", (uint16_t)(edx & 0x0000ffff), (uint8_t)(eax & 0x000000ff));
        }
    }
    
#endif
    
    return KERN_SUCCESS;
}

kern_return_t overclock_stop(kmod_info_t *ki, void *d)
{
    return KERN_SUCCESS;
}
