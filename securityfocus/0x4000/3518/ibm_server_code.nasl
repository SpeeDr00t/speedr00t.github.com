s script was written by Felix Huber <huberfelix@webtopia.de>
#
# v. 1.00 (last update 08.11.01)

if(description)
{
 script_id(?????????);
 name["english"] = "IBM-HTTP-Server View Code";
 script_name(english:name["english"]);

 desc["english"] = "
IBM's HTTP Server on the AS/400 platform is vulnerable to an attack
that will show the source code of the page -- such as an .html or .jsp
page -- by attaching an '/' to the end of a URL.

Example:
http://www.foo.com/getsource.jsp/

Solution :  Not yet


Risk factor : High";


 script_description(english:desc["english"]);

 summary["english"] = "IBM-HTTP-Server View Code";

 script_summary(english:summary["english"]);

 script_category(ACT_GATHER_INFO);


 script_copyright(english:"This script is Copyright (C) 2001 Felix Huber");
 family["english"] = "CGI abuses";
 script_family(english:family["english"]);
 script_dependencie("find_service.nes");
 script_dependencie("httpver.nasl");
 script_require_ports("Services/www", 80);
 exit(0);
}

#
# The script code starts here
#

port = get_kb_item("Services/www");
if(!port)port = 80;

dir[0] = "/index.html";
dir[1] = "/index.htm";
dir[2] = "/index.jsp";
dir[3] = "/default.html";
dir[4] = "/default.htm";
dir[5] = "/default.jsp";
dir[6] = "/home.html";
dir[7] = "/home.htm";
dir[8] = "/home.jsp";

if(get_port_state(port))
{

 for (i = 0; dir[i] ; i = i + 1)
 {



     soc = http_open_socket(port);

     if(soc)

     {
        url = string(dir[i], "/");


        req = http_get(item:url, port:port);
        send(socket:soc, data:req);
        r = recv(socket:soc, length:409600);
        close(soc);

	    #display(r);

	    if("Server: IBM-HTTP-Server/1.0" >< r)
              {
                if("Content-Type: www/unknown" >< r)
                    {
                     	#security_hole(port);
                     	display("Security Hole detected\n");
                     	exit(0);
                    }
              }

     }
 }
}

