# criando os recursos
resources_arr = [
	{:id => 1, :controller => 'users', :action => 'create', :description => 'Incluir novos usuarios no sistema'},
	{:id => 2, :controller => 'users', :action => 'update', :description => 'Alteracao dos dados do usuario'},
	{:id => 3, :controller => 'users', :action => 'mysolar', :description => 'Lista dos Portlest/Pagina inicial'},
	{:id => 4, :controller => 'users', :action => 'update_photo', :description => 'Trocar foto'},
	{:id => 5, :controller => 'users', :action => 'pwd_recovery', :description => 'Recuperar senha'},

	{:id => 6, :controller => 'offers', :action => 'show', :description => 'Visualizacao de ofertas'},
	{:id => 7, :controller => 'offers', :action => 'update', :description => 'Edicao de ofertas'},
	{:id => 8, :controller => 'offers', :action => 'showoffersbyuser', :description => 'Exibe oferta atraves de busca'},

	{:id => 9, :controller => 'groups', :action => 'show', :description => 'Visualizar turmas'},
	{:id => 10, :controller => 'groups', :action => 'update', :description => 'Editar turmas'},

  {:id => 11, :controller => 'curriculum_units', :action => 'show', :description => 'Acessar Unidade Curricular'},
  {:id => 12, :controller => 'curriculum_units', :action => 'participants', :description => 'Listar participantes de uma Unidade Curricular'},
  {:id => 13, :controller => 'curriculum_units', :action => 'informations', :description => 'Listar informacoes de uma Unidade Curricular'},

  {:id => 14, :controller => 'allocations', :action => 'cancel', :description => 'Cancelar matricula'},
  {:id => 15, :controller => 'allocations', :action => 'reactivate', :description => 'Pedir reativacao de matricula'},
  {:id => 16, :controller => 'allocations', :action => 'send_request', :description => 'Pedir matricula'},
  {:id => 17, :controller => 'allocations', :action => 'cancel_request', :description => 'Cancelar pedido de matricula'},

  {:id => 18, :controller => 'lessons', :action => 'show', :description => 'Ver aula'},
  {:id => 19, :controller => 'lessons', :action => 'list', :description => 'Listar aulas de uma Unidade Curricular'},
  {:id => 20, :controller => 'lessons', :action => 'show_header', :description => 'Ver aula - header'},
  {:id => 21, :controller => 'lessons', :action => 'show_content', :description => 'Ver aula - content'},

  {:id => 22, :controller => 'discussions', :action => 'list', :description => 'Listar Foruns'},
  {:id => 23, :controller => 'bibliography', :action =>'list', :description => 'Bibliografia do curso'},

  {:id => 24, :controller => 'portfolio', :action =>'list', :description => 'Portfolio da Unidade Curricular'},
  {:id => 25, :controller => 'messages', :action =>'index', :description => 'Mensagens'},
  {:id => 26, :controller => 'schedules', :action =>'list', :description => 'Agenda'},

  {:id => 27, :controller => 'portfolio', :action => 'activity_details', :description => 'Atividades Individuais'},
  {:id => 28, :controller => 'portfolio', :action => 'delete_file_individual_area', :description => 'Delecao de arquivos da area privada'},
  {:id => 29, :controller => 'portfolio', :action => 'delete_file_public_area', :description => 'Delecao de arquivos da area publica'},
  {:id => 30, :controller => 'portfolio', :action => 'download_file_comment', :description => 'Download de arquivos enviados pelo professor'},
  {:id => 31, :controller => 'portfolio', :action => 'upload_files_public_area', :description => 'Upload de arquivos para a area publica'},
  {:id => 32, :controller => 'portfolio', :action => 'download_file_public_area', :description => 'Download de arquivos da area publica'},
  {:id => 33, :controller => 'portfolio', :action => 'upload_files_individual_area', :description => 'Upload de arquivos para a area privada'},
  {:id => 34, :controller => 'portfolio', :action => 'download_file_individual_area', :description => 'Download de arquivos da area privada'},

  {:id => 35, :controller => 'portfolio_teacher', :action => 'list', :description => 'Lista os alunos da turma'},
  {:id => 36, :controller => 'portfolio_teacher', :action => 'student_detail', :description => 'Detalha portfolio do aluno'},
  {:id => 37, :controller => 'portfolio_teacher', :action => 'update_comment', :description => 'Comentar atividade do aluno'},
  {:id => 38, :controller => 'portfolio_teacher', :action => 'delete_file', :description => 'Deletar arquivos de comentarios'},
  {:id => 39, :controller => 'portfolio_teacher', :action => 'upload_files', :description => 'Upload de arquivos de correcao'},
  {:id => 40, :controller => 'portfolio_teacher', :action => 'download_files_student', :description => 'Download de arquivos enviados pelo aluno'},

  # Discussion deve ser separado em dois controllers: Discussion e Discussion_post#
  {:id => 42, :controller => 'discussions', :action => 'new_post', :description => 'Cria um novo post'},
  {:id => 43, :controller => 'discussions', :action => 'remove_post', :description => 'Remove um post'},
  {:id => 44, :controller => 'discussions', :action => 'update_post', :description => 'Atualiza o conteudo de um post'},
  {:id => 45, :controller => 'discussions', :action => 'show', :description => 'Exibe todos os posts'},
  {:id => 46, :controller => 'discussions', :action => 'list', :description => 'Lista os foruns'},

  # acompanhamento
  {:id => 47, :controller => 'scores', :action => 'show', :description => 'Exibicao dos dados do aluno'},

  # acompanhamento do professor
  {:id => 48, :controller => 'scores_teacher', :action => 'list', :description => 'Lista dos alunos da turma'},
  {:id => 49, :controller => 'discussions', :action => 'download_post_file', :description => 'Baixar arquivos de foruns'},
  {:id => 50, :controller => 'discussions', :action => 'attach_file', :description => 'Anexar arquivos de foruns'},
  {:id => 51, :controller => 'discussions', :action => 'remove_attached_file', :description => 'Remover arquivos de postagens'},
  {:id => 52, :controller => 'users', :action => 'find', :description => 'Consultar dados do usuario'},
  {:id => 53, :controller => 'discussions', :action => 'post_file_upload', :description => 'Exibir janela para upload de arquivos no foruns'},

  # Material de apoio
  {:id => 54, :controller => 'support_material_file', :action => 'list', :description => 'Visualizar material de apoio'},
  {:id => 55, :controller => 'support_material_file', :action => 'download', :description => 'Baixar material de apoio'},
  {:id => 56, :controller => 'support_material_file', :action => 'download_all_file_ziped', :description => 'Baixar material de apoio ZIPADO'},
  {:id => 57, :controller => 'support_material_file', :action => 'download_folder_file_ziped', :description => 'Baixar pasta do material de apoio ZIPADO'},

  #curso
  {:id => 58, :controller => 'courses', :action => 'create', :description => 'Criar novo curso'},
  {:id => 59, :controller => 'courses', :action => 'update', :description => 'Editar um curso'},
  {:id => 60, :controller => 'courses', :action => 'show', :description => 'Mostrar um curso'},
  {:id => 61, :controller => 'courses', :action => 'index', :description => 'inicio'},
  {:id => 62, :controller => 'courses', :action => 'destroy', :description => 'Apaga um curso'},

  #Material de apoio do editor
  {:id => 63, :controller => 'support_material_file_editor', :action => 'list', :description => 'Visulalizar arquivos do material de apoio do editor'},
  {:id => 64, :controller => 'support_material_file_editor', :action => 'upload_link', :description => 'Upload de link do material de apoio'},
  {:id => 65, :controller => 'support_material_file_editor', :action => 'upload_files', :description => 'Upload de arquivos do material de apoio'},
]

count = 0
resources = Resource.create(resources_arr) do |registro|
  registro.id = resources_arr[count][:id]
  count += 1
end
########################
#        PERFIS        #
########################

###############
#    ALUNO    #
###############
perm_alunos = PermissionsResource.create([
    # offer
    {:profile_id => 1, :resource_id => 6, :per_id => true},
    {:profile_id => 1, :resource_id => 7, :per_id => true},
    {:profile_id => 1, :resource_id => 8, :per_id => true},
    # group
    {:profile_id => 1, :resource_id => 9, :per_id => true},
    {:profile_id => 1, :resource_id => 10, :per_id => true},
    # curriculum unit
    {:profile_id => 1, :resource_id => 11, :per_id => false},
    {:profile_id => 1, :resource_id => 12, :per_id => false},
    {:profile_id => 1, :resource_id => 13, :per_id => false},
    {:profile_id => 1, :resource_id => 14, :per_id => false},
    {:profile_id => 1, :resource_id => 15, :per_id => false},
    {:profile_id => 1, :resource_id => 16, :per_id => false},
    {:profile_id => 1, :resource_id => 17, :per_id => false},
    {:profile_id => 1, :resource_id => 18, :per_id => false},
    {:profile_id => 1, :resource_id => 19, :per_id => false},
    {:profile_id => 1, :resource_id => 20, :per_id => false},
    {:profile_id => 1, :resource_id => 21, :per_id => false},
    {:profile_id => 1, :resource_id => 22, :per_id => false},
    {:profile_id => 1, :resource_id => 23, :per_id => false},
    {:profile_id => 1, :resource_id => 24, :per_id => false},

    {:profile_id => 1, :resource_id => 27, :per_id => false},
    {:profile_id => 1, :resource_id => 28, :per_id => false},
    {:profile_id => 1, :resource_id => 29, :per_id => false},
    {:profile_id => 1, :resource_id => 30, :per_id => false},
    {:profile_id => 1, :resource_id => 31, :per_id => false},
    {:profile_id => 1, :resource_id => 32, :per_id => false},
    {:profile_id => 1, :resource_id => 33, :per_id => false},
    {:profile_id => 1, :resource_id => 34, :per_id => false},

    # discussion
    {:profile_id => 1, :resource_id => 42, :per_id => false},
    {:profile_id => 1, :resource_id => 43, :per_id => false},
    {:profile_id => 1, :resource_id => 44, :per_id => false},
    {:profile_id => 1, :resource_id => 45, :per_id => false},
    {:profile_id => 1, :resource_id => 46, :per_id => false},
    {:profile_id => 1, :resource_id => 49, :per_id => false},
    {:profile_id => 1, :resource_id => 50, :per_id => false},
    {:profile_id => 1, :resource_id => 51, :per_id => false},
    {:profile_id => 1, :resource_id => 53, :per_id => false},
    # acompanhamento
    {:profile_id => 1, :resource_id => 47, :per_id => true},
    {:profile_id => 1, :resource_id => 52, :per_id => true},
    # Material de apoio
    {:profile_id => 1, :resource_id => 54, :per_id => false},
    {:profile_id => 1, :resource_id => 55, :per_id => false},
    {:profile_id => 1, :resource_id => 56, :per_id => false},
    {:profile_id => 1, :resource_id => 57, :per_id => false},
    
    #TESTE  CURSO !!!!!!!!!!!!!!!!!!!!!!APAGAR!!!!!!!!!!!!!!!!!!!!!!!
    {:profile_id => 1, :resource_id => 58, :per_id => false},
    {:profile_id => 1, :resource_id => 59, :per_id => false},
    {:profile_id => 1, :resource_id => 60, :per_id => false},
    {:profile_id => 1, :resource_id => 61, :per_id => false},
    {:profile_id => 1, :resource_id => 62, :per_id => false}
  ])

##############################
#      PROFESSOR TITULAR     #
##############################
perm_prof_titular = PermissionsResource.create([
    # offer
    {:profile_id => 2, :resource_id => 6, :per_id => true},
    {:profile_id => 2, :resource_id => 7, :per_id => true},
    {:profile_id => 2, :resource_id => 8, :per_id => true},
    # group
    {:profile_id => 2, :resource_id => 9, :per_id => true},
    {:profile_id => 2, :resource_id => 10, :per_id => true},
    # curriculum unit
    {:profile_id => 2, :resource_id => 11, :per_id => false},
    {:profile_id => 2, :resource_id => 12, :per_id => false},
    {:profile_id => 2, :resource_id => 13, :per_id => false},
    {:profile_id => 2, :resource_id => 14, :per_id => false},
    {:profile_id => 2, :resource_id => 15, :per_id => false},
    {:profile_id => 2, :resource_id => 16, :per_id => false},
    {:profile_id => 2, :resource_id => 17, :per_id => false},
    {:profile_id => 2, :resource_id => 18, :per_id => false},
    {:profile_id => 2, :resource_id => 19, :per_id => false},
    {:profile_id => 2, :resource_id => 20, :per_id => false},
    {:profile_id => 2, :resource_id => 21, :per_id => false},
    {:profile_id => 2, :resource_id => 22, :per_id => false},
    {:profile_id => 2, :resource_id => 23, :per_id => false},
    # portfolio
    {:profile_id => 2, :resource_id => 30, :per_id => false},
    {:profile_id => 2, :resource_id => 35, :per_id => false},
    {:profile_id => 2, :resource_id => 36, :per_id => false},
    {:profile_id => 2, :resource_id => 37, :per_id => false},
    {:profile_id => 2, :resource_id => 38, :per_id => false},
    {:profile_id => 2, :resource_id => 39, :per_id => false},
    {:profile_id => 2, :resource_id => 40, :per_id => false},
    #discussion
    {:profile_id => 2, :resource_id => 42, :per_id => false},
    {:profile_id => 2, :resource_id => 43, :per_id => false},
    {:profile_id => 2, :resource_id => 44, :per_id => false},
    {:profile_id => 2, :resource_id => 45, :per_id => false},
    {:profile_id => 2, :resource_id => 46, :per_id => false},
    {:profile_id => 2, :resource_id => 49, :per_id => false},
    {:profile_id => 2, :resource_id => 50, :per_id => false},
    {:profile_id => 2, :resource_id => 51, :per_id => false},
    {:profile_id => 2, :resource_id => 53, :per_id => false},

    # acompanhamento
    {:profile_id => 2, :resource_id => 47, :per_id => false},
    {:profile_id => 2, :resource_id => 48, :per_id => false},
    {:profile_id => 2, :resource_id => 52, :per_id => false},

    # Material de apoio
    {:profile_id => 2, :resource_id => 54, :per_id => false},
    {:profile_id => 2, :resource_id => 55, :per_id => false},
    {:profile_id => 2, :resource_id => 56, :per_id => false},
    {:profile_id => 2, :resource_id => 57, :per_id => false}
  ])

##############################
#      TUTOR A DISTANCIA     #
##############################
perm_prof_titular = PermissionsResource.create([
    # offer
    {:profile_id => 3, :resource_id => 6, :per_id => true},
    {:profile_id => 3, :resource_id => 7, :per_id => true},
    {:profile_id => 3, :resource_id => 8, :per_id => true},
    # group
    {:profile_id => 3, :resource_id => 9, :per_id => true},
    {:profile_id => 3, :resource_id => 10, :per_id => true},
    # curriculum unit
    {:profile_id => 3, :resource_id => 11, :per_id => false},
    {:profile_id => 3, :resource_id => 12, :per_id => false},
    {:profile_id => 3, :resource_id => 13, :per_id => false},
    {:profile_id => 3, :resource_id => 14, :per_id => false},
    {:profile_id => 3, :resource_id => 15, :per_id => false},
    {:profile_id => 3, :resource_id => 16, :per_id => false},
    {:profile_id => 3, :resource_id => 17, :per_id => false},
    {:profile_id => 3, :resource_id => 18, :per_id => false},
    {:profile_id => 3, :resource_id => 19, :per_id => false},
    {:profile_id => 3, :resource_id => 20, :per_id => false},
    {:profile_id => 3, :resource_id => 21, :per_id => false},
    {:profile_id => 3, :resource_id => 22, :per_id => false},
    {:profile_id => 3, :resource_id => 23, :per_id => false},
    {:profile_id => 3, :resource_id => 24, :per_id => false},
    # portfolio
    {:profile_id => 3, :resource_id => 35, :per_id => false},
    {:profile_id => 3, :resource_id => 36, :per_id => false},
    {:profile_id => 3, :resource_id => 37, :per_id => false},
    {:profile_id => 3, :resource_id => 38, :per_id => false},
    {:profile_id => 3, :resource_id => 39, :per_id => false},
    {:profile_id => 3, :resource_id => 40, :per_id => false},

    #discussion
    {:profile_id => 3, :resource_id => 42, :per_id => false},
    {:profile_id => 3, :resource_id => 43, :per_id => false},
    {:profile_id => 3, :resource_id => 44, :per_id => false},
    {:profile_id => 3, :resource_id => 45, :per_id => false},
    {:profile_id => 3, :resource_id => 46, :per_id => false},
    {:profile_id => 3, :resource_id => 47, :per_id => false},
    {:profile_id => 3, :resource_id => 48, :per_id => false},
    {:profile_id => 3, :resource_id => 49, :per_id => false},
    {:profile_id => 3, :resource_id => 50, :per_id => false},
    {:profile_id => 3, :resource_id => 51, :per_id => false},
    {:profile_id => 3, :resource_id => 53, :per_id => false},

    # Material de apoio
    {:profile_id => 3, :resource_id => 54, :per_id => false},
    {:profile_id => 3, :resource_id => 55, :per_id => false},
    {:profile_id => 3, :resource_id => 56, :per_id => false},
    {:profile_id => 3, :resource_id => 57, :per_id => false}
    
  ])


##############################
#           EDITOR           #
##############################
perm_editor = PermissionsResource.create([
    {:profile_id => 5, :resource_id => 58, :per_id => false},
    {:profile_id => 5, :resource_id => 59, :per_id => false},
    {:profile_id => 5, :resource_id => 60, :per_id => false}
  ])


######## PERMISSIONS MENUS #########

PermissionsMenu.create([
    {:profile_id => 1, :menu_id => 10},
    {:profile_id => 1, :menu_id => 101},
    {:profile_id => 1, :menu_id => 20},
    {:profile_id => 1, :menu_id => 201},
    {:profile_id => 1, :menu_id => 202},
    {:profile_id => 1, :menu_id => 204},
    {:profile_id => 1, :menu_id => 30},
    {:profile_id => 1, :menu_id => 301},
    {:profile_id => 1, :menu_id => 303},
    {:profile_id => 1, :menu_id => 304},
    {:profile_id => 1, :menu_id => 50},
    {:profile_id => 1, :menu_id => 100},
    #{:profile_id => 1, :menu_id => 70},
    {:profile_id => 1, :menu_id => 302},
    {:profile_id => 1, :menu_id => 102},

    # professor titular
    {:profile_id => 2, :menu_id => 10},
    {:profile_id => 2, :menu_id => 101},
    {:profile_id => 2, :menu_id => 20},
    {:profile_id => 2, :menu_id => 201},
    {:profile_id => 2, :menu_id => 207},
    {:profile_id => 2, :menu_id => 208},
    {:profile_id => 2, :menu_id => 30},
    {:profile_id => 2, :menu_id => 301},
    {:profile_id => 2, :menu_id => 303},
    {:profile_id => 2, :menu_id => 304},
    {:profile_id => 2, :menu_id => 50},
    {:profile_id => 2, :menu_id => 100},
    #{:profile_id => 2, :menu_id => 70},
    {:profile_id => 2, :menu_id => 302},
    {:profile_id => 2, :menu_id => 102},

    # tutor a distancia
    {:profile_id => 3, :menu_id => 10},
    {:profile_id => 3, :menu_id => 101},
    {:profile_id => 3, :menu_id => 20},
    {:profile_id => 3, :menu_id => 201},
    {:profile_id => 3, :menu_id => 202},
    {:profile_id => 3, :menu_id => 30},
    {:profile_id => 3, :menu_id => 301},
    {:profile_id => 3, :menu_id => 303},
    {:profile_id => 3, :menu_id => 304},
    {:profile_id => 3, :menu_id => 50},
    {:profile_id => 3, :menu_id => 100},
    #{:profile_id => 3, :menu_id => 70},
    {:profile_id => 3, :menu_id => 302},
    {:profile_id => 3, :menu_id => 102},

    #editor
    {:profile_id => 5, :menu_id => 10},
    {:profile_id => 5, :menu_id => 101},
    {:profile_id => 5, :menu_id => 20},
    {:profile_id => 5, :menu_id => 201},
    {:profile_id => 5, :menu_id => 202},
    {:profile_id => 5, :menu_id => 30},
    {:profile_id => 5, :menu_id => 301},
    {:profile_id => 5, :menu_id => 303},
    {:profile_id => 5, :menu_id => 304},
    {:profile_id => 5, :menu_id => 50},
    {:profile_id => 5, :menu_id => 100},
    #{:profile_id => 5, :menu_id => 70},
    {:profile_id => 5, :menu_id => 302},
    {:profile_id => 5, :menu_id => 102},
    {:profile_id => 5, :menu_id => 120}

  ])
