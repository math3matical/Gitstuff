# We are not setting retirement dates on VMs. Only on services.
# The service retirement date is being set in catalogiteminitialization
# Set the retirement date on the VM and Service
def set_retirement_date(prov, vm, service)
  $evm.log(:info, "entering set_retirement_date")
  $evm.log(:info, "prov: #{prov.inspect}")

  retirement_date_type = prov.get_option(:retirement_date_type)
  if retirement_date_type == "end_date"
  	retirement_date = prov.get_option(:retirement_date)
    retirement_date = Date.parse(retirement_date)
  else
  	retirement_date = (prov.get_option(:relative_retirement_date)).to_i
    retirement_date = Date.today + retirement_date.month
  end
  
  $evm.log(:info, "retirement_date: #{retirement_date}")
  vm.retires_on = retirement_date
  service.retires_on = retirement_date
  service.retirement_warn = 30.days.to_i
end

def set_custom_attributes(prov, vm)
  vm.custom_set("Clarity Project ID", prov.get_option(:clarity_project_id))
  vm.custom_set("System Diagram Wiki Link", prov.get_option(:system_diagram_wiki_link))
  vm.custom_set("Project Name", prov.get_option(:project_name))  
  vm.custom_set("PgM", prov.get_option(:pgm))
  vm.custom_set("PM", prov.get_option(:pm))
  vm.custom_set("IE", prov.get_option(:ie))
end

$evm.root.attributes.sort.each { |k, v| $evm.log(:info,"Root:<$evm.root> Attributes - #{k}: #{v}")}

prov = $evm.root['miq_provision']
prov.attributes.sort.each { |k, v| $evm.log(:info,"miq_provision attributes - #{k}: #{v}")}

vm = prov.vm
service = prov.miq_request_task.destination

set_custom_attributes(prov, vm)
#set_retirement_date(prov, vm, service)


