
#
# Description: This method is used to email the requester and approver that the service request has been denied
#

def send_mail(to, from, subject, body)
  $evm.log(:info, "Sending email to #{to} from #{from} subject: #{subject}")
  $evm.execute(:send_email, to, from, subject, body)
end

def requester
  @miq_request.requester
end

def signature
  $evm.object['signature']
end

def reason
  @miq_request.reason
end

def approver_href(ui_vip)
  " <a href='https://#{ui_vip}/miq_request/show/#{@miq_request.id}'</a>"
end

def approver_denied_text(requester_email, msg, reason)
  body = "<br>A service request received from #{requester_email} was denied."
  body += "<br><br>#{msg}."
  body += "<br><br>Approvers notes: #{reason}"
end

def approver_text(ui_vip, msg, requester_email)
  body = "Approver, "
  body += approver_denied_text(requester_email, msg, reason)
  body += "<br><br>For more information you can go to:"
  body += approver_href(ui_vip)
  body += "<br><br> Thank you,"
  body += "<br> #{signature}"
end

def requester_email_address
  owner_email = @miq_request.options.fetch(:owner_email, nil)
  email = requester.email || owner_email || $evm.object['to_email_address']
  $evm.log(:info, "Requester email: #{email}")
  email
end

def email_approver(ui_vip, msg)
  $evm.log(:info, "Approver email logic starting")
  requester_email = requester_email_address
  to = $evm.object['to_email_address']
  from = $evm.object['from_email_address']
  subject = "Request ID #{@miq_request.id} - Service request was denied"

  send_mail(to, from, subject, approver_text(ui_vip, msg, requester_email))
end

def requester_href(ui_vip)
  body = "<a href='https://#{ui_vip}/miq_request/show/#{@miq_request.id}'"
  body += ">https://#{ui_vip}/miq_request/show/#{@miq_request.id}</a>"
end

def requester_text(ui_vip, msg)
  body = "Hello, "
  body += "<br>#{msg}."
  body += "<br><br>Approvers notes: #{reason}"
  body += "<br><br>For more information you can go to:"
  body += requester_href(ui_vip)
  body += "<br><br> Thank you,"
  body += "<br> #{signature}"
end

def email_requester(ui_vip, msg)
  $evm.log(:info, "Requester email logic starting")
  to = requester_email_address
  from = $evm.object['from_email_address']
  subject = "Request ID #{@miq_request.id} - Your service request was denied"

  send_mail(to, from, subject, requester_text(ui_vip, msg))
end

#Set the ip of the ui appliance... turn this into an instance variable
ui_vip = $evm.object['vip_address']

@miq_request = $evm.root['miq_request']
$evm.log(:info, "miq_request id: #{@miq_request.id} approval_state: #{@miq_request.approval_state}")
$evm.log(:info, "options: #{@miq_request.options.inspect}")

service_template = $evm.vmdb(@miq_request.source_type, @miq_request.source_id)
$evm.log(:info, "service_template id: #{service_template.id} service_type: #{service_template.service_type}")
$evm.log(:info, "description: #{service_template.description} services: #{service_template.service_resources.count}")

msg = @miq_request.resource.message || "Request denied"
appliance = $evm.root['miq_server'].ipaddress

email_requester(ui_vip, msg)
email_approver(ui_vip, msg)
