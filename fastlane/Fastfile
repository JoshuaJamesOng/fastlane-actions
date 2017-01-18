fastlane_version '1.111.0'

desc "Creates a tag on Gitlab if it doesn't exist"
lane :tag do |options|

  sh('git fetch --tags')

  if !git_tag_exists(tag: "#{options[:tag]}")
    add_gitlab_tag(
        tag_name: "#{options[:tag]}",
        server_url: "#{options[:server_url]}",
        api_token: "#{options[:api_token]}",
        repository_id: "#{options[:repository_id]}",
        commit_hash: "#{options[:commit_hash]}"
    )
  else
    raise "Tag #{options[:tag]} already exists"
  end

end

desc "Creates a Gitlab release for a tag or updates it if it already exists"
lane :gitlab_release do |options|
  set_gitlab_release(
      server_url: "#{options[:server_url]}",
      api_token: "#{options[:api_token]}",
      repository_id: "#{options[:repository_id]}",
      tag_name: "#{options[:tag]}",
      description: "#{options[:changelog]}"
  )
end


