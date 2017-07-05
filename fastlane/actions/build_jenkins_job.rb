module Fastlane
  module Actions
    module SharedValues
    end

    class BuildJenkinsJobAction < Action
      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        UI.important("Starting Jenkins job \"http://#{params[:server_url]}/job/#{params[:job_name]}\"")

        # Call endpoint
        response = build(
            params[:server_url],
            params[:job_name],
            params[:username],
            params[:password],
            params[:parameters],
            params[:form_data]
        )

        # Consume endpoint result
        case response[:status]
          when 201
            UI.success('Successfully started job')
          else
            UI.user_error!("Jenkins responded with #{response[:status]}:#{response[:body]}")
        end
      end

      def self.call_endpoint(url, method, form_data)
        require 'excon'

        case method
          when 'post'
            if form_data.nil?
              response = Excon.post(
                  url,
                  :headers => {'Content-Type' => 'application/x-www-form-urlencoded'}
              )
            else
              command = "curl -X POST -sw '%{http_code}' #{url}"
              form_data.each_pair do |key, value|
                command.concat(" -F '#{key}=@#{value}'")
              end

              response = sh(command)
              code = response[response.length - 3, 3]
              response = {status: Integer(code), body: ''}
            end
          else
            UI.user_error!("Unsupported method #{method}")
        end

        return response
      end

      def self.build(server_url, job_name, username, password, parameter, form_data)
        # curl -X POST JENKINS_URL/job/JOB_NAME/build --data token=TOKEN --data-urlencode json='{"parameter": [{"name":"id", "value":"123"}, {"name":"verbosity", "value":"high"}]}'

        if parameter.nil? && form_data.nil?
          url = "http://#{username}:#{password}@#{server_url}/job/#{job_name}/build"
        elsif form_data.nil?
          url = "http://#{username}:#{password}@#{server_url}/job/#{job_name}/buildWithParameters?#{parameter}"
        else
          url = "http://#{username}:#{password}@#{server_url}/job/#{job_name}/buildWithParameters"
        end

        call_endpoint(url, 'post', form_data)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "A short description with <= 80 characters of what this action does"
      end

      def self.details
        # Optional:
        # this is your chance to provide a more detailed description of this action
        "You can use this action to do cool things..."
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
        [
            FastlaneCore::ConfigItem.new(key: :server_url,
                                         env_name: "FL_BUILD_JENKINS_JOB_SERVER_URL",
                                         description: "The server url. e.g. 'https://gitlab.intranet.company/api/v3'",
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :job_name,
                                         env_name: "FL_BUILD_JENKINS_JOB_JOB_NAME",
                                         description: "Gitlab API Private Token from /profile/account",
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :username,
                                         env_name: "FL_BUILD_JENKINS_JOB_USERNAME",
                                         description: "D",
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :password,
                                         env_name: "FL_BUILD_JENKINS_JOB_PASSWORD",
                                         description: "D",
                                         sensitive: true,
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :parameters,
                                         env_name: "FL_BUILD_JENKINS_PARAMETERS",
                                         description: "D",
                                         default_value: nil,
                                         optional: true),
            FastlaneCore::ConfigItem.new(key: :form_data,
                                         env_name: "FL_BUILD_JENKINS_FORM_DATA",
                                         description: 'Form data to submit with request',
                                         default_value: nil,
                                         is_string: false,
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
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["Your GitHub/Twitter Name"]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
