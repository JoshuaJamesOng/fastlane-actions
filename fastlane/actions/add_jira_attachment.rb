module Fastlane
  module Actions
    module SharedValues
    end

    class AddJiraAttachmentAction < Action
      def self.run(params)
        UI.important('Adding JIRA attachment')

        # Call endpoint
        response = create_issue(
            params[:server_url],
            params[:api_token],
            params[:issue_key],
            {cert: params[:certificate], pass: params[:certificate_pass]},
            params[:file]
        )

        # Consume endpoint result
        case response[:status]
          when 403
            UI.user_error!("Attachments are disabled or you don't have permission to add attachments to this issue")
          when 404
            UI.user_error!('Issue not found, the user does not have permission to view it, or the attachments exceeds the maximum configured attachment size')
          when 200
            UI.success("Successfully attached to JIRA issue #{params[:issue_key]}")
          else
            if response[:status] != 200
              UI.user_error!("JIRA responded with #{response[:status]}:#{response[:body]}")
            end
        end

        response
      end

      def self.call_endpoint(url, method, headers, certificate, file)
        require 'http'

        case method
          when 'post'
            if !certificate[:cert].nil? && !certificate[:pass].nil?

              # Build command
              command = "curl --cert #{certificate[:cert]}:#{certificate[:pass]} -X POST"
              headers.each_pair do |key, value|
                command.concat(" -H '#{key}: #{value}'")
              end
              command.concat(" -sw '%{http_code}' #{url} -F 'file=@#{file}'")

              response = sh(command)

              # Parse HTTP status code manually :(
              code = response[response.length - 3, 3]
              body = response[0, response.length - 3]
              response = {status: Integer(code), body: body}
            else
              response = HTTP.headers(headers).post(url, :form => {
                  :file   => HTTP::FormData::File.new(file)
              })
            end
          else
            response = nil
            UI.user_error!("Unsupported method #{method}")
        end

        response
      end

      def self.create_issue(server_url, api_token, issue_key, certificate, file)
        # POST /rest/api/2/issue/:key/attachment
        url = "#{server_url}/rest/api/2/issue/#{issue_key}/attachments"
        call_endpoint(url, 'post', headers(api_token), certificate, file)
      end

      def self.headers(api_token)
        require 'base64'
        headers = {'Content-Type' => 'multipart/form-data'}
        headers['X-Atlassian-Token'] = 'nocheck'
        headers['Authorization'] = "Basic #{Base64.strict_encode64(api_token)}"
        headers
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Attaches a file to the given JIRA issue'
      end

      def self.details
        [
            'Attaches a file to the given JIRA issue',
            '',
            'You must provide a username & password in the format `username:password`, the server url, the issue key, and a file'
        ].join("\n")
      end

      def self.available_options
        [
            FastlaneCore::ConfigItem.new(key: :server_url,
                                         env_name: 'FL_ADD_JIRA_ATTACHMENTSERVER_URL',
                                         description: "The Jira server url. e.g. 'https://jira.intranet.company'",
                                         optional: false,
                                         verify_block: proc do |value|
                                           UI.user_error!('Please include the protocol in the server url, e.g. https://www.jira.intranet.company') unless value.include? "//"
                                         end),
            FastlaneCore::ConfigItem.new(key: :api_token,
                                         env_name: 'FL_ADD_JIRA_ATTACHMENT_API_TOKEN',
                                         description: "Username and password in the format 'username:token'",
                                         sensitive: true,
                                         default_value: ENV['JIRA_PRIVATE_TOKEN'],
                                         optional: false,
                                         verify_block: proc do |value|
                                           UI.user_error!("No username and password, pass using `api_token: 'STRING'`") unless (value and not value.empty?)
                                         end),
            FastlaneCore::ConfigItem.new(key: :issue_key,
                                         env_name: 'FL_ADD_JIRA_ATTACHMENT_ISSUE_KEY',
                                         description: 'Issue key which can be retrieved from api',
                                         optional: false,
                                         verify_block: proc do |value|
                                           UI.user_error!("No issue key, pass using `issue_key: 'STRING'`") unless (value and not value.empty?)
                                         end),
            FastlaneCore::ConfigItem.new(key: :file,
                                         env_name: 'FL_ADD_JIRA_ATTACHMENT_FILE',
                                         description: 'File to attach to ticket',
                                         is_string: true,
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :certificate,
                                         env_name: 'FL_ADD_JIRA_ATTACHMENT_CERTIFICATE',
                                         description: 'Absolute URI to certificate',
                                         default_value: nil,
                                         is_string: true,
                                         optional: true),
            FastlaneCore::ConfigItem.new(key: :certificate_pass,
                                         env_name: 'FL_ADD_JIRA_ATTACHMENT_CERTIFICATE_PASS',
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
            'add_jira_attachment(
              server_url: "https://jira.intranet.company",
              api_token: "username:password",
              issue_key: "DEV-1000",
              file: "path/to/upload.txt",
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
