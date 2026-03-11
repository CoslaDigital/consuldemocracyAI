class Admin::Sensemaker::IndexComponent < ApplicationComponent
  include Header

  attr_reader :sensemaker_jobs, :running_jobs, :filter_target

  def initialize(sensemaker_jobs, running_jobs, filter_target: nil)
    @sensemaker_jobs = sensemaker_jobs
    @running_jobs = running_jobs
    @filter_target = filter_target
  end

  def title
    t("admin.sensemaker.index.title")
  end

  def enabled?
    feature?(:sensemaker)
  end

  def filter_target_name
    return nil unless filter_target

    filter_target&.name.presence || filter_target&.title.presence || "##{filter_target.id}"
  end
end
