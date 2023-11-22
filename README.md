# io_oci_facts DPK Module

1. Return OCI tags as facts (based on https://github.com/BIAndrews/ec2tagfacts)
2. Discover instances by tags for failover strings


## OCI Tags as Facts

Any tags attached to the current instance are returned as Facter facts for the instance. 

### Freeform Tags

Freeform Tags will return like this:

```ruby
oci_tag => {
  <key> => "<value>",
}
```

This is an example of an instance with a freeform tag.

```ruby
oci_tag => {
  sla => "business_hours"
}
```

### Defined Tags

Defined Tags will return like this:

```ruby
oci_tag_<namespace> => {
  <key> => "<value>"
}
```

This is an example of an instance with defined tags from the `peoplesoft` and `schedule` namespaces.

```ruby
oci_tag_peoplesoft => {
  failovergroup => "pia",
  role => "midtier",
  tier => "dev",
  tools_version => "8.60"
}
oci_tag_schedule => {
  WeekDay => "0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0 ",
  Weekend => "0,0,0,0,0,0,0,*,*,*,*,*,*,*,*,*,*,*,*,*,*,*,*,0 "
}
```

## Failover Group Discovery

Uses these defaults to looks for tags to associate instances:

* Namespace: `peoplesoft`
* Grouping: `failovergroup`
* Environment Level: `tier`

For example, your HR production web servers would have these tags:

* `peoplesoft.failovergroup=pia`
* `peoplesoft.tier=hrprd`

and any instance that has those tags are returned in a list as the fact `pia_failover_group`

Create the file `$DPK_HOME/modules/io_oci_facts/lib/facter/tags.yaml` with this structure to use non-default tag values:

```yaml
namespace:    'psadminio'
grouping:     'role'
environment:  'zone'
```

You can use existing tags and a namespace or create your own. 
* The "environment" tag is use to identify your DEV, TST, PRD, etc environments. 
* The "grouping" tag is used to identify what type of failover string you need. The defined tag values must be: 
  * `pia`
  * `ib`
  * `ren`
  * `search`
  * `dashboard`

If you do not have tags setup, there is a helper script that can create the Tag Namespace and Tags to be used by this module. It is intended to be run from OCI's Cloud Shell and will set up the default tags.

```bash
$ ./create_tag_ns.sh

Creating 'peoplesoft' Tag Namespace
Creating 'peoplesoft.failovergroup' Tag
Creating 'peoplesoft.tier' Tag

Tag Namespace and Tags are ready for io_oci_facts DPK Module.
 - Modify the 'tier' tag values as needed.
```

## Installation

### DPK Installation

First, install the `oci` gem on each server with the DPK. The module uses the OCI Ruby SDK to query instances in the compartment.

```bash
gem install oci --no-document
```

Cloning the repository:

```bash
cd $DPK_HOME/puppet
git clone https://github.com/psadmin-io/psadminio-io_oci_facts.git modules/io_oci_facts
```

As a Git Submodule:

```bash
cd $DPK_HOME/puppet
git submodule add https://github.com/psadmin-io/psadminio-io_oci_facts.git modules/io_oci_facts
```

### OCI Requirements

To query other instances for the failover discovery, you need to grant read access to the servers where the DPK is running. This can be done through a dynamic group and a policy.

The dynamic group should include all instances where you are running the DPK (this can be done at the compartment level):

**Dynamic Group Name**: `dpk-read-group`
  * Criteria: `ANY { instance.compartment.id <compartment_id> }`

**Policy Name**: `dpk-read-instance-and-vcn`
  * Policies:
    * `Allow dynamic-group dpk-read-group to read instance-family in compartment <compartment_name>`
    * `Allow dynamic-group dpk-read_group to read virtual-network-family in compartment <compartment_name>`

### Assumptions:

* Looks in current compartment only (where DPK is executed) when discovering other instances with the same tags for the failover groups.
* Default tags and namespace are: `peoplesoft.failovergroup` and `peoplesoft.tier`