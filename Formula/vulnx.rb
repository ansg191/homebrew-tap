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
