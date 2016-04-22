class ExamsController < ApplicationController

  include SysLog::Actions

  before_filter :prepare_for_group_selection, only: :index
  before_filter :get_groups_by_allocation_tags, only: [:new, :create]
  # before_filter :set_current_user, only: :index
  layout false, except: :index

  def index
    @allocation_tag_id = active_tab[:url][:allocation_tag_id]
    authorize! :index, Exam, on: [@allocation_tag_id]
    @allocation_tags_ids = AllocationTag.find(@allocation_tag_id).related
    @exams = Exam.my_exams(@allocation_tags_ids)

  rescue
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  end

  def new
    @allocation_tags_ids = params[:allocation_tags_ids]
    @exam = Exam.new
    @exam.build_schedule(start_date: Date.today, end_date: Date.today)
  end

  def create
    authorize! :create, Exam, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @exam = Exam.new exam_params
    @exam.allocation_tag_ids_associations = @allocation_tags_ids.split(' ').flatten
    @exam.schedule.verify_today = true
    if @exam.save
      render_exam_success_json('created')
    else
      render :new
    end
  rescue => error
    render_json_error(error, 'exams.error')
  end

  # require 'will_paginate/array'
  def list
    @allocation_tags_ids = params[:groups_by_offer_id].present? ? AllocationTag.at_groups_by_offer_id(params[:groups_by_offer_id]) : params[:allocation_tags_ids]
    authorize! :list, Exam, { on: @allocation_tags_ids }

    @all_groups = Group.where(offer_id: params[:offer_id])
    @exams = Exam.exams_by_ats(@allocation_tags_ids.split(' '))#.paginate(page: params[:page], per_page: 1)
    @can_see_preview = can? :show, Question, { on: @allocation_tags_ids }
    respond_to do |format|
      format.html
      format.js
    end
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'exams.error')
  end

  def edit
    @exam = Exam.find(params[:id])
  end

  def update
    @exam = Exam.find(params[:id])
    authorize! :update, Exam, { on: @exam.academic_allocations.pluck(:allocation_tag_id) }
    @exam.schedule.verify_today = true
    if @exam.update_attributes(exam_params)
      render_exam_success_json('updated')
    else
      render :edit
    end
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'exams.error')
  end

  def destroy
    authorize! :destroy, Exam, { on: params[:allocation_tags_ids] }
    Exam.find(params[:id]).destroy
    render_exam_success_json('deleted')
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'exams.error')
  end

  def open
    authorize! :open, Exam, { on: params[:allocation_tag_id] }
    situation =  params[:situation]
    @exam = Exam.find(params[:id])
    @preview = false
    @exam_questions = ExamQuestion.list(@exam.id, @exam.raffle_order).paginate(page: params[:page], per_page: 1, total_entries: @exam.number_questions) unless @exam.nil?
    @exam_user_id = params[:exam_user_id]
    @last_attempt = Exam.create_exam_user_attempt(@exam_user_id)
    @total_time = @last_attempt.exam_responses.sum(:duration) 
    
    mod_correct_exam = @exam.attempts_correction
    grade = Exam.get_grade(mod_correct_exam, @exam_user_id) 

    if situation=='finished' and grade
       #caso não tenha nota chama o metodo que calcula a nota

       @total_questions = @exam_questions.count(:id)
       @scores_exam = @exam_questions.sum(:score)
       @temp_questions = @total_time/@total_questions

       render :result_exam_user
    else  
      respond_to do |format|
        format.html
        format.js
      end
    end  
  end
 

  def change_status
    authorize! :change_status, Exam, { on: params[:allocation_tags_ids] }
    exam = Exam.find(params[:id])
    exam.can_change_status?
    exam.update_attributes status: !exam.status

    render_exam_success_json('status')
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    render_json_error(error, 'exams.error')
  end

  def show
    authorize! :show, Exam, { on: params[:allocation_tags_ids] }
    @exam = Exam.find(params[:id])
  end

  def summary
    #authorize! :summary, ExamUser, { on: params[:allocation_tags_ids] }
    exam_id = Exam.find(params[:exam_id])
    exam_user_id = params[:exam_user_id]

    @examUserAttempt = ExamUserAttempt.where(["exam_user_id = ?", exam_user_id]).last    
    @exam = Exam.find(exam_id)
  end

  def preview
    authorize! :show, Question, { on: params[:allocation_tags_ids] }
    @exam = Exam.find(params[:id])
    @preview = true
    @exam_questions = ExamQuestion.list(@exam.id, @exam.raffle_order).paginate(page: params[:page], per_page: 1, total_entries: @exam.number_questions) unless @exam.nil?

    render :open
  end

  private

  def exam_params
    params.require(:exam).permit(:name, :description, :duration, :start_hour, :end_hour, 
                                 :random_questions, :raffle_order, :auto_correction, 
                                 :block_content, :number_questions, :attempts, 
                                 :attempts_correction, :result_email,
                                 schedule_attributes: [:id, :start_date, :end_date])
  end

  def render_exam_success_json(method)
    render json: { success: true, notice: t(method, scope: 'exams.success') }
  end

end