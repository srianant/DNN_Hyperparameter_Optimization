require 'spec_helper'
require 'metasploit/framework/login_scanner/gitlab'

RSpec.describe Metasploit::Framework::LoginScanner::GitLab do

    it_behaves_like 'Metasploit::Framework::LoginScanner::Base',  has_realm_key: true, has_default_realm: false
    it_behaves_like 'Metasploit::Framework::LoginScanner::RexSocket'
    it_behaves_like 'Metasploit::Framework::LoginScanner::HTTP'

end
