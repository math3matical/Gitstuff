retirement_date_type = nil
$evm.root.attributes.detect { |k,v| retirement_date_type = v if k.end_with?('retirement_date_type')}

if retirement_date_type == "length_of_time"
  $evm.object['visible'] = true
  $evm.object['values'] = {
  1 => "1 Month",
  3 => "3 Months",
  6 => "6 Months",
  9 => "9 Months",
  12 => "12 Months",
  18 => "18 Months",
  24 => "24 Months"
  }
end
