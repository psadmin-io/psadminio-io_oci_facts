# io_oci_facts DPK Module

Return OCI tags for an instance as facts to be used by Hiera and Puppet (based on https://github.com/BIAndrews/ec2tagfacts)

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

## Installation

### DPK Installation

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

Once copied the `modules` directory, Puppet will include the new facts the next time it is run.