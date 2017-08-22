class ApacheZeppelin < Formula
  desc "Web-based notebook that enables interactive data analytics"
  homepage "https://zeppelin.apache.org"
  url "https://www.apache.org/dyn/closer.lua?path=zeppelin/zeppelin-0.6.1/zeppelin-0.6.1-bin-all.tgz"
  sha256 "5185952361d1999fb3c00b8aca2c6ddc57353af5a1fd93f4f5b9dd89c7222147"
  head "https://github.com/apache/zeppelin.git"

  bottle :unneeded

  def install
    rm_f Dir["bin/*.cmd"]
    libexec.install Dir["*"]
    bin.write_exec_script Dir["#{libexec}/bin/*"]
  end

  test do
    begin
      ENV["ZEPPELIN_LOG_DIR"] = "logs"
      ENV["ZEPPELIN_PID_DIR"] = "pid"
      ENV["ZEPPELIN_CONF_DIR"] = "#{testpath}/conf"
      conf = testpath/"conf"
      conf.mkdir
      (conf/"zeppelin-env.sh").write <<-EOF.undent
        export ZEPPELIN_WAR_TEMPDIR="#{testpath}/webapps"
        export ZEPPELIN_PORT=9999
      EOF
      ln_s "#{libexec}/conf/log4j.properties", conf
      ln_s "#{libexec}/conf/shiro.ini", conf
      system "#{bin}/zeppelin-daemon.sh", "start"
      begin
        sleep 10
        json_text = shell_output("curl -s http://localhost:9999/api/notebook/r")
        assert_operator Utils::JSON.load(json_text)["body"]["paragraphs"].length, :>=, 1
      ensure
        system "#{bin}/zeppelin-daemon.sh", "stop"
      end
    end
  end
end
