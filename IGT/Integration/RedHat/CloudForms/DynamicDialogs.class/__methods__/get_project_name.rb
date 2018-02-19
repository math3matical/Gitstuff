#
# Description: <Method description here>
#
vm = $evm.root['vm']
$evm.log(:info, "Root Attributes: #{$evm.root.attributes.sort}")
#$evm.root.attributes.sort.each {|k,v| $evm.log(:info, "Root Attribute - #{k}: #{v}")}
$evm.log(:info, "vm: #{vm}")
$evm.log(:info, "evm.object: #{$evm.object.attributes.sort}")
if vm
  current_project_name = vm.custom_get('Project Name')
  $evm.log(:info, "current_project_name: #{current_project_name}")
  $evm.object['value'] = current_project_name
else
  $evm.log(:info, "no vm found")
end
