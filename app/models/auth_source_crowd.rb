class AuthSourceCrowd < AuthSource
  unloadable 
  validates_presence_of :host, :port
  validates_length_of :name, :account_password, :maximum => 60, :allow_nil => true
  validates_length_of :account, :base_dn, :maximum => 255, :allow_nil => true
  validates_length_of :attr_login, :attr_firstname, :attr_lastname, :attr_mail, :maximum => 30, :allow_nil => true
  validates_numericality_of :port, :only_integer => true
  
  attr_accessor :app_token
  
  #before_validation :strip_ldap_attributes
  
  def after_initialize
    self.port = 80 if self.port == 0
  end
  
  def get_user_attrs(username)
    self.test_connection unless app_token
    return load_attrs(Crowd.find_principal_by_username(username))
  end
  
  def authenticate(login, password)
    self.test_connection unless app_token
    crowd_user = Crowd.find_principal_by_username(login)
    attrs={}
    if crowd_user
      begin
        usertoken = Crowd.authenticate_principal(login, password)
      rescue Crowd::AuthenticationObjectNotFoundException => e
        return false
      end
      if usertoken
        attrs = load_attrs(crowd_user) if onthefly_register?
      else
        raise "ERROR Authenticating"
      end
    else
      raise "USER NOT FOUND"
    end
    return attrs
  end
#  def authenticate(login, password)
#    return nil if login.blank? || password.blank?
#    attrs = get_user_dn(login)
#    
#    if attrs && attrs[:dn] && authenticate_dn(attrs[:dn], password)
#      logger.debug "Authentication successful for '#{login}'" if logger && logger.debug?
#      return attrs.except(:dn)
#    end
#  rescue  Net::LDAP::LdapError => text
#    raise "LdapError: " + text
#  end
#
  def check_values
    Crowd.crowd_url = "http://#{self.host}#{self.port.to_s != "80" ? ":#{self.port}": ""}/crowd/services/SecurityServer"
    Crowd.crowd_app_name = self.account
    Crowd.crowd_app_pword = self.account_password
  end

  # test the connection to Crowd
  def test_connection
    check_values
    self.app_token = Crowd.authenticate_application
  rescue  Crowd::AuthenticationException
    raise "Crowd Authentication Failed"
  end
 
  def auth_method_name
    "Crowd"
  end
#  
  private
  
  def load_attrs(crowd_user)
        {
         :firstname => crowd_user[:attributes][:givenName],
         :lastname => crowd_user[:attributes][:sn],
           :mail => crowd_user[:attributes][:mail],
         :auth_source_id => self.id
        }
  end
#  
#  def strip_ldap_attributes
#    [:attr_login, :attr_firstname, :attr_lastname, :attr_mail].each do |attr|
#      write_attribute(attr, read_attribute(attr).strip) unless read_attribute(attr).nil?
#    end
#  end
#  
#  def get_user_attributes_from_ldap_entry(entry)
#    {
#     :dn => entry.dn,
#     :firstname => AuthSourceLdap.get_attr(entry, self.attr_firstname),
#     :lastname => AuthSourceLdap.get_attr(entry, self.attr_lastname),
#     :mail => AuthSourceLdap.get_attr(entry, self.attr_mail),
#     :auth_source_id => self.id
#    }
#  end
#
#  # Return the attributes needed for the LDAP search.  It will only
#  # include the user attributes if on-the-fly registration is enabled
#  def search_attributes
#    if onthefly_register?
#      ['dn', self.attr_firstname, self.attr_lastname, self.attr_mail]
#    else
#      ['dn']
#    end
#  end
#
#  # Check if a DN (user record) authenticates with the password
#  def authenticate_dn(dn, password)
#    if dn.present? && password.present?
#      initialize_ldap_con(dn, password).bind
#    end
#  end
#
#  # Get the user's dn and any attributes for them, given their login
#  def get_user_dn(login)
#    ldap_con = initialize_ldap_con(self.account, self.account_password)
#    login_filter = Net::LDAP::Filter.eq( self.attr_login, login ) 
#    object_filter = Net::LDAP::Filter.eq( "objectClass", "*" ) 
#    attrs = {}
#    
#    ldap_con.search( :base => self.base_dn, 
#                     :filter => object_filter & login_filter, 
#                     :attributes=> search_attributes) do |entry|
#
#      if onthefly_register?
#        attrs = get_user_attributes_from_ldap_entry(entry)
#      else
#        attrs = {:dn => entry.dn}
#      end
#
#      logger.debug "DN found for #{login}: #{attrs[:dn]}" if logger && logger.debug?
#    end
#
#    attrs
#  end
#  
#  def self.get_attr(entry, attr_name)
#    if !attr_name.blank?
#      entry[attr_name].is_a?(Array) ? entry[attr_name].first : entry[attr_name]
#    end
#  end
end
