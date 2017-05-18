class Service < ActiveRecord::Base
  belongs_to :suite

  def docker_image_tags
    @docker_image_tags ||= JSON.parse(HTTParty.get("http://registry.hub.docker.com/v1/repositories/#{docker_repo}/tags", :verify => false).body).collect {|item| item["name"]}.to_set
  end

  def github_shas
    @github_shas ||= JSON.parse(HTTParty.get("https://api.github.com/repos/#{git_repo}/commits", :verify => false).body).collect {|item| {:sha => item["sha"], :message => item["commit"]["message"], :committer => item["commit"]["committer"]["name"], :time => item["commit"]["committer"]["date"]}}
  end

  def release_versions
    github_shas.select {|item| docker_image_tags.include?(item[:sha])}
  end

  def get_message_for_release sha
    release_versions.find {|item| item[:sha] == sha}[:message] rescue nil
  end
end
