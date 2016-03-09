#### functions


# function to ask which distro will be created in chroot
# input: nothing
# output: messages with choice
# return: nothing (using global var)
ask_which_distro_chroot()
{
	# read which distro chroot will be created
	echo -e "Which distro do you want to create chroot?"
	echo -e "(1) Fedora 23.1 x86_64 Workstation"
	echo -e "(2) CentOS 7.2-1511 x86_64"
	echo -e "(0) Exit"
	read selectdistro
}

# function to ask if user has enough free space to create chroot
# input: nothing
# output: messages
# return: nothing
ask_free_space()
{
	echo -e "Do you have enough free space to create chroot in ${path_chroot} PATH? Provide at least 5GB."
	df -h
	echo -e "\nPlease confirm if you have enough free space. Answers: (yes/y/no/n)"
	read freespaceanswer

	if [ \( $freespaceanswer != "yes" \) && \( $freespaceanswer != "y" \) ]
	then	
  	      echo -e "Please release more space or provide other path that have enough free space and execute this script again."
	      echo -e "Aborting..."
	      exit 5
	fi
}

# function to ask and create path to generate chroot
# input: nothing
# output: messages and erros
# return: nothing
create_chroot_path()
{
	# assume that PATH already exist and can damage user files
	exist_path_with_files=":"
	while $exist_path_with_files
	do
		echo -e "Type the full PATH that you want to create chroot. If dir PATH does not exist completely, it will be created."
		read path_chroot


		# verify if PATH is absolut
		if [[ $path_chroot != /* ]]
		then
			echo -e "PATH that you typed >> $path_chroot << is not absolut PATH."
			echo -e "You will be asked again to provide new path."
		fi

		# verify if PATH can damage user files
		if [ "$(ls -A ${path_chroot})" ]
		then
			echo "You need to provide an empty directory. ${path_root} is not empty."
			echo -e "You will be asked again to provide new path."
		else
			# now the path is secure to be used and we can proceed
		    	exist_path_with_files="0"
		fi
	done

	
	# create path that user typed (if it already exist does not matter)
	echo -e "Creating PATH ${path_chroot}..."
	mkdir -p ${path_chroot}/var/lib/rpm/
	if [ $? == "0" ]
	then
		echo -e "PATH ${path_chroot} created."
	else
		echo -e "PATH ${path_chroot} not created (error from mkdir)."
		echo -e "Aborting..." 
		exit 4
	fi
}


# function to create chroot using yum
# input:
# (1) release rpm
# output: messages and errors
# return: nothing
create_chroot_with_yum()
{

	# ask about enough free space to continue
	ask_free_space
	
	# ask about which chroot PATH will be used to create chroot environment
	create_chroot_path

	distrorelease=$1
	echo -e "Downloading ${distrorelease}..."
	wget $distrorelease -O $tmpdir
	if [ $? != 0 ]
	then
		echo -e "wget failed to download. Check your internet connection."
		echo -e "Aborting..."
		exit 6
	fi
	echo 
	
	echo -e "Generating RPM base..."
	rpm --rebuilddb --root=$path_chroot
	if [ $? != 0 ]
	then
		echo -e "Fail to generate RPM base."
		echo -e "Aborting..."
		exit 9
	fi

	echo -e "Installing $distrorelease package..."
	rpm -i --root=$path_chroot --nodeps $distrorelease
	if [ $? != 0 ]
	then
		echo -e "Installation of ${distrorelease} package failed."
		echo -e "Aborting..."
		exit 10
	fi
	
	echo -e "Installing chroot base system..."
	yum --installroot=$path_chroot install -y rpm-build yum
	if [ $? != 0 ]
	then
		echo -e "Installation of chroot base system failed."
		echo -e "Aborting..."
		exit 11
	fi

	echo -e "Finishing chroot creation...\c "
	sync
	echo -e "Finished with success!"
}
