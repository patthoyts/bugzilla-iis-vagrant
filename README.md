# Bugzilla on IIS.

A Vagrant setup to install Bugzilla on Windows Server 2012 R2.

This requires a Windows Server 2012r2 vagrant box. I actually followed
the instructions on [this blog post][1] to create my own licensed
Windows vagrant box but there are also [premade boxes][2] available
using evaluation editions of Windows Server 2012. The current version
of one of these will be downloaded unless the `config.vm.box` entry is
modified.

The provisioning files in the scripts folder install [chocolatey][3]
and then use this to install git, sqlite and strawberry perl. Other
scripts install IIS and then install Bugzilla as a web application
hosted by IIS in a subdirectory of the default site.

These scripts could also be used on a non-vagrant system to simplify
the installation of Bugzilla under IIS. The `install-iis-bugzilla.ps1`
script deals with just installing the Bugzilla web application.

If any patch files are included in the patches folder then these will be
applied using `git am`.

If any Bugzilla extensions are included as zip archives in the
extensions folder then these are unpacked in the Bugzilla extensions
folder on the server.

*Note* that some sections take up to half an hour or more. Installing
IIS is quite slow and installing all the required Perl modules from
CPAN also takes a long time.

*Note* this installation uses SQLite as the database to simplify the
 installation. This should not be used for production installations.

Provisioning does require the use of a shared folder using VirtualBox
host shared folders. This may require an update of the VirtualBox
Additions on the guest operating system. To deal with this the vagrant
box can be started without provisioning and the additions installed
manually before explicitly provisioning the box. Rerunning the
provisioning is a safe operation and will not result in excessive
additional work being performed.

    vagrant up --no-provision
    -- Install VirtualBox Additions. --
    vagrant provision

Once the provisioning stage has completed the Bugzilla application
will be running and just needs logging in as `admin@example.com` using
password `password`.

The box exports the guest port 80 to localhost port 8080 so the final
URL to access your Bugzilla application will be:

    http://localhost:8080/Bugzilla/


[1]: http://www.hurryupandwait.io/blog/in-search-of-a-light-weight-windows-vagrant-box
[2]: https://atlas.hashicorp.com/mwrock/boxes/Windows2012R2
[3]: https://chocolatey.org/