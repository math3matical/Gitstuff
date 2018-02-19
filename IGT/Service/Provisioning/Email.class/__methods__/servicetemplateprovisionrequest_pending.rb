#
# Description: This method is used to email the requester that the Service request was not auto-approved
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
  body = "<a href='https://#{ui_vip}/miq_request/show/#{@miq_request.id}'"
#  body += ">https://#{appliance}/miq_request/show/#{@miq_request.id}</a>"
  body += ">https://#{ui_vip}/miq_request/show/#{@miq_request.id}</a>"
  body
end

def approver_text(ui_vip, requester_email)
  body = "Approver, "
  body += "<br>A Service request received from #{requester_email} is pending."
  body += "<br><br>Approvers notes: #{@miq_request.reason}"
  body += "<br><br>For more information you can go to: "
  body += approver_href(ui_vip)
  body += "<br><br> Thank you,"
  body += "<br> #{signature}"
  body
end

def requester_email_address
  owner_email = @miq_request.options.fetch(:owner_email, nil)
  email = requester.email || owner_email || $evm.object['to_email_address']
  $evm.log(:info, "To email: #{email}")
  email
end

def email_approver(ui_vip)
  $evm.log(:info, "Requester email logic starting")
  requester_email = requester_email_address
  to = $evm.object['to_email_address']
  from = $evm.object['from_email_address']
  subject = "Request ID #{@miq_request.id} - Service request NEEDS YOUR ATTENTION!!!"

  send_mail(to, from, subject, approver_text(ui_vip, requester_email))
end

def requester_href(ui_vip)
  body = "<a href='https://#{ui_vip}/miq_request/show/#{@miq_request.id}'>"
  body += "https://#{ui_vip}/miq_request/show/#{@miq_request.id}</a>"
end

def requester_text(ui_vip)
  body = "Hello, "
  body += "<br><br>Please review your Request and look at pictures of cute animals at https://www.reddit.com/r/aww/ while you wait for approval from an Administrator."
  body += "<br><br>To view this Request go to: "
  body += requester_href(ui_vip)
  body += "<br><br> Thank you,"
  body += "<br> #{signature}"
end

def email_requester(ui_vip)
  $evm.log(:info, "Requester email logic starting")
  to = requester_email_address
  from = $evm.object['from_email_address']
  subject = "Request ID #{@miq_request.id} - Your Service Request is under review"

  send_mail(to, from, subject, requester_text(ui_vip))
end

#Set the ip of the ui appliance... turn this into an instance variable
ui_vip = $evm.object['vip_address']

@miq_request = $evm.root['miq_request']
$evm.log(:info, "miq_request id: #{@miq_request.id} approval_state: #{@miq_request.approval_state}")
$evm.log(:info, "options: #{@miq_request.options.inspect}")

service_template = $evm.vmdb(@miq_request.source_type, @miq_request.source_id)
$evm.log(:info, "service_template id: #{service_template.id} service_type: #{service_template.service_type}")
$evm.log(:info, "description: #{service_template.description} services: #{service_template.service_resources.count}")

appliance = $evm.root['miq_server'].ipaddress

email_requester(ui_vip)
email_approver(ui_vip)
