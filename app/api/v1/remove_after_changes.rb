module V1
  class RemoveAfterChanges < Base

    before { verify_ip_access_and_guard! }

    namespace :load do

        namespace :groups do

          # load/groups/allocate_user
          # params { requires :cpf, :perfil, :codDisciplina, :codGraduacao, :codTurma, :periodo, :ano }
          put :allocate_user do # Receives user's cpf, group and profile to allocate
            begin
              allocation = params[:allocation]
              user       = verify_or_create_user(allocation[:cpf])
              profile_id = get_profile_id(allocation[:perfil])

              destination = get_destination(allocation[:codDisciplina], allocation[:codGraduacao], allocation[:nomeTurma], (allocation[:periodo].blank? ? allocation[:ano] : "#{allocation[:ano]}.#{allocation[:periodo]}"))

              destination.allocate_user(user.id, profile_id)

              {ok: :ok}
            end
          end # allocate_profile

          # load/groups/block_profile
          put :block_profile do # Receives user's cpf, group and profile to block
            allocation = params[:allocation]
            user       = User.find_by_cpf!(allocation[:cpf].to_s.delete('.').delete('-'))
            group_info = allocation[:turma]
            profile_id = get_profile_id(allocation[:perfil])

            begin
              destination = get_destination(group_info[:codDisciplina], group_info[:codGraduacao], group_info[:nome], (group_info[:periodo].blank? ? group_info[:ano] : "#{group_info[:ano]}.#{group_info[:periodo]}"))

              destination.cancel_allocations(user.id, profile_id) if destination

              {ok: :ok}
            end
          end # block_profile

        end # groups

        namespace :groups do
          # POST load/groups
          post "/" do
            load_group    = params[:turmas]
            cpfs          = load_group[:professores]
            semester_name = load_group[:periodo].blank? ? load_group[:ano] : "#{load_group[:ano]}.#{load_group[:periodo]}"
            offer_period  = { start_date: load_group[:dtInicio].to_date, end_date: (load_group[:dtFim].to_date) }
            course        = Course.find_by_code! load_group[:codGraduacao]
            uc            = CurriculumUnit.find_by_code! load_group[:codDisciplina]

            begin
              ActiveRecord::Base.transaction do
                semester = verify_or_create_semester(semester_name, offer_period)
                offer    = verify_or_create_offer(semester, {curriculum_unit_id: uc.id, course_id: course.id}, offer_period)
                group    = verify_or_create_group({offer_id: offer.id, code: load_group[:code], name: load_group[:name], location_name: load_group[:location_name], location_office: load_group[:location_office]})

                allocate_professors(group, cpfs || [])
              end

              { ok: :ok }
            end
          end

          segment do
            params{ requires :matriculas }
            before do
              load_enrollments = params[:matriculas]
              @user             = verify_or_create_user(load_enrollments[:cpf])
              @groups           = JSON.parse(load_enrollments[:turmas])
              @student_profile  = 1 # Aluno => 1

              @groups = @groups.collect do |group_info|
                get_group_by_names(group_info["codDisciplina"], group_info["codGraduacao"], group_info["nome"], (group_info["periodo"].blank? ? group_info["ano"] : "#{group_info["ano"]}.#{group_info["periodo"]}")) unless group_info["codDisciplina"] == 78
              end # Se cód. graduação for 78, desconsidera (por hora, vem por engano).

              raise ActiveRecord::RecordNotFound if @groups.include?(nil)
            end # before

            # POST load/groups/enrollments
            post :enrollments do
              begin
                create_allocations(@groups.compact, @user, @student_profile)

                { ok: :ok }
              end
            end

            # DELETE load/groups/enrollments
            delete :enrollments do
              begin
                cancel_allocations(@groups.compact, @user, @student_profile)

                { ok: :ok }
              end
            end

          end # segment

          # GET load/groups/enrollments
          params { requires :codDisciplina, :codGraduacao, :nomeTurma, :periodo, :ano, type: String }
          get :enrollments, rabl: "users/list" do
            group  = get_group_by_names(params[:codDisciplina], params[:codGraduacao], params[:nomeTurma], (params[:periodo].blank? ? params[:ano] : "#{params[:ano]}.#{params[:periodo]}"))
            raise ActiveRecord::RecordNotFound if group.nil?
            begin
              @users = group.students_participants
            end
          end

        end # groups

        namespace :user do
          params { requires :cpf, type: String }
          # load/user
          post "/" do
            begin
              user = User.new cpf: params[:cpf]
              ma_response = user.connect_and_validates_user
              raise ActiveRecord::RecordNotFound if ma_response.nil? # nao existe no MA
              { ok: :ok }
            end
          end
        end # user

      end # load

      namespace :integration do

        namespace :event do

          desc "Edição de evento"
          params do
            requires :id, type: Integer, desc: "Event ID."
            requires :Data, :HoraInicio, :HoraFim
          end
          put "/:id" do
            begin
              event = ScheduleEvent.find(params[:id])

              ActiveRecord::Base.transaction do
                start_hour, end_hour = params[:HoraInicio].split(":"), params[:HoraFim].split(":")
                event.schedule.update_attributes! start_date: params[:Data], end_date: params[:Data]
                event.api = true
                event.update_attributes! start_hour: [start_hour[0], start_hour[1]].join(":"), end_hour: [end_hour[0], end_hour[1]].join(":")
              end

              { ok: :ok }
            end
          end # put :id

        end # event

        namespace :events do

          desc "Criação de um ou mais eventos"
          params do
            requires :Turmas, type: Array
            requires :CodigoCurso, :CodigoDisciplina, :Periodo, type: String
            requires :DataInserida, type: Hash do
              requires :Data
              requires :HoraInicio, :HoraFim, :Polo, :Tipo, type: String
            end
          end
          post "/" do
            group_events = []

            begin
              ActiveRecord::Base.transaction do
                offer = get_offer(params[:CodigoDisciplina], params[:CodigoCurso], params[:Periodo])
                params[:Turmas].each do |group_name|
                  group = get_offer_group(offer, group_name)
                  group_events << create_event1(get_offer_group(offer, group_name), params[:DataInserida])
                end
              end

              group_events
            end

          end # /

          desc "Remoção de um ou mais eventos"
          params { requires :ids, type: String, desc: "Events IDs." }
          delete "/:ids" do
            begin
              ScheduleEvent.transaction do
                ScheduleEvent.where(id: params[:ids].split(",")).each do |event|
                  event.api = true
                  raise event.errors.full_messages unless event.destroy
                end
              end

              {ok: :ok}
            end
          end # delete :id

        end # events

      end # integration

  end
end