=begin
 list_ec2_keypair_ids.rb

 Author: Kevin Morey <kevin@redhat.com>

 Description: This method lists Amazon key pair ids
-------------------------------------------------------------------------------
   Copyright 2016 Kevin Morey <kevin@redhat.com>

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
-------------------------------------------------------------------------------
=end
def log(level, msg, update_message = false)
  $evm.log(level, "#{msg}")
  @task.message = msg if @task && (update_message || level == 'error')
end

def get_provider(provider_id=nil)
  $evm.root.attributes.detect { |k,v| provider_id = v if k.end_with?('provider_id') } rescue nil
  provider = $evm.vmdb(:ManageIQ_Providers_Amazon_CloudManager).find_by_id(provider_id)
  log(:info, "Found provider: #{provider.name} via provider_id: #{provider.id}") if provider

  if !provider
    provider = $evm.vmdb(:ManageIQ_Providers_Amazon_CloudManager).first
    log(:info, "Found amazon: #{provider.name} via default method")
  end
  provider ? (return provider) : (return nil)
end

def get_provider_from_template(template_guid=nil)
  $evm.root.attributes.detect { |k,v| template_guid = v if k.end_with?('_guid') } rescue nil
  template = $evm.vmdb(:ManageIQ_Providers_Amazon_CloudManager_Template).find_by_guid(template_guid)
  return nil unless template
  provider = $evm.vmdb(:ManageIQ_Providers_Amazon_CloudManager).find_by_id(template.ems_id)
  log(:info, "Found provider: #{provider.name} via template.ems_id: #{template.ems_id}") if provider
  provider ? (return provider) : (return nil)
end

def query_catalogitem(option_key, option_value=nil)
  # use this method to query a catalogitem
  # note that this only works for items not bundles since we do not know which item within a bundle(s) to query from
  service_template = $evm.root['service_template']
  unless service_template.nil?
    begin
      if service_template.service_type == 'atomic'
        log(:info, "Catalog item: #{service_template.name}")
        service_template.service_resources.each do |catalog_item|
          catalog_item_resource = catalog_item.resource
          if catalog_item_resource.respond_to?('get_option')
            option_value = catalog_item_resource.get_option(option_key)
          else
            option_value = catalog_item_resource[option_key] rescue nil
          end
          log(:info, "Found {#{option_key} => #{option_value}}") if option_value
        end
      else
        log(:info, "Catalog bundle: #{service_template.name} found, skipping query")
      end
    rescue
      return nil
    end
  end
  option_value ? (return option_value) : (return nil)
end

$evm.root.attributes.sort.each { |k, v| log(:info, "\t Attribute: #{k} = #{v}")}

dialog_hash = {}

# see if provider is already set in root
provider = get_provider(query_catalogitem(:src_ems_id)) || get_provider_from_template()

if provider
  provider.key_pairs.each do |key_pair|
    next if key_pair.name.nil?
    dialog_hash[key_pair.id] = "#{key_pair.name} on #{provider.name}"
  end
else
  # no provider so list everything
  $evm.vmdb(:ManageIQ_Providers_Amazon_CloudManager_AuthKeyPair).all.each do |key_pair|
    provider = $evm.vmdb(:ManageIQ_Providers_Amazon_CloudManager).find_by_id(key_pair.resource_id)
    next if key_pair.name.nil?
    dialog_hash[key_pair.id] = "#{key_pair.name} on #{provider.name}"
  end
end

if dialog_hash.blank?
  dialog_hash[''] = "< no key pairs found >"
  $evm.object['required'] = false
else
  $evm.object['default_value'] = dialog_hash.first[0]
end

$evm.object['values'] = dialog_hash
log(:info, "$evm.object['values']: #{$evm.object['values'].inspect}")
