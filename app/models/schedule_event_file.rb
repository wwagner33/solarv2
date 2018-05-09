class ScheduleEventFile < ActiveRecord::Base

  # include ControlledDependency
  # include SentActivity
  include AcademicTool
  include FilesHelper

  belongs_to :user
  belongs_to :academic_allocation_user, counter_cache: true

  before_destroy :can_destroy?
  before_save :replace_attachment_file_name

  validates :attachment, presence: true
  validates :academic_allocation_user_id, presence: true

  has_attached_file :attachment,
    path: ":rails_root/media/schedule_event/schedule_event_files/:id_:normalized_attachment_file_name",
    url: "/media/schedule_event/schedule_event_files/:id_:normalized_attachment_file_name"

  validates_attachment_size :attachment, less_than: 26.megabyte, message: I18n.t('schedule_event_files.error.attachment_file_size_too_big')
  validates_attachment_content_type :attachment, content_type: /(^image\/(jpeg|jpg|gif|png)$)|\Aapplication\/pdf/, message: I18n.t('schedule_event_files.error.wrong_type')

  Paperclip.interpolates :normalized_attachment_file_name do |attachment, style|
    attachment.instance.normalized_attachment_file_name
  end

  def normalized_attachment_file_name
    "#{self.academic_allocation_user.user.cpf}-#{self.attachment_file_name.gsub( /[^a-zA-Z0-9_\.]/, '_')}"
  end

  def can_destroy?
    raise 'remove' unless academic_allocation_user.grade.nil? && academic_allocation_user.working_hours.nil? && academic_allocation_user.comments_count == 0
  end

  def delete_with_dependents
    self.delete
  end

  private

    def replace_attachment_file_name
      self.attachment_file_name = normalized_attachment_file_name
    end
end
