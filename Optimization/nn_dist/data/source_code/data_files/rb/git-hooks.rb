class GitHooks < Formula
  desc "Manage project, user, and global Git hooks"
  homepage "https://github.com/icefox/git-hooks"
  url "https://github.com/icefox/git-hooks/archive/1.00.0.tar.gz"
  sha256 "8197ca1de975ff1f795a2b9cfcac1a6f7ee24276750c757eecf3bcb49b74808e"

  head "https://github.com/icefox/git-hooks.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "aaceeb7b390f71c45e3c1db15c23ab664a06bfc34de1c629a2b2f5b29e1bdec2" => :sierra
    sha256 "bdfffb820e5a7574169b91113ed59c578ebe88bcea8c890166a33fb9af17c0ce" => :el_capitan
    sha256 "d4c5fba7f1b80e8e68762356a2f64ac216bf4e9f3151cf2f236c92a9524b97ed" => :yosemite
    sha256 "ace6acaff04ef09795d26e6034bf411a89c9f348287dd95f756c82068cea123d" => :mavericks
    sha256 "d6fb1c69f50a6798e288b46f36d331fe86f8c2cc7b6ea2c8e43dfe675ed80132" => :mountain_lion
  end

  def install
    bin.install "git-hooks"
    (etc/"git-hooks").install "contrib"
  end

  test do
    system "git", "init"
    output = shell_output("git hooks").strip
    assert_match "Listing User, Project, and Global hooks", output
  end
end
