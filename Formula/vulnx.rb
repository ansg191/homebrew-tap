class Vulnx < Formula
  desc "Modern CLI for exploring vulnerability data"
  homepage "https://github.com/projectdiscovery/vulnx"
  url "https://github.com/projectdiscovery/vulnx/archive/refs/tags/v2.0.2.tar.gz"
  sha256 "d3954dbcbee35fc7ff5417d3314949d7f7e1cf4939082a153515ce58b51ab7a6"
  license "MIT"
  head "https://github.com/projectdiscovery/vulnx.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/ansg191/homebrew-tap/releases/download/vulnx-2.0.2"
    sha256 cellar: :any_skip_relocation, arm64_golden_gate: "5882d529037ae71d7a9b9b677989ba78c57ec9e0363ba70d7db1683226734dbf"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:       "17439c82f6fc6458f81d8cf77d013d993c68fd4222b38bd99b880dee44e13e67"
    sha256 cellar: :any_skip_relocation, arm64_linux:       "448363772cb094696864a39e0142f7ac414f67a374c3475437914f20efeeb3ae"
    sha256 cellar: :any_skip_relocation, x86_64_linux:      "4f47e210fc65f91c1c53b0cbdc2057ab68a0c074bfde21be90979326ba645485"
  end

  depends_on "go" => :build

  deny_network_access!

  def fetch
    system "go", "mod", "download"
  end

  def install
    ENV["CGO_ENABLED"] = "0"
    ldflags = "-X github.com/projectdiscovery/vulnx/v2/cmd/vulnx/clis.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/vulnx"

    generate_completions_from_executable(bin/"vulnx", "completion", "--disable-update-check")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/vulnx version 2>&1")
  end
end
