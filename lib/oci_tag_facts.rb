
require "net/http"
require 'json' # hint: yum install ruby-json, or apt-get install ruby-json
require "uri"
require "date"

# if set, file will be appended to with debug data
$debug = "/tmp/oci_tag_facts.log"

################################################
#
# void debug_msg ( string txt )
#
# Used to dump debug messages if debug is set
#

def debug_msg(txt)
  if $debug.is_a? String
    File.open($debug, 'a') { |file| file.write(Time.now.strftime("%Y/%m/%d %H:%M") + " " + txt + "\n") }
  end
end

####################################################
#
# Start
#

begin

  ################################################################
  #
  # Get the OCI Compute instance ID from http://169.254.169.254/
  #

  uri = URI.parse("http://169.254.169.254")
  http = Net::HTTP.new(uri.host, uri.port)
  http.open_timeout = 4
  http.read_timeout = 4
  request = Net::HTTP::Get.new("/opc/v2/instance/id")
  request['Authorization'] = "Bearer Oracle"
  response = http.request(request)
  instance_id = response.body

  debug_msg("Instance ID is #{instance_id}")

rescue

  debug_msg("This is not an OCI Compute instance or unable to contact the OCI instance-data web server.")

end


if !instance_id.is_a? String then

  # We couldn't find an instance string. Not an OCI Compute instance?

  debug_msg("Something bad happened since there was no error but this isn't a string.")

else

   # We have an instance ID we continue on...

  ##############################################################################################
  #
  # Get the OCI Compute instance region from http://instance-data/ and then shorten the region
  # for example we convert us-west-2b into us-west-2 in order to get the tags.
  #

  # TODO
  #request2 = Net::HTTP::Get.new("/latest/meta-data/placement/availability-zone")
  #response2 = http.request(request2)
  #r = response2.body

  #region = /.*-.*-[0-9]/.match(r)

  #debug_msg("Region is #{region}")

  uri = URI.parse("http://169.254.169.254")
  http = Net::HTTP.new(uri.host, uri.port)
  http.open_timeout = 4
  http.read_timeout = 4
  request = Net::HTTP::Get.new("/opc/v2/instance")
  #request = Net::HTTP::Get.new("/opc/v2/instance/definedTags")
  request['Authorization'] = "Bearer Oracle"
  response = http.request(request)
  jsonString = response.body

  debug_msg("JSON is...\n#{jsonString}")

  # convert json string to hash
  hash = JSON.parse(jsonString)

  if hash.is_a? Hash then

    debug_msg("Hash of metadata found")

    if hash.has_key?("freeformTags") then

      debug_msg("Hash of freeformTags found")
      result = {}

      ################################################################################
      #
      # Loop through all tags
      #

      hash['freeformTags'].each do |child|
      #  debug_msg("#{child[0]}")

        # Name it and make sure its lower case and convert spaces to understores
        name = "#{child[0]}".to_s
        name.downcase!
        name.gsub!(/\W+/, "_")
        fact = "oci_tag_#{name}"

        #debug_msg("Setting fact #{fact} to #{child[1]}")

        # append to the hash for structured fact later
        #result[name] = child[1].dup

        debug_msg("Added #{fact} to results hash for structured fact")

        # set puppet fact - flat version
        Facter.add("#{fact}") do
          setcode do
            child[1]
          end
        end

      end

    end

  end

end
      
