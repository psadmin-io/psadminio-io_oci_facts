# gem install oci --no-document
require 'oci'
require "net/http"
require 'json' # hint: yum install ruby-json, or apt-get install ruby-json
require "uri"
require "yaml"

tags = YAML.load_file('tags.yml')

pia_failover_group = []

compute_client = OCI::Core::ComputeClient.new
vcn_client = OCI::Core::VirtualNetworkClient.new

# Get ocid of current instance
begin
  uri = URI.parse("http://169.254.169.254")
  http = Net::HTTP.new(uri.host, uri.port)
  http.open_timeout = 4
  http.read_timeout = 4
  request = Net::HTTP::Get.new("/opc/v2/instance/id")
  request['Authorization'] = "Bearer Oracle"
  response = http.request(request)
  instance_id = response.body
rescue
  debug_msg("This is not an OCI Compute instance or unable to contact the OCI instance-data web server.")
  exit 1
end

# Get compartment id of current instance
begin
  compartmentid = compute_client.get_instance(instance_id).data
rescue
  debug_msg("Unable to get compartment id for instance")
  exit 1
end

# PIA Failover Groups
compute_client.list_instances(compartmentid).data.each { |inst|
  if inst.defined_tags[tags['namespace']][tags['grouping']] == 'pia' then
    compute_client.list_vnic_attachments(compartmentid, instance_id: inst.id).each { |vnic_attachments|
      vnic_attachments.data.each { |attachment|
        vnic = vcn_client.get_vnic(attachment.vnic_id).data
        pia_failover_group.push(vnic.private_ip)
      }
    }
  end
}

Facter.add(:pia_failover_group) do
  setcode do
    pia_failover_group
  end
end