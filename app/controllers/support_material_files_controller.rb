class SupportMaterialFilesController < ApplicationController

  include SysLog::Actions
  include FilesHelper

  layout false, except: :index
  before_filter :prepare_for_group_selection, only: :index

  before_filter :get_groups_by_allocation_tags, only: [:new, :create]

  before_filter only: [:edit, :update] do |controller|
    @allocation_tags_ids = params[:allocation_tags_ids]
    get_groups_by_tool(@support_material_file = SupportMaterialFile.find(params[:id]))
  end


  def index
    authorize! :index, SupportMaterialFile, on: [@allocation_tag_id = active_tab[:url][:allocation_tag_id]]
    allocation_tag_ids = AllocationTag.find(@allocation_tag_id).related

      @list_files = SupportMaterialFile.find_files(allocation_tag_ids)

      @folders_list = {}
      @list_files.collect { |file|
        @folders_list[file["folder"]] = [] unless @folders_list[file["folder"]].is_a?(Array) # utiliza nome do folder como chave da lista
        @folders_list[file["folder"]] << file
      }
  end

  def new
    authorize! :create, SupportMaterialFile, on: @allocation_tags_ids = params[:allocation_tags_ids]
    @support_material_file = SupportMaterialFile.new material_type: params[:material_type]
  end

  def create
    authorize! :create, SupportMaterialFile, on: @allocation_tags_ids = params[:allocation_tags_ids].split(" ").flatten
    if params[:support_material_file][:material_type].to_i == Material_Type_File
      raise 'empty' if params[:files].blank?
      create_many
    else
      create_one
     end


    render json: { success: true, notice: t('support_materials.success.created') }
  rescue ActiveRecord::AssociationTypeMismatch
    render json: { success: false, alert: t(:not_associated) }, status: :unprocessable_entity
  rescue CanCan::AccessDenied
    render json: { success: false, alert: t(:no_permission) }, status: :unauthorized
  rescue => error
    @allocation_tags_ids = @allocation_tags_ids.join(' ')
    if @support_material_file.nil? || @support_material_file.is_file?
      render json: { success: false, alert: t('support_material_files.error.file') }, status: :unprocessable_entity
    else
      render :new
    end
  end

  def edit
    raise 'cant_edit_file' if @support_material_file.is_file?
    authorize! :update, SupportMaterialFile, on: @allocation_tags_ids
  end

  def update
    raise 'cant_edit_file' if @support_material_file.is_file?
    authorize! :update, SupportMaterialFile, on: @support_material_file.academic_allocations.pluck(:allocation_tag_id)

    if @support_material_file.update_attributes(support_material_file_params)
      render json: {success: true, notice: t('support_materials.success.updated')}
    else
      render json: {success: false, alert: @support_material_file.errors.full_messages}, status: :unprocessable_entity
    end
  rescue => error
    request.format = :json
    raise error.class
  end

  def open
    if Exam.verify_blocking_content(current_user.id)
        redirect_to :back, alert: t('exams.restrict')
    else
      @file = SupportMaterialFile.find(params[:id]) unless params[:id].blank?
      if @file.url.blank? && !File.exist?(@file.attachment.path)
        render text: t(:file_error_nonexistent_file)
      else
        allocation_tag_ids = if !((current_at = active_tab[:url][:allocation_tag_id]).blank?) # dentro de uma UC
            ats = AllocationTag.find(current_at).related
            # se tenho acesso ao arquivo de dentro da UC que estou acessando
            @file.nil? ? ats : @file.academic_allocations.map(&:allocation_tag_id) & ats
          else # fora da UC
            @file.academic_allocations.map(&:allocation_tag_id)
          end
        authorize! :download, SupportMaterialFile, on: allocation_tag_ids, read: true

        render layout: 'lesson'
      end
    end

  end

  def destroy
    @support_material_files = SupportMaterialFile.where(id: params[:id].split(",").flatten)
    @allocation_tags_ids = @support_material_files.map(&:academic_allocations).flatten.map(&:allocation_tag_id).flatten # params[:allocation_tags_ids]

    authorize! :destroy, SupportMaterialFile, on:@allocation_tags_ids

    @support_material_files.destroy_all

    render json: {success: true, notice: t('support_materials.success.deleted')}
  rescue => error
    request.format = :json
    raise error.class
  end

  def download
    if Exam.verify_blocking_content(current_user.id)
        redirect_to :back, alert: t('exams.restrict')
    else
      file = SupportMaterialFile.find(params[:id]) unless params[:id].blank?

      unless file.nil? || file.url.blank?
        redirect_to file.url, blank: true
      else
        allocation_tag_ids = if !((current_at = active_tab[:url][:allocation_tag_id]).blank?) # dentro de uma UC
          ats = AllocationTag.find(current_at).related
          # se tenho acesso ao arquivo de dentro da UC que estou acessando
          file.nil? ? ats : file.academic_allocations.map(&:allocation_tag_id) & ats
        else # fora da UC
          file.academic_allocations.map(&:allocation_tag_id)
        end

        authorize! :download, SupportMaterialFile, on: allocation_tag_ids, read: true

        unless params[:type].blank? # folder ou all
          redirect_error = support_material_files_path

          folder = (params[:type] == :folder && !params[:folder].blank?) ? params[:folder] : nil
          path_zip = compress_file({ files: SupportMaterialFile.find_files(allocation_tag_ids, folder), table_column_name: 'attachment_file_name' })

          if path_zip
            download_file(redirect_error, path_zip)
          else
            redirect_to redirect_error, alert: t(:file_error_nonexistent_file)
          end
        else # baixando um arquivo individualmente
          download_file(support_material_files_path, file.attachment.path, file.attachment_file_name)
        end
      end
    end
  end

  def list
    @allocation_tags_ids = params[:groups_by_offer_id].present? ? AllocationTag.at_groups_by_offer_id(params[:groups_by_offer_id]) : params[:allocation_tags_ids]
    authorize! :list, SupportMaterialFile, on: @allocation_tags_ids

    @support_materials = SupportMaterialFile.joins(academic_allocations: :allocation_tag).where(allocation_tags: {id: @allocation_tags_ids.split(" ").flatten}).order("attachment_updated_at DESC").uniq
  rescue => error
    request.format = :json
    raise error.class
  end

  private

    def support_material_file_params
      params.require(:support_material_file).permit(:material_type, :url, :attachment, :title)
    end

     def create_one(params=support_material_file_params)
      @support_material_file = SupportMaterialFile.new(params)

      SupportMaterialFile.transaction do
        @support_material_file.allocation_tag_ids_associations = @allocation_tags_ids
        @support_material_file.save!
      end

      @support_material_file
    rescue => error
      raise error
    end

    def create_many
      SupportMaterialFile.transaction do
        unless params[:files].blank?
          @support_material_files = []
          params[:files].each do |file|
            create_one(support_material_file_params.merge!(attachment: file, title: params[:support_material_file][:title]))
            @support_material_files << @support_material_file
          end
          @support_material_file = nil
        end
      end
    rescue => error
      raise error
    end

end
