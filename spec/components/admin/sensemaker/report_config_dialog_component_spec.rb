# frozen_string_literal: true

require "rails_helper"

describe Admin::Sensemaker::ReportConfigDialogComponent, type: :component do
  include_context "sensemaker report ui config schema"

  it "renders dialog fields with translated labels from the schema keys" do
    render_inline(Admin::Sensemaker::ReportConfigDialogComponent.new)

    expect(page).to have_css("dialog#report-config-dialog")
    expect(page).to have_field("sensemaker_job[run_options][config][title]")
    expect(page).to have_field("sensemaker_job[run_options][config][logo]")
    expect(page).to have_field("sensemaker_job[run_options][config][excluded_topics][]")
    expect(page).to have_content(I18n.t("admin.sensemaker.report_config.fields.title.label"))
    expect(page).to have_content(I18n.t("admin.sensemaker.report_config.fields.logo.label"))
    expect(page).to have_content(I18n.t("admin.sensemaker.report_config.fields.excluded_topics.label"))
    expect(page).to have_content(I18n.t("admin.sensemaker.report_config.fields.excluded_topics.hint"))
    expect(page).to have_button(I18n.t("admin.sensemaker.new.generate_report"))
    expect(page).to have_css("button[name='quick_action'][value='report']")
  end
end
