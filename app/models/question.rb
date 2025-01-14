class Question < ActiveRecord::Base

  include FilesHelper

  UNIQUE, MULTIPLE, TRUE_FALSE = 0, 1, 2

  belongs_to  :user
  belongs_to :updated_by_user, class_name: 'User'
  belongs_to :question_text

  has_many :exam_questions
  has_many :exam_responses
  has_many :exams, through: :exam_questions
  has_many :question_images, class_name: 'QuestionImage', dependent: :destroy
  has_many :question_items , class_name: 'QuestionItem' , dependent: :destroy
  has_many :question_audios, class_name: 'QuestionAudio', dependent: :destroy


  has_and_belongs_to_many :question_labels

  accepts_nested_attributes_for :question_images, allow_destroy: true, reject_if: :reject_images
  accepts_nested_attributes_for :question_labels, allow_destroy: true, reject_if: :reject_labels
  accepts_nested_attributes_for :question_items, allow_destroy: true, reject_if: :reject_items
  accepts_nested_attributes_for :question_audios, allow_destroy: true, reject_if: :reject_audios

  validates :enunciation, :type_question, presence: true

  validate :enunciation_presence

  validate :verify_labels, :verify_files

  validate :verify_privacy, if: 'privacy_changed? && privacy && !new_record?'

  before_destroy :can_destroy?
  before_destroy { question_labels.clear }

  before_save :get_labels

  def enunciation_presence
    errors.add :enunciation, :blank  if enunciation.blank? || enunciation == '<br>' || enunciation == '<p><br></p>'
  end

  def reject_images(img)
    (img[:image].blank? && (new_record? || img[:id].blank?))
  end

  def reject_audios(aud)
    (aud[:audio].blank? && (new_record? || aud[:id].blank?))
  end

  def reject_labels(label)
    (label[:name].blank? && (new_record? || label[:id].blank?))
  end

  def reject_items(item)
    ((item[:description].blank? || item[:description] == '<br>' || item[:description] == '<p><br></p>') && (new_record? || item[:id].blank?))
  end

  def get_labels
    self.question_labels = self.question_labels.collect do |label|
      QuestionLabel.find_or_create_by(name: label.name)
    end
  end

  def verify_privacy
    can_destroy?
  rescue => error
    errors.add(:privacy, I18n.t("questions.error.privacy_#{error}"))
  end

  def copy_dependencies_from(question_to_copy, user_id = nil)
    if question_to_copy.question_images.any?
      question_to_copy.question_images.each do |file|
        dup_file(file, :question_image)
        # new_file = QuestionImage.create! file.attributes.merge({ question_id: id })
        # copy_file(file, new_file, File.join('questions', 'images'), 'image')
      end
    end
    if question_to_copy.question_items.any?
      question_to_copy.question_items.each do |item|
        dup_file(item, :question_item)
        # new_item = QuestionItem.create! item.attributes.merge({ question_id: id })
        # copy_file(item, new_item, File.join('questions', 'items'), 'item_image') unless new_item.item_image_file_name.nil?
      end
    end
    if question_to_copy.question_labels.any?
      question_to_copy.question_labels.each do |label|
        question_labels << label
      end
    end
    if question_to_copy.question_audios.any?
      question_to_copy.question_audios.each do |file|
        dup_file(file, :question_audio)
        # new_file = QuestionAudio.create! file.attributes.merge({ question_id: id })
        # copy_file(file, new_file, File.join('questions', 'audios'), 'audio')
      end
    end
  end

  def dup_file(file, type)
    new_file = file.dup
    new_file.question_id = id
    case type
    when :question_image
      new_file.image = file.image
    when :question_item
      new_file.item_image = file.item_image
      new_file.item_audio = file.item_audio
    else
      new_file.audio = file.audio
    end
    new_file.save
  end

  def self.copy(question_to_copy, user_id = nil)
    attributes = (user_id != question_to_copy.user_id ? { updated_by_user_id: user_id } : {})
    question   = Question.create question_to_copy.attributes.except('id', 'updated_by_user_id').merge(attributes)
    question.copy_dependencies_from(question_to_copy, user_id)
    question
  end

  def type
    case type_question
    when UNIQUE     then I18n.t('questions.types.unique_choice')
    when MULTIPLE   then I18n.t('questions.types.multiple_choice')
    when TRUE_FALSE then I18n.t('questions.types.true_or_false')
    else
     ''
    end
  end

  def self.get_all(user_id, search={}, verify_privacy=false)
    query = []

    query << ((search[:only_owner] == 'false' || search[:only_owner].blank?) ? "
              (authors.id = #{user_id} OR updated_by.id = #{user_id}
              OR ((
               ((SELECT count FROM user_public_questions) = 0 AND (SELECT count FROM user_private_questions) = 0)
               OR ((SELECT count FROM user_public_questions) >= (SELECT count FROM user_private_questions)/10)
              ) AND questions.status = 't' AND privacy = 'f'))" : "authors.id = #{user_id} OR updated_by.id = #{user_id}")

    query << "lower(unaccent(questions.enunciation)) ~ lower(unaccent('#{search[:enun].to_s}'))" unless search[:enun].blank?
    query << "lower(unaccent(l1.name)) ~ lower(unaccent('#{search[:label].to_s}'))"              unless search[:label].blank?
    query << "date_part('year', questions.updated_at) = '#{search[:year].to_s}'"                 unless search[:year].blank?

    author_query = []
    author_query << "lower(unaccent(authors.name)) ~ lower(unaccent('#{search[:author].to_s}'))"        unless search[:author].blank?
    author_query << "lower(unaccent(updated_by.name)) ~ lower(unaccent('#{search[:author].to_s}'))" unless search[:author].blank?
    author_query = '(' + author_query.join(' OR ') + ')' unless author_query.empty?

    query << author_query

    query = query.reject(&:empty?)

    query = query.empty? ? '' : ['WHERE', query.join(' AND ')].join(' ')

    Question.find_by_sql <<-SQL
      WITH user_private_questions AS (
        SELECT COUNT(questions.id) AS count FROM questions
        WHERE  questions.privacy = 't' AND questions.status = 't' AND questions.user_id = #{user_id}
      ),   user_public_questions AS (
        SELECT COUNT(questions.id) AS count FROM questions
        WHERE  questions.privacy = 'f' AND questions.status = 't' AND questions.user_id = #{user_id}
      )
      SELECT  DISTINCT questions.id,
              questions.enunciation,
              questions.type_question,
              questions.status,
              questions.updated_at,
              questions.privacy,
              authors.name                                        AS author_name,
              updated_by.name                                     AS updated_by_name,
              COALESCE(COUNT(DISTINCT exam_questions.exam_id), 0) AS count_exams,
              (
                SELECT COUNT(question_items.id)
                FROM question_items
                WHERE question_items.question_id = questions.id
              )                                    AS count_items,
              EXISTS(
                SELECT question_images.id
                FROM question_images
                WHERE questions.id = question_images.question_id
              )                                    AS has_images,
              EXISTS(
                SELECT question_audios.id
                FROM question_audios
                WHERE questions.id = question_audios.question_id
              )                                    AS has_audios,
              replace(replace(translate(array_agg(distinct l2.name)::text,'{}', ''),'\"', ''),',',', ') AS labels
              FROM questions
              LEFT JOIN users AS authors    ON questions.user_id = authors.id
              LEFT JOIN users AS updated_by ON questions.updated_by_user_id   = updated_by.id
              LEFT JOIN exam_questions      ON exam_questions.question_id     = questions.id
              LEFT JOIN question_labels_questions AS qlq1 ON qlq1.question_id = questions.id
              LEFT JOIN question_labels_questions AS qlq2 ON qlq2.question_id = questions.id
              LEFT JOIN question_labels           AS l1  ON l1.id = qlq1.question_label_id
              LEFT JOIN question_labels           AS l2  ON l2.id = qlq2.question_label_id
              #{query}
              GROUP BY questions.id, questions.enunciation, questions.type_question, questions.status, questions.updated_at, questions.privacy, authors.name, updated_by.name
              ORDER BY questions.updated_at DESC;

    SQL
  end

  def verify_labels
    errors.add(:question, I18n.t('questions.error.max_labels')) if question_labels.size > 8
  end

  def verify_files
    total = question_images.size + question_audios.size
    errors.add(:question, I18n.t('questions.error.max_files')) if total  > 4
  end

  def can_destroy?
    raise 'permission' unless owner?
    raise 'in_use'     if exams.any?
  end

  def can_change_status?
    raise 'permission' unless owner?
    raise 'in_use'     if exams.any? && status # if in use and already published
    validate_items
  end

  def validate_items
    if !status
      raise 'min_items'     if question_items.size < 3
      raise 'correct_item'  if type_question != Question::TRUE_FALSE && question_items.where(value: true).empty?
      raise 'only_one_true' if type_question == 0 && question_items.where(value: true).size > 1
    end
  end

  def can_see?(boolean=false)
    # result = !privacy || owners?
    # raise 'permission' unless boolean || result
    # result
    true
  end

  def have_access?
    return false if User.current.try(:id).blank?
    ats = exams.map(&:allocation_tags).flatten.map(&:id).compact.uniq
    return User.current.profiles_with_access_on('show', 'questions', ats, true, false, true).any?
   end


  def can_change?
    raise 'permission' unless owner?
    raise 'in_use'     if exams.any? && status # if in use and already published
  end

  def owner?(s = false)
    if s
      (self.updated_by_user_id.nil? ? self.user_id == User.current.id : self.updated_by_user_id == User.current.id)
    else
      (updated_by_user_id.nil? ? user_id == User.current.id : updated_by_user_id == User.current.id)
    end
  end

  def owners?(s = false)
    if s
      (self.user_id == User.current.id || self.updated_by_user_id == User.current.id)
    else
      (user_id == User.current.id || updated_by_user_id == User.current.id)
    end
  end

  def in_use?
    exams.any?
  end

  def validate_images
    total = question_images.size + question_audios.size
    errors.add(:question, I18n.t('questions.error.max_files')) if question_images.any? && total > 4
  end

  def can_import_or_export?(current_user, exam = nil)
    raise 'private' unless !privacy || owners?(true)
    user_questions    = current_user.questions
    user_up_questions = current_user.up_questions
    raise 'min_public_questions' if !owners?(true) && !user_questions.empty? && ((user_questions.where(privacy: true).count/user_questions.where(privacy: false).count > 10 rescue false) || (user_up_questions.where(privacy: true).count/user_up_questions.where(privacy: false).count > 10 rescue false))
    raise 'draft' if !privacy && !owner?(true) && !status
    raise 'already_exists' if !exam.nil? && exam.questions.where(id: id).any?
    raise 'published' if !exam.nil? && exam.status
  end

  def can_copy?
    owners = owners?
    raise 'private' unless (!privacy) || owners
    raise 'draft' if (!privacy && !status) && !owners
  end

  def log_description
    desc = {}

    desc.merge!(attributes.except('attachment_updated_at', 'updated_at', 'created_at', 'id'))
    desc.merge!(images: question_images.collect{|img| img.attributes.except('image_updated_at' 'question_id')})
    desc.merge!(items: question_items.collect{|item| item.attributes.except('question_id', 'item_image_updated_at')})
    desc.merge!(labels: question_labels.collect{|item| item.attributes.except('created_at', 'updated_at')})
    desc.merge!(audios: question_audios.collect{|audio| audio.attributes.except('audio_updated_at' 'question_id')})
  end

  def have_media?
    if new_record?
      return false
    else
      return !self.question_text_id.blank? || question_audios.exists? || question_images.exists? ? true : false
    end
  end

  def disabled_option(exam_id)
    return self.get_questions_text(exam_id).count == 0 ? true : false
  end

  def checked_option(exam_id)
    if new_record?
      return true
    elsif self.question_text_id.blank?
      return true
    else
      return Question.joins(:exam_questions).where("question_text_id = ? AND questions.id <> ?", self.question_text_id, self.id).where({:'exam_questions.exam_id' => exam_id}).count == 0 ? true : false
    end
  end

  def questions_text(exam_id)
    if new_record?
      return Question.joins(:exam_questions).where("question_text_id IS NOT NULL").where({:'exam_questions.exam_id' => exam_id})
    else
      return Question.joins(:exam_questions).where("question_text_id IS NOT NULL").where({:'exam_questions.exam_id' => exam_id})
    end
  end

  def get_questions_text(exam_id)
    if new_record?
      return Question.joins(:exam_questions).where("question_text_id IS NOT NULL").where({:'exam_questions.exam_id' => exam_id})
    else
      return Question.joins(:exam_questions).where("question_text_id IS NOT NULL AND questions.id <> ?", self.id).where({:'exam_questions.exam_id' => exam_id})
    end
  end

end
