class Lesson < ApplicationRecord

  validates_presence_of :title, :description, :number_of_credit
  validates :title, uniqueness: { case_sensitive: false }, length: { minimum: 10 }
  validates :description, length: { in: 20...5000 }
  validates :number_of_credit, numericality: { greater_than_or_equal_to: 1 }
  after_create :add_teacher_role, if: :not_teacher?

  belongs_to :user
  has_one_attached :picture

  private

  def not_teacher?
    user.teacher? ? false : true
  end

  def add_teacher_role
    user.assign_teacher_role
  end
end
