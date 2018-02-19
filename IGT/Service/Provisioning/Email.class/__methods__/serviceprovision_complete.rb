#
# Description: This method sends an e-mail when the following event is raised:
# Events: vm_provisioned
#
# Model Notes:
# 1. to_email_address - used to specify an email address in the case where the
#    vm's owner does not have an  email address. To specify more than one email
#    address separate email address with commas. (I.e. admin@example.com,user@example.com)
# 2. from_email_address - used to specify an email address in the event the
#    requester replies to the email
# 3. signature - used to stamp the email with a custom signature
#

# Get vm from miq_provision object
#prov = $evm.root['miq_provision']
#vm = prov.vm
#raise "VM not found" if vm.nil?
$evm.root.attributes.sort.each {|key, value| $evm.log(:info, "root attribute #{key}: #{value}")}

# get the service from the miq_provision object
prov_task = $evm.root['service_template_provision_task']
$evm.log(:info, "prov.inspect: #{prov_task.inspect}")
#service = $evm.vmdb('service').find_by_guid(prov.get_option(:service_guid))
service = prov_task.destination
$evm.log(:info, "service: #{service.inspect}")
service_vms = service.vms

#We only want to send emails for bundles and individual services
#If the service has a parent, this servic is the child service of a bundle
#and we don't want to send an email for it.
if service.has_parent
  exit MIQ_OK
end

#Set the ip of the ui appliance... turn this into an instance variable
ui_vip = $evm.object['vip_address']

#Grab the email addresses from the dialog
pgm = service.get_dialog_option("dialog_pgm")
pm = service.get_dialog_option("dialog_pm")
ie = service.get_dialog_option("dialog_ie")
spm = service.get_dialog_option("dialog_spm")
ipm = service.get_dialog_option("dialog_ipm")
reporting_lead = service.get_dialog_option("dialog_reporting_lead")
sse = service.get_dialog_option("dialog_sse")
se = service.get_dialog_option("dialog_se")

# Get VM Owner Name and Email
evm_owner_id = service_vms.first.attributes['evm_owner_id']
owner = nil
owner = $evm.vmdb('user', evm_owner_id)
owner_email = owner.email unless owner.nil?

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

# Assign original to_email_Address to orig_to for later use
orig_to = to

# Get from_email_address from model unless specified below
from = nil
from ||= $evm.object['from_email_address']

# Get signature from model unless specified below
signature = nil
signature ||= $evm.object['signature']

#Get the service name
subject = "Service Request has Completed - Service: #{service['name']}"

#Get the domain for the fqdn
domain = $evm.object['domain']

ip_address_available = true

body = "Hello, "

# VM Provisioned Email Body
body += "<br><br>Your request to provision a service was approved and completed on #{Time.now.strftime('%A, %B %d, %Y at %I:%M%p')}. "
body += "<br><br>Service #{service['name']}<b> will be available in approximately 15 minutes</b>. "
body += "<br><br>VMs belonging to #{service['name']}:<br>"
service_vms.each do |vm|
  if vm.ipaddresses.empty?
  	$evm.root['ae_result'] = 'retry'
  	$evm.root['ae_retry_interval'] = 60.seconds
    ip_address_available = false
    break
  end
  body += "<br>#{vm.name}.#{domain}: #{vm.ipaddresses.first}"
end
body += "<br><br>For Windows VM access is available via RDP and for Linux VM access is available via putty/ssh, etc."
body += "<br><br>This VM will automatically be retired on #{service['retires_on'].strftime('%A, %B %d, %Y')}, unless you request an extension. " if service['retires_on'].respond_to?('strftime')
body += " You will receive a warning #{service['reserved'][:retirement][:warn]} days before #{service['name']} set retirement date." if service['reserved'] && service['reserved'][:retirement] && service['reserved'][:retirement][:warn]
body += " You will receive expiration warnings at the following email address(es): #{orig_to}"
body += "<br><br>If you are not already logged in, you can access and manage your virtual machine here <a href='https://#{ui_vip}/service/show/#{service['id']}'>https://#{ui_vip}/service/show/#{service['id']}</a>"
body += "<br><br> If you have any issues with your new virtual machine please contact Support."
body += "<br><br> Thank you,"
body += "<br> #{signature}"

if ip_address_available
  $evm.log("info", "Sending email to <#{to}> from <#{from}> subject: <#{subject}>")
  $evm.execute('send_email', to, from, subject, body)
end
