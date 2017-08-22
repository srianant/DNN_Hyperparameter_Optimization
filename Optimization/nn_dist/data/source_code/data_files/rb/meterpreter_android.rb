# -*- coding: binary -*-

require 'msf/base/sessions/meterpreter'
require 'msf/base/sessions/meterpreter_java'
require 'msf/base/sessions/meterpreter_options'

module Msf
module Sessions

###
#
# This class creates a platform-specific meterpreter session type
#
###
class Meterpreter_Java_Android < Msf::Sessions::Meterpreter_Java_Java

  def initialize(rstream, opts={})
    super
    self.platform = 'java/android'
  end

  def load_android
    original = console.disable_output
    console.disable_output = true
    console.run_single('load android')
    console.disable_output = original
  end

end

end
end

