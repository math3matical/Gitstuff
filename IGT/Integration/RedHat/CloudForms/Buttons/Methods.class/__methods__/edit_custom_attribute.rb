#
# Description: <Method description here>
#
vm = $evm.root['vm']
$evm.root.attributes.sort.each {|k,v| $evm.log(:info, "Root Attribute - #{k}: #{v}")}

new_project_name = $evm.root['dialog_new_project_name']
new_clarity_project_id = $evm.root['dialog_new_clarity_project_id']
new_system_diagram_wiki_link = $evm.root['dialog_new_system_diagram_wiki_link']

unless new_project_name.empty?
  $evm.log(:info, "Setting new project name for #{vm.name}: #{new_project_name}")
  vm.custom_set('Project Name', new_project_name)
else
  $evm.log(:info, "Skipping set of custom attribute for new_project_name on #{vm.name}.  Value is empty.")
end

unless new_clarity_project_id.empty?
  $evm.log(:info, "Setting new Clarity Project ID for #{vm.name}: #{new_clarity_project_id}")
  vm.custom_set('Clarity Project ID', new_clarity_project_id)
else
  $evm.log(:info, "Skipping set of custom attribute for new_clarity_project_id on #{vm.name}.  Value is empty.")
end

unless new_system_diagram_wiki_link.empty?
  $evm.log(:info, "Setting new System Diagram Wiki Link for #{vm.name}: #{new_system_diagram_wiki_link}")
  vm.custom_set('System Diagram Wiki Link', new_system_diagram_wiki_link)
else
  $evm.log(:info, "Skipping set of custom attribute for new_system_diagram_wiki_link on #{vm.name}.  Value is empty.")
end
