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

  POD_API_BASE_PATH = "/api/v1/namespaces/default/pods"

  def pod_rest_url
    "#{environment.k8s_master}#{POD_API_BASE_PATH}"
  end

  def initiate_command
    headers = environment.prepare_auth_headers

    url = pod_rest_url

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
    mark_submitted if result.response.class == Net::HTTPOK
  end

  def check_status

  end


end
