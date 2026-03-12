class Admin::Sensemaker::IndexComponent < ApplicationComponent
  include Header

  attr_reader :sensemaker_jobs, :running_jobs, :filter_target,
              :filter_resource_type, :filter_resource_id, :filter_resource_type_options

  def initialize(sensemaker_jobs, running_jobs, filter_target: nil,
                 filter_resource_type: nil, filter_resource_id: nil, filter_resource_type_options: [])
    @sensemaker_jobs = sensemaker_jobs
    @running_jobs = running_jobs
    @filter_target = filter_target
    @filter_resource_type = filter_resource_type
    @filter_resource_id = filter_resource_id
    @filter_resource_type_options = filter_resource_type_options || []
  end

  def title
    t("admin.sensemaker.index.title")
  end

  def enabled?
    feature?(:sensemaker)
  end

  def target_specified?
    filter_target.present?
  end

  def filter_active?
    filter_target.present? || filter_resource_type.present?
  end

  def filter_description
    return filter_target_name if filter_target.present?
    return t("admin.sensemaker.index.resource_types.#{filter_resource_type}") if filter_resource_type.present?

    nil
  end

  def filter_target_name
    return nil unless filter_target

    filter_target&.name.presence || filter_target&.title.presence || "##{filter_target.id}"
  end
end
