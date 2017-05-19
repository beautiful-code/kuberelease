class Environment < ActiveRecord::Base
  belongs_to :suite
  has_many :commands, -> { order(created_at: :desc) }

  delegate :services, to: :suite

  DEPLOYMENT_API_BASE_PATH = "/apis/extensions/v1beta1/namespaces/default/deployments/"

  def prepare_auth_headers
    basic_auth_base64 = Base64.encode64("#{k8s_username}:#{k8s_password}")
    auth_header_value = "Basic #{basic_auth_base64}"

    {
      "Authorization" => auth_header_value,
      "Content-Type" => 'application/json'
    }
  end

  def deployment_rest_url service_name
    "#{k8s_master}#{DEPLOYMENT_API_BASE_PATH}#{service_name}"
  end

  def deployment_details service_name
    headers = prepare_auth_headers
    url = deployment_rest_url(service_name)

    JSON.parse(
      HTTParty.get(url,
                   :headers => headers,
                   :verify => false
                  ).body
    )
  end

  def current_service_tag service_name
    json = deployment_details service_name

    container = json["spec"]["template"]["spec"]["containers"].find{|c| c["name"] == service_name} rescue nil

    if container
      container["image"].split(":").last
    end
  end

  def launch_version service, sha
    headers = prepare_auth_headers.merge({
      "Content-Type" => "application/strategic-merge-patch+json"
    })

    url = deployment_rest_url(service.name)
    body = <<-eos
{
  "spec":{
    "template":{
      "spec":{
        "containers":[
          {
            "name":"#{service.name}",
            "image":"#{service.docker_repo}:#{sha}"
          }
        ]
      }
    }
  }
}
eos

    result = HTTParty.patch(url,
      :body => body,
      :headers => headers,
      :verify => false
                 )

    result.response.class == Net::HTTPOK
  end


  def run_command service, cmd, desc = nil
    # Create a command object
    cmd = Command.create(
      :environment => self,
      :service => service,
      :version => current_service_tag(service.name),
      :desc => desc,
      :cmd => cmd,
    )
    cmd.pod_name = "pod-#{self.name}-#{service.name}-#{cmd.id}".downcase
    cmd.save

    # TODO: Put it in delayed job
    cmd.initiate_command
  end


end
