class Command < ActiveRecord::Base

  STATES = [
    "new", "submitted", "completed", "failed"
  ]

  validates :state, presence: true, :inclusion => STATES

  belongs_to :environment
  belongs_to :service


  state_machine :state, initial: :new do
    event :mark_submitted do
      transition :new => :submitted
    end

    event :mark_completed do
      transition :submitted => :completed
    end

    event :mark_failed do
      transition :submitted => :failed
    end
  end

  def finished?
    ['completed', 'failed'].include? state
  end

  PODS_API_BASE_PATH = "/api/v1/namespaces/default/pods"

  def pods_rest_url
    "#{environment.k8s_master}#{PODS_API_BASE_PATH}"
  end

  def pod_rest_url pod_name
    "#{pods_rest_url}/#{pod_name}"
  end

  def pod_logs_rest_url pod_name
    "#{pod_rest_url(pod_name)}/log"
  end



  def initiate_command
    headers = environment.prepare_auth_headers

    url = pods_rest_url

    body = <<-eos
    {
  "apiVersion": "v1",
  "kind": "Pod",
  "metadata": {
    "name": "#{pod_name}"
  },
  "spec": {
  	"restartPolicy": "Never",
    "containers": [
      {
      	"name": "command-runner",
        "image": "#{service.docker_repo}:#{version}",
        "restartPolicy": "Never",
        "command": [
          "#{cmd}"
        ],
        "args": [
        ]
      }
    ]
  }
}
eos

    result = HTTParty.post(url,
                           :body => body,
                           :headers => headers,
                           :verify => false
                          )

    puts result.body

    # Got 200 from k8s, mark sumbitted
    if result.response.class == Net::HTTPCreated
       mark_submitted
       self.save!
    end

    poll_status
  end

  def poll_status
    # Fetch the latest log.
    fetch_log

    fetch_status

    # If status is not completed/failed, retry after N seconds.
    poll_status unless self.finished?
  end
  handle_asynchronously :poll_status, :run_at => Proc.new {3.seconds.from_now}

  def fetch_log
    headers = environment.prepare_auth_headers
    url = pod_logs_rest_url(pod_name)

    result = HTTParty.get(url,
                 :headers => headers,
                 :verify => false
                )
    case result.response.class.name
    when "Net::HTTPBadRequest" # Happens when the pod is not created at
      self.output = result.body
      self.save!
    when "Net::HTTPOK"
      self.output = result.body
      self.save!
    else
      puts "Received status #{result.response.class.name} with the following body #{result.body}"
    end
  end

  def fetch_status
    headers = environment.prepare_auth_headers
    url = pod_rest_url(pod_name)

    result = HTTParty.get(url,
                 :headers => headers,
                 :verify => false
                )
    case result.response.class.name
    when "Net::HTTPOK"
      pod_status = JSON.parse(result.body)["status"]["phase"]
      case pod_status
      when 'Succeeded'
        self.mark_completed
        self.save!
      when 'Failed'
        self.mark_failed
        self.save!
      else
        puts "Received pod_status #{pod_status}. Dont know what to do."
      end
    end

  end


end
