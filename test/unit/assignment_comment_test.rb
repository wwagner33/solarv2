require 'test_helper'

class  AssignmentCommentTest < ActiveSupport::TestCase

  fixtures :assignment_comments, :send_assignments

  test "novo comentario deve ter conteudo" do
    comment = AssignmentComment.create(:send_assignment_id => send_assignments(:sa1).id, :user_id => send_assignments(:sa1).user_id)

    assert (not comment.valid?)
    assert_equal comment.errors[:comment].first, I18n.t(:blank, :scope => [:activerecord, :errors, :messages])
  end

  test "novo comentario valido" do
    comment = AssignmentComment.create(:send_assignment_id => send_assignments(:sa1).id, :user_id => send_assignments(:sa1).user_id, :comment => "comentario 1")
    assert comment.valid?
  end  

end
