require "rails_helper"

describe ClassificationSuggestions::Llm::Client do
  let(:title) { "More green spaces" }
  let(:description) { "We need parks and trees in the city centre." }

  before do
    Setting["llm.provider"] = "OpenAI"
    Setting["llm.model"] = "gpt-4o"
    Setting["llm.use_ai_classification_suggestions"] = true
  end

  describe ".call" do
    it "returns a response with sampled categories, tags, and sdgs" do
      create(:tag, :category, name: "Culture")
      create(:tag, :category, name: "Health")
      goal_codes = SDG::Goal.pluck(:code).map(&:to_s)
      target_codes = SDG::Target.pluck(:code).map(&:to_s)
      available_sdg_codes = goal_codes + target_codes

      result = ClassificationSuggestions::Llm::Client.call(
        title: title,
        description: description,
        max_suggestions: 6
      )

      expect(result).to be_a(ClassificationSuggestions::Llm::Client::Response)
      expect(result.errors).to be_empty
      expect(result.categories).to all(be_in(%w[Culture Health]))
      expect(result.categories.size).to be <= 2
      expect(result.tags).to eq([])
      expect(result.sdgs).to all(be_in(available_sdg_codes))
      expect(result.sdgs.size).to be <= 6
      expect(result.sdgs).to be_present
    end

    it "clamps max_suggestions to at most 6" do
      create_list(:tag, 8, :category)

      result = ClassificationSuggestions::Llm::Client.call(
        title: title,
        description: description,
        max_suggestions: 99
      )

      expect(result.categories.size).to be <= 6
    end

    it "treats invalid max_suggestions as the default of 6" do
      create_list(:tag, 8, :category)

      result = ClassificationSuggestions::Llm::Client.call(
        title: title,
        description: description,
        max_suggestions: 0
      )

      expect(result.categories.size).to be <= 6
    end

    context "when use_ai_classification_suggestions is disabled" do
      before { Setting["llm.use_ai_classification_suggestions"] = false }

      it "returns an error and empty lists" do
        result = ClassificationSuggestions::Llm::Client.call(title: title, description: description)

        expect(result.errors).to include(
          "LLM is not properly configured. Please contact an administrator."
        )
        expect(result.categories).to eq([])
        expect(result.tags).to eq([])
        expect(result.sdgs).to eq([])
      end
    end

    context "when LLM is not configured" do
      before do
        Setting["llm.provider"] = nil
        Setting["llm.model"] = nil
      end

      it "returns an error and empty lists" do
        result = ClassificationSuggestions::Llm::Client.call(title: title, description: description)

        expect(result.errors).to be_present
        expect(result.categories).to eq([])
      end
    end
  end
end
