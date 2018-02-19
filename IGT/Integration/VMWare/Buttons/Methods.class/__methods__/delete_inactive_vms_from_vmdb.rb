#
# Description: This method removes the VM from the VMDB database
#

vms_to_remove = []
$evm.root['ae_result'] = 'ok'
root_vm = $evm.root['vm']
service = $evm.root['service']

unless root_vm.nil?
  vms_to_remove.push(root_vm)
else
  vms_to_remove = service.vms
end

if vms_to_remove.empty?
  $evm.log(:warn, "No VMs to remove. Exiting now.")
  exit MIQ_WARN
end

#go through each vm and make sure it has been removed from the provider
vms_to_remove.each do |vm|
  if vm #&& $evm.get_state_var('vm_removed_from_provider')
    #if vm.retired? || vm.orphaned || vm.archived
    if vm.active == false
      $evm.log('info', "Removing VM <#{vm.name}> from VMDB")
      vm.remove_from_vmdb
      $evm.root['vm'] = nil
    else
      $evm.log(:info, "Skipping VM <#{vm.name} because it is still active")
    end
  end
end
