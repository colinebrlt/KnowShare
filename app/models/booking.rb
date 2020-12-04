class Booking < ApplicationRecord
  validates :start_date, presence: true,
                         if: :start_in_future

  validates :duration, presence: true,
                       numericality: { only_integer: true, greater_than: 0 },
                       if: :multiple_of_thirty?

  belongs_to :user
  belongs_to :lesson

  validate :student_enough_credit?, :prevent_teacher_booking
  after_create :payment_from_student, :payment_to_teacher, :send_email_new_booking_user, :send_email_new_booking_teacher
  
  before_destroy :destroy_booking

  # Easier to read and use
  def student
    user
  end

  def teacher
    lesson.user
  end

  # The number of credit to be transferred
  def price
    duration / 30
  end

  def lesson_title
    followed_lesson.title
  end

  def display_start_date
    start_date.strftime('%Y/%m/%d à %H:%M')
    
  end

  def student_is_teacher?
    user == teacher
  end

  def prevent_teacher_booking
    errors.add(:base, :student_is_teacher, message: 'Vous ne pouvez pas réserver une séance avec vous-même !') if student_is_teacher?
  end

  def student_enough_credit?
    errors.add(:base, :student_personal_credit, message: 'Vous ne possédez pas suffisamment de crédit(s) !') unless user.personal_credit >= price
  end

  def not_begun?
    errors.add(:start_date, ": Impossible d'annuler un cours qui a déjà commencé.") unless start_date > DateTime.now
  end

  def destroy_booking
    if start_date > DateTime.now
      action_destroy_booking
    else
      errors.add(:start_date, ": Impossible d'annuler un cours qui a déjà commencé.")
      # Cancels the destroy action
      :abort
    end

  end

  def refund
    refund_from_teacher
    refund_to_student
    
  end

  def action_destroy_booking
    refund
    after_destroy_booking_email
  end

  def display_start_date_time
    start_date.strftime("%d/%m/%Y à %I:%M%p")
  end 

  private

  def start_in_future
    errors.add(:start_date, ": Impossible de réserver une leçon dans le passé") unless start_date > DateTime.now
  end

  def multiple_of_thirty?
    errors.add(:duration, ": Les cours se font par tranche de 30min") unless (duration % 30).zero?
  end

  def payment_from_student
    student.remove_credit(price)
  end

  # Will change after finding out how to launch method at a certain date
  def payment_to_teacher
    teacher.add_credit(price)
  end

  # Will disappear after finding out how to launch method at a certain date : the credit won't be given until the lesson start
  def refund_from_teacher
    teacher.remove_credit(price)
  end

  def refund_to_student
    student.add_credit(price)
  end

  # -------- Email section -------- #

  def send_email_new_booking_user
    BookingMailer.send_email_confirm_to_user(self.student, self.teacher, self.display_start_date, self.lesson_title).deliver_now
  end

  def send_email_new_booking_teacher
    BookingMailer.send_email_confirm_to_teacher(self.student, self.teacher, self.display_start_date, self.lesson_title).deliver_now
  end

  def after_destroy_booking_email
    BookingMailer.after_destroy_booking_email(self.teacher, self.display_start_date, self.lesson_title).deliver_now
    BookingMailer.after_destroy_booking_email(self.student, self.display_start_date, self.lesson_title).deliver_now # Not DRY, but it works
  end

end
