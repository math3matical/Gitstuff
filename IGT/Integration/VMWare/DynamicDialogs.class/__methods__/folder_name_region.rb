dialog_options = {}
root_directory = "Datacenters/WG/vm/DEV/"
provider = $evm.vmdb('ext_management_system').first
$evm.log(:info, "provider: #{provider.inspect}")
split_path = root_directory.split("/")
$evm.log(:info, "split_path: #{split_path.inspect}")

ems_folders = provider.ems_folders
valid_folders = []

ems_folders.each do |folder|
  if folder.folder_path.start_with?(root_directory)
    #$evm.log(:info, "start_with was true")
    split_name = folder.folder_path.split("/")
    #$evm.log(:info, "split_name: #{split_name.inspect}")
    #$evm.log(:info, "split_name.length: #{split_name.length}")
    if split_name.length == 5
    	valid_folders.push(folder)
    end
  end
end

$evm.log(:info, "valid_folders: #{valid_folders}")

dialog_options[nil] = "Please select a Region"

valid_folders.each do |folder|
  dialog_options[folder.folder_path] = folder.name
end

$evm.object['values'] = dialog_options
