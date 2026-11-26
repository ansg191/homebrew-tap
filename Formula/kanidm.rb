class Kanidm < Formula
  desc "Client tools for the Kanidm identity management platform"
  homepage "https://kanidm.com/"
  url "https://github.com/kanidm/kanidm/archive/refs/tags/v1.12.2.tar.gz"
  sha256 "4ed023d39ddf304cd24d829cd6c5b90689d8e50428a043c8033fc75e813a5b47"
  license "MPL-2.0"
  head "https://github.com/kanidm/kanidm.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/ansg191/homebrew-tap/releases/download/kanidm-1.12.1"
    sha256 cellar: :any_skip_relocation, arm64_golden_gate: "e7ed611e19fa48500db8df6265eb247381a869fe49fe71dea18e5874521eebd5"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:       "99aa0ab8efab40d2f18750413ec2be03ffd4e85a91ca8a14d6d653b40f1e7a14"
    sha256 cellar: :any,                 arm64_linux:       "ddd0ed42dde6ccdbab883e8396d9b3e0e8b2d2770a36e8ede352d9485a5b1cf8"
    sha256 cellar: :any,                 x86_64_linux:      "66a2c98f8bccd1b92732fb724577e624610ee3d3e65dba4c2d24793130e43db3"
  end

  depends_on "rust" => :build

  on_linux do
    depends_on "pkgconf" => :build
    depends_on "systemd"
  end

  deny_network_access!

  def fetch
    system "cargo", "fetch", *std_cargo_fetch_args
  end

  def install
    # Upstream forces the `clang` and `lld` linker on Linux
    rm ".cargo/config.toml" if OS.linux?

    # The build profile sets the system-wide client config path
    cp "libs/profiles/release_freebsd.toml", "libs/profiles/homebrew.toml"
    inreplace "libs/profiles/homebrew.toml", "/usr/local", HOMEBREW_PREFIX
    ENV["KANIDM_BUILD_PROFILE"] = "homebrew"

    system "cargo", "install", *std_cargo_args(path: "tools/cli")

    %w[kanidm kanidm_ssh_authorizedkeys_direct].each do |cmd|
      completions = "target/release/build/kanidm_tools/completions"
      bash_completion.install "#{completions}/#{cmd}.bash" => cmd
      fish_completion.install "#{completions}/#{cmd}.fish"
      zsh_completion.install "#{completions}/_#{cmd}"
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/kanidm version")
    assert_match "session", shell_output("#{bin}/kanidm --help")
  end
end
