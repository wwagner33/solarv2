class GroupsController < ApplicationController

  include SysLog::Actions

  layout false, except: [:index]

  # Mobilis
  def index
    @groups = current_user.groups

    if params.include?(:curriculum_unit_id)
      ucs_groups = CurriculumUnit.find(params[:curriculum_unit_id]).groups
      @groups = ucs_groups.select {|g| (ucs_groups.map(&:id) & @groups.map(&:id)).include?(g.id) }
    end

    respond_to do |format|
      format.html
      format.xml  { render :xml => map_to_xml_or_json }
      format.json  { render :json => map_to_xml_or_json }
    end
  end

  # SolarMobilis
  # GET /groups/listando.json
  def mobilis_list
     @groups = current_user.groups

    if params.include?(:curriculum_unit_id)
      @groups = CurriculumUnit.find(params[:curriculum_unit_id]).groups.where(id: @groups)
    end

    render json: { groups: map_to_xml_or_json }
  end

  # Edicao
  def list
    @type_id = params[:type_id].to_i
    offer = Offer.find(params[:offer_id]) if params.include?(:offer_id)

    if offer.nil?
      query = []
      query << (params[:course_id].blank? ? "course_id IS NULL" : "course_id = #{params[:course_id]}")
      query << (@type_id == 3 ? nil : (params[:curriculum_unit_id].blank? ? "curriculum_unit_id IS NULL" : "curriculum_unit_id = #{params[:curriculum_unit_id]}"))
      offer = Offer.where(semester_id: params[:semester_id]).where(query.compact.join(" AND ")).first
    end

    authorize! :list, Group, on: [offer.allocation_tag.id] unless params[:checkbox]

    @groups, @offer_id, @filter_number = ( offer.nil? ? [] : offer.groups.order("code") ), offer.try(:id), params[:filter_number].to_i
    render partial: 'groups_checkboxes', locals: { groups: @groups } if params[:checkbox]
  rescue CanCan::AccessDenied
    render json: {success: false, alert: t(:no_permission)}, status: :unauthorized
  end

  def new
    authorize! :create, Group

    @group = Group.new offer_id: params[:offer_id]
  end

  def edit
    authorize! :update, Group

    @group = Group.find(params[:id])
    @type_id = params[:type_id]
  end

  def create
    @group = Group.new(group_params)
    authorize! :create, Group, on: [@group.offer.allocation_tag.id]

    @group.user_id = current_user.id
    if @group.save
      render_group_success_json('created')
    else
      render :new
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  def update
    @group = Group.where(id: params[:id].split(","))
    authorize! :update, Group, on: [@group.first.offer.allocation_tag.id]

    @type_id = params[:type_id]

    params[:multiple] ? update_multiple : update_single
  rescue => error
    request.format = :json
    raise error.class
  end

  def destroy
    @groups = Group.where(id: params[:id].split(","))
    authorize! :destroy, Group, on: [@groups.first.offer.allocation_tag.id]

    destroy_multiple
  rescue => error
    request.format = :json
    raise error.class
  end

  def tags
    tool_model = model_by_tool_type(params[:tool_type])
    @tool      = tool_model.find(params[:tool_id])
    @groups    = @tool.groups

    @paths = { remove: polymorphic_path([tool_model], id: 'param_id', tool_id: @tool.id, action: :remove_group_from),
               unbind: polymorphic_path([tool_model], id: 'param_id', tool_id: @tool.id, action: :unbind_group_from)}
  end

  # desvincular/remover/adicionar turmas para determinada ferramenta
  def change_tool
    groups = Group.where(id: params[:id].split(','))
    authorize! :change_tool, Group, on: [RelatedTaggable.where(group_id: params[:id].split(',')).pluck(:group_at_id)]

    begin
      tool_model = model_by_tool_type(params[:tool_type])
      tool = tool_model.find(params[:tool_id])

      if params[:type] == 'add'
        allocation_tags_ids = groups.map(&:allocation_tag).map(&:id).flatten

        raise 'cant_add_group' unless (!tool.respond_to?(:can_add_group?) || tool.can_add_group?(allocation_tags_ids))

        AcademicAllocation.transaction do
          AcademicAllocation.create! allocation_tags_ids.map { |at| { allocation_tag_id: at, academic_tool_id: params[:tool_id], academic_tool_type: params[:tool_type] } }
        end
      else
        academic_allocations = AcademicAllocation.where(allocation_tag_id: groups.map(&:allocation_tag).map(&:id), academic_tool_type: params[:tool_type], academic_tool_id: params[:tool_id])
        evaluative = academic_allocations.map(&:verify_evaluative).include?(true) rescue false

        unless tool.groups.size == groups.size # se nao for deixar a ferramenta sem turmas
          case params[:type]
            when 'unbind' # desvincular uma turma

              raise 'must_have_group' if tool.academic_allocations.size == academic_allocations.size
              raise 'cant_unbind' unless (!tool.respond_to?(:can_unbind?) || tool.can_unbind?(groups))

              new_tool = tool.dup
              new_tool.created_at = tool.attributes["created_at"] if new_tool.respond_to?(:created_at)
              new_tool.updated_at = tool.attributes["updated_at"] if new_tool.respond_to?(:updated_at)
              new_tool.merge = true
              new_tool.copy_associations(tool) if new_tool.respond_to?(:copy_associations)
              new_tool.save!
              academic_allocations.update_all(academic_tool_id: new_tool.id)

              # se a ferramenta possuir um schedule, cria um igual para a nova
              if tool.respond_to?(:schedule)
                schedule = tool.schedule.dup
                schedule.save
                new_tool.update_attributes(schedule_id: schedule.id)
              end
              # copia as dependencias pro novo objeto caso existam
              new_tool.copy_dependencies_from(tool) if new_tool.respond_to?(:copy_dependencies_from)
            when 'remove' # remover uma turma
              raise 'cant_transfer_dependencies' unless (!tool.respond_to?(:can_remove_groups?) || tool.can_remove_groups?(groups))
              academic_allocations.destroy_all
            else
              raise 'option_not_found'
          end
        else # se for a unica turma
          raise 'last_group'
        end
      end

      message = evaluative ? ['warning', t('evaluative_tools.warnings.evaluative')] : ['notice', t("#{params[:type]}", scope: [:groups, :success])]
      render json: { success: true, type_message: message.first,  message: message.last }
    rescue ActiveRecord::RecordNotSaved
      render json: { success: false, alert: t(:academic_allocation_already_exists, scope: [:groups, :error]) }, status: :unprocessable_entity
    rescue => error
      error_message = I18n.translate!("#{error.message}", scope: [:groups, :error], :raise => true) rescue t('tool_change', scope: [:groups, :error])
      render json: { success: false, alert: error_message }, status: :unprocessable_entity
    end
  end

  def show
    @group = Group.find(params[:id])
    authorize! :list, Group, on: [@group.offer.allocation_tag.id]
  end

  private

    def group_params
      params.require(:group).permit(:offer_id, :code, :name, :location)
    end

    def map_to_xml_or_json
      @groups.map { |g| {id: g.id, code: g.code, semester: g.offer.semester.name} }
    end

    def model_by_tool_type(type)
      type.constantize if ['Discussion', 'LessonModule', 'Assignment', 'ChatRoom', 'SupportMaterialFile', 'Bibliography', 'Notification', 'Webconference', 'Exam', 'ScheduleEvent'].include?(type)
    end

    def update_multiple
      @group.update_all(status: params[:status])
      @group.first.offer.notify_editors_of_disabled_groups([@group]) if params[:status] == 'false'

      render_group_success_json('updated')
    end

    def update_single
      @group = @group.first
      if @group.update_attributes(group_params)
        render_group_success_json('updated')
      else
        render :edit
      end
    end

    def destroy_multiple
      Group.transaction do
        if @groups.map(&:can_destroy?).include?(false)
          render json: { success: false, alert: (@groups.map(&:errors).flatten.map(&:full_messages).flatten.compact.any? ? @groups.map(&:errors).flatten.map(&:full_messages).flatten.uniq.join(', ') : t('groups.error.deleted')) }, status: :unprocessable_entity
        else
          @groups.destroy_all
          render_group_success_json('deleted')
        end
      end
    end

    def render_group_success_json(method)
      render json: { success: true, notice: t("groups.success.#{method}") }
    end

end
