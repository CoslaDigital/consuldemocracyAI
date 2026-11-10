module ClassificationSuggestions
  class PromptBuilder
    TITLE_MAX_LENGTH = 80
    SUMMARY_MAX_LENGTH = 200
    DESCRIPTION_MAX_LENGTH = 6000

    def initialize(title:, summary:, description:, locale:, max_tags:,
                   max_sdgs:, sdg_enabled:)
      @title = title.to_s
      @summary = summary.to_s
      @description = description.to_s
      @locale = locale
      @max_tags = max_tags
      @max_sdgs = max_sdgs
      @sdg_enabled = sdg_enabled
    end

    def system_instructions
      parts = [base_prompt]
      parts << sdg_appendix if @sdg_enabled
      parts.join("\n")
    end

    def user_message
      prompts.fetch("classification_suggestion_user") % {
        title: truncate(@title, TITLE_MAX_LENGTH),
        summary: truncate(@summary, SUMMARY_MAX_LENGTH),
        description: truncate(@description, DESCRIPTION_MAX_LENGTH)
      }
    end

    private

      def base_prompt
        prompts.fetch("classification_suggestion_prompt") % {
          locale: @locale,
          max_tags: @max_tags,
          available_categories: available_category_lines
        }
      end

      def sdg_appendix
        prompts.fetch("classification_suggestion_sdg_system_appendix") % {
          max_sdgs: @max_sdgs,
          available_sdgs: available_sdg_lines
        }
      end

      def available_category_lines
        Tag.category.order(:name).pluck(:name).join("\n")
      end

      def available_sdg_lines
        lines = []
        SDG::Goal.order(:code).includes(:targets, :local_targets).each do |goal|
          lines << "#{goal.code} | #{goal.title}"
          (goal.targets + goal.local_targets).sort.each do |target|
            lines << "#{target.code} | #{target.title}"
          end
        end
        lines.join("\n")
      end

      def truncate(value, length)
        value.truncate(length, omission: "")
      end

      def prompts
        @prompts ||= ::Llm::Config.prompts
      end
  end
end
