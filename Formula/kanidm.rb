class Kanidm < Formula
  desc "Client tools for the Kanidm identity management platform"
  homepage "https://kanidm.com/"
  url "https://github.com/kanidm/kanidm/archive/refs/tags/v1.12.1.tar.gz"
  sha256 "d31453a6d78b774eb4109622ac13eada112ba144f2772358920c7c28e9be1fc1"
  license "MPL-2.0"
  head "https://github.com/kanidm/kanidm.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
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
