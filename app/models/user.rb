class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :username,  presence: true,
                        uniqueness: true

  has_many  :lessons, dependent: :destroy
  has_many  :bookings, dependent: :destroy
  has_many  :followed_lessons,
            through: :bookings,
            foreign_key: 'followed_lesson_id',
            class_name: 'Lesson',
            dependent: :destroy

  has_one_attached :avatar

  def role_include?(searched_role)
    role.split.include?(searched_role)
  end

  def teacher?
    role_include?('teacher')
  end

  def assign_teacher_role
    new_role = 'teacher'
    update(role: new_role)
  end

  def first_name?
    first_name
  end

  def last_name?
    last_name
  end

  def display_name
    if first_name?
      if last_name?
        "#{first_name} #{last_name}"
      else
        first_name
      end
    else
      username
    end
  end

  def display_avatar
    if avatar.attached?
      avatar
    else
      # url to picture of cute cat
      "https://static.toiimg.com/photo/msid-67586673/67586673.jpg?3918697"
    end
  end

  def has_description?
    description
  end

  def add_credit(number_of_credit)
    new_personal_credit = personal_credit + number_of_credit
    update(personal_credit: new_personal_credit)
  end

  def remove_credit(number_of_credit)
    new_personal_credit = personal_credit - number_of_credit
    update(personal_credit: new_personal_credit)
  end

  def past_bookings
    bookings.select { |booking| booking.start_date < DateTime.now }
  end

  def future_bookings
    bookings.select { |booking| booking.start_date > DateTime.now }
  end

  def past_lessons
    past_lessons = []
    past_bookings.each { |booking| past_lessons << booking.followed_lesson }
    past_lessons
  end

  def future_lessons
    future_lessons = []
    future_bookings.each { |booking| future_lessons << booking.followed_lesson }
    future_lessons
  end
end
