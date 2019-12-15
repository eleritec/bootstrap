

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

# begin by checking admin privs.  if we're not in admin mode, we can't really do much of anything
Ensure-Privilges
# next install Chocolatey.  this will be the basis for most other things
Setup-Choco


