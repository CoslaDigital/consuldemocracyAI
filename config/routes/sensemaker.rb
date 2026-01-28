namespace :sensemaker do
  get "proposals/jobs", to: "jobs#all_proposals_index", as: :all_proposals_jobs
  get "budgets/:budget_id/jobs", to: redirect("/budgets/%{budget_id}/sensemaking", status: 301),
                                 as: :budget_jobs

  get ":resource_type/:resource_id/jobs",
      to: "jobs#index",
      constraints: {
        resource_type: /
          debates|proposals|polls|topics|poll_questions|legislation_processes|
          legislation-questions|legislation_questions|legislation_proposals|legislation_question_options
          /x
      },
      as: :resource_jobs

  resources :jobs, only: [:show] do
    get "artefacts/report", on: :member, to: "jobs#serve_report", as: :serve_report
    get "artefacts/comments", on: :member, to: "jobs#serve_comments", as: :serve_comments
    get "artefacts/summary", on: :member, to: "jobs#serve_summary", as: :serve_summary
    get "artefacts/topic-stats", on: :member, to: "jobs#serve_topic_stats", as: :serve_topic_stats
  end
end
