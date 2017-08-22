##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class MetasploitModule < Msf::Exploit::Remote
  Rank = ManualRanking

  #
  # This module does basically nothing
  # NOTE: Because of this it's missing a disclosure date that makes msftidy angry.
  #

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Generic Payload Handler',
      'Description'    => %q{
        This module is a stub that provides all of the
        features of the Metasploit payload system to exploits
        that have been launched outside of the framework.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>  ['hdm'],
      'References'     =>  [ ],
      'Payload'        =>
        {
          'Space'       => 10000000,
          'BadChars'    => '',
          'DisableNops' => true,
        },
      'Platform'       => %w{ android bsd java js linux osx nodejs php python ruby solaris unix win mainframe },
      'Arch'           => ARCH_ALL,
      'Targets'        => [ [ 'Wildcard Target', { } ] ],
      'DefaultTarget'  => 0
      ))

    register_advanced_options(
      [
        OptBool.new("ExitOnSession", [ false, "Return from the exploit after a session has been created", true ]),
        OptInt.new("ListenerTimeout", [ false, "The maximum number of seconds to wait for new sessions", 0])
      ], self.class)
  end

  def exploit
    if not datastore['ExitOnSession'] and not job_id
      fail_with(Failure::Unknown, "Setting ExitOnSession to false requires running as a job (exploit -j)")
    end

    stime = Time.now.to_f
    print_status "Starting the payload handler..."
    while(true)
      break if session_created? and datastore['ExitOnSession']
      break if ( datastore['ListenerTimeout'].to_i > 0 and (stime + datastore['ListenerTimeout'].to_i < Time.now.to_f) )

      select(nil,nil,nil,1)
    end
  end


end
