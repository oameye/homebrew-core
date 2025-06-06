class Circleci < Formula
  desc "Enables you to reproduce the CircleCI environment locally"
  homepage "https://circleci.com/docs/2.0/local-cli/"
  # Updates should be pushed no more frequently than once per week.
  url "https://github.com/CircleCI-Public/circleci-cli.git",
      tag:      "v0.1.32219",
      revision: "c563702e31e2dee4f4a45882c57ddaae91caeb8f"
  license "MIT"
  head "https://github.com/CircleCI-Public/circleci-cli.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "08c81f76f23546390918fb9252af5d138a1ca07758035628914b9d5deb8c3e6e"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "08c81f76f23546390918fb9252af5d138a1ca07758035628914b9d5deb8c3e6e"
    sha256 cellar: :any_skip_relocation, arm64_ventura: "08c81f76f23546390918fb9252af5d138a1ca07758035628914b9d5deb8c3e6e"
    sha256 cellar: :any_skip_relocation, sonoma:        "bfb2cb75236390116f33b4832c4d8fde2fb8bc6c15deea9242dac526a3d49453"
    sha256 cellar: :any_skip_relocation, ventura:       "bfb2cb75236390116f33b4832c4d8fde2fb8bc6c15deea9242dac526a3d49453"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "d876d75b710f7ae40a1546bfd299a7679b88f87d397a376c8a59c2e7c57fb092"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/CircleCI-Public/circleci-cli/version.packageManager=#{tap.user.downcase}
      -X github.com/CircleCI-Public/circleci-cli/version.Version=#{version}
      -X github.com/CircleCI-Public/circleci-cli/version.Commit=#{Utils.git_short_head}
      -X github.com/CircleCI-Public/circleci-cli/telemetry.SegmentEndpoint=https://api.segment.io
    ]
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"circleci", "--skip-update-check", "completion",
                                        shells: [:bash, :zsh])
  end

  test do
    ENV["CIRCLECI_CLI_TELEMETRY_OPTOUT"] = "1"
    # assert basic script execution
    assert_match(/#{version}\+.{7}/, shell_output("#{bin}/circleci version").strip)
    (testpath/".circleci.yml").write("{version: 2.1}")
    output = shell_output("#{bin}/circleci config pack #{testpath}/.circleci.yml")
    assert_match "version: 2.1", output
    # assert update is not included in output of help meaning it was not included in the build
    assert_match(/update.+This command is unavailable on your platform/, shell_output("#{bin}/circleci help 2>&1"))
    assert_match "update is not available because this tool was installed using homebrew.",
      shell_output("#{bin}/circleci update")
  end
end
