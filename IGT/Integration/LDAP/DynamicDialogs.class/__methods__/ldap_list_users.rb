begin  
  def dump_root()
    $evm.log(:info, "Root:<$evm.root> Begin $evm.root.attributes")
    $evm.root.attributes.sort.each { |k, v| $evm.log(:info, "Root:<$evm.root> Attribute - #{k}: #{v}")}
    $evm.log(:info, "Root:<$evm.root> End $evm.root.attributes")
    $evm.log(:info, "")
  end
  
  #creates a filter that is the intersection of all of these emails
  #def create_email_filter(ldap_email)
  #  return_filter = nil
  #  email_filter = nil
  #  
  #  ldap_email.each do |email|
  #    email_filter = Net::LDAP::Filter.eq("mail", email)
  #    if return_filter.nil?
  #    	return_filter = email_filter
  #    else
  #      return_filter = Net::LDAP::Filter.join(return_filter, email_filter)
  #    end
  #  end
  #  return return_filter
  #end

  def call_ldap
    require 'rubygems'
    require 'net/ldap'
    
    # get parameters
    servername = nil || $evm.object['servername']
    $evm.log(:info, "servername: #{servername}")
    username = nil || $evm.object['username']
    $evm.log(:info, "username: #{username}")
    password = nil || $evm.object.decrypt('password')
    basedn = nil || $evm.object['basedn']
    $evm.log(:info, "basedn: #{basedn}")
    port = nil || $evm.object['port']
    $evm.log(:info, "port: #{port}")
    ldap_email = nil || $evm.object['ldap_email']
    $evm.log(:info, "ldap_email: #{ldap_email.inspect}")
    
    dialog_options = {}
    dialog_options[nil] = "Please select a user"
    
    # setup authentication to LDAP
    ldap = Net::LDAP.new :basedn => basedn, :host => servername, :port => port,
    :auth => {
      :method => :simple,
      :username => username,
      :password => password
    }
    $evm.log(:info, "ldap: #{ldap.inspect}")
    if ldap.bind
      $evm.log(:info, "Bind successful")
    else
      $evm.log(:info, "Bind unsuccessful")
    end
        
    # Search LDAP for computername
    $evm.log(:info, "Searching LDAP server: #{servername} basedn: #{basedn}")
    
    #filter ensures that the object is a user and that they are active
    result_attrs = ["sAMAccountName", "displayName", "member"]
	group_filter = Net::LDAP::Filter.eq("objectClass", "group")
	#user_result_attrs = ["sAMAccountName", "displayName"]
    user_result_attrs = ["mail", "displayName"]
  
    #go through each distribution list and add the members to the dialog_options
    ldap_email.each do |mail|
      email_filter = Net::LDAP::Filter.eq("mail", mail)
      composite_filter = Net::LDAP::Filter.join(email_filter, group_filter)
      #Find the distribution list in LDAP
      ldap.search(:base => basedn, :filter => composite_filter, :attributes => result_attrs) do |item|
          $evm.log(:info, "#{item.sAMAccountName.first}: #{item.displayName.first}")
          #Go through each member of the distribution list
          item.member.map do |m| 
            $evm.log(:info, "inspecting m: #{m}")
            user_search_filter = Net::LDAP::Filter.eq("DistinguishedName", m)
            #Look up each member in LDAP by their DN
            ldap.search(:base => basedn, :filter => user_search_filter, :attributes => user_result_attrs) do |user|
              $evm.log(:info, "user: #{user.inspect}")
              #sam_account_name = user.try(:samaccountname)
              user_email = user.try(:mail)
              display_name = user.try(:displayname)
              #unless display_name.nil? || sam_account_name.nil?
              unless display_name.nil? || user_email.nil?
                  #dialog_options[sam_account_name.first] = display_name.first
                  dialog_options[user_email.first] = display_name.first
              end
            end
          end
      end
    end
    $evm.log(:info, "result code: #{ldap.get_operation_result.code}, result message: #{ldap.get_operation_result.message}")
    $evm.log(:info, "dialog_options: #{dialog_options.inspect}")
    return dialog_options
  end
  
  ################
  # Start Method #
  ################

  $evm.log(:info, "CFME Automate Method Started")

  # dump all root attributes to the log
  dump_root()

  dialog_options = {}
  
  dialog_options = call_ldap
  
  $evm.object['values'] = dialog_options
  # Exit method
  $evm.log(:info, "CFME Automate Method Ended")
  exit MIQ_OK
  
  # Ruby rescue
rescue => err
  $evm.log(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_ABORT
end
