#
# Description: This method sets the retirement_state to retiring
#

service = $evm.root['service']
if service.nil?
  $evm.log('error', "Service Object not found")
  exit MIQ_ABORT
end

$evm.log('info', "Service before start_retirement: #{service.inspect} ")

if service.retired?
  $evm.log('error', "Service is already retired. Aborting current State Machine.")
  exit MIQ_ABORT
end

if service.retiring?
  $evm.log('error', "Service is in the process of being retired. Aborting current State Machine.")
  exit MIQ_ABORT
end

if service.retirement_state == "error"
  $evm.log('error', "service.retirement_state was error. Aborting retirement. If you need to retire this service, reset the retirement date and try again.")
  exit MIQ_ABORT
end

service.start_retirement

$evm.log('info', "Service after start_retirement: #{service.inspect} ")
