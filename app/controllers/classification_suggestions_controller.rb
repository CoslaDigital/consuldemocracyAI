class ClassificationSuggestionsController < ApplicationController
  before_action :authenticate_user!
  skip_authorization_check

  rate_limit to: 10,
             within: 15.minutes,
             by: -> { current_user.id },
             only: :create,
             with: -> { render_rate_limit_response }

  def create
    @suggestions = ClassificationSuggestions::Llm::Client.call(
      title: draft_params[:title],
      description: draft_params[:description],
      summary: draft_params[:summary],
      max_suggestions: params[:max_suggestions]
    )

    render json: @suggestions
  end

  private

    def render_rate_limit_response
      suggestions = ClassificationSuggestions::Llm::Client::Response.new
      suggestions.errors << I18n.t("classification_suggestions.errors.messages.rate_limit_exceeded")

      render json: suggestions
    end

    def draft_params
      @draft_params ||= extract_draft_params
    end

    def extract_draft_params
      resource = params.require(params[:resource_type].parameterize.underscore)
      translation = Array(resource[:translations_attributes]&.values).first

      {
        title: translation&.dig(:title) || resource[:title],
        description: translation&.dig(:description) || resource[:description],
        summary: translation&.dig(:summary) || resource[:summary]
      }
    end
end
