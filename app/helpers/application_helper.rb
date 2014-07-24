module ApplicationHelper

  def message
    [:notice,:success,:error].map {|type| %{<span class="#{type}">#{flash[type]}</span>} if flash[type] }.compact.join
  end

  def render_tabs
    tabs_opened = user_session[:tabs][:opened]

    return if tabs_opened.nil?

    tabs_opened.map { |name, link|
      general_context = tabs_opened[name][:url][:context] == Context_General
      active_tab      = tabs_opened[name][:breadcrumb].first[:url][:id] rescue ""
      %{
        <li class="#{'mysolar_unit%s_tab' % [('_active' if (user_session[:tabs][:active] == name))]} #{'general_context' if general_context}">
          #{link_to(name, activate_tab_path(name: name))}
          #{link_to_if(not(general_context), '', close_tab_path(name: name), {class: 'tabs_close', id: "#{active_tab}" })}
        </li>
      }
    }.join
  end

  ## Renderiza a navegação da paginação.
  def render_pagination_bar(total_itens = "1", hash_params = nil)
    total_pages = (total_itens.to_f/Rails.application.config.items_per_page.to_f).ceil.to_i
    total_pages = 1 unless total_itens.to_i > 0

    result = ''
    if @current_page.to_i > total_pages
      @current_page = total_pages.to_s
      result << '<script>$(function() { $(\'form[name="paginationForm"]\').submit();  });</script>'
    end

    total_pages = total_pages.to_s

    result << '<form accept-charset="UTF-8" action="" method="' << request.method << '" name="paginationForm">'

    unless hash_params.nil?
      # ex: type=index&search=1 2 3
      hash_params.split("&").each do |item| 
        individual_param = item.split("=")
        v = individual_param[1].nil? ? "" : individual_param[1]
        result << '<input id="' << individual_param[0] << '" name="' << individual_param[0] << '" value="' << v << '" type="hidden">'
      end
    end

    unless (@current_page.eql? "1") # voltar uma página: <<
      result << '<a class="link_navigation" onclick="$(this).siblings(\'[name=\\\'current_page\\\']\').val(' << ((@current_page.to_i)-1).to_s << ');$(this).parent().submit();">&lt;&lt;</a>'
    end

    result << ' ' << @current_page << t(:navigation_of) << total_pages << ' '
    unless (@current_page.eql? total_pages) # avançar uma página: >>
      result << '<a class="link_navigation" onclick="$(this).siblings(\'[name=\\\'current_page\\\']\').val(' << ((@current_page.to_i)+1).to_s << ');$(this).parent().submit();">&gt;&gt;</a>'
    end

    result << '<input type="hidden" id="current_page" name="current_page" value="' << @current_page << '"/>'
    result << '</form>'
  end

  ## Renderiza a seleção de turmas
  def render_group_selection(hash_params = nil)
    active_tab = user_session[:tabs][:opened][user_session[:tabs][:active]]
    offer_id   = active_tab[:url][:id]
    groups     = Group.find_all_by_offer_id_and_user_id(offer_id, current_user.id)
    # O grupo (turma) a ter seus fóruns exibidos será o grupo selecionado na aba de seleção ('selected_group')
    selected_group_id = AllocationTag.find(active_tab[:url][:allocation_tag_id]).group_id
    # Se o group_select estiver vazio, ou seja, nenhum grupo foi selecionado pelo usuário,
    # o grupo a ter seus fóruns exibidos será o primeiro grupo encontrado para o usuário em questão
    selected_group_id = groups.first.id if selected_group_id.blank?

    result = ''
    if (groups.length > 1 and @can_select_group)
      result = "<form accept-charset='UTF-8' action='' method='#{request.method}' name='groupSelectionForm' style='display:inline'>"
      result <<  t(:group) << ":&nbsp"
      result << select_tag(:selected_group, options_from_collection_for_select(groups, :id, :code, selected_group_id),
        {:onchange => "$(this).parent().submit();"} # versao SEM AJAX
        # {:onchange => "reloadContentByForm($(this).parent());"} # versao AJAX
      )

      unless hash_params.nil?
        # ex: type=index&search=1 2 3
        hash_params.split("&").each { |item|
          individual_param = item.split("=")
          v = individual_param[1].nil? ? "" : individual_param[1]
          result << "<input id='#{individual_param[0]}' name='#{individual_param[0]}' value='#{v}' type='hidden'>"
        }
      end

      result << " <input name='authenticity_token' value='#{form_authenticity_token}' type='hidden'>"
      result << '</form>'
    else
      result = t(:group) << ":&nbsp #{Group.find(selected_group_id).code}"
    end

    return result
  end

  def is_curriculum_unit_selected?
    not(user_session[:tabs][:opened][user_session[:tabs][:active]][:url][:id].nil?)
  end

  def in_mysolar?
    return (params[:action] == "mysolar")
  end

end
