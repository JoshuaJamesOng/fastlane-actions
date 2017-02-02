module Fastlane
  module Actions
    module SharedValues
    end

    class CreateJiraIssueAction < Action
      def self.run(params)
        UI.important('Creating a JIRA issue')

        require 'json'

        # https://developer.atlassian.com/jiradev/jira-apis/jira-rest-apis/jira-rest-api-tutorials/jira-rest-api-example-create-issue
        body_obj = {
            'fields' => {
                'project' => {
                    'id' => "#{params[:project_id]}"
                },
                'summary' => "#{params[:issue_title]}",
                'description' => "#{params[:issue_description]}",
                'issuetype' => {
                    'id' => "#{params[:type_id]}"
                },
                'components' => [
                    {'id' => "#{params[:component_id]}"}
                ]
            }
        }

        body = body_obj.to_json

        # Call endpoint
        response = create_issue(
            params[:server_url],
            params[:api_token],
            {cert: params[:certificate], pass: params[:certificate_pass]},
            body
        )

        # Consume endpoint result
        case response[:status]
          when 200
            UI.user_error!("JIRA responded with #{response[:status]}:#{response[:body]}")
            UI.success('Successfully created JIRA issue')

          else
            if response[:status] != 200
              UI.user_error!("JIRA responded with #{response[:status]}:#{response[:body]}")
            end
        end

        response
      end

      def self.call_endpoint(url, method, headers, certificate, body)
        require 'excon'

        case method
          when 'post'

            if !certificate[:cert].nil? && !certificate[:pass].nil?

              # Build command
              command = "curl --cert #{certificate[:cert]}:#{certificate[:pass]} -X POST"
              headers.each_pair do |key, value|
                command.concat(" -H '#{key}: #{value}'")
              end
              command.concat(" -sw '%{http_code}' #{url} -d '#{body}'")

              response = sh(command)

              # Parse HTTP status code manually :(
              code = response[response.length - 3, 3]
              body = response[0, response.length - 3]
              response = {status: Integer(code), body: body}
            else
              UI.important('No certificate supplied')
              response = Excon.post(url, headers: headers, body: body)
            end

          else
            response = nil
            UI.user_error!("Unsupported method #{method}")
        end

        response
      end

      def self.create_issue(server_url, api_token, certificate, body)
        # POST /rest/api/2/issue/
        url = "#{server_url}/rest/api/2/issue"
        call_endpoint(url, 'post', headers(api_token), certificate, body)
      end

      def self.headers(api_token)
        require 'base64'
        headers = {'Content-Type' => 'application/json'}
        headers['Authorization'] = "Basic #{Base64.strict_encode64(api_token)}"
        headers
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'This will create a new JIRA issue for the given project and component'
      end

      def self.details
        [
            'Creates a new JIRA issue for the given project and component.',
            '',
            'You must provide a username & password in the format `username:password`, the server url, the project id, the component id, a type id, and a issue summary and description'
        ].join("\n")
      end

      def self.available_options
        [
            FastlaneCore::ConfigItem.new(key: :server_url,
                                         env_name: 'FL_CREATE_JIRA_ISSUE_SERVER_URL',
                                         description: "The Jira server url. e.g. 'https://jira.intranet.company'",
                                         optional: false,
                                         verify_block: proc do |value|
                                           UI.user_error!('Please include the protocol in the server url, e.g. https://www.jira.intranet.company') unless value.include? "//"
                                         end),
            FastlaneCore::ConfigItem.new(key: :api_token,
                                         env_name: 'FL_CREATE_JIRA_ISSUE_API_TOKEN',
                                         description: "Username and password in the format 'username:token'",
                                         sensitive: true,
                                         default_value: ENV['JIRA_PRIVATE_TOKEN'],
                                         optional: false,
                                         verify_block: proc do |value|
                                           UI.user_error!("No username and password, pass using `api_token: 'STRING'`") unless (value and not value.empty?)
                                         end),
            FastlaneCore::ConfigItem.new(key: :project_id,
                                         env_name: 'FL_CREATE_JIRA_ISSUE_PROJECT_ID',
                                         description: 'Project id which can be retrieved from api',
                                         optional: false,
                                         verify_block: proc do |value|
                                           UI.user_error!("No project id, pass using `project_id: 'INTEGER'`") unless (value and not value.empty?)
                                         end),
            FastlaneCore::ConfigItem.new(key: :component_id,
                                         env_name: 'FL_CREATE_JIRA_ISSUE_COMPONENT_ID',
                                         description: 'Component id which can be retrieved from api',
                                         optional: false,
                                         verify_block: proc do |value|
                                           UI.user_error!("No component id, pass using `component_id: 'INTEGER'`") unless (value and not value.empty?)
                                         end),
            FastlaneCore::ConfigItem.new(key: :type_id,
                                         env_name: 'FL_CREATE_JIRA_ISSUE_TYPE_ID',
                                         description: 'Type id which can be retrieved from api',
                                         optional: false,
                                         verify_block: proc do |value|
                                           UI.user_error!("No type id, pass using `type_id: 'INTEGER'`") unless (value and not value.empty?)
                                         end),
            FastlaneCore::ConfigItem.new(key: :issue_title,
                                         env_name: 'FL_CREATE_JIRA_ISSUE_SUMMARY',
                                         description: 'Issue title',
                                         is_string: true,
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :issue_description,
                                         env_name: 'FL_CREATE_JIRA_ISSUE_DESCRIPTION',
                                         description: 'Issue description',
                                         default_value: '',
                                         is_string: true,
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :certificate,
                                         env_name: 'FL_CREATE_JIRA_ISSUE_CERTIFICATE',
                                         description: 'Absolute URI to certificate',
                                         default_value: nil,
                                         is_string: true,
                                         optional: true),
            FastlaneCore::ConfigItem.new(key: :certificate_pass,
                                         env_name: 'FL_CREATE_JIRA_ISSUE_CERTIFICATE_PASS',
                                         description: 'Password to certificate',
                                         default_value: nil,
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
            'create_jira_issue(
              server_url: "https://jira.intranet.company",
              api_token: "username:password",
              project_id: "1000",
              component_id: "1001",
              type_id: "3",
              issue_title: "My Jira Issue",
              issue_description: "Hello world",
              certificate: "/Users/me/mycert.p12",
              certificate_pass: "12345678"
            )'
        ]
      end

      def self.category
        :misc
      end
    end
  end
end
