module Fastlane
  module Actions
    module SharedValues
    end

    class TestGitlabAccessAction < Action
      def self.run(params)
        UI.important("Testing access to Gitlab")

        # Call endpoint
        response = test_api(
            params[:server_url],
            params[:api_token]
        )

        # Consume endpoint result
        case response[:status]
          when 200
            UI.success("Successfully accessed API")

          else
            UI.user_error!("Could not access API. Responded with #{response[:status]}:#{response[:body]}")
        end
      end

      def self.call_endpoint(url, method, headers)
        require 'excon'

        case method
          when "get"
            response = Excon.get(url, headers: headers)
          else
            UI.user_error!("Unsupported method #{method}")
        end

        return response
      end

      def self.test_api(server_url, api_token)
        # GET /projects
        url = "#{server_url}/projects"
        call_endpoint(url, "get", headers(api_token))
      end

      def self.headers(api_token)
        require 'base64'
        headers = {'Content-Type' => 'application/json'}
        headers['PRIVATE-TOKEN'] = "#{api_token}"
        headers
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Tests token has access to Gitlab'
      end

      def self.details
        [
            'Sends a GET request to Gitlab with the passed token as the authorization header.',
            '',
            'You must provide your GitLab personal token (get one from /profile/account) and the server url.',
            '',
            'Will throw a UI error if the server returns anything other than 200.'
        ].join("\n")
      end

      def self.available_options
        # Define all options your action supports. 

        # Below a few examples
        [
            FastlaneCore::ConfigItem.new(key: :server_url,
                                         env_name: 'FL_TEST_GITLAB_ACCESS_SERVER_URL',
                                         description: "The server url. e.g. 'https://gitlab.intranet.company/api/v3'",
                                         optional: false,
                                         verify_block: proc do |value|
                                           UI.user_error!('Please include the protocol in the server url, e.g. https://gitlab.intranet.company/api/v3') unless value.include? "//"
                                         end),
            FastlaneCore::ConfigItem.new(key: :api_token,
                                         env_name: 'FL_TEST_GITLAB_ACCESS_API_TOKEN',
                                         description: 'Gitlab API Private Token from /profile/account',
                                         sensitive: true,
                                         default_value: ENV['GITLAB_PRIVATE_TOKEN'],
                                         optional: false,
                                         verify_block: proc do |value|
                                           UI.user_error!("No Gitlab API Private Token, pass using `api_token: 'token'`") unless (value and not value.empty?)
                                         end)
        ]
      end

      def self.authors
        ['JoshuaJamesOng']
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        [
            'test_gitlab_access(
              server_url: "https://gitlab.intranet.company/api/v3/",
              api_token: ENV["GITLAB_PRIVATE_TOKEN"]
            )'
        ]
      end

      def self.category
        :misc
      end
    end
  end
end
