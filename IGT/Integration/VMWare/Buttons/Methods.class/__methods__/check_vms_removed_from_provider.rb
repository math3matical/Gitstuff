#
# Description: This method checks to see if the VM has been removed from the provider
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
    #We are only concerned with the retired VMs we previously removed
    if vm.retired?
      if vm.ext_management_system
        vm.refresh
        $evm.root['ae_result']     = 'retry'
        $evm.root['ae_retry_interval'] = '60.seconds'
        break
      end
    end
  end
end
