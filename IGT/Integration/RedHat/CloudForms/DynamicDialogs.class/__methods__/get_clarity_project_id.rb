#
# Description: <Method description here>
#
vm = $evm.root['vm']
if vm
  current_clarity_project_id = vm.custom_get('Clarity Project ID')
  $evm.log(:info, "current_clarity_project_id: #{current_clarity_project_id}")
  $evm.object['value'] = current_clarity_project_id
else
  $evm.log(:info, "no vm found")
end
