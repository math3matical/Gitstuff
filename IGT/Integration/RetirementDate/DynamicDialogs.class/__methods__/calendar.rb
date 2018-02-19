retirement_date_type = nil
$evm.root.attributes.detect { |k,v| retirement_date_type = v if k.end_with?('retirement_date_type')}

if retirement_date_type == "end_date"
  $evm.object['visible'] = true
end
