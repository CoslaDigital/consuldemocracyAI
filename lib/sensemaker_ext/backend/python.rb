# frozen_string_literal: true

require "shellwords"

module SensemakerExt
  module Backend
    class Python
      attr_reader :job, :artefacts, :runtime_config

      def initialize(job, runtime_config:)
        @job = job
        @artefacts = job.artefacts
        @runtime_config = runtime_config
      end

      def build_command
        command_parts = [Shellwords.escape(cli_executable.to_s)]
        append_llm_flags(command_parts)
        append_script_flags(command_parts)
        append_additional_context_flags(command_parts)
        command_parts.join(" ")
      end

      def working_directory
        artefacts.job_directory
      end

      def check_runtime_dependencies?
        unless system("which python3 > /dev/null 2>&1")
          job.record_error!("Python 3 not found in PATH")
          return false
        end

        return false unless file_exists?(Sensemaker::Paths.sensemaker_folder,
                                         description: "sensemaking-tools folder")
        return false unless file_exists?(Sensemaker::Paths.sensemaker_data_folder,
                                         description: "Sensemaker data folder")
        return false unless file_exists?(artefacts.job_directory,
                                         description: "Sensemaker job data folder")
        return false unless file_exists?(cli_executable, description: "Sensemaker Python CLI")
        return false if requires_input? && !file_exists?(resolved_input_path, description: "Input file")

        true
      end

      def after_input_prepared
        nil
      end

      def redact_command(command)
        command.to_s.gsub(/--api_key\s+\S+/, "--api_key [REDACTED]")
      end

      private

        def cli_executable
          cli_name = Sensemaker::ScriptRegistry.python_cli_for(job.script)
          raise ArgumentError, "No Python CLI mapped for #{job.script}" if cli_name.blank?

          Sensemaker::Paths.sensemaker_folder.join("venv/bin/#{cli_name}")
        end

        def append_llm_flags(command_parts)
          model_name = runtime_config.model
          command_parts << "--model_name #{Shellwords.escape(model_name)}" if model_name.present?

          case runtime_config.adapter
          when "vertex"
            command_parts << "--adapter vertex"
            command_parts << "--vertex_project #{Shellwords.escape(runtime_config.vertex_project_id)}"
            command_parts << "--vertex_location #{Shellwords.escape(runtime_config.vertex_location)}"
          when "openai-compatible"
            command_parts << "--adapter openai-compatible"
            command_parts << "--provider #{Shellwords.escape(runtime_config.compat_provider)}"
            api_key = runtime_config.api_key
            command_parts << "--api_key #{Shellwords.escape(api_key)}" if api_key.present?
          end

          base_url = runtime_config.base_url
          command_parts << "--base_url #{Shellwords.escape(base_url)}" if base_url.present?
        end

        def append_script_flags(command_parts)
          input_path = Shellwords.escape(resolved_input_path)
          output_path = Shellwords.escape(artefacts.default_output_path.to_s)
          output_dir = Shellwords.escape(artefacts.job_directory.to_s)

          case job.script
          when "health_check"
            command_parts << "--output_file #{output_path}"
          when "categorize"
            command_parts << "--input_file #{input_path}"
            command_parts << "--output_dir #{output_dir}"
            command_parts << "--skip_autoraters"
          when "bridge_scores"
            command_parts << "--input_csv #{input_path}"
            command_parts << "--output_csv #{output_path}"
            command_parts << "--scorer_type GEMINI"
          when "report_text"
            command_parts << "--input_csv #{input_path}"
            command_parts << "--output_dir #{output_dir}"
          when "report_ui"
            command_parts << "inline"
            command_parts << "--summary #{input_path}"
            command_parts << "--output #{output_dir}"
          else
            raise ArgumentError, "Unsupported python script for spike: #{job.script}"
          end
        end

        def append_additional_context_flags(command_parts)
          return unless supports_additional_context?

          context = job.additional_context.to_s
          return if context.empty?

          command_parts << "--additional_context #{Shellwords.escape(context)}"
        end

        def supports_additional_context?
          %w[categorize report_text].include?(job.script)
        end

        def requires_input?
          Sensemaker::ScriptRegistry.requires_input?(job.script)
        end

        def resolved_input_path
          path = artefacts.input_path.to_s
          case job.script
          when "bridge_scores"
            return path if path.end_with?("_without_other_filtered.csv")

            "#{path}_without_other_filtered.csv"
          when "report_ui"
            return path if path.end_with?(".json")

            "#{path}.json"
          else
            path
          end
        end

        def file_exists?(file_path, description:)
          return true if File.exist?(file_path)

          job.record_error!("#{description} not found: #{file_path}")
          false
        end
    end
  end
end
