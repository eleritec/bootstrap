

function Setup-Basic-Tools {
	choco install dos2unix -y
	choco install 7zip -y
	choco install procexp -y
	choco install notepadplusplus -y

}
function Setup-Dev-Tools {
	choco install git -y
	choco install vscode -y

	Setup-Java
	Setup-Python
}

function Setup-WSL {
	Install-Ubuntu-18
}

function Install-Ubuntu-18 {
	# download and install ubuntu 18.04 with Chocolatey
	choco install wsl-ubuntu-1804 -y
	
	# TODO: find out if there's a way we can determine this programmatically
	$ubuntu_path = "C:\ProgramData\chocolatey\lib\wsl-ubuntu-1804\tools\unzipped"
	
	# the choco package will install ubuntu with the root user.  we want to create
	# and set the default user to match our current windows user
	
	# calling `wsl -d Ubuntu-18.04 adduser` chokes on --geocos for some reason, 
	# so instead we'll dump the creation to a bash script that we can execute as root
	$pw_params = $env:username + ':password'
	echo "#!/bin/bash" > user_init.sh
	echo "adduser --disabled-password --gecos '' $env:username" >> user_init.sh
	echo "echo '$pw_params' | chpasswd" >> user_init.sh
	$script_text = Get-Content user_init.sh
	echo $script_text | out-file -encoding ASCII user_init.sh
	dos2unix user_init.sh
	wsl -d Ubuntu-18.04 chmod 744 ./user_init.sh
	wsl -d Ubuntu-18.04 ./user_init.sh
	rm user_init.sh
	
	# force them to change their password on next login
	wsl -d Ubuntu-18.04 passwd --expire $env:username
	
	# add the user to expected groups
    echo "Configuring groups for $env:username ..."
	wsl -d Ubuntu-18.04 usermod -aG adm $env:username
	wsl -d Ubuntu-18.04 usermod -aG dialout $env:username
	wsl -d Ubuntu-18.04 usermod -aG cdrom $env:username
	wsl -d Ubuntu-18.04 usermod -aG floppy $env:username
	wsl -d Ubuntu-18.04 usermod -aG sudo $env:username
	wsl -d Ubuntu-18.04 usermod -aG audio $env:username
	wsl -d Ubuntu-18.04 usermod -aG dip $env:username
	wsl -d Ubuntu-18.04 usermod -aG video $env:username
	wsl -d Ubuntu-18.04 usermod -aG plugdev $env:username
	wsl -d Ubuntu-18.04 usermod -aG lxd $env:username
	wsl -d Ubuntu-18.04 usermod -aG netdev $env:username
	
	# make our user the default for ubuntu
	if(-Not ($env:path -like '*wsl-ubuntu-1804*')) {
		$env:path += ";$ubuntu_path"
	}	
	ubuntu1804 config --default-user $env:username
	
	# choco package installs under C:\ProgramData, which is restricted to admin.
	# in order to run ubuntu without elevated privileges, we need to grant the
	# current user full control to $ubuntu_path
    echo "Setting up Windows Host filesystem access ..."
	$self = [Security.Principal.WindowsIdentity]::GetCurrent().Name
	$acl = Get-Acl $ubuntu_path
	$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($self, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
	$acl.SetAccessRule($AccessRule)
	$acl | Set-Acl $ubuntu_path
	
	# place a shortcut on the desktop
	# TODO: figure out how to pin this shortcut to the taskbar
    echo "Creating Ubuntu-18.04 Desktop shortcut..."
	$launcher = "$ubuntu_path\ubuntu1804.exe"
	$shortcut_file = [Environment]::GetFolderPath("Desktop") + "\Ubuntu-18_04.lnk"
	Create-Shortcut $launcher $shortcut_file
}

function Setup-Java {
	# java 1.8
	choco install openjdk8 -y
	choco install maven -y
}

function Setup-Python {
	choco install python -y
}

function Ensure-Privilges {
	$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
	if(-Not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
		echo 'Unsufficient privileges.  Please run this under Administrative privileges.'
		echo ''
		exit
	}
}

function Setup-Choco {
	$version = Get-Choco-Version
	if([string]::IsNullOrEmpty($version)) {
		echo "Chocolately not detected.  Installing..."
		Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
	}

	# make sure we have the gui installed on the system too
	choco install chocolateygui -y
}

function Get-Choco-Version {
	$choco_output = Try-Command 'choco.exe'

	$choco_version = ($choco_output -split '\n')[0]
	if($choco_version -like 'Chocolatey *') {
		$choco_version = ($choco_version -split ' ')[1].trim()
		return $choco_version
	}
	return $null
}

function Try-Command() {
	Param($command)
	$old_preference = $ErrorActionPreference
	$ErrorActionPreference = 'stop'
	try {
		if(Get-Command $command) {
			return Invoke-Expression $command
		}
	}
	catch{
		return $null
	}
	finally {
		$ErrorActionPreference = $old_preference
	}
}

function Create-Shortcut($source_exe, $dest_link) {
	$WScriptShell = New-Object -ComObject WScript.Shell
	$Shortcut = $WScriptShell.CreateShortcut($dest_link)
	$Shortcut.TargetPath = $source_exe
	$Shortcut.Save()
}

function Prep-System {
	# this will allow us to run PowerShell scripts
	Set-ExecutionPolicy RemoteSigned -Scope LocalMachine
	# this will require a restart
	Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
}

# begin by checking admin privs.  if we're not in admin mode, we can't really do much of anything
Ensure-Privilges
# next install Chocolatey.  this will be the basis for most other things
Setup-Choco

# setup base tools
Setup-Basic-Tools
# set dev platforms
Setup-Dev-Tools
# setup linux subsystem
Setup-WSL

