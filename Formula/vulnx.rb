class Vulnx < Formula
  desc "Modern CLI for exploring vulnerability data"
  homepage "https://github.com/projectdiscovery/vulnx"
  url "https://github.com/projectdiscovery/vulnx/archive/refs/tags/v2.1.0.tar.gz"
  sha256 "10255d08ee85fec2eac021508734302648fbdf375152689356367947dc366ab1"
  license "MIT"
  head "https://github.com/projectdiscovery/vulnx.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/ansg191/homebrew-tap/releases/download/vulnx-2.1.0"
    sha256 cellar: :any_skip_relocation, arm64_golden_gate: "d22a05a3655bcab04a8fbaabc6445ea5d9012ffd1fe00df54cca06dad1199fc9"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:       "5a9086a59b1618d0c90358be6712de253b12f3bbb19615bc6d01f3bd59921383"
    sha256 cellar: :any_skip_relocation, arm64_linux:       "6f7ec6585ca8b7b482fccfa783f2803d68daf93e1a332c43385b217a5166c52d"
    sha256 cellar: :any_skip_relocation, x86_64_linux:      "cee001534e96e7bab8d4399a1f4a798c5f300f7a8943993426cc03c268105b58"
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
