char_code = nil
request = nil
new_vm_name = nil

case $evm.root['vmdb_object_type']
  when 'miq_provision_request'
    request = $evm.root['miq_provision_request']
  when 'miq_provision'
    miq_provision = $evm.root['miq_provision']
    request = miq_provision.miq_provision_request
  else
    request = nil
end
$evm.log(:info, "request_object: #{request.inspect}")

unless request.nil?
  dialog_options = request.options[:dialog]
  $evm.log(:info, "dialog_options: #{dialog_options}")
  folder_path = dialog_options["dialog_folder_path_product"]
  $evm.log(:info, "folder_path: #{folder_path.inspect}")
  unless folder_path.empty?
    char_code = folder_path.split(" ").last.downcase
    $evm.log(:info, "char_code: #{char_code}")
  end
end

unless char_code.nil?
  # Prepended the numbering with a 1 to start the clouformz VM numbering higher.  Thus allowing us to create some VMs manually.  - AK
  new_vm_name = "xx#{char_code}1$n{3}" 
else
   new_vm_name = "#{$evm.object['vm_prefix']}1$n{3}"
end

$evm.log(:info, "new_vm_name: #{new_vm_name}")
$evm.object['vmname'] = new_vm_name
