DESCRIPTION
===========

Chef cookbook to manage CPU related actions on linux.

REQUIREMENTS
============

Linux 2.6+
tested on Ubuntu.

Attributes
==========

* `node['cpu']['governor']` - governator for to set for the node

Recipes
=======

governor
----------

Set the governator for the node from attributes

affinity
--------

Install software to set cpu affinity of a process.

Resources and Providers
=======================

`affinity`
----------

Set the affinity for a process.

# Actions

* `set` - Set affinity

# Attribute Parameters

* `cpu` : Cpu(s) affinity - required
* `pid` : Pid or PidFile - name

# Examples

```
cpu_affinity 1234 do
  cpu 0
end
```

```
# Set affinity to processor 0,1,2 for process nginx
cpu-affinity "set affinity for nginx" do
  pid "/var/run/nginx.pid"
  cpu "0-2"
end
```

`nice`
----------

Set the priority for a process.

# Actions

* `set` - Set priority

# Attribute Parameters

* `pid` : Pid or PidFile - name
* `priority` : priority for process

# Examples

```
cpu_nice 1234 do
  priority 12
end
```

```
cpu_nice "set affinity for nginx" do
  pid "/var/run/nginx.pid"
  priority 19
end
```

USAGE
=====

in a recipe:

   node.set["node"]["cpu"]["governor"] = "performance"
   include_recipe "cpu::governor"
