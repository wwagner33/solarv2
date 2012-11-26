Solar::Application.routes.draw do 

  devise_for :users, :path_names => {:sign_up => :register}

  devise_scope :user do
    get  :login, :to => "devise/sessions#new"
    post :login, :to => "devise/sessions#create"
    get  :logout, :to => "devise/sessions#destroy"
    get "/", :to => "devise/sessions#new"
    resources :sessions, :only => [:create]
  end

  ## curriculum_units/:id/participants
  ## curriculum_units/:id/informations
  resources :curriculum_units do
    collection do 
      get :list
      get :list_informations
      get :list_participants
    end
    member do
      get :participants
      get :informations
      get :home
    end
    resources :groups, :only => [:index]
  end

  ## curriculum_units/:id/groups
  # get 'curriculum_units/:curriculum_unit_id/groups' => "groups#list", :as => :groups_curriculum_unit

  resources :discussions do
    get :list, on: :collection
  end

  ## groups/:id/discussions
  resources :groups, :except => [:show] do
    resources :discussions, :only => [:index]
    get :list, on: :collection
  end

  ## discussions/:id/posts
  resources :discussions, :only => [] do
    resources :posts, :except => [:show, :new, :edit]
    controller :posts do
      get "posts/user/:user_id", :to => :show, :as => "posts_of_the_user"
      get "posts/:type/:date(/order/:order(/limit/:limit))", :to => :index, :defaults => {:display_mode => 'list'} # :types => [:news, :history]; :order => [:asc, :desc]
    end
  end

  ## posts/:id/post_files
  resources :posts, :only => [] do
    resources :post_files, :only => [:new, :create, :destroy, :download] do
      get :download, on: :member
    end
  end

  ## users/:id/photo
  ## users/edit_photo
  resources :users do
    get :photo, on: :member
    get :edit_photo, on: :collection
  end

  ## allocations/enrollments
  resources :allocations, :except => [:new] do
    collection do
      get :designates
      get :enrollments, :action => :index
      get :search_users
      post :create_designation
    end
    member do
      delete :cancel, :action => :destroy
      delete :cancel_request, :action => :destroy, :defaults => {:type => 'request'}
      post :deactivate
      post :activate
    end
  end
  
  resources :offers do
    post :deactivate_groups, on: :member
  end

  resources :enrollments, :only => [:index]
  resources :scores, :only => [:show, :index]
  resources :courses
  resources :editions, :only => [:index]

  resources :lessons, :only => [:show] do
    collection do
      get :show_header
      get :show_content
      get :index
      get :list
    end
  end

  mount Ckeditor::Engine => "/ckeditor"

  resources :assignments, :only => [:show] do
    collection do
      get :list
      get :download_files
      get :list_to_student
      get :send_public_files_page
      post :upload_file
      delete :delete_file
    end
    member do
      get :information
      get :import_groups_page
      post :evaluate
      post :send_comment
      post :manage_groups
      post :import_groups
      delete :remove_comment
    end
  end

  resources :schedules, :only => [] do
    get :list, on: :collection
  end

  resources :messages do
    get :restore, on: :collection
  end

  get "activate_tab" => "application#activate_tab", as: :activate_tab
  get "add_tab" => "application#add_tab", as: :add_tab
  get "close_tab" => "application#close_tab", as: :close_tab

  get "pages/index"
  get "pages/team"
  get "access_control/index"
  get "schedules/show"
  get "scores/:id/history_access" => "scores#history_access"
  get 'home' => "users#mysolar", :as => :home
  get 'user_root' => 'users#mysolar'
  
  get "/media/users/:id/photos/:style.:extension", :to => "users#photo"
  get "/media/lessons/:id/:file.:extension", :to => "access_control#lesson"
  get "/media/messages/:file.:extension", :to => "access_control#message"

  get "/media/assignment/sent_assignment_files/:file.:extension", :to => "access_control#assignment"
  get "/media/assignment/comments/:file.:extension", :to => "access_control#assignment"
  get "/media/assignment/public_area/:file.:extension", :to => "access_control#assignment"
  get "/media/assignment/enunciation/:file.:extension", :to => "access_control#assignment"

  match ':controller(/:action(/:id(.:format)))'

  root :to => 'devise/sessions#new'

end