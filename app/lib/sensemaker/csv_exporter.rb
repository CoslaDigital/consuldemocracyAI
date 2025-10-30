require "csv"

module Sensemaker
  class CsvExporter
    attr_reader :conversation, :include_votes

    def initialize(conversation, options = {})
      raise ArgumentError,
            "conversation must be a Sensemaker::Conversation" unless conversation.is_a?(Conversation)

      @conversation = conversation
      @include_votes = options.fetch(:include_votes, true)
    end

    def export_to_csv(file_path = nil)
      file_path ||= default_file_path
      FileUtils.mkdir_p(File.dirname(file_path))

      CSV.open(file_path, "w", write_headers: true, headers: csv_headers) do |csv|
        export_data.each do |row|
          csv << row
        end
      end

      file_path
    end

    def export_to_string
      CSV.generate(headers: true) do |csv|
        csv << csv_headers
        export_data.each do |row|
          csv << row
        end
      end
    end

    def self.filter_zero_vote_comments_from_csv(csv_file_path)
      return unless File.exist?(csv_file_path)

      # Read the CSV and filter out rows with zero votes
      filtered_rows = []
      filtering_required = false
      CSV.foreach(csv_file_path, headers: true) do |row|
        agrees = (row["agrees"] || 0).to_i
        disagrees = (row["disagrees"] || 0).to_i
        passes = (row["passes"] || 0).to_i

        # Only include rows that have at least one vote
        if agrees > 0 || disagrees > 0 || passes > 0
          filtered_rows << row
        else
          filtering_required = true
        end
      end

      if filtering_required
        # Keep an unfiltered copy of the CSV
        FileUtils.cp(csv_file_path, "#{csv_file_path}.unfiltered")
        headers = CSV.read("#{csv_file_path}.unfiltered", headers: true).headers
        CSV.open(csv_file_path, "w", write_headers: true, headers: headers) do |csv|
          filtered_rows.each do |row|
            csv << row
          end
        end
        Rails.logger.debug("Filtered CSV: #{filtered_rows.length} comments without votes")
      else
        Rails.logger.debug("All comments have votes, no filtering required")
      end
    end

    private

      def csv_headers
        ["comment-id", "comment_text", "agrees", "disagrees", "passes", "author-id"]
      end

      def export_data
        data = []
        data.concat(comments_as_rows)
        data
      end

      def comments_as_rows
        items = @conversation.comments

        items.map do |item|
          # Works with both Comment AR objects and CommentLikeItem Data objects
          [
            item_id(item),
            item.body,
            item.cached_votes_up || 0,
            item.cached_votes_down || 0,
            item_votes_neutral(item),
            item.user_id
          ]
        end
      end

      def item_id(item)
        if item.is_a?(CommentLikeItem)
          "item_#{item.id}"
        else
          "comment_#{item.id}"
        end
      end

      def item_votes_neutral(item)
        total = item.cached_votes_total || 0
        up = item.cached_votes_up || 0
        down = item.cached_votes_down || 0
        [total - up - down, 0].max
      end

      def default_file_path
        data_folder = Sensemaker::JobRunner.sensemaker_data_folder
        File.join(data_folder, "sensemaker-input.csv")
      end
  end
end
