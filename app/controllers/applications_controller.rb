class ApplicationsController < ApplicationController
  if Rails.application.config.anon_apply == true
    before_action :require_user, except: [:new, :create]
  else
    before_action :require_user
  end

  ITEMS_PER_PAGE = 20

  before_action :set_job
  before_action :set_application, only: [:edit, :update, :show, :destroy, :change_status]
  before_action :require_same_user, only: [:edit, :update, :destroy]
  before_action :require_poster_or_collab, only: [:change_status, :index]
  before_action :require_poster_or_collab_or_applicant, only: [:show]
  before_action :require_not_poster_or_collab, only: [:new, :create]
 
  def change_status
  	if @application.av_status.include?(params[:status].to_s)
      @application.status = params[:status].to_s
      if @application.save
        flash[:success] = "Status updated successfully"
        redirect_to job_application_path(@job, @application)
  	  else
        flash[:error] = "Status can't be updated"
        redirect_to job_application_path(@job, @application)
      end
    else
      flash[:error] = "Status can't be updated"
      redirect_to job_application_path(@job, @application)
  	end
  end

  def show

    @page = 1
    if params[:page].to_i > 0
      @page = params[:page].to_i
    end

    @title = @application.name
    @collcomment = Collcomment.new
    @collcomments_count = @application.collcomments.where(is_deleted: false).count
    @collcomments = @application.collcomments.where(is_deleted: false).order("created_at").reverse_order.offset((@page - 1) * ITEMS_PER_PAGE).limit(ITEMS_PER_PAGE)
  end

  def index
    @applications = @job.applications.where(is_deleted: false)
    @title = "Applications"
  end

  def new
    @title = "New Application"
    @application = Application.new
    if Rails.application.config.anon_apply != true
      @application.name = current_user.username
      @application.email = current_user.email
    end
  end

  def create
    @application = Application.new(application_params)
    if Rails.application.config.anon_apply != true
      @application.applicant = current_user
    end
    @application.job = Job.find(params[:job_id])
    @application.status = "Applied"
    @application.is_deleted = false

    if @application.save
      flash[:success] = "Application Created!"
      if Rails.application.config.anon_apply == true
        redirect_to job_path(@job)
      else
        redirect_to job_application_path(@job, @application)
      end
    else
      render :new
    end
  end

  def edit
    @title = "Edit Application"
  end

  def update
    if @application.update(application_params)
      flash[:success] = 'Updated Successfully!'
      redirect_to job_application_path(@job, @application)
    else
      render :edit
    end
  end

  def destroy
    tempjob = @application.job
    @application.is_deleted = true
    @application.save
    flash[:success] = 'Application Deleted'
    redirect_to job_path(tempjob)
  end

  private

    def set_application
      @application = Application.where(is_deleted: false).find(params[:id])
    end

    def set_job
      @job = Job.where(is_deleted: false).find(params[:job_id])
    end

    def require_same_user
      if current_user.id != @application.applicant_id
        flash[:error] = 'You can only edit applications you have posted'
        redirect_to job_application_path
      end
    end

    def require_poster_or_collab
    	if (!@job.collaborators.include?(current_user))&&(current_user != @job.poster)
        	flash[:error] = 'You are not allowed to do this action'
        	redirect_to job_path(@job)
    	end
    end

    def require_poster_or_collab_or_applicant
      if Rails.application.config.anon_apply == true
        if (current_user != @job.poster) and (!@job.collaborators.include?(current_user))
          if @application.applicant_id.nil?
            flash[:error] = 'You are not allowed to see applications'
            redirect_to job_path(@job)      
          else
            if @application.applicant != current_user
              flash[:error] = 'You are not allowed to see applications'
              redirect_to job_path(@job)
            end
          end
            flash[:error] = 'You are not allowed to see applications'
            redirect_to job_path(@job)
        end
      else
        if (current_user != @job.poster) and (current_user != @application.applicant) and (!@job.collaborators.include?(current_user))
            flash[:error] = 'You are not allowed to see applications'
            redirect_to job_path(@job)
        end
      end
    end

    def require_not_poster_or_collab
      if Rails.application.config.anon_apply == true
        if user_signed_in?
          if (@job.collaborators.include?(current_user))||(current_user == @job.poster)
              flash[:error] = 'You are not allowed to apply to your own job'
              redirect_to job_path(@job)
          end 
        end
      else
        if (@job.collaborators.include?(current_user))||(current_user == @job.poster)
            flash[:error] = 'You are not allowed to apply to your own job'
            redirect_to job_path(@job)
        end 
      end

    end

    def application_params
      params.require(:application).permit(:name, :email, :phoneno, :details_nomark, :status)
    end
    
end