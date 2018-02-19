#
# Description: <Method description here>
#
vm = $evm.root['vm']
if vm
  current_system_diagram_wiki_link = vm.custom_get('System Diagram Wiki Link')
  $evm.log(:info, "current_system_diagram_wiki_link: #{current_system_diagram_wiki_link}")
  $evm.object['value'] = current_system_diagram_wiki_link
else
  $evm.log(:info, "no vm found")
end
