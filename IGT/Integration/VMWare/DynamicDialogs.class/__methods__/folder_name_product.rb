dialog_options = {}
valid_folders = []
site_path = nil
$evm.root.attributes.detect { |k,v| site_path = v if k.end_with?('folder_path_site')}
$evm.log(:info, "site_path: #{site_path}")
unless site_path.nil? || site_path.empty?
  root_directory = "#{site_path}/"
  provider = $evm.vmdb('ext_management_system').first
  $evm.log(:info, "provider: #{provider.inspect}")
  split_path = root_directory.split("/")
  $evm.log(:info, "split_path: #{split_path.inspect}")

  ems_folders = provider.ems_folders
  
  ems_folders.each do |folder|
    if folder.folder_path.start_with?(root_directory)
      #$evm.log(:info, "start_with was true")
      split_name = folder.folder_path.split("/")
      #$evm.log(:info, "split_name: #{split_name.inspect}")
      #$evm.log(:info, "split_name.length: #{split_name.length}")
      if split_name.length == 7
          valid_folders.push(folder)
      end
    end
  end

  $evm.log(:info, "valid_folders: #{valid_folders}")
end

region_path = nil
$evm.root.attributes.detect { |k,v| region_path = v if k.end_with?('folder_path_region')}
if region_path.nil?
  dialog_options[nil] = "Please select a Region"
elsif site_path.nil? || site_path.empty?
  dialog_options[nil] = "Please select a Site"
else
  dialog_options[nil] = "Please select a Product"
end

valid_folders.each do |folder|
  dialog_options[folder.folder_path] = folder.name
end

$evm.object['values'] = dialog_options
