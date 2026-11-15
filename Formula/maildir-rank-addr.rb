class MaildirRankAddr < Formula
  desc "Creates a ranked list of email addresses from local email files"
  homepage "https://github.com/ferdinandyb/maildir-rank-addr"
  url "https://github.com/ferdinandyb/maildir-rank-addr/archive/refs/tags/v1.4.1.tar.gz"
  sha256 "5536cbfd0dd1f686dbe0bcf6a45d3c62659e5d7172b5df8ca3d257a6bf66b6cd"
  license "MIT"
  head "https://github.com/ferdinandyb/maildir-rank-addr.git", branch: "master"

  depends_on "go" => :build

  deny_network_access!

  def fetch
    system "go", "mod", "download"
  end

  def install
    system "go", "build", *std_go_args
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
