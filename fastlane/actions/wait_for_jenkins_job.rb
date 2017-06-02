module Fastlane
  module Actions
    module SharedValues
    end

    class WaitForJenkinsJobAction < Action
      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        UI.important("Waiting for Jenkins job \"http://#{params[:server_url]}/job/#{params[:job_name]}/#{params[:job_number]}\"")

        waiting = true

        while waiting do
          # Call endpoint
          response = build(
              params[:server_url],
              params[:job_name],
              params[:job_number]
          )

          # Get result from response
          result = get_result_from_response(response)

          # Consume endpoint result
          case result
            when "SUCCESS"
              UI.success('Job was a success')
              waiting = false
              success = true
            when "FAILURE"
            when "ABORTED"
            when "UNSTABLE"
              UI.error('Job was a failure')
              waiting = false
              success = false
            else
              UI.important('Waiting for Job to finish')
              sleep(5)
          end
        end

        return success;
      end

      def self.get_result_from_response(response)
        require 'json'

        return JSON.parse(response[:body])['result']
      end

      def self.call_endpoint(url, method)
        require 'excon'

        case method
          when 'get'
            response = Excon.get(url)
          else
            UI.user_error!("Unsupported method #{method}")
        end

        return response
      end

      def self.build(server_url, job_name, job_number)
        # curl -X GET JENKINS_URL/job/JOB_NAME/JOB_NUMBER

        call_endpoint("http://#{server_url}/job/#{job_name}/#{job_number}/api/json", 'get')
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Wait for the specified Jenkins job to finish"
      end

      def self.details
        [
            'Waits for the specified Jenkins job to finish building.',
            '',
            'You must provide the server url, job name and number. If no job number is given, the latest number is used.',
            '',
            'When the build has a result of SUCCESS or FAILURE, then the action will complete.'
        ].join("\n")
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
        [
            FastlaneCore::ConfigItem.new(key: :server_url,
                                         env_name: "FL_BUILD_JENKINS_JOB_SERVER_URL",
                                         description: "The server url. e.g. 'gitlab.intranet.company/api/v3'",
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :job_name,
                                         env_name: "FL_BUILD_JENKINS_JOB_JOB_NAME",
                                         description: "The Jenkins job. e.g. WC-PR11-Releases",
                                         optional: false,
                                         verify_block: proc do |value|
                                           UI.user_error!("No Jenkins Job specified") unless (value and not value.empty?)
                                         end),
            FastlaneCore::ConfigItem.new(key: :job_number,
                                         env_name: "FL_BUILD_JENKINS_JOB_JOB_NUMBER",
                                         description: "The Jenkins job number. e.g. 1, 2, defaults to lastBuild",
                                         default_value: "lastBuild",
                                         optional: true)
        ]
      end

      def self.output
        # Define the shared values you are going to provide
        # Example
        [
            ['BUILD_JENKINS_JOB_CUSTOM_VALUE', 'A description of what this value contains']
        ]
      end

      def self.return_value
        # If you method provides a return value, you can describe here what it does
        "Returns a bool, which is true if the job successfully complete, else false"
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["ThomasBruggenwirth"]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
