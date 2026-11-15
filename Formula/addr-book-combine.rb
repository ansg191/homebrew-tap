class AddrBookCombine < Formula
  desc "Combine multiple aerc-style address books into one"
  homepage "https://jasoncarloscox.com/creations/addr-book-combine/"
  url "https://git.sr.ht/~jcc/addr-book-combine/archive/11696f4726b981c774ad1d4858f1a935ac71e9ac.tar.gz"
  version "0.0.0-20221214"
  sha256 "b07b1f57a5324ccb60d696870354c5da05e53b1fbd17c4aa8118503bf968f000"
  license "GPL-3.0-only"
  head "https://git.sr.ht/~jcc/addr-book-combine", branch: "master"

  bottle do
    root_url "https://github.com/ansg191/homebrew-tap/releases/download/addr-book-combine-0.0.0-20221214"
    sha256 cellar: :any_skip_relocation, arm64_golden_gate: "447abfeed8cbe8b75f3534a047e3c668c0a73ecf9b88c6d43411907d0bc3e438"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:       "9f3e36b92ed0a815004e3cc0f95c555a235b6b0954862e810f01e2d1bb101f10"
    sha256 cellar: :any_skip_relocation, arm64_linux:       "ca16a3e8d9a69d14adc3552d02001da50fc04b0ab2e3c08465117df5a49a49df"
    sha256 cellar: :any_skip_relocation, x86_64_linux:      "5810f19c1a629b3ca0f5ad6d151becda9ef9f3db4d7495eb91f61a1ffb97bb5a"
  end

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
