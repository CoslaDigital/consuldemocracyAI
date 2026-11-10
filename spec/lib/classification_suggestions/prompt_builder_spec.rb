require "rails_helper"

describe ClassificationSuggestions::PromptBuilder do
  def build(sdg_enabled: false, **attrs)
    described_class.new(
      title: "Green parks",
      summary: "More trees",
      description: "Plant trees downtown",
      locale: :en,
      max_tags: 4,
      max_sdgs: 3,
      sdg_enabled: sdg_enabled,
      **attrs
    )
  end

  describe "#system_instructions" do
    before do
      create(:tag, :category, name: "Culture")
      create(:tag, :category, name: "Health")
    end

    it "includes categories, max_tags, and locale" do
      instructions = build.system_instructions

      expect(instructions).to include("Culture")
      expect(instructions).to include("Health")
      expect(instructions).to include("<max_tags>4</max_tags>")
      expect(instructions).to include("<locale>en</locale>")
    end

    it "omits the SDG appendix when disabled" do
      instructions = build(sdg_enabled: false).system_instructions

      expect(instructions).not_to include("<available_sdgs>")
      expect(instructions).not_to include("sdg_instructions")
    end

    it "appends SDG goals, targets, local targets, and max_sdgs when enabled" do
      local_target = create(:sdg_local_target, code: "1.1.1")
      target = local_target.target
      goal = local_target.goal

      instructions = build(sdg_enabled: true).system_instructions

      expect(instructions).to include("<max_sdgs>3</max_sdgs>")
      expect(instructions).to include("sdg_instructions")
      expect(instructions).to include("#{goal.code} | #{goal.title}")
      expect(instructions).to include("#{target.code} | #{target.title}")
      expect(instructions).to include("#{local_target.code} | #{local_target.title}")
    end
  end

  describe "#user_message" do
    it "includes truncated draft fields" do
      message = build(
        title: "T" * 100,
        summary: "S" * 250,
        description: "D" * 6100
      ).user_message

      expect(message).to include("<title>#{"T" * 80}</title>")
      expect(message).to include("<summary>#{"S" * 200}</summary>")
      expect(message).to include("<description>#{"D" * 6000}</description>")
      expect(message).not_to include("T" * 81)
    end

    it "renders blank draft fields as empty tags" do
      message = build(title: nil, summary: nil, description: nil).user_message

      expect(message).to include("<title></title>")
      expect(message).to include("<summary></summary>")
      expect(message).to include("<description></description>")
    end
  end
end
