class Ori < Formula
  desc "OpenRouter's CLI for working with projects you already have"
  homepage "https://openrouter.ai/ori"
  version "0.17.0"
  license "Apache-2.0"

  livecheck do
    url :stable
    regex(/^cli[._-]v?(\d+(?:\.\d+)+)/i)
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/ansg191/homebrew-tap/releases/download/ori-0.17.0"
    sha256                               arm64_tahoe:  "f1c78052e810facf5df44f0593419dea6727046e00d0b0bc28299ea2244fa7c8"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "bfaa478aeeb709432d8449dd0ebe59a8611e5f8d44e2d0c57365243a5961b6e1"
  end

  on_macos do
    on_arm do
      url "https://github.com/OpenRouterLabs/ori-releases/releases/download/cli-0.17.0-31fbdff/ori-darwin-arm64.gz"
      sha256 "cec8028aebd0a08475a9346fb4c5bfb05a29e2a045cbf7a0dae5c7584306b270"
    end
    on_intel do
      url "https://github.com/OpenRouterLabs/ori-releases/releases/download/cli-0.17.0-31fbdff/ori-darwin-x64.gz"
      sha256 "a4a84da114d830447fd908c3efa84f9f2ad127526dc7fb1b8be400323a0edbcc"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/OpenRouterLabs/ori-releases/releases/download/cli-0.17.0-31fbdff/ori-linux-arm64.gz"
      sha256 "424864cf380d11bca37431ffe2cb24d95a31bb8d98804079c46c175033b4f8da"
    end
    on_intel do
      url "https://github.com/OpenRouterLabs/ori-releases/releases/download/cli-0.17.0-31fbdff/ori-linux-x64.gz"
      sha256 "7b81d00663112b0b35f105d537b7a1b9310e02f033b91458a2ba7387820c95e4"
    end
  end

  def install
    bin.install Dir["ori-*"].first => "ori"
  end

  test do
    ENV["ORI_NO_UPDATE_CHECK"] = "1"
    ENV["ORI_TELEMETRY"] = "0"
    assert_match version.to_s, shell_output("#{bin}/ori --version")
  end
end
