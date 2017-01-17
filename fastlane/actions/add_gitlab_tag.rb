module Fastlane
  module Actions
    module SharedValues
    end

    class AddGitlabTagAction < Action
      def self.run(params)
        UI.important("Creating tag \"#{params[:tag_name]}\"")

        # Call endpoint
        response = create_tag(
            params[:server_url],
            params[:api_token],
            params[:repository_id],
            params[:tag_name],
            params[:commit_hash]
        )

        # Consume endpoint result
        case response[:status]
          when 409

          when 201
            UI.success("Successfully created tag \"#{params[:tag_name]}\" on GitLab")

          else
            if response[:status] != 200
              UI.error("GitLab responded with #{response[:status]}:#{response[:body]}")
            end
        end
      end

      def self.call_endpoint(url, method, headers)
        require 'excon'

        case method
          when "post"
            response = Excon.post(url, headers: headers)
          else
            UI.user_error!("Unsupported method #{method}")
        end

        return response
      end

      def self.create_tag(server_url, api_token, id, tag_name, commit)
        # POST /projects/:id/repository/tags?tag_name=:tag_name&ref=:commit
        url = "#{server_url}/projects/#{id}/repository/tags?tag_name=#{tag_name}&ref=#{commit}"
        call_endpoint(url, "post", headers(api_token))
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
        'This will create a new tag on Gitlab'
      end

      def self.details
        'Creates a new tag on Gitlab. You must provide your GitLab personal token
        (get one from /profile/account), the server url, the repository id, tag
        name and commit to tag.'
      end

      def self.available_options
        # Define all options your action supports. 

        # Below a few examples
        [
            FastlaneCore::ConfigItem.new(key: :server_url,
                                         env_name: "FL_SET_GITLAB_RELEASE_SERVER_URL",
                                         description: "The server url. e.g. 'https://gitlab.intranet.company/api/v3'",
                                         optional: false,
                                         verify_block: proc do |value|
                                           UI.user_error!("Please include the protocol in the server url, e.g. https://gitlab.intranet.company/api/v3") unless value.include? "//"
                                         end),
            FastlaneCore::ConfigItem.new(key: :api_token,
                                         env_name: "FL_SET_GITLAB_RELEASE_API_TOKEN",
                                         description: "Gitlab API Private Token from /profile/account",
                                         sensitive: true,
                                         default_value: ENV['GITLAB_PRIVATE_TOKEN'],
                                         optional: false,
                                         verify_block: proc do |value|
                                           UI.user_error!("No Gitlab API Private Token, pass using `api_token: 'token'`") unless (value and not value.empty?)
                                         end),
            FastlaneCore::ConfigItem.new(key: :repository_id,
                                         env_name: "FL_SET_GITLAB_RELEASE_REPOSITORY_ID",
                                         description: "D",
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :tag_name,
                                         env_name: "FL_SET_GITLAB_TAG_NAME",
                                         description: "D",
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :commit_hash,
                                         env_name: "FL_SET_GITLAB_COMMIT_HASH",
                                         description: "D",
                                         default_value: "HEAD",
                                         optional: false)
        ]
      end

      def self.output
        []
      end

      def self.return_value
        []
      end

      def self.authors
        ['JoshuaJamesOng']
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        [
            'add_gitlab_tag(
              server_url: "https://gitlab.intranet.company/api/v3/",
              api_token: ENV["GITLAB_PRIVATE_TOKEN"],
              repository_id: 1,
              tag_name: "v1.0.0",
              commit_hash: "dead69"
            )'
        ]
      end

      def self.category
        :misc
      end
    end
  end
end
