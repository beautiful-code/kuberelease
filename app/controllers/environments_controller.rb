class EnvironmentsController < ApplicationController
  include ActionView::Helpers::DateHelper

  before_action :set_suite
  before_action :set_environment
  before_action :set_environment_service, only: [
    :show_service, :update_service_variables,
    :service_variables, :launch_version
  ]
  before_action :build_environment_service_variables, only: [:update_service_variables]

  # GET /environments
  # GET /environments.json
  def index
    @environments = Environment.all
  end

  # GET /environments/1
  # GET /environments/1.json
  def show
  end

  # GET /environments/new
  def new
    @environment = Environment.new
  end

  # GET /environments/1/edit
  def edit
  end

  # POST /environments
  # POST /environments.json
  def create
    @environment = Environment.new(environment_params)
    @environment.suite = @suite

    respond_to do |format|
      if @environment.save
        format.html { redirect_to [@suite, @environment], notice: 'Environment was successfully created.' }
        format.json { render :show, status: :created, location: @environment }
      else
        format.html { render :new }
        format.json { render json: @environment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /environments/1
  # PATCH/PUT /environments/1.json
  def update
    respond_to do |format|
      if @environment.update(environment_params)
        format.html { redirect_to [@suite,@environment], notice: 'Environment was successfully updated.' }
        format.json { render :show, status: :ok, location: @environment }
      else
        format.html { render :edit }
        format.json { render json: @environment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /environments/1
  # DELETE /environments/1.json
  def destroy
    @environment.destroy
    respond_to do |format|
      format.html { redirect_to @suite, notice: 'Environment was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def deployment_details
    render json: @environment.deployment_details(params[:service_name]), status: :ok
  end

  def launch_version
    service = @suite.services.find_by_name(params[:service_name])

    if @environment.launch_version(
      service, params[:launch][:version],
      @environment_service
    )
      flash[:notice] = 'Version launched successfully'
    else
      flash[:error] = 'Unable to launch version'
    end

    redirect_to show_service_suite_environment_path(@suite, @environment, service)
  end

  def run_command
    service = @suite.services.find_by_id(params[:command][:service_id])

    if @environment.run_command service, params[:command][:cmd]
      flash[:notice] = 'Command initialized.'
    else
      flash[:error] = 'Unable to initialize command.'
    end

    redirect_to show_service_suite_environment_path(@suite, @environment, service)
  end

  def show_service
    @service = @environment.services.find(params[:service_id])

    respond_to do |format|
      format.json {
        current_tag = @environment.current_service_tag(@service.name)
        render json: {
          object: @service,
          releaseVersions: @service.release_versions.collect {|r| {message: r[:message], sha: r[:sha]} },
          currentVersion: {
            name: @service.get_message_for_release(current_tag),
            tag: current_tag
          }
        }
      }

      format.html
    end
  end

  def service_variables
    render json: @environment_service.try(:variables), status: 200
  end

  def service_commands
    commands = @environment.commands.where(
      service_id: params[:service_id]
    ).map do |command|
      ret = command.attributes

      ret["time_in_words"] = distance_of_time_in_words(
        command.created_at, Time.now.utc,
        include_seconds: true
      )

      ret
    end

    render json: commands, status: 200
  end

  def update_service_variables
    if @environment_service.save
      flash[:notice] = 'Updated ENV variables for the service.'
    end

    redirect_to show_service_suite_environment_path(@suite, @environment, params[:service_id])
  end

  def service_pod_log
    service = @environment.services.find(params[:service_id])
    logs = @environment.get_service_pod_log(service.name)
    render text: logs, status: 200
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_environment
      @environment = @suite.environments.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def environment_params
      params.require(:environment).permit(
        :name, :k8s_master,
        :k8s_username, :k8s_password
      )
    end

    def set_environment_service
      @environment_service = @environment.environment_services.find_or_initialize_by(
        service_id: params[:service_id]
      )
    end

    def build_environment_service_variables
      variables = []

      if params[:env_vars].present?
        env_vars = params[:env_vars]

        (env_vars.keys.size / 2).times do |index|
          name = env_vars["name_#{index}"]

          variables << {
            name: name,
            value: env_vars["value_#{index}"],
          } if name.present?
        end
      end

      @environment_service.variables = variables.to_json
    end
end
