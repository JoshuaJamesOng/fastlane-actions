module Fastlane
  module Actions
    module SharedValues
    end

    class DownloadJenkinsArtifactsAction < Action
      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        UI.important("Downloading artifacts from job \"http://#{params[:server_url]}/job/#{params[:job_name]}/#{params[:job_number]}\"")
        UI.important("Downloading artifacts that match \"#{params[:apk_regex]}\"")

        # Call endpoint
        response = build(
            params[:server_url],
            params[:job_name],
            params[:job_number],
            params[:username],
            params[:password]
        )

        # Match artifacts and download
        files = download_artifacts(
            params[:server_url],
            params[:job_name],
            params[:job_number],
            params[:downloads_dir],
            params[:apk_regex],
            get_artifacts_from_response(response),
            params[:username],
            params[:password]
        )

        files
      end

      def self.get_artifacts_from_response(response)
        require 'json'

        return JSON.parse(response[:body])['artifacts']
      end

      def self.download_artifacts(server_url, job_name, job_number, downloads_dir, apk_regex, artifacts, username, password)
        files = []

        for artifact in artifacts do
          if artifact['fileName'].match(apk_regex)
            files << download_artifact("http://#{server_url}/job/#{job_name}/#{job_number}", downloads_dir, artifact, username, password)
          end
        end

        files
      end

      def self.download_artifact(url, downloads_dir, artifact, username, password)
        UI.important("Downloading #{artifact['fileName']}...")

        require 'open-uri'

        filename = "#{downloads_dir}/#{artifact['fileName']}"
        open(filename, 'wb') do |file|
          if !username.nil? && !password.nil?
            file << open("#{url}/artifact/#{artifact['relativePath']}", http_basic_authentication: [username, password]).read
          else
            file << open("#{url}/artifact/#{artifact['relativePath']}").read
          end
        end

        filename
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

      def self.build(server_url, job_name, job_number, username, password)
        # curl -X GET JENKINS_URL/job/JOB_NAME/JOB_NUMBER

        if !username.nil? && !password.nil?
          call_endpoint("http://#{username}:#{password}@#{server_url}/job/#{job_name}/#{job_number}/api/json", 'get')
        else
          call_endpoint("http://#{server_url}/job/#{job_name}/#{job_number}/api/json", 'get')
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Download artifacts from the specified Jenkins Job"
      end

      def self.details
        [
            'Download artifacts from the specified Jenkins Job that match the regex provided.',
            '',
            'You must provide the server url, job name and number. If no job number is given, the latest number is used.',
            '',
            'You must also provide a regex to match artifacts, and the directory to download to.'
        ].join("\n")
      end

      def self.available_options
        [
            FastlaneCore::ConfigItem.new(key: :server_url,
                                         env_name: "FL_DOWNLOAD_ARTIFACTS_JENKINS_JOB_SERVER_URL",
                                         description: "The server url. e.g. 'gitlab.intranet.company/api/v3'",
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :job_name,
                                         env_name: "FL_DOWNLOAD_ARTIFACTS_JENKINS_JOB_JOB_NAME",
                                         description: "The Jenkins job. e.g. WC-PR11-Releases",
                                         optional: false,
                                         verify_block: proc do |value|
                                           UI.user_error!("No Jenkins Job specified") unless (value and not value.empty?)
                                         end),
            FastlaneCore::ConfigItem.new(key: :job_number,
                                         env_name: "FL_DOWNLOAD_ARTIFACTS_JENKINS_JOB_JOB_NUMBER",
                                         description: "The Jenkins job number. e.g. 1, 2, defaults to lastBuild",
                                         default_value: "lastBuild",
                                         optional: true),
            FastlaneCore::ConfigItem.new(key: :apk_regex,
                                         env_name: "FL_DOWNLOAD_ARTIFACTS_APK_MATCHER",
                                         description: "Regex to match apks against e.g. \".+\.apk\"",
                                         default_value: ".+",
                                         optional: true),
            FastlaneCore::ConfigItem.new(key: :downloads_dir,
                                         env_name: "FL_DOWNLOAD_ARTIFACTS_DOWNLOADS_DIR",
                                         description: "Directory to save downloads to. e.g. downloads",
                                         default_value: "",
                                         optional: true),
            FastlaneCore::ConfigItem.new(key: :username,
                                         env_name: 'FL_DOWNLOAD_ARTIFACTS_DOWNLOADS_USERNAME',
                                         description: 'Username for Jenkins server',
                                         default_value: nil,
                                         optional: true),
            FastlaneCore::ConfigItem.new(key: :password,
                                         env_name: 'FL_DOWNLOAD_ARTIFACTS_DOWNLOADS_PASSWORD',
                                         description: 'Password for Jenkins server',
                                         default_value: nil,
                                         sensitive: true,
                                         optional: true)
        ]
      end

      def self.output

      end

      def self.return_value

      end

      def self.authors
        ["ThomasBruggenwirth"]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
