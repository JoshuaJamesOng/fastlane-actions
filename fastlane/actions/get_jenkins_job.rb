module Fastlane
  module Actions
    module SharedValues
    end

    class GetJenkinsJobAction < Action
      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        UI.important("Fetching Jenkins job \"http://#{params[:server_url]}/job/#{params[:job_name]}\"")

        # Call endpoint
        response = build(
            params[:server_url],
            params[:job_name],
            params[:username],
            params[:password]
        )

        # Consume endpoint result
        case response[:status]
          when 200
            UI.success('Successfully fetched job')
          else
            UI.important("Jenkins responded with #{response[:status]}:#{response[:body]}")
        end

        response
      end

      def self.call_endpoint(url, method)
        require 'excon'

        case method
          when 'get'
            response = Excon.get(
                url,
                :headers => {'Content-Type' => 'application/x-www-form-urlencoded'}
            )
          else
            UI.user_error!("Unsupported method #{method}")
        end

        return response
      end

      def self.build(server_url, job_name, username, password)
        # curl -X GET JENKINS_URL/job/JOB_NAME/api/json?pretty=true
        url = "http://#{username}:#{password}@#{server_url}/job/#{job_name}/api/json?pretty=true"
        call_endpoint(url, 'get')
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Gets the details for a specific Jenkins job"
      end

      def self.details
        # Optional:
        # this is your chance to provide a more detailed description of this action
        "Makes a GET call to endpoint and returns JSON response"
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
        [
            FastlaneCore::ConfigItem.new(key: :server_url,
                                         env_name: "FL_BUILD_JENKINS_JOB_SERVER_URL",
                                         description: "The server url. e.g. 'https://jenkins.intranet.company'",
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :job_name,
                                         env_name: "FL_BUILD_JENKINS_JOB_JOB_NAME",
                                         description: "Jenkins job name e.g. 'release-1.0.0'",
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :username,
                                         env_name: "FL_BUILD_JENKINS_JOB_USERNAME",
                                         description: "Jenkins username",
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :password,
                                         env_name: "FL_BUILD_JENKINS_JOB_PASSWORD",
                                         description: "Jenkins password",
                                         sensitive: true,
                                         optional: false)
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
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ['JoshuaJamesOng']
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
