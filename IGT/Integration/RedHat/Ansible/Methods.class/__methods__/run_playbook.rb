require 'yaml'
require 'net/ssh'
require 'net/scp'

def error(msg)
    @request.resource.set_message(msg)
    $evm.parent['reason'] = msg
    $evm.root['ae_result'] = 'error'
end

def run_ansible(args)
  options = {
    :paranoid => false,
    :password => args[:ansible_password]
  }

  $evm.log(:info, "running ssh #{args[:ansible_username]}@#{args[:ansible_server]}")
  #remove the white space from the service name because it is used in the .inv filename
  args[:service_name].delete!(' ')
  output = nil
  begin
    Net::SSH.start(args[:ansible_server], args[:ansible_username], options) do |ssh|
      command =  "cd #{args[:inventory_directory]} && \\"
      command += "echo \"#{args[:hosts_inv_file]}\" > #{args[:service_name]}.inv && \\"
      command += "ansible-playbook -i #{args[:inventory_directory]}/#{args[:service_name]}.inv #{args[:playbook_directory]}/#{args[:playbook_name]} --vault-password-file #{args[:var_directory]}/vault && \\"
      if args[:service_name].include? "ARPIAPP"
        $evm.log(:info, "RUNNING ANSIBLE BO INSTALL playbook_name: #{args[:bo_playbook_name]}")
        #command += "ansible-playbook -i #{args[:inventory_directory]}/#{args[:service_name]}.inv #{args[:bo_playbook_directory]}/#{args[:bo_playbook_name]}  && \\"
        command += "ansible-playbook -i #{args[:inventory_directory]}/#{args[:service_name]}.inv #{args[:bo_playbook_directory]}/bo_install.yml  && \\"
      end
      command += "rm -f #{args[:service_name]}.inv"
      
      output = ssh.exec!(command)
    end
  rescue => err
    error("[#{err}]\n#{err.backtrace.join("\n")}")
  end

  $evm.log(:info, "ssh output: #{output}")
  output
end

#if a vm is missing an ip address, exit and retry this method in a minute
def check_for_ip(vm)
  if vm.ipaddresses.length.zero?
    $evm.log(:info, "#{vm.name} does not have an IP address yet. Retrying in 1 minute.")
    $evm.root['ae_result'] = 'retry'
    $evm.root['ae_retry_interval'] = '1.minute'
    @continue = false
    #exit MIQ_OK
  end
end

##############
# BEGIN HERE #
##############
@continue = true
$evm.log(:info, "Running Ansible playbook on remote server")

# Get the service object so we can access the needed parameters
task = $evm.root["service_template_provision_task"]
service = task.destination
vms = service.vms

ansible_server = $evm.object['ansible_server']
ansible_username = $evm.object['ansible_username']
ansible_password = $evm.object.decrypt('ansible_password')
vm_username = $evm.object['vm_username']
vm_password = $evm.object.decrypt('vm_password')
playbook_directory = $evm.object['playbook_directory']
bo_playbook_directory = $evm.object['bo_playbook_directory']
playbook_name = $evm.object['playbook_name']
bo_playbook_name = $evm.object['bo_playbook_name']
inventory_directory = $evm.object['inventory_directory']
var_directory = $evm.object['var_directory']

#make sure we have IP addresses for all of the vms in the service before we start
vms.each do |vm|
  check_for_ip(vm)
end

if @continue == true
  #Create a single inventory file with all of the vms
  hosts_inv = ""
  vms.each do |vm|
    hosts_inv += "#{vm.ipaddresses.first} ansible_user=#{ansible_username} ansible_ssh_pass=#{vm_password} host_ip=#{vm.ipaddresses.first} host_name=#{vm.name}\n"
  end

    args = {
      :hosts_inv_file => hosts_inv,
      :ansible_server => ansible_server,
      :ansible_username => ansible_username,
      :ansible_password => ansible_password,
      :playbook_directory => playbook_directory,
      :bo_playbook_directory => bo_playbook_directory,
      :inventory_directory => inventory_directory,
      :var_directory => var_directory,
      :vm_username => vm_username,
      :playbook_name => playbook_name,
      :bo_playbook_name => bo_playbook_name,
      :service_name => service.name
    }

  run_ansible(args)
end
