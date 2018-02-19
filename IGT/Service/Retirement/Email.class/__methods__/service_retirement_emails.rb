#
# Description: This method sends out retirement emails when the following events are raised:
# Events: service_retire_warn and request_service_retire
# Model Notes:
# 1. to_email_address - used to specify an email address in the case where the
#    vm's owner does not have an  email address. To specify more than one email
#    address separate email address with commas. (I.e. admin@example.com,user@example.com)
# 2. from_email_address - used to specify an email address in the event the
#    requester replies to the email
# 3. signature - used to stamp the email with a custom signature
#

$evm.log(:info, "retirement_logs")
$evm.root.attributes.sort.each {|k,v| $evm.log(:info, "root attribute - #{k}: #{v}")}

service = $evm.root['service']
$evm.log(:info, "service: #{service.inspect}")

#We only want to send emails for bundles and individual services
#If the service has a parent, this servic is the child service of a bundle
#and we don't want to send an email for it.
if service.has_parent
  exit MIQ_OK
end
  

send_email = false

#Set the ip of the ui appliance
ui_vip = $evm.object['ip_address']

#Grab the email addresses from the dialog
pgm = service.get_dialog_option("dialog_pgm")
pm = service.get_dialog_option("dialog_pm")
ie = service.get_dialog_option("dialog_ie")
spm = service.get_dialog_option("dialog_spm")
ipm = service.get_dialog_option("dialog_ipm")
reporting_lead = service.get_dialog_option("dialog_reporting_lead")
sse = service.get_dialog_option("dialog_sse")
se = service.get_dialog_option("dialog_se")

# Get Owner Email
service_vms = service.vms
owner_email = service.evm_owner_email

#compile the email addresses into a single list
email_addresses = []
email_addresses.push(pgm) unless pgm.nil?
email_addresses.push(pm) unless pm.nil?
email_addresses.push(ie) unless ie.nil?
email_addresses.push(spm) unless spm.nil?
email_addresses.push(ipm) unless ipm.nil?
email_addresses.push(reporting_lead) unless reporting_lead.nil?
email_addresses.push(sse) unless sse.nil?
email_addresses.push(se) unless se.nil?
email_addresses.push(owner_email) unless owner_email.nil?

$evm.log(:info, "email_addresses: #{email_addresses.join(",")}")

to = email_addresses.uniq.join(",")

#Get Service Name
service_name = service['name']

# Look at the Event Type in the Current Object or in the Root Object
event_type = $evm.object['event'] || $evm.root['event_type']

######################################
#
# Service Retirement Warning Email
#
######################################
if event_type == "service_retire_warn"

  #warnings at 30 days, 2 weeks, 1 week
  $evm.log(:info, "retirement_warn: #{service.retirement_warn}")
  if service.retirement_warn == 30.days.to_i && service.retires_on <= (DateTime.now + 30.days)
    $evm.log(:info, "setting retirement_warn to 14 days")
    service.retirement_warn = 14.days.to_i
    send_email = true
  elsif service.retirement_warn == 14.days.to_i && service.retires_on <= (DateTime.now + 14.days)
    $evm.log(:info, "setting retirement_warn to 7 days")
  	service.retirement_warn = 7.days.to_i
    send_email = true
  elsif service.retirement_warn == 7.days.to_i && service.retires_on <= (DateTime.now + 7.days)
    service.retirement_warn = nil
    send_email = true
  end
  
  # Get from_email_address from model unless specified below
  from = nil
  from ||= $evm.object['from_email_address']

  # Get signature from model unless specified below
  signature = nil
  signature ||= $evm.object['signature']

  # email subject
  subject = "Service Retirement Warning for #{service_name}"

  # Build email body
  body = "Hello, "
  body += "<br><br>Your service: [#{service_name}] will be retired on [#{service['retires_on']}]."
  body += "<br><br>If you need to use this service past this date please request"
  body += "<br><br>an extension by contacting Support."
  body += "<br><br> Thank you,"
  body += "<br> #{signature}"
end

######################################
#
# Service Retirement Exended Email
#
######################################
if event_type == "service_retire_extend"

  send_email = true
  # Get from_email_address from model unless specified below
  from = nil
  from ||= $evm.object['from_email_address']

  # Get signature from model unless specified below
  signature = nil
  signature ||= $evm.object['signature']

  # email subject
  subject = "Service Retirement Extended for #{vm_name}"

  # Build email body
  body = "Hello, "
  body += "<br><br>Your virtual machine: [#{service_name}] will now be retired on [#{service['retires_on']}]."
  body += "<br><br>If you need to use this virtual machine past this date please request"
  body += "<br><br>an extension by contacting Support."
  body += "<br><br> Thank you,"
  body += "<br> #{signature}"
end

######################################
#
#  Service Retirement Email
#
######################################
if event_type == "request_service_retire"

  send_email = true
  
  # Get from_email_address from model unless specified below
  from = nil
  from ||= $evm.object['from_email_address']

  # Get signature from model unless specified below
  signature = nil
  signature ||= $evm.object['signature']

  # email subject
  subject = "Service Retirement Alert for #{service_name}"

  # Build email body
  body = "Hello, "
  body += "<br><br>Your service named [#{service_name}] has been retired."
  body += "<br><br> Thank you,"
  body += "<br> #{signature}"
end

if send_email == true
  $evm.log("info", "Sending email to <#{to}> from <#{from}> subject: <#{subject}>")
  $evm.execute('send_email', to, from, subject, body)
end
