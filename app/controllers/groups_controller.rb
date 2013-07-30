class GroupsController < ApplicationController

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
      format.xml  { render :xml => @groups.map {|g| {id: g.id, code: g.code, semester: g.offer.semester.name} } }
      format.json  { render :json => @groups.map {|g| {id: g.id, code: g.code, semester: g.offer.semester.name} } }
    end
  end

  # Edicao
  def list
    authorize! :list, Group

    # os três dados são obrigatórios
    query = []
    query << "offers.curriculum_unit_id = #{params[:curriculum_unit_id]}" unless params[:curriculum_unit_id].blank?
    query << "offers.course_id = #{params[:course_id]}" unless params[:course_id].blank?
    query << "offers.semester_id = #{params[:semester_id]}" unless params[:semester_id].blank?

    @groups = []
    @groups = Group.joins(offer: :semester).where(query.join(" AND ")) unless query.empty?

    respond_to do |format|
      format.html
      format.xml { render xml: @groups }
      format.json  { render json: @groups }
    end
  end

  def new
    authorize! :create, Group
    offer  = Offer.find_by_curriculum_unit_id_and_semester_id_and_course_id(params[:curriculum_unit_id], params[:semester_id], params[:course_id])
    @group = Group.new offer_id: offer.try(:id)
  end

  def edit
    authorize! :update, Group
    @group = Group.find(params[:id])
  end

  def create
    authorize! :create, Group
    @group = Group.new(params[:group])

    if @group.save
      render json: {success: true, notice: t(:created, scope: [:groups, :success])}
    else
      render :new
    end
  end

  def update
    authorize! :update, Group

    if(params[:multiple])
      Group.where(id: params[:id].split(",")).update_all(status: params[:status])
      render json: {success: true, notice: t(:updated, scope: [:groups, :success])}
    else
      @group = Group.find(params[:id])

      if @group.update_attributes(params[:group])
        render json: {success: true, notice: t(:updated, scope: [:groups, :success])}
      else
        render :edit
      end
    end
  end

  def destroy
    authorize! :destroy, Group

    Group.transaction do 
      begin
        Group.where(id: params[:id].split(",")).each do |group|
          raise "erro" unless group.destroy
        end
        render json: {success: true, notice: t(:deleted, scope: [:groups, :success])}
      rescue
        render json: {success: false, alert: t(:deleted, scope: [:groups, :error])}, status: :unprocessable_entity
      end
    end
  end

end
