require "rails_helper"

describe Sensemaker::Paths do
  describe ".sensemaker_folder" do
    it "uses tmp test folder in test environment" do
      expect(described_class.sensemaker_folder.to_s).to end_with("tmp/sensemaker_test_folder")
    end
  end

  describe ".sensemaker_venv and .sensemaker_bin" do
    it "resolves venv and bin under sensemaker folder" do
      expect(described_class.sensemaker_venv).to eq(
        described_class.sensemaker_folder.join("venv")
      )
      expect(described_class.sensemaker_bin).to eq(
        described_class.sensemaker_venv.join("bin")
      )
    end
  end

  describe ".sensemaking_cli" do
    it "raises when the CLI binary is missing" do
      cli_path = described_class.sensemaker_bin.join(Sensemaker::HEALTH_CHECK_CLI)

      expect do
        described_class.sensemaking_cli(Sensemaker::HEALTH_CHECK_CLI)
      end.to raise_error(RuntimeError, /Sensemaker CLI not found.*#{Regexp.escape(cli_path.to_s)}/)
    end

    it "returns the path when the CLI binary exists and is executable" do
      bin_dir = described_class.sensemaker_bin
      FileUtils.mkdir_p(bin_dir)
      cli_path = bin_dir.join(Sensemaker::HEALTH_CHECK_CLI)
      FileUtils.touch(cli_path)
      FileUtils.chmod(0o755, cli_path)

      expect(described_class.sensemaking_cli(Sensemaker::HEALTH_CHECK_CLI)).to eq(cli_path)
    ensure
      FileUtils.rm_f(described_class.sensemaker_bin.join(Sensemaker::HEALTH_CHECK_CLI))
    end
  end
end
