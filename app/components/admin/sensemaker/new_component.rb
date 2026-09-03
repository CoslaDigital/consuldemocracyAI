class Admin::Sensemaker::NewComponent < ApplicationComponent
  include Header

  attr_reader :sensemaker_job

  QUICK_ACTIONS = {
    summary: { label_key: "admin.sensemaker.new.generate_summary", default_backend: :node },
    report: { label_key: "admin.sensemaker.new.generate_report", default_backend: :node }
  }.freeze

  def quick_action_scripts(logical_name)
    scripts = Sensemaker::ScriptRegistry.scripts_for_logical_name(logical_name)
    preferred = QUICK_ACTIONS.fetch(logical_name)[:default_backend]
    default = scripts.find { |script| Sensemaker::ScriptRegistry.backend_for(script) == preferred }

    ([default] + scripts).compact.uniq
  end

  def script_option_label(script)
    key = Sensemaker::ScriptRegistry.i18n_key(script)
    I18n.t("admin.sensemaker.scripts.#{key}.title")
  end

  def script_options
    Sensemaker::ScriptRegistry.user_selectable.map do |script|
      key = Sensemaker::ScriptRegistry.i18n_key(script)
      [I18n.t("admin.sensemaker.scripts.#{key}.title"), script]
    end
  end

  def initialize(sensemaker_job, search_results, result_count)
    @sensemaker_job = sensemaker_job
    @search_results = search_results
    @result_count = result_count
    @query_types = [
      "Debate",
      "Proposal",
      "Poll",
      "Legislation::Process",
      "Budget"
    ]
  end

  def title
    t("admin.sensemaker.new.title")
  end
end
