//
//  overclock.c
//  overclock
//
//  Created by Mikhail Krasnorutskiy on 10/3/23.
//  Copyright (c) 2023 Mikhail Krasnorutskiy. All rights reserved.
//

#include <libkern/libkern.h>
#include <mach/mach_types.h>
#include <sys/sysctl.h>
#include <sys/kauth.h>
#include <sys/kern_control.h>

#define KEXT_BUNDLE_ID "co.mk.overclock"
#define VALUES_BUFFER_SIZE 1000
#define BYTES_FROM_CHIP_BUFFER_SIZE 100

#ifdef __x86_64__
typedef uint64_t reg_t;
#elif defined __i386__
typedef uint32_t reg_t;
#else
#error Unsupported architecture
#endif

reg_t values[VALUES_BUFFER_SIZE];//In/Out logs
reg_t* pValues = values;

reg_t bytesRead = 0;
reg_t* pBytesRead = &bytesRead;

uint8_t bytesFromChip[BYTES_FROM_CHIP_BUFFER_SIZE];
uint8_t* pBytesFromChip = bytesFromChip;

uint8_t lockByte = 0x43;
uint8_t* pLockByte = &lockByte;

uint8_t unlockByte = 0xC3;
uint8_t* pUnlockByte = &unlockByte;

uint8_t readSizeByte = 0x16;
uint8_t* pReadSizeByte = &readSizeByte;

uint8_t overclockBytes[2] = {0xCD, 0xB1};
uint8_t* pOverclockBytes = overclockBytes;

void do_read(void);
void do_overclock(void);

u_int32_t sc_unit = 0;
int connected = 0;

static errno_t ctlHandleConnect(kern_ctl_ref ctlref, struct sockaddr_ctl *sac, void **unitinfo) {
    errno_t error = KERN_SUCCESS;
    
    printf("ctlHandleConnect\n");
    
    sc_unit = sac->sc_unit;
    connected = 1;

    return error;
}

static errno_t ctlHandleDisconnect(kern_ctl_ref ctlref, unsigned int unit, void *unitinfo) {
    errno_t error = KERN_SUCCESS;
    
    printf("ctlHandleDisconnect\n");
    
    connected = 0;

    return error;
}

#define MAX_RESPONSE_LENGTH 50
uint8_t response[MAX_RESPONSE_LENGTH];
static errno_t ctlHandleWrite(kern_ctl_ref ctlref, unsigned int unit, void *userdata, mbuf_t m, int flags) {
    errno_t error = KERN_SUCCESS;
    
    printf("ctlHandleHandleWrite\n");
    
    uint8_t *data = (uint8_t*)mbuf_data(m);
    
    response[0] = 0;
    
    uint8_t command = data[0];
    if (command == 1)//read
    {
        do_read();
        
        response[0] = (uint8_t)bytesRead;
        for (uint8_t i = 0; i<MIN(bytesRead,(MAX_RESPONSE_LENGTH-1)); ++i)
        {
            response[i+1] = bytesFromChip[i];
        }
    }
    else if (command == 2) //write
    {
        overclockBytes[0] = data[1];
        overclockBytes[1] = data[2];
        
        do_overclock();
        
        return KERN_SUCCESS;
    }
    
    error = ctl_enqueuedata(ctlref, sc_unit, response, response[0]+1, 0);
    if (error != KERN_SUCCESS)
    {
        printf("ctl_enquedata failed: %d\n", error);
    }
    
    return error;
}

void SMBus_runCommand_printf_SMBus_timed_out(void);
void SMBus_runCommand_printf_SMBus_timed_out(void)
{
    printf("SMBus timed out.\n");
}

kern_return_t overclock_start(kmod_info_t * ki, void *d);
kern_return_t overclock_stop(kmod_info_t *ki, void *d);

static kern_ctl_ref gCtlRef = NULL;

// this is not a const structure since the ctl_id field
static struct kern_ctl_reg gCtlReg = {
    KEXT_BUNDLE_ID,//kext bundle_id
    0,                      //will be set when the ctl_register call succeeds. Set to 0 for dynamically assigned control ID - CTL_FLAG_REG_ID_UNIT not set
    0,                      // ctl_unit - ignored when CTL_FLAG_REG_ID_UNIT not set
    0,                      // privileged access required to access this filter
    0,                      // use default send size buffer
    0,                      // use default recv size buffer
    ctlHandleConnect,            // Called when a connection request is accepted
    ctlHandleDisconnect,         // called when a connection becomes disconnected
    ctlHandleWrite,                   // ctl_send_func - handles data sent from the client to kernel control
    NULL,                   // called when the user process makes the setsockopt call
    NULL                    // called when the user process makes the getsockopt call
};

kern_return_t overclock_start(kmod_info_t * ki, void *d)
{    
    kern_return_t err = ctl_register(&gCtlReg, &gCtlRef);
    if (err != KERN_SUCCESS)
    {
        printf("Failed to create socket");
    }
    
    return err;
}

kern_return_t overclock_stop(kmod_info_t *ki, void *d)
{
    if (gCtlRef)
    {
        errno_t res = ctl_deregister(gCtlRef);
        if (res)
        {
            // see http://lists.apple.com/archives/darwin-kernel/2005/Jul/msg00035.html
            printf("Cannot unload kext, the client is still connected (%d)\n", res);
            
            return KERN_FAILURE; // prevent unloading when client is still connected
        }
        
        gCtlRef = NULL;
    }
    
    return KERN_SUCCESS;
}
