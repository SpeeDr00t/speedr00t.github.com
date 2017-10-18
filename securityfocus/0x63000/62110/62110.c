void *__cdecl Buffer::getStringAsBuffer(int a1)
{
char v1; // al@1
void *v2; // edx@1
unsigned int v3; // eax@2
char v4; // al@2
void *v5; // ST18_4@3
unsigned int v7; // [sp+14h] [bp-1Ch]@2

v1 = Buffer::avail(a1, 4);
v2 = 0;
if ( v1 )
{
v3 = Buffer::getInt32(a1);
v7 = v3;
v4 = Buffer::avail(a1, v3);
v2 = 0;
if ( v4 )
{
v5 = malloc(0x14u);
Buffer::Buffer(v5, v7);
v2 = v5;
memcpy(*((void **)v5 + 1), (const void *)(*(_DWORD *)(a1 + 12) + *(_DWORD *)(a1 + 4)), v7);
*(_DWORD *)(a1 + 12) += v7;
}
}
return v2;
}

//.. (00014FB4) ...................
int __cdecl Buffer::Buffer(int a1, int a2)
{
int result; // eax@1

result = a1;
*(_BYTE *)(a1 + 16) = 0;
*(_DWORD *)(a1 + 12) = 0;
*(_DWORD *)a1 = 0;
*(_DWORD *)(a1 + 4) = 0;
*(_DWORD *)(a1 + 8) = 0;
if ( a2 )
result = Buffer::expand(a1, a2);
return result;
}

//.. (00014EAA) ...................
char __cdecl Buffer::expand(int a1, int a2)
{
int v2; // ecx@1
const void *v3; // eax@1
int v4; // esi@1
char result; // al@1
void *v6; // eax@5
int v7; // edx@5
int v8; // [sp+4h] [bp-24h]@1
unsigned int v9; // [sp+8h] [bp-20h]@4
const void *ptr; // [sp+Ch] [bp-1Ch]@1

v2 = *(_DWORD *)(a1 + 8);
v3 = *(const void **)(a1 + 4);
ptr = v3;
v8 = v2 . (_DWORD)v3;
v4 = *(_DWORD *)(a1 + 12) + a2;
result = 1;
if ( v4 > (unsigned int)v8 )
{
if ( (unsigned int)v4 <= 0×0400 )
{
v9 = *(_DWORD *)a1;
if ( (unsigned int)v4 <= *(_DWORD *)a1 )
{
*(_DWORD *)(a1 + 8) = v4 . v8 + v2;
}
else
{
v6 = malloc((v4 + 71) & 0xFFFFFFF8);
v7 = a1;
*(_DWORD *)(a1 + 4) = v6;
*(_DWORD *)(a1 + 8) = (char *)v6 + v4;
if ( ptr )
{
memcpy(v6, ptr, v9);
free((void *)ptr);
v7 = a1;
}
*(_DWORD *)v7 = (v4 + 71) & 0xFFFFFFF8;
result = 1;
}
}
else
{
*(_BYTE *)(a1 + 16) = 1;
result = 0;
}
}
return result;
}
