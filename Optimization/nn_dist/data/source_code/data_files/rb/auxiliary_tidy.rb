##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class MetasploitModule < Msf::Auxiliary
  def initialize(info = {})
    super(
      update_info(
        info,
        'Name'            => 'Tidy Auxiliary Module for RSpec'
        'Description'     => 'Test!'
        },
        'Author'         => %w(Unknown),
        'License'        => MSF_LICENSE,
      )
    )
  end
end
