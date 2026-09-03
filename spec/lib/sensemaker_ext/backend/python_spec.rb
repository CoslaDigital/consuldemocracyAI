# frozen_string_literal: true

require "rails_helper"

describe SensemakerExt::Backend::Python do
  include_context "sensemaker llm config"

  let(:user) { create(:user) }
  let(:debate) { create(:debate) }
  let(:data_folder) { "/tmp/sensemaker_test_folder/data" }
  let(:report_builder_folder) { Rails.root.join("tmp/sensemaker_test_folder/report-builder") }
  let(:runtime_config) do
    Sensemaker::RuntimeConfig.new(setting: Setting, llm_context: Llm::Config.context)
  end

  before do
    SensemakerExt::Loader.install!
    allow(Sensemaker::Paths).to receive(:sensemaker_data_folder).and_return(data_folder)
    allow(Sensemaker::Paths).to receive(:job_directory) do |j|
      "#{data_folder}/job-#{j.id}"
    end
    allow(SensemakerExt::Paths).to receive(:report_builder_folder).and_return(report_builder_folder)
    FileUtils.mkdir_p(report_builder_folder.join("bin"))
    File.write(report_builder_folder.join("bin/cli.js"), "#!/usr/bin/env node\n")
  end

  describe "report_ui" do
    let(:summary_path) { "#{data_folder}/job-summary/report_data.json" }
    let(:bridging_path) { "#{data_folder}/job-bridge/bridging_scores.csv" }

    let(:job) do
      create(:sensemaker_job,
             analysable_type: "Debate",
             analysable_id: debate.id,
             script: "report_ui",
             user: user,
             started_at: Time.current,
             input_file: summary_path,
             additional_context: "")
    end
    let(:backend) { SensemakerExt::Backend::Python.new(job, runtime_config: runtime_config) }

    let!(:report_text_job) do
      create(:sensemaker_job,
             parent_job: job,
             analysable_type: "Debate",
             analysable_id: debate.id,
             script: "report_text",
             user: user,
             started_at: Time.current)
    end
    let!(:bridge_job) do
      create(:sensemaker_job,
             parent_job: report_text_job,
             analysable_type: "Debate",
             analysable_id: debate.id,
             script: "bridge_scores",
             user: user,
             started_at: Time.current)
    end

    before do
      FileUtils.mkdir_p(File.dirname(summary_path))
      FileUtils.mkdir_p(File.dirname(bridging_path))
      FileUtils.mkdir_p(Sensemaker::Paths.job_directory(job))
      FileUtils.mkdir_p(Sensemaker::Paths.job_directory(bridge_job))
      File.write(summary_path, '{"text":"hi","sub_contents":[]}')
      File.write(bridging_path, "topic,opinion,quote,participant_id\n")
      # Place bridging output where JobArtefacts expects it for bridge_scores
      FileUtils.cp(
        bridging_path,
        File.join(Sensemaker::Paths.job_directory(bridge_job), "bridging_scores.csv")
      )
    end

    describe "#build_command" do
      it "invokes the report-builder CLI with summary, bridging scores, and output file" do
        command = backend.build_command
        expected_bridging = File.join(Sensemaker::Paths.job_directory(bridge_job), "bridging_scores.csv")
        expected_output = File.join(Sensemaker::Paths.job_directory(job), "report.html")

        expect(command).to include("node #{report_builder_folder.join("bin/cli.js")}")
        expect(command).to include("inline")
        expect(command).to include("--bridging_scores #{expected_bridging}")
        expect(command).to include("--summary #{summary_path}")
        expect(command).to include("--output #{expected_output}")
        expect(command).not_to include("--adapter")
        expect(command).not_to include("sensemaking-")
        expect(command).not_to include("venv/bin")
      end
    end

    describe "#working_directory" do
      it "uses Rails.root so node_modules resolves" do
        expect(backend.working_directory).to eq(Rails.root)
      end
    end

    describe "#check_runtime_dependencies?" do
      before do
        allow(backend).to receive(:system).with("which node > /dev/null 2>&1").and_return(true)
      end

      it "returns true when node, package, summary, and bridging artefacts exist" do
        expect(backend.check_runtime_dependencies?).to be true
      end

      it "returns false when bridging scores are missing from the prep chain" do
        FileUtils.rm_f(File.join(Sensemaker::Paths.job_directory(bridge_job), "bridging_scores.csv"))
        expect(backend.check_runtime_dependencies?).to be false
        expect(job.error).to include("Bridging scores CSV")
      end

      it "returns false when the report-builder CLI is missing" do
        FileUtils.rm_f(report_builder_folder.join("bin/cli.js"))
        expect(backend.check_runtime_dependencies?).to be false
        expect(job.error).to include("sensemaking-report-builder CLI")
      end
    end
  end
end
