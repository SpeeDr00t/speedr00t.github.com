/** This software is provided by the copyright owner "as is" and any
 *  expressed or implied warranties, including, but not limited to,
 *  the implied warranties of merchantability and fitness for a particular
 *  purpose are disclaimed. In no event shall the copyright owner be
 *  liable for any direct, indirect, incidential, special, exemplary or
 *  consequential damages, including, but not limited to, procurement
 *  of substitute goods or services, loss of use, data or profits or
 *  business interruption, however caused and on any theory of liability,
 *  whether in contract, strict liability, or tort, including negligence
 *  or otherwise, arising in any way out of the use of this software,
 *  even if advised of the possibility of such damage.
 *
 *  Copyright (c) 2012 halfdog <me (%) halfdog.net>
 *
 *  Compile: gcc -o RtcInt RtcInt.c
 *  Usage: ./RtcInt 
 */
int main(int argc, char **argv) {
  asm (
    "int $0x8;"
    : // output: none
    : // input: none
    :"%eax", "%ebx", "%ecx", "%edx"   // clobbered register
  );
  return(0);
}

