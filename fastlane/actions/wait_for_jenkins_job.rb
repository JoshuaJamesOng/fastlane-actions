module Fastlane
  module Actions
    module SharedValues
    end

    class WaitForJenkinsJobAction < Action
      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        UI.important("Waiting for Jenkins job \"http://#{params[:server_url]}/job/#{params[:job_name]}/#{params[:job_number]}\"")

        is_built = false
        is_success = false

        until is_built do
          # Call endpoint
          response = build(
              params[:server_url],
              params[:job_name],
              params[:job_number]
          )

          # Consume endpoint result
          case response[:status]
            when 200
              # Get result from response
              json = JSON.parse(response[:body])

              # Check if job finished building
              if !json['building']
                is_built = true

                # Return build status of job
                is_success = get_result(
                    json['result']
                )
              else
                # If not built, try again in a few moments
                wait('Waiting for Job to finish')
              end

            when 404
              wait('Waiting for Job to exist')

            else
              UI.user_error!('Unexpected error whilst fetching Jenkins job')
          end

        end

        return is_success
      end

      def self.wait(message)
        UI.important(message)
        sleep(5)
      end

      def self.get_result(result)
        success = false

        case result
          when 'SUCCESS'
            success = true
          when 'FAILURE'
          when 'ABORTED'
          when 'UNSTABLE'
            success = false
          else
            UI.user_error!('Unhandled Jenkins status')
        end

        if success
          UI.success('Result was a success')
        else
          UI.error('Result was a failure')
        end

        success
      end

      def self.call_endpoint(url, method)
        require 'excon'

        case method
          when 'get'
            response = Excon.get(url)
          else
            response = nil
            UI.user_error!("Unsupported method #{method}")
        end

        response
      end

      def self.build(server_url, job_name, job_number)
        # curl -X GET JENKINS_URL/job/JOB_NAME/JOB_NUMBER

        call_endpoint("http://#{server_url}/job/#{job_name}/#{job_number}/api/json", 'get')
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Wait for the specified Jenkins job to finish'
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
                                         env_name: 'FL_BUILD_JENKINS_JOB_SERVER_URL',
                                         description: "The server url. e.g. 'gitlab.intranet.company/api/v3'",
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :job_name,
                                         env_name: 'FL_BUILD_JENKINS_JOB_JOB_NAME',
                                         description: 'The Jenkins job. e.g. WC-PR11-Releases',
                                         optional: false,
                                         verify_block: proc do |value|
                                           UI.user_error!('No Jenkins Job specified') unless (value and not value.empty?)
                                         end),
            FastlaneCore::ConfigItem.new(key: :job_number,
                                         env_name: 'FL_BUILD_JENKINS_JOB_JOB_NUMBER',
                                         description: 'The Jenkins job number. e.g. 1, 2, defaults to lastBuild',
                                         default_value: 'lastBuild',
                                         optional: true)
        ]
      end

      def self.return_value
        'Returns a bool, which is true if the job successfully complete, else false'
      end

      def self.authors
        ['ThomasBruggenwirth && JoshuaJamesOng']
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        [
            'is_success = wait_for_jenkins_job(
              server_url: "https://jenkins.intranet.company.com",
              job_name: "MyGroup/view/MyView/job/release-1.0.0",
              job_number: "lastBuild"
            )'
        ]
      end
    end
  end
end
