class Neo4j < Formula
  desc "Robust (fully ACID) transactional property graph database"
  homepage "https://neo4j.com/"
  url "https://neo4j.com/artifact.php?name=neo4j-community-3.0.6-unix.tar.gz"
  version "3.0.6"
  sha256 "efeab41183e9e5fa94a2d396c65ea93a24e9f105cb3b5f0d0a8e42fb709f4660"

  bottle :unneeded

  depends_on :java => "1.8+"

  def install
    ENV["NEO4J_HOME"] = libexec
    # Remove windows files
    rm_f Dir["bin/*.bat"]

    # Install jars in libexec to avoid conflicts
    libexec.install Dir["*"]

    # Symlink binaries
    bin.install Dir["#{libexec}/bin/neo4j{,-shell,-import,-shared.sh,-admin}"]
    bin.env_script_all_files(libexec/"bin", :NEO4J_HOME => ENV["NEO4J_HOME"])

    # Adjust UDC props
    # Suppress the empty, focus-stealing java gui.
    (libexec/"conf/neo4j-wrapper.conf").append_lines <<-EOS.undent
      wrapper.java.additional=-Djava.awt.headless=true
      wrapper.java.additional.4=-Dneo4j.ext.udc.source=homebrew
    EOS
  end

  test do
    ENV["NEO4J_HOME"] = libexec
    ENV.java_cache
    ENV["NEO4J_LOG"] = testpath/"libexec/data/log/neo4j.log"
    ENV["NEO4J_PIDFILE"] = testpath/"libexec/data/neo4j-service.pid"
    mkpath testpath/"libexec/data/log"
    assert_match /Neo4j .*is not running/i, shell_output("#{bin}/neo4j status", 3)
  end
end
