class MaildirRankAddr < Formula
  desc "Creates a ranked list of email addresses from local email files"
  homepage "https://github.com/ferdinandyb/maildir-rank-addr"
  url "https://github.com/ferdinandyb/maildir-rank-addr/archive/refs/tags/v1.4.1.tar.gz"
  sha256 "5536cbfd0dd1f686dbe0bcf6a45d3c62659e5d7172b5df8ca3d257a6bf66b6cd"
  license "MIT"
  head "https://github.com/ferdinandyb/maildir-rank-addr.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/ansg191/homebrew-tap/releases/download/maildir-rank-addr-1.4.1"
    sha256 cellar: :any_skip_relocation, arm64_golden_gate: "5f068e6e0b1886986cc14b0bd7ff3bbd968db1282e75dd49848c85413e061d5a"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:       "0a10e84ea7407cce5d79abd13fe537edeed681a9f7b760b0b5ba8fe16bafa9d6"
    sha256 cellar: :any_skip_relocation, arm64_linux:       "047e30dd003e6fc1e9686cf0e43e1ea829ff43726ad3b04216ba00171f1526cc"
    sha256 cellar: :any,                 x86_64_linux:      "e5b90a48a763b5a46243c21f4a33472255df872acfe777fe094ecad9f321171a"
  end

  depends_on "go" => :build

  deny_network_access!

  def fetch
    system "go", "mod", "download"
  end

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    (testpath/"mail/cur/1.eml").write <<~EOS
      From: Me <me@example.com>
      To: Alice Example <alice@example.com>
      Cc: Bob Example <bob@example.com>
      Subject: Hello
      Date: Mon, 02 Nov 2026 10:00:00 +0000
      Message-ID: <1@example.com>

      Hello
    EOS
    (testpath/"mail/cur/2.eml").write <<~EOS
      From: Carol Example <carol@example.com>
      To: Me <me@example.com>
      Subject: Newsletter
      Date: Tue, 03 Nov 2026 10:00:00 +0000
      Message-ID: <2@example.com>

      News
    EOS

    output = shell_output("#{bin}/maildir-rank-addr --maildir=#{testpath}/mail " \
                          "--addresses=me@example.com --outputpath=-")
    addresses = output.lines.filter_map { |line| line.split("\t").first if line.include?("\t") }
    assert_equal "alice@example.com", addresses.first
    assert_operator addresses.index("bob@example.com"), :<, addresses.index("carol@example.com")
    assert_match "alice@example.com\tAlice Example", output
  end
end
