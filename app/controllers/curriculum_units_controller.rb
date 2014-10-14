class CurriculumUnitsController < ApplicationController

  layout false, only: [:new, :edit, :create, :update]

  before_filter :prepare_for_group_selection, only: [:home, :participants, :informations]
  before_filter :curriculum_data, only: [:home, :informations, :participants]
  before_filter :ucs_for_list, only: [:list, :mobilis_list]

  load_and_authorize_resource only: [:edit, :update]

  def home
    allocation_tags = @allocation_tags.map(&:id)
    authorize! :show, CurriculumUnit, on: allocation_tags, read: true

    @messages = Message.user_inbox(current_user.id, @allocation_tag_id, only_unread = true)
    @lessons_modules  = LessonModule.to_select(allocation_tags, current_user)
    @discussion_posts = list_portlet_discussion_posts(allocation_tags.join(', '))
    @scheduled_events = Agenda.events(allocation_tags, nil, true)
  end

  def index
    @type = CurriculumUnitType.find(params[:type_id])
    @curriculum_units = []

    if params[:combobox]
      if @type.id == 3
        @course_name      = Course.find(params[:course_id]).name
        @curriculum_units = CurriculumUnit.where(name: @course_name).order(:name)
      else
        @curriculum_units = CurriculumUnit.joins(:offers).where(curriculum_unit_type_id: @type.id).order(:name)
        @curriculum_units = @curriculum_units.where(offers: {course_id: params[:course_id]}) unless params[:course_id].blank?
      end

      render json: { html: render_to_string(partial: 'select_curriculum_unit.html', locals: { curriculum_units: @curriculum_units.uniq! }) }
    else # list
      authorize! :index, CurriculumUnit
      if not(params[:curriculum_unit_id].blank?)
        @curriculum_units = CurriculumUnit.where(id: params[:curriculum_unit_id]).paginate(page: params[:page])
      else
        allocation_tags_ids = current_user.allocation_tags_ids_with_access_on([:update, :destroy], "curriculum_units")
        @curriculum_units = @type.curriculum_units.joins(:allocation_tag).where(allocation_tags: {id: allocation_tags_ids}).paginate(page: params[:page])
      end
      respond_to do |format|
        format.html {render partial: 'curriculum_units/index'}
        format.js
      end
    end
  rescue
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  # Mobilis
  # GET /curriculum_units/list.json
  def list
    respond_to do |format|
      format.json { render json: @curriculum_units }
      format.xml { render xml: @curriculum_units }
    end
  end

  # Mobilis
  # GET /curriculum_units/:curriculum_unit_id/groups/mobilis_list.json
  def mobilis_list
    respond_to do |format|
      format.json { render json: { curriculum_units: @curriculum_units } }
      format.xml { render xml: @curriculum_units }
    end
  end

  # GET /curriculum_units/new
  def new
    @curriculum_unit = CurriculumUnit.new(curriculum_unit_type_id: params[:type_id])
  end

  # POST /curriculum_units
  def create
    authorize! :create, CurriculumUnit

    @curriculum_unit = CurriculumUnit.new(curriculum_unit_params)
    @curriculum_unit.user_id = current_user.id

    if @curriculum_unit.save
      render json: {success: true, notice: t('curriculum_units.success.created'), code_name: @curriculum_unit.code_name, id: @curriculum_unit.id}
    else
      render :new
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  # GET /curriculum_units/1/edit
  def edit
  end

  # PUT /curriculum_units/1
  def update
    if @curriculum_unit.update_attributes(curriculum_unit_params)
      render json: {success: true, notice: t('curriculum_units.success.updated'), code_name: @curriculum_unit.code_name, id: @curriculum_unit.id}
    else
      render :edit
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  def destroy
    uc_ids = params[:id].split(",")
    authorize! :destroy, CurriculumUnit, on: AllocationTag.where(curriculum_unit_id: uc_ids).pluck(:id)

    @curriculum_unit = CurriculumUnit.where(id: uc_ids)
    if @curriculum_unit.destroy_all.map(&:destroyed?).include?(false)
      render json: {success: false, alert: t('curriculum_units.error.deleted')}, status: :unprocessable_entity
    else
      render json: {success: true, notice: t('curriculum_units.success.deleted')}
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  # information about UC from a offer from the group selected
  def informations
    authorize! :show, CurriculumUnit, on: [@allocation_tag_id]

    @offer = @allocation_tags.select {|at| not(at.offer_id.nil?)}.first.try(:offer)
  end

  def participants
    authorize! :show, CurriculumUnit, on: [@allocation_tag_id]

    allocation_tags = @allocation_tags.map(&:id).join(",")
    @participants = CurriculumUnit.class_participants_by_allocations_tags_and_is_profile_type(allocation_tags, Profile_Type_Student)
  end

  private

    def curriculum_unit_params
      params.require(:curriculum_unit).permit(:code, :name, :curriculum_unit_type_id, :resume, :syllabus, :passing_grade, :objectives, :prerequisites, :credits, :working_hours)
    end

    def curriculum_data
      @curriculum_unit = Offer.find(active_tab[:url][:id]).curriculum_unit
      @allocation_tag_id = active_tab[:url][:allocation_tag_id]
      @allocation_tags = AllocationTag.find(@allocation_tag_id).related(objects: true)

      at_ids = @allocation_tags.map(&:id).join(",")

      @responsible = CurriculumUnit.class_participants_by_allocations_tags_and_is_profile_type(at_ids, Profile_Type_Class_Responsible)
    end

    def list_portlet_discussion_posts(allocation_tags)
      Post.joins(:academic_allocation)
        .where(academic_allocations: {allocation_tag_id: allocation_tags})
        .select(%{substring("content" from 0 for 255) AS content}).select('*')
        .order("updated_at DESC").limit(Rails.application.config.items_per_page.to_i)
    end

    def ucs_for_list
      @curriculum_units = CurriculumUnit.all_by_user(current_user).collect {|uc| {id: uc.id, code: uc.code, name: uc.name}}

      if params.include?(:search)
        @curriculum_units = @curriculum_units.select {|uc| uc[:code].downcase.include?(params[:search].downcase) or uc[:name].downcase.include?(params[:search].downcase)}
      end
    end

end
