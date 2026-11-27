# frozen_string_literal: true

class Admin::Sensemaker::ReportConfigDialogComponent < ApplicationComponent
  attr_reader :sensemaker_job

  def initialize(sensemaker_job)
    @sensemaker_job = sensemaker_job
  end

  def properties
    @properties ||= JSON.parse(
      File.read(Sensemaker::Paths.report_ui_config_schema)
    ).fetch("properties", {})
  end

  def string_field?(definition)
    definition["type"] == "string"
  end

  def string_array_field?(definition)
    definition["type"] == "array" && definition.dig("items", "type") == "string"
  end

  def field_label(key, definition)
    t("admin.sensemaker.report_config.fields.#{key}.label",
      default: definition["title"].presence || key.humanize)
  end

  def field_description(key, definition)
    t("admin.sensemaker.report_config.fields.#{key}.hint",
      default: definition["description"].presence || "").presence
  end

  def field_value(key)
    return default_report_title if key == "title"

    nil
  end

  def default_report_title
    sensemaker_job.conversation.target_label(format: :full)
  end
end
