module Fastlane
  module Actions
    module SharedValues
    end

    class TestGithubAccessAction < Action
      def self.run(params)
        UI.important("Testing access to GitHub")

        # Call endpoint
        response = test_api(
            'https://api.github.com',
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
        # GET /user
        url = "#{server_url}/user"
        call_endpoint(url, "get", headers(api_token))
      end

      def self.headers(api_token)
        require 'base64'
        headers = {'Content-Type' => 'application/json'}
        headers['Authorization'] = "token #{api_token}"
        headers['User-Agent'] = 'Fastlane'
        headers
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Tests token has access to GitHub'
      end

      def self.details
        [
            'Sends a GET request to GitHub with the passed token as the authorization header.',
            '',
            'You must provide your GiHub access token (get one from /settings/tokens).',
            '',
            'Will throw a UI error if the server returns anything other than 200.'
        ].join("\n")
      end

      def self.available_options
        # Define all options your action supports. 

        # Below a few examples
        [
            FastlaneCore::ConfigItem.new(key: :api_token,
                                         env_name: 'FL_TEST_GITHUB_ACCESS_API_TOKEN',
                                         description: 'GitHub API Private Token from /settings/tokens',
                                         sensitive: true,
                                         default_value: ENV['GITHUB_PRIVATE_TOKEN'],
                                         optional: false,
                                         verify_block: proc do |value|
                                           UI.user_error!("No GitHub API Private Token, pass using `api_token: 'token'`") unless (value and not value.empty?)
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
            'test_githhub_access(
              api_token: ENV["GITHUB_PRIVATE_TOKEN"]
            )'
        ]
      end

      def self.category
        :misc
      end
    end
  end
end
