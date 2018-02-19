def log(level, msg, update_message = false)
  $evm.log(level, "#{msg}")
  @task.message = msg if @task && (update_message || level == 'error')
end

#### Modified for IGT ####
def set_folder
  log(:info, "Processing set_folder...", true)
  ###################################
  # Drop the VM in the targeted folder if no folder was chosen in the dialog
  # The vCenter folder must exist for the VM to be placed correctly else the
  # VM will placed along with the template
  # Folder starts at the Data Center level
  ###################################
  
  if @task.get_option(:folder_path_product).nil?
    datacenter = @template.v_owning_datacenter
    vsphere_fully_qualified_folder = "#{datacenter}/Discovered virtual machine"
    @task.set_folder(vsphere_fully_qualified_folder)

    log(:info, "Provisioning object <:folder_path_product> updated with <#{@task.options[:folder_path_product].inspect}>")
  else
    datacenter = @template.v_owning_datacenter
    root_directory = "Datacenters/WG/vm/"
    desired_folder = @task.get_option(:folder_path_product)
    desired_folder.slice!(root_directory)
    folder_path = "#{datacenter}/#{desired_folder}"
	$evm.log(:info, "folder_path: #{folder_path}")
    @task.set_folder(folder_path)
    log(:info, "Placing VM in folder: <#{@task.options[:folder_path_product].inspect}>")
  end
  log(:info, "Processing set_folder...Complete", true)
end
#### Modified for IGT ####

begin
  # Get provisioning object
  @task = $evm.root['miq_provision']
  log(:info, "Provision:<#{@task.id}> Request:<#{@task.miq_request.id}> Type:<#{@task.type}>")

  @template = @task.vm_template
  provider = @template.ext_management_system
  product  = @template.operating_system['product_name'].downcase
  bitness = @template.operating_system['bitness']
  log(:info, "Template:<#{@template.name}> Provider:<#{provider.name}> Vendor:<#{@template.vendor}> Product:<#{product}> Bitness:<#{bitness}>")

  tags = @task.get_tags
  log(:info, "Provision Tags:<#{tags.inspect}>")

  set_folder
  
  # Set Ruby rescue behavior
rescue => err
  log(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_STOP
end
