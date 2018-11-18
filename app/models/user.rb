class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :emails, dependent: :destroy

  belongs_to :default_email, class_name: Email.name
  validates :default_email, presence: true
  default_scope { includes :default_email }

  after_commit :save_default_email, on: :create

  def email
    default_email.email rescue nil
  end

  def email= email
    self.default_email = Email.where(email: email).first_or_initialize
  end

  def self.having_email email
    User
      .joins(:emails)
      .where(emails: {email: email})
      .first
  end

  def self.find_first_by_auth_conditions warden_conditions
    conditions = warden_conditions.dup
    if email = conditions.delete(:email)
      having_email email
    else
      super(warden_conditions)
    end
  end

  def will_save_change_to_email?
    false
  end

  private

  def save_default_email
    if default_email.user.blank?
      default_email.user = self
    elsif default_email.user != self
      raise ActiveRecord::Rollback
    end
    default_email.save!
  end
end
