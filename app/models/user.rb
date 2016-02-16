class User < ActiveRecord::Base
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable #, :async

  validate :email_is_unique, on: :create
  validate :subdomain_is_unique, on: :create
  after_validation :create_tenant
  after_create :create_account
  after_create :add_role_to_user
  # def confirmation_required?
  #   false
  # end


  private
  #Email should be unique in Account model
  def email_is_unique
    #Do not validate email if errors are already present.
    return false unless self.errors[:email].empty?

    unless Account.find_by_email(email).nil?
        errors.add(:email, " is already used")
    end
  end

  def subdomain_is_unique
    if subdomain.present?
      unless Account.find_by_subdomain(subdomain).nil?
          errors.add(:subdomain, " is already used")
      end
    end
    if Apartment::Elevators::Subdomain.excluded_subdomains.include?(subdomain)
      errors.add(:subdomain, "is not a valid subdomain")
    end
  end

  def create_account
    account = Account.new(:email => email, :subdomain => subdomain)
    account.save!
  end

# As soon as we create tenant, we need to swtich tenant.
# We validate submain is unique.
# User model get saved in tenant
# Account model will be saved in public tenant
def create_tenant
   return false unless self.errors.empty?
   #If its a new record, create the tenant
   #For Edits, do not create
   if self.new_record?
     Apartment::Tenant.create(subdomain)
   end
   #Change schema to the tenant
   Apartment::Tenant.switch!(subdomain)
 end

# Add default role to admin
  def add_role_to_user
    if created_by_invite?
      add_role :app_user
    else
      add_role :app_admin
    end
  end

end
