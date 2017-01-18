module Fastlane
  module Actions
    module SharedValues
    end

    class SetGitlabReleaseAction < Action
      def self.run(params)
        UI.important("Creating release on tag \"#{params[:tag_name]}\"")

        require 'json'

        # https://docs.gitlab.com/ee/api/tags.html#create-a-new-release
        body_obj = {
            'tag_name' => params[:tag_name],
            'description' => params[:description]
        }
        body = body_obj.to_json

        # Call endpoint
        response = create_release(
            params[:server_url],
            params[:api_token],
            params[:repository_id],
            params[:tag_name],
            body
        )

        # Consume endpoint result
        case response[:status]
          when 409
            UI.important("Release already exists. Updating release instead")
            response = update_release(
                params[:server_url],
                params[:api_token],
                params[:repository_id],
                params[:tag_name],
                body)

            case response[:status]
              when 200
                UI.success("Successfully created release at tag \"#{params[:tag_name]}\" on GitLab")
              else
                UI.user_error!("GitLab responded with #{response[:status]}:#{response[:body]}")
            end

          when 201
            UI.success("Successfully created release at tag \"#{params[:tag_name]}\" on GitLab")

          else
            if response[:status] != 200
              UI.user_error!("GitLab responded with #{response[:status]}:#{response[:body]}")
            end
        end
      end

      def self.call_endpoint(url, method, headers, body)
        require 'excon'

        case method
          when "post"
            response = Excon.post(url, headers: headers, body: body)
          when "put"
            response = Excon.put(url, headers: headers, body: body)
          else
            UI.user_error!("Unsupported method #{method}")
        end

        return response
      end

      def self.create_release(server_url, api_token, id, tag_name, body)
        # POST /projects/:id/repository/tags/:tag_name/release
        url = "#{server_url}/projects/#{id}/repository/tags/#{tag_name}/release"
        call_endpoint(url, "post", headers(api_token), body)
      end

      def self.update_release(server_url, api_token, id, tag_name, body)
        # PUT /projects/:id/repository/tags/:tag_name/release
        url = "#{server_url}/projects/#{id}/repository/tags/#{tag_name}/release"
        call_endpoint(url, "put", headers(api_token), body)
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
        'This will create a new or update an existing release on Gitlab for the given tag'
      end

      def self.details
        [
            'Creates a new or updates an existing release on Gitlab for the given tag.',
            '',
            'You must provide your GitLab personal token (get one from /profile/account), the server url, the repository id and tag name',
            '',
            'If the release already exists, the existing release will be updated.'
        ].join("\n")
      end

      def self.available_options
        [
            FastlaneCore::ConfigItem.new(key: :server_url,
                                         env_name: 'FL_SET_GITLAB_RELEASE_SERVER_URL',
                                         description: "The Gitlab server url. e.g. 'https://gitlab.intranet.company/api/v3/'",
                                         optional: false,
                                         verify_block: proc do |value|
                                           UI.user_error!('Please include the protocol in the server url, e.g. https://gitlab.intranet.company/api/v3/') unless value.include? "//"
                                         end),
            FastlaneCore::ConfigItem.new(key: :api_token,
                                         env_name: 'FL_SET_GITLAB_RELEASE_API_TOKEN',
                                         description: 'Gitlab API Private Token from /profile/account',
                                         sensitive: true,
                                         default_value: ENV['GITLAB_PRIVATE_TOKEN'],
                                         optional: false,
                                         verify_block: proc do |value|
                                           UI.user_error!("No Gitlab API Private Token, pass using `api_token: 'STRING'`") unless (value and not value.empty?)
                                         end),
            FastlaneCore::ConfigItem.new(key: :repository_id,
                                         env_name: 'FL_SET_GITLAB_RELEASE_REPOSITORY_ID',
                                         description: 'Repository id which can be retrieved from api',
                                         optional: false,
                                         verify_block: proc do |value|
                                           UI.user_error!("No repository id, pass using `repository_id: 'INTEGER'`") unless (value and not value.empty?)
                                         end),
            FastlaneCore::ConfigItem.new(key: :tag_name,
                                         env_name: 'FL_SET_GITLAB_TAG_NAME',
                                         description: 'Name of the tag to attach release notes',
                                         optional: false,
                                         verify_block: proc do |value|
                                           UI.user_error!("No tag, pass using `tag_name: 'HASH'`") unless (value and not value.empty?)
                                         end),
            FastlaneCore::ConfigItem.new(key: :description,
                                         env_name: 'FL_SET_GITLAB_DESCRIPTION',
                                         description: 'Release description e.g. changelog',
                                         default_value: '',
                                         is_string: true,
                                         optional: true)
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
            'set_gitlab_release(
              server_url: "https://gitlab.intranet.company/api/v3/",
              api_token: ENV["GITLAB_PRIVATE_TOKEN"],
              repository_id: "1",
              tag_name: "1.0.1",
              description: "Just a few bug fixes :)"
            )'
        ]
      end

      def self.category
        :misc
      end
    end
  end
end
