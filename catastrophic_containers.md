---
layout: doc
title: "Catastrophic containers"
submissions:
- title: Entire Assignment
  due_date: 04/24/2019 11:59 pm
  graded_files:
  - assignment.txt
learning_objectives:
  - Learn about containers and how they work
---

# Catastrophic containers

Implement at least one feature from each section and 10 features overall.

---

## Misc Features

* Be able to save/load the state of the container
* Load an image from another OS (e.g. if you start on ubuntu load fedora)
* Be able to launch multiple containers concurrently
* Be able to list all running containers
* Have a control channel visible only the the host namespace
* Have a good user experience, with helpful help/error messages and a good CLI

### Hints:
* http://man7.org/linux/man-pages/man2/unshare.2.html
* https://www.toptal.com/linux/separation-anxiety-isolating-your-system-with-linux-namespaces
* https://ericchiang.github.io/post/containers-from-scratch/

---

## Process/resource management features

* Container moves into a new namespace (mount, user, PID, net)
* Have an init process that cleans up orphans
* Limit CPU frequency
* Limit number of processes

### Hints:
* https://blogs.rdoproject.org/2015/08/hands-on-linux-sandbox-with-namespaces-and-cgroups/

---

## Networking Features

* Be able to assign an IP to the container
* Be able to connect to the internet from within the container
* Be able to ssh into the container (You might need to patch your ssh config - if you ask us, we’ll provide you with a patch file)
* Use a public DNS server (the default one won’t work.)
    * Try 8.8.8.8
* Be able to forward ports from the container to the host

### Hints:
* https://gist.github.com/dpino/6c0dca1742093346461e11aa8f608a99

---

## Filesystem Features:

* Be able to have full read/write access to the container
* Be able to have full write access to the container without polluting the real filesystem
* Container launches in a new root partition
* /dev, /proc, /sys have been remounted and are reporting information about the current namespace

### Hints:
* https://wiki.archlinux.org/index.php/Overlay_filesystem
* https://superuser.com/questions/165116/mount-dev-proc-sys-in-a-chroot-environment
* https://linux.die.net/man/8/pivot_root

---

## User Features:

* Have a user in the container that is not root
* Have a user in the container that has sudo privileges
* Be able to create a new container without being root (i.e. use the set-uid bit)

