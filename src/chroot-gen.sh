#!/bin/bash

#### variables
distro_version="/etc/*-release file"
supported_package_manager="(deb|rpm)"
supported_rpm_distros="(centos|redhat|fedora)"
supported_deb_distros="(ubuntu|debian)"
package_manager=""
tmpdir=$(mktemp /tmp/XXXXXXXXXXX)
path_chroot=""

#### source

# functions
source functions.sh

#### processing variables

# verify who is you
if [ "$(id -u)" != "0" ]
then
	echo "You need to be root to use this script." 1>&2
	echo "Aborting..."
	exit 1
fi

# verifying if your distro is supported
if egrep -iq "$supported_rpm_distros" $distro_version
then
	package_manager="rpm"
elif egrep -iq "$supported_deb_distros" $distro_version
then
	package_manager="deb"
	echo "Developing..."
	exit 0
else
	echo "This script only oficially support: ${supported_deb_distros} ${supported_rpm_distros}."
	echo "If you know what you are doing, you can force continue."
	echo "Do you want force execute this script? (yes/y/no/n)"
	read tmp_force_execute
	if [ \( $tmp_force_execute == "n" \) || \( $tmp_force_execute == "no" \) ]
	then
		echo "Aborting..."
		exit 0
	elif [ \( $tmp_force_execute == "y" \) || \( $tmp_force_execute == "yes" \) ]
	then
		echo "We support these package managers: $supported_package_manager "
		echo "Which package manager do you use?"
		read tmp_force_execute_package
		
		if [ $tmp_force_execute == "rpm" ]
		then
			package_manager="rpm"
		elif [ $tmp_force_execute == "deb" ]
		then
			package_manager="deb"
		else
			echo "Unrecognized package manager."
			echo "Aborting..."
			exit 2
		fi
	else
		echo "Unrecognized answer."
		echo "Aborting..."
		exit 12
	fi
fi


# ask about which distro chroot will be created
ask_which_distro_chroot

# proccess chroot creation
case $selectdistro in
	1)
		create_chroot_with_yum http://fedora.c3sl.ufpr.br/linux/releases/23/Workstation/x86_64/os/Packages/f/fedora-release-workstation-23-1.noarch.rpm
		exit 0
	;;
	2)
		create_chroot_with_yum http://mirror.centos.org/centos/7/os/x86_64/Packages/centos-release-7-2.1511.el7.centos.2.10.x86_64.rpm
		exit 0
	;;

	0)
		echo -e "Nothing did. Exiting..."
		exit 0
	;;

	*)
		echo -e "Option choosed not recognized."
		echo -e "Aborting..."
		exit 8
	;;
esac


# should never reach here
# general error or not treated error
echo -e "Unrecognized error. Something not expected happened."
exit 255
