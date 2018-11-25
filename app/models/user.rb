class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  has_many :emails, dependent: :destroy

  belongs_to :default_email, class_name: Email.name
  validates :default_email, presence: true
  default_scope { includes :default_email }

  after_commit :save_default_email, on: :create

  accepts_nested_attributes_for :emails, reject_if: :all_blank, allow_destroy: true

  def email
    default_email.email rescue nil
  end

  def email= email
    self.default_email = Email.where(email: email).first_or_initialize
    errors.add(:base, :taken) if default_email.persisted? && default_email.user != self
  end

  def self.having_email email
    User.joins(:emails).where(emails: { email: email }).first
  end

  def self.find_first_by_auth_conditions warden_conditions
    conditions = warden_conditions.dup
    if email = conditions.delete(:email)
      having_email email
    else
      super(warden_conditions)
    end
  end

  def self.from_omniauth auth
    email = Email
      .includes(:user)
      .where(email: auth.info.email)
      .first_or_initialize

    ui = UserIdentity
      .where(provider: auth.provider, uid: auth.uid)
      .first_or_initialize

    if ui.persisted?
      # Existing user, Existing social identity
      if ! email.persisted?
        # Email changed on third party site
        email.user = ui.user
        email.save!
        ui.email = email
      elsif email.user == ui.user
        ui.user
      else
        raise ActiveRecord::RecordNotUnique
      end
    elsif email.persisted?
      # Existing User, new identity
      ui.user = email.user
      ui.email = email
      ui.save!
      ui.user
    else
      # New user new identity
      email.save!
      user = User.new(
        password: Devise.friendly_token[0,20],
        default_email: email
      )
      user.save!
      ui.user = user
      ui.email = email
      ui.save!
    end

    ui.user
  end

  def will_save_change_to_email?
    false
  end

  private

  def save_default_email
    if default_email.user.blank?
      default_email.user = self
    end
    default_email.save!
  end
end
