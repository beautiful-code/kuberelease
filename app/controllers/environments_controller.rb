class EnvironmentsController < ApplicationController
  before_action :set_suite
  before_action :set_environment

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
    if @environment.launch_version service, params[:launch][:version]
       redirect_to [@suite, @environment], notice: 'Version launched successfully'
    else
       redirect_to [@suite, @environment], error: 'Unable to launch version'
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_environment
      @environment = @suite.environments.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def environment_params
      params.require(:environment).permit(:name, :k8s_master, :k8s_username, :k8s_password)
    end
end
