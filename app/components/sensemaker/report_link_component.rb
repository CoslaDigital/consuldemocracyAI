class Sensemaker::ReportLinkComponent < ApplicationComponent
  attr_reader :analysable_resource

  def initialize(analysable_resource)
    @analysable_resource = analysable_resource
  end

  def render?
    feature?(:sensemaker) && report_available?
  end

  def report_available?
    case analysable_resource
    when Budget
      Sensemaker::Job.for_budget(analysable_resource).exists?
    when Legislation::Process
      Sensemaker::Job.for_process(analysable_resource).exists?
    when Budget::Group
      Sensemaker::Job.for_budget(analysable_resource.budget).exists?
    else
      if analysable_resource.class.name == "Proposal" && analysable_resource.id.nil?
        Sensemaker::Job.published.where(analysable_type: "Proposal", analysable_id: nil).exists?
      else
        Sensemaker::Job.published
                       .where(analysable_type: analysable_resource.class.name,
                              analysable_id: analysable_resource.id)
                       .exists?
      end
    end
  end

  def analysis_title
    t("sensemaker.analysis.title")
  end

  def analysis_description
    t("sensemaker.analysis.description",
      subject: t("activerecord.models.#{analysable_resource.class.model_name.i18n_key}.one").downcase)
  end

  def view_report_text
    t("sensemaker.analysis.view_report")
  end

  def link_to_analysis
    link_to view_report_text, jobs_index_path_for(analysable_resource), class: "button hollow expanded",
                                                                        target: "_blank"
  end

  private

    def jobs_index_path_for(resource)
      case resource
      when Budget
        sensemaker_budget_jobs_path(resource.id)
      when Legislation::Process
        sensemaker_legislation_process_jobs_path(resource.id)
      when Budget::Group
        sensemaker_budget_jobs_path(resource.budget_id)
      else
        if resource.class.name == "Proposal" && resource.id.nil?
          sensemaker_all_proposals_jobs_path
        else
          resource_type = resource_type_for_route(resource.class)
          sensemaker_resource_jobs_path(resource_type: resource_type, resource_id: resource.id)
        end
      end
    end

    def resource_type_for_route(model_class)
      case model_class.name
      when "Debate"
        "debates"
      when "Proposal"
        "proposals"
      when "Poll"
        "polls"
      when "Poll::Question"
        "poll_questions"
      when "Legislation::Question"
        "legislation_questions"
      when "Legislation::Proposal"
        "legislation_proposals"
      when "Legislation::QuestionOption"
        "legislation_question_options"
      when "Topic"
        "topics"
      else
        raise ArgumentError, "Unknown resource type for route: #{model_class.name}"
      end
    end
end
