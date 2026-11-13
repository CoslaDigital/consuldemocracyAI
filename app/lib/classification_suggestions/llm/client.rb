module ClassificationSuggestions
  module Llm
    class Client
      DEFAULT_MAX_SUGGESTIONS = 6
      MAX_SUGGESTIONS_LIMIT = 6
      FAKE_LATENCY_SECONDS = 2

      def self.call(title: nil, description: nil, summary: nil, max_suggestions: DEFAULT_MAX_SUGGESTIONS)
        new(
          title: title,
          description: description,
          summary: summary,
          max_suggestions: max_suggestions
        ).call
      end

      def initialize(title: nil, description: nil, summary: nil, max_suggestions: DEFAULT_MAX_SUGGESTIONS)
        @title = title
        @description = description
        @summary = summary
        @max_suggestions = clamp_max_suggestions(max_suggestions)
      end

      def call
        validate_llm_settings!
        return response if response.errors.any?

        simulate_latency
        response.categories = sample_categories
        response.tags = []
        response.sdgs = sample_sdgs
        response
      end

      def response
        @response ||= Response.new
      end

      class Response
        attr_accessor :categories, :tags, :sdgs
        attr_reader :errors

        def initialize
          @categories = []
          @tags = []
          @sdgs = []
          @errors = []
        end

        def as_json(*)
          {
            categories: categories,
            tags: tags,
            sdgs: sdgs,
            errors: errors
          }
        end
      end

      private

        def clamp_max_suggestions(value)
          n = value.to_i
          n = DEFAULT_MAX_SUGGESTIONS if n < 1
          [n, MAX_SUGGESTIONS_LIMIT].min
        end

        def validate_llm_settings!
          unless ::Llm::Config.configured? && Setting["llm.use_ai_classification_suggestions"].present?
            response.errors << I18n.t("classification_suggestions.errors.messages.llm_not_configured")
          end
        end

        def simulate_latency
          sleep(FAKE_LATENCY_SECONDS)
        end

        def sample_categories
          Tag.category.pluck(:name).sample(@max_suggestions)
        end

        def sample_sdgs
          codes = SDG::Goal.pluck(:code).map(&:to_s) + SDG::Target.pluck(:code).map(&:to_s)
          codes.uniq.sample(@max_suggestions)
        end
    end
  end
end
