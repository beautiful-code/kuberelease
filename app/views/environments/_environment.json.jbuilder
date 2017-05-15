json.extract! environment, :id, :name, :suite_id, :k8s_master, :k8s_username, :k8s_password, :created_at, :updated_at
json.url environment_url(environment, format: :json)
