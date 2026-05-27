require "rails_helper"

describe Sensemaker::Scripts do
  describe ".cli_for" do
    it "returns the sensemaking CLI command for categorize" do
      expect(Sensemaker::Scripts.cli_for("categorize")).to eq("sensemaking-categorize")
    end

    it "returns the sensemaking report CLI command for report_ui" do
      expect(Sensemaker::Scripts.cli_for("report_ui")).to eq("sensemaking-report")
    end

    it "raises for unknown scripts" do
      expect do
        Sensemaker::Scripts.cli_for("runner.ts")
      end.to raise_error(ArgumentError, /Unknown Sensemaker script/)
    end
  end

  describe ".primary_output_basename" do
    it "returns report_data.json for report_text" do
      expect(Sensemaker::Scripts.primary_output_basename("report_text")).to eq("report_data.json")
    end
  end
end
