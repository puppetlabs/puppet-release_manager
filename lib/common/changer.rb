# frozen_string_literal: true

module ReleaseManager
  module Common
    class PromotionChanger
      class << self
        def change_promotion(request)
          clone_ci_configs
          file_path = CI_CONFIGS_DIR.join('jenkii/platform/projects/puppet-agent.yaml')
          @branch = request.source_branch.tr('.', '')
          @found = false
          git_helper.use_repo(CI_CONFIGS_DIR) do
            FileEditor.new(file_path: file_path).edit(&modify_promotion)
            commit_and_push_changes(request)
          end
        end

        private

        def clone_ci_configs
          logger.info('Cloning ci-job-configs...')
          cloner.clone_component(factory.create_ci_jobs_config)
        end

        def commit_and_push_changes(request)
          git_helper.commit("(maint) Disable PE promotion for #{request.source_branch}")
          git_helper.push
        end

        def modify_promotion
          lambda do |line|
            if @found == true
              line = change_line(line)
              @found = false
            end
            @found = true if /&#{@branch}_agent_pe_promotion/.match?(line)
            line
          end
        end

        def change_line(line)
          return line.gsub('TRUE', 'FALSE') if /TRUE/.match?(line)

          line.gsub('FALSE', 'TRUE') if /FALSE/.match?(line)
        end

        def cloner
          Common::Cloner
        end

        def git_helper
          Helpers::Git
        end

        def file_helper
          Helpers::File
        end

        def factory
          Factories::ComponentFactory
        end

        def logger
          ReleaseManager.logger
        end
      end
    end
  end
end
