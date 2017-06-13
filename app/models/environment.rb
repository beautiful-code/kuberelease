class Environment < ActiveRecord::Base
  belongs_to :suite
  has_many :commands, -> { order(created_at: :desc) }
  has_many :environment_services

  delegate :services, to: :suite

  DEPLOYMENT_API_BASE_PATH = "/apis/extensions/v1beta1/namespaces/default/deployments/"
  POD_API_BASE_PATH = "/api/v1/namespaces/default/pods/"

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
      HTTParty.get(
        url,
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

  def launch_version service, sha, env_service
    headers = prepare_auth_headers.merge({
      "Content-Type" => "application/strategic-merge-patch+json"
    })

    url = deployment_rest_url(service.name)
    body = <<-EOS
    {
      "spec":{
          "template":{
            "spec":{
                "containers":[
                  {
                    "name":"#{service.name}",
                    "image":"#{service.docker_repo}:#{sha}",
                    "env":[]
                  }
                ]
            }
          }
      }
    }
    EOS

    body_hash = JSON.parse(body)
    body_hash["spec"]["template"]["spec"]["containers"][0]["env"] = JSON.parse(env_service.variables)

    result = HTTParty.patch(
      url,
      :body => body_hash.to_json,
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
    cmd.delay.initiate_command
  end

  def get_service_pod_log_rest_url service_name
    pod_name = find_service_pod(service_name)
    pods_rest_url + pod_name + '/log' if pod_name

  end

  def get_service_pod_log service_name
    url = get_service_pod_log_rest_url(service_name)

    HTTParty.get(
      url,
      :headers => prepare_auth_headers,
      :verify => false
    ).body if url
  end

  def pods_rest_url
    "#{k8s_master}#{POD_API_BASE_PATH}"
  end

  def find_service_pod service_name
    pod_name = nil

    result = JSON.parse(
      HTTParty.get(
        pods_rest_url,
        :headers => prepare_auth_headers,
        :verify => false
      ).body
    )

    if result["items"].present?
      pods =  result["items"].select do |pod|
        pod if  pod["metadata"]["name"] =~ /^#{service_name}/
      end

      pod_name = pods[0]["metadata"]["name"] if pods.size > 0
    end

    pod_name
  end
end
