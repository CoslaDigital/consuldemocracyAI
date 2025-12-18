require "rails_helper"

describe Sensemaker::JobsController do
  let(:user) { create(:user) }
  let(:debate) { create(:debate) }
  let(:job) do
    create(:sensemaker_job,
           analysable_type: "Debate",
           analysable_id: debate.id,
           user: user,
           finished_at: Time.current,
           persisted_output: Rails.root.join("tmp", "test-report.html").to_s,
           published: true)
  end

  before do
    FileUtils.mkdir_p(File.dirname(job.persisted_output))
    File.write(job.persisted_output, "<html><body>Test Report</body></html>")
  end

  after do
    FileUtils.rm_f(job.persisted_output) if job.persisted_output.present?
  end

  describe "GET #show" do
    context "when job is unpublished" do
      before do
        job.update!(published: false)
      end

      it "returns 302 and redirects to root path" do
        get :show, params: { id: job.id }
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_path)
      end
    end

    context "when job exists and has output" do
      it "renders the report view page" do
        get :show, params: { id: job.id }

        expect(response).to have_http_status(:ok)
      end
    end

    context "when job exists but has no output" do
      before do
        job.update!(persisted_output: nil)
      end

      it "returns 404" do
        get :show, params: { id: job.id }

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when job exists but file is missing" do
      before do
        FileUtils.rm_f(job.persisted_output)
      end

      it "returns 404" do
        get :show, params: { id: job.id }

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET #serve_report" do
    context "when job is unpublished" do
      before do
        job.update!(published: false)
      end

      it "returns 302 and redirects to root path" do
        get :serve_report, params: { id: job.id }
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_path)
      end
    end

    context "when job exists and has output" do
      it "sends the file with correct headers" do
        get :serve_report, params: { id: job.id }

        expect(response).to have_http_status(:ok)
        expect(response.headers["Content-Type"]).to eq("text/html")
        expect(response.headers["Content-Disposition"]).to include("inline")
        expect(response.body).to include("Test Report")
      end

      it "determines correct content type for HTML files" do
        get :serve_report, params: { id: job.id }

        expect(response.headers["Content-Type"]).to eq("text/html")
      end

      it "determines correct content type for CSV files" do
        job.update!(persisted_output: Rails.root.join("tmp", "test-report.csv").to_s)
        File.write(job.persisted_output, "col1,col2\nval1,val2")

        get :serve_report, params: { id: job.id }

        expect(response.headers["Content-Type"]).to eq("text/csv")
      end

      it "determines correct content type for JSON files" do
        job.update!(persisted_output: Rails.root.join("tmp", "test-report.json").to_s)
        File.write(job.persisted_output, '{"test": "data"}')

        get :serve_report, params: { id: job.id }

        expect(response.headers["Content-Type"]).to eq("application/json")
      end

      it "determines correct content type for TXT files" do
        job.update!(persisted_output: Rails.root.join("tmp", "test-report.txt").to_s)
        File.write(job.persisted_output, "Plain text content")

        get :serve_report, params: { id: job.id }

        expect(response.headers["Content-Type"]).to eq("text/plain")
      end

      it "uses application/octet-stream for unknown file types" do
        job.update!(persisted_output: Rails.root.join("tmp", "test-report.unknown").to_s)
        File.write(job.persisted_output, "Unknown content")

        get :serve_report, params: { id: job.id }

        expect(response.headers["Content-Type"]).to eq("application/octet-stream")
      end
    end

    context "when job does not exist" do
      it "returns 404" do
        get :serve_report, params: { id: 99999 }

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when job exists but has no output" do
      before do
        job.update!(persisted_output: nil)
      end

      it "returns 404" do
        get :serve_report, params: { id: job.id }

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when job exists but file is missing" do
      before do
        FileUtils.rm_f(job.persisted_output)
      end

      it "returns 404" do
        get :serve_report, params: { id: job.id }

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET #serve_comments" do
    let(:admin) { create(:administrator).user }
    let(:comments_file) { "#{job.persisted_output}-comments-with-scores.json" }

    before do
      FileUtils.mkdir_p(File.dirname(comments_file))
      File.write(comments_file, '{"comments": []}')
    end

    after do
      FileUtils.rm_f(comments_file)
    end

    context "when user is an administrator" do
      before { sign_in(admin) }

      context "when job exists and file exists" do
        it "sends the file with correct headers" do
          get :serve_comments, params: { id: job.id }

          expect(response).to have_http_status(:ok)
          expect(response.headers["Content-Type"]).to eq("application/json")
          expect(response.headers["Content-Disposition"]).to include("inline")
          expect(response.headers["Content-Disposition"]).to include("comments-with-scores.json")
          expect(response.body).to include("comments")
        end
      end

      context "when file does not exist" do
        before do
          FileUtils.rm_f(comments_file)
        end

        it "returns 404" do
          get :serve_comments, params: { id: job.id }

          expect(response).to have_http_status(:not_found)
        end
      end

      context "when job has no persisted_output and uses default_output_path" do
        let(:job_without_persisted) do
          create(:sensemaker_job,
                 analysable_type: "Debate",
                 analysable_id: debate.id,
                 user: admin,
                 finished_at: Time.current,
                 persisted_output: nil,
                 published: true,
                 script: "advanced_runner.ts")
        end
        let(:default_comments_file) do
          base_path = job_without_persisted.default_output_path
          "#{base_path}-comments-with-scores.json"
        end

        before do
          FileUtils.mkdir_p(File.dirname(default_comments_file))
          File.write(default_comments_file, '{"comments": []}')
        end

        after do
          FileUtils.rm_f(default_comments_file)
        end

        it "sends the file from default_output_path" do
          get :serve_comments, params: { id: job_without_persisted.id }

          expect(response).to have_http_status(:ok)
          expect(response.headers["Content-Type"]).to eq("application/json")
        end
      end
    end
  end

  describe "GET #serve_summary" do
    let(:admin) { create(:administrator).user }
    let(:summary_file) { "#{job.persisted_output}-summary.json" }

    before do
      FileUtils.mkdir_p(File.dirname(summary_file))
      File.write(summary_file, '{"summary": "test"}')
    end

    after do
      FileUtils.rm_f(summary_file)
    end

    context "when user is an administrator" do
      before { sign_in(admin) }

      context "when job exists and file exists" do
        it "sends the file with correct headers" do
          get :serve_summary, params: { id: job.id }

          expect(response).to have_http_status(:ok)
          expect(response.headers["Content-Type"]).to eq("application/json")
          expect(response.headers["Content-Disposition"]).to include("inline")
          expect(response.headers["Content-Disposition"]).to include("summary.json")
          expect(response.body).to include("summary")
        end
      end

      context "when file does not exist" do
        before do
          FileUtils.rm_f(summary_file)
        end

        it "returns 404" do
          get :serve_summary, params: { id: job.id }

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe "GET #serve_topic_stats" do
    let(:admin) { create(:administrator).user }
    let(:topic_stats_file) { "#{job.persisted_output}-topic-stats.json" }

    before do
      FileUtils.mkdir_p(File.dirname(topic_stats_file))
      File.write(topic_stats_file, '{"topics": []}')
    end

    after do
      FileUtils.rm_f(topic_stats_file)
    end

    context "when user is an administrator" do
      before { sign_in(admin) }

      context "when job exists and file exists" do
        it "sends the file with correct headers" do
          get :serve_topic_stats, params: { id: job.id }

          expect(response).to have_http_status(:ok)
          expect(response.headers["Content-Type"]).to eq("application/json")
          expect(response.headers["Content-Disposition"]).to include("inline")
          expect(response.headers["Content-Disposition"]).to include("topic-stats.json")
          expect(response.body).to include("topics")
        end
      end
    end
  end
end
