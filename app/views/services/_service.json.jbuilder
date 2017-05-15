json.extract! service, :id, :name, :suite_id, :docker_repo, :git_repo, :k8s_service, :created_at, :updated_at
json.url service_url(service, format: :json)
