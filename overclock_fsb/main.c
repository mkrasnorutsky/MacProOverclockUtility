//
//  overclock.c
//  overclock
//
//  Created by Mikhail Krasnorutskiy on 10/3/23.
//  Copyright (c) 2023 Mikhail Krasnorutskiy. All rights reserved.
//

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/kern_control.h>
#include <sys/kern_event.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/mount.h>

#define KEXT_BUNDLE_ID "co.mk.overclock"

#define DEFAULT_BUFFER_SIZE 256
uint8_t buffer[DEFAULT_BUFFER_SIZE];

static void send_receive(uint8_t* data, size_t dataSize, int shouldReadResponse)
{
    struct sockaddr_ctl addr;
    bzero(&addr, sizeof(addr));
    addr.sc_len     = sizeof(addr);
    addr.sc_family  = AF_SYSTEM;
    addr.ss_sysaddr = AF_SYS_CONTROL;
    addr.sc_id      = 0;
    addr.sc_unit    = 0;
    
    struct ctl_info info;
    bzero(&info, sizeof(info));
    strncpy(info.ctl_name, KEXT_BUNDLE_ID, sizeof(KEXT_BUNDLE_ID));
    
    int fd = socket(PF_SYSTEM, SOCK_DGRAM, SYSPROTO_CONTROL);
    if (!fd)
    {
        printf("[ERR] Could not create socket.\n");
        exit(-1);
    }
    
    int res = ioctl(fd, CTLIOCGINFO, &info);
    if (res)
    {
        printf("[ERR] Could not find Kernel Control. Most likely overclock.kext is not loaded.\n");
        close(fd);
        exit(-1);
    }
    
    addr.sc_id = info.ctl_id;
    printf("[OK] Found Kernel Control. Name: %s, ID: %d\n", info.ctl_name, info.ctl_id);
    
    ssize_t rc = connect(fd, (struct sockaddr *)&addr, sizeof(addr));
    if (rc)
    {
        printf("[ERR] Could not create connection.\n");
        close(fd);
        exit(-1);
    }
    
    rc = send(fd, data, dataSize, 0);
    if (rc == -1)
    {
        printf("[ERR] Could not send message.\n");
        close(fd);
        exit(-1);
    }
    
    printf("[OK] Message sent to kext\n");
    
    if (!shouldReadResponse)
    {
        close(fd);
        return;
    }
    
    bzero(buffer,DEFAULT_BUFFER_SIZE);
    
    rc = read(fd,buffer,DEFAULT_BUFFER_SIZE);
    if (rc == -1 ||
        rc == 0 ||
        buffer[0] != (rc-1))
    {
        printf("[ERR] Malformed response from kext.\n");
        close(fd);
        exit(-1);
    }

    printf("Got %zd Bytes from chip\n",rc-1);
    for (int i=0; i<(rc-1);++i)
    {
        if (!(i%4))
        {
            printf("\n");
        }
        
        printf("Byte %d = %02x\n", i, buffer[i+1]);
    }
    
    close(fd);
}

static double fsb_frequency(uint8_t byte_b, uint8_t byte_c, uint8_t byte_13)
{
    uint8_t ICS932S4x_Clock_Div_TABLE[] = { 0x02, 0x03, 0x05, 0x0f, 0x04, 0x06, 0x0a, 0x1e, 0x08, 0x0c, 0x14, 0x3c, 0x10, 0x18, 0x28, 0x78 };
    
    uint32_t ecx = byte_b;
    uint32_t edx = byte_c;
    
    uint32_t eax = ecx;
    
    ecx &= 0x3f;
    eax >>= 6;
    ecx += 2;
    eax <<= 8;
    eax |= edx;

    eax += 8;
    double xmm0 = eax;
    xmm0 *= 14.31818;
    double result = xmm0;
    xmm0 = ecx;
    
    ecx = byte_13;
    
    double xmm1 = result;
    xmm1 /= xmm0;
    ecx >>= 4;
    ecx = ICS932S4x_Clock_Div_TABLE[ecx];
    xmm0 = ecx;
    xmm1 /= xmm0;
    result = xmm1;
    
    return result;
}

#define SQUARE_DIFF_MAX 64
int main(int argc, char* const* argv)
{
    uint8_t command_read[] = {0x1};
    send_receive(command_read, sizeof(command_read),1);
    
    uint8_t byte_b = buffer[0xb+1];
    uint8_t byte_c = buffer[0xc+1];
    double current_frequency = fsb_frequency(byte_b, byte_c, buffer[0x13+1]);
    printf("Current FSB frequency is %d Mhz\n", (int)(current_frequency+0.5));
    
    if (argc < 2)
    {
        return 0;
    }
    
    int desired_frequency = atoi(argv[1]);
    double square_diff_min = INT_MAX;

    double new_frequency = current_frequency;
    
    for (uint32_t i_=0; i_<=UINT16_MAX; ++i_)
    {
        uint16_t i = (uint16_t)i_;
        uint8_t* p = (uint8_t*)&i;
        uint8_t byte_b_tmp = (buffer[0xb+1] & 0x3F) + (p[0] & 0xC0);
        double freq = fsb_frequency(byte_b_tmp, p[1], buffer[0x13+1]);
        double diff = freq - desired_frequency;
        if ((diff * diff) < square_diff_min)
        {
            byte_b = byte_b_tmp;
            byte_c = p[1];
            new_frequency = freq;
            square_diff_min = diff * diff;
        }
    }

    if (square_diff_min > SQUARE_DIFF_MAX)
    {
        printf("Invalid FSB frequency to set: %d\n", desired_frequency);
        exit(1);
    }
    
    uint8_t command_write[] = {0x2,byte_b,byte_c};
    send_receive(command_write, sizeof(command_write),0);
    
    printf("FSB frequency updated successfully to %d Mhz\n", (int)(new_frequency+0.5));
    
    return 0;
}

