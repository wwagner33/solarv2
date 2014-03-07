class WebconferencesController < ApplicationController

  layout false, except: :index

  def index
    authorize! :index, Webconference, on: [at = active_tab[:url][:allocation_tag_id]]

    @webconferences = Webconference.all_by_allocation_tags(AllocationTag.find(at).related(upper: true) + [at])
  end

  # GET /webconferences/list
  # GET /webconferences/list.json
  def list
    authorize! :list, Webconference, on: @allocation_tags_ids = (params[:allocation_tags_ids].class == String ? params[:allocation_tags_ids].split(",") : params[:allocation_tags_ids])

    @webconferences = Webconference.joins(academic_allocations: :allocation_tag).where(allocation_tags: {id: @allocation_tags_ids}).uniq
  end

  # GET /webconferences/new
  # GET /webconferences/new.json
  def new
    authorize! :create, Webconference, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @webconference = Webconference.new
    @groups_codes = Group.joins(:allocation_tag).where(allocation_tags: {id: [@allocation_tags_ids].flatten}).map(&:code).uniq
  end

  # GET /webconferences/1/edit
  def edit
    authorize! :update, Webconference, on: @allocation_tags_ids = params[:allocation_tags_ids]

    @webconference = Webconference.find(params[:id])
    @groups_codes = @webconference.groups.map(&:code)
  end

  # POST /webconferences
  # POST /webconferences.json
  def create
    authorize! :create, Webconference, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ")

    @webconference = Webconference.new(params[:webconference])
    @webconference.moderator = current_user

    begin
      Webconference.transaction do
        @webconference.save!
        @webconference.academic_allocations.create! @allocation_tags_ids.map {|at| {allocation_tag_id: at}}
      end
      render json: {success: true, notice: t(:created, scope: [:webconferences, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue
      @groups_codes = Group.joins(:allocation_tag).where(allocation_tags: {id: [@allocation_tags_ids].flatten}).map(&:code).uniq
      render :new
    end
  end

  # PUT /webconferences/1
  # PUT /webconferences/1.json
  def update
    authorize! :update, Webconference, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten

    @webconference = Webconference.find(params[:id])
    begin
      @webconference.update_attributes!(params[:webconference])

      render json: {success: true, notice: t(:updated, scope: [:webconferences, :success])}
    rescue ActiveRecord::AssociationTypeMismatch
      render json: {success: false, alert: t(:not_associated)}, status: :unprocessable_entity
    rescue
      @groups_codes = @webconference.groups.map(&:code)
      render :edit
    end
  end

  # DELETE /webconferences/1
  # DELETE /webconferences/1.json
  def destroy
    authorize! :destroy, Webconference, on: params[:allocation_tags_ids]

    @webconference = Webconference.where(id: params[:id].split(","))

    unless @webconference.empty?
      @webconference.destroy_all
      render json: {success: true, notice: t(:deleted, scope: [:webconferences, :success])}
    else
      render json: {success: false, alert: t(:deleted, scope: [:webconferences, :error])}, status: :unprocessable_entity
    end
  end
end