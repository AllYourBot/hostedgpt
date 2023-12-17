class TasksController < ApplicationController
  before_action :set_project
  before_action :set_task, only: %i[ show edit update destroy ]

  def index
    @tasks = @project.tasks
  end

  def show
  end

  def new
    @task = @project.tasks.build
  end

  def edit
  end

  def create
    @task = @project.tasks.create! task_params

    redirect_to project_url(@project), notice: "Task was successfully created."
  end

  def update
    @task.update! task_params

    redirect_to project_url(@project), notice: "Task was successfully updated."
  end

  def destroy
    @task.destroy!

    redirect_to project_url(@project), notice: "Task was successfully destroyed."
  end

  private
    def set_project
      @project = Project.find(params[:project_id])
    end

    def set_task
      @task = @project.tasks.find(params[:id])
    end

    def task_params
      params.require(:task).permit(:title, :completed, :project_id)
    end
end
