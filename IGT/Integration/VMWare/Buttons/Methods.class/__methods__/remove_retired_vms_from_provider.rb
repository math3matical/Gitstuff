vms_to_remove = []
root_vm = $evm.root['vm']
service = $evm.root['service']

unless root_vm.nil?
  vms_to_remove.push(root_vm)
else
  vms_to_remove = service.vms
end

if vms_to_remove.empty?
  $evm.log(:warn, "No VMs to remove. Exiting now.")
  exit MIQ_ABORT
end

#go through each vm and remove it from the provider if it has been retired
vms_to_remove.each do |vm|
    
  ems = vm.ext_management_system if vm
    
  if vm.nil? || ems.nil?
    $evm.log('info', "Skipping remove from provider for VM:<#{vm.try(:name)}> on provider:<#{ems.try(:name)}>")
  else    
    #If the vm isn't retired it's either still active, orphaned, or archived... any which way, we don't want/need to remove it from the provider
    if vm.retired?
      #if the VM's still powered on, power it off
      if vm.power_state == "on"
        $evm.log(:warn, "VM, #{vm.name} is still powered on. Powering it off.")
        vm.stop
      end
      $evm.log('info', "Removing VM:<#{vm.name}> from provider:<#{ems.name}>")
      vm.remove_from_disk(false)
    else
      $evm.log(:warn, "VM, #{vm.name}, was not removed. It is either already removed or is still active.")
    end
  end
end
