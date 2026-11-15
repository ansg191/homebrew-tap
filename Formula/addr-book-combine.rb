class AddrBookCombine < Formula
  desc "Combine multiple aerc-style address books into one"
  homepage "https://jasoncarloscox.com/creations/addr-book-combine/"
  url "https://git.sr.ht/~jcc/addr-book-combine/archive/11696f4726b981c774ad1d4858f1a935ac71e9ac.tar.gz"
  version "0.0.0-20221214"
  sha256 "b07b1f57a5324ccb60d696870354c5da05e53b1fbd17c4aa8118503bf968f000"
  license "GPL-3.0-only"
  head "https://git.sr.ht/~jcc/addr-book-combine", branch: "master"

  depends_on "go" => :build

  deny_network_access!

  def install
    system "go", "build", *std_go_args
  end

  test do
    (testpath/"first.tsv").write <<~EOS
      c@example.com\tChad Cherry\t4
      a@example.com\tAndy Apple\t1
    EOS
    (testpath/"second.tsv").write <<~EOS
      a@example.com\tAndy Apple\t2
      b@example.com\tBart Berry\t3
    EOS

    output = shell_output("#{bin}/addr-book-combine -f first.tsv -c 'cat second.tsv'")
    assert_equal %w[a@example.com c@example.com b@example.com], output.lines.map { |line| line.split("\t").first }
  end
end
