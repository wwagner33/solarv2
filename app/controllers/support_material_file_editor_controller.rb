class SupportMaterialFileEditorController < ApplicationController



  def list

    # Recuperando os arquivos enviados do material de apoio

    #################  OBTER OS ARQUIVO COM O QUAL O EDITOR FEZ O UPLOAD  ##################
    @editor_general_data = SupportMaterialFileEditor.list_editor_option(current_user.id)[0]
    @editor_courses_current = SupportMaterialFileEditor.list_editor_by_course(@editor_general_data["course_id"])
    allocation_tag_id = user_session[:tabs][:opened][user_session[:tabs][:active]][:url]['allocation_tag_id'] #@editor_general_data["allocation_tag_id"].to_i
    @list_files = SupportMaterialFile.search_files(allocation_tag_id)
    curriculum_unit_id = active_tab[:url]['id']

    # construindo um conjunto de objetos
    @folders_list = {}
    @list_files.collect {|file|
      @folders_list[file["folder"]] = [] unless @folders_list[file["folder"]].is_a?(Array)
      @folders_list[file["folder"]] << file
    }
    #######################################################

    @editor_general_data = SupportMaterialFileEditor.list_editor_option(current_user.id)[0]
    @editor_courses_current = SupportMaterialFileEditor.list_editor_by_course(@editor_general_data["course_id"])

    # As variáveis comentadas a seguir serão necessárias caso o menu esteja dentro do Curriculun Unit
    @editor_course_choose = ""
    @editor_curriculum_unit = ""
    @editor_group = ""
  end

  def upload_link
    url  = params[:link]["link"]
    @editor_general_data = SupportMaterialFileEditor.list_editor_option(current_user.id)[0]

    if (url.empty?)
      flash[:error] = "Link deve ser preenchido !"
      redirect_to :controller => "support_material_file_editor", :action => "list"
      return
    end

    allocation_tag_id = user_session[:tabs][:opened][user_session[:tabs][:active]][:url]['allocation_tag_id'] #@editor_general_data["allocation_tag_id"]
    SupportMaterialFile.upload_link(allocation_tag_id, url)

    flash[:success] = "Link enviado com sucesso!"
    redirect_to :controller => "support_material_file_editor", :action => "list"

  end

  def edit_link
    raise "para implementar"
  end

  def upload_files
    #    authorize! :upload_files, SupportMaterialFileEditor

    respond_to do |format|
      begin
        # redireciona para a lista
        redirect = {:action => :list}

        # verifica se o arquivo foi adicionado
        raise t(:error_no_file_sent) unless params.include?(:support_material)

        # verifica se é uma pasta existente no banco ou uma nova criado pelo usuário.
        if (params[:support_material][:new_folder] != "")
          params[:support_material][:folder] = params[:support_material][:new_folder]
        end

        params[:support_material].delete(:new_folder)

        # verifica se o arquivo enviado já existe na pasta selecionada
        file = SupportMaterialFile.new params[:support_material]

        # Se retornar um registro é porque já existe no banco e nao pode inserir, se for vazio pode inserir
        verify = SupportMaterialFile.find_by_attachment_file_name_and_folder(file.attachment_file_name, file.folder.upcase.strip)

        raise "Arquivo escolhido existe nessa mesma pasta !" unless (verify.nil?)

        # allocation_tag_id selecionada pela sessão do usuário
        allocation_tag_id = user_session[:tabs][:opened][user_session[:tabs][:active]][:url]['allocation_tag_id'] #@editor_general_data["allocation_tag_id"].to_i

        @file = SupportMaterialFile.new params[:support_material]
        @file.folder = @file.folder.upcase.strip
        @file.allocation_tag_id = allocation_tag_id
        @file.save!

        # arquivo salvo com sucesso
        flash[:success] = t(:file_uploaded)
        format.html { redirect_to(redirect) }

      rescue Exception => error
        flash[:error] = error.message
        format.html { redirect_to(redirect) }
      end
    end
  end

  #Deleta arquivos e links
  def delete_select_file
    #    authorize! :delete_file_public_area, Portfolio
    redirect = {:action => :list}
    respond_to do |format|
      begin
        # arquivo a ser deletado
        file_del = "#{::Rails.root.to_s}/media/support_material_file/#{params[:id]}_#{SupportMaterialFile.find(params[:id]).attachment_file_name}"

        error = false

        # deletar arquivo da base de dados
        error = true unless SupportMaterialFile.find(params[:id]).delete

        # deletar arquivo do servidor
        unless error
          File.delete(file_del) if File.exist?(file_del)

          flash[:success] = t(:file_deleted)
          format.html { redirect_to(redirect) }
        else
          raise t(:error_delete_file) unless !error
        end

      rescue Exception
        flash[:error] = t(:error_delete_file)
        format.html { redirect_to(redirect) }
      end
    end
  end

end
