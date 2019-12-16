function Try-Command($command) {
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

function Is-Admin {
	$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
	return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-Choco-Path {
    $choco_version = Get-Choco-Version
    if([string]::IsNullOrEmpty($choco_version)) {
        return $null
    }
    
	$choco_path = (get-command choco | Select-Object -ExpandProperty Definition)
	$choco_path = $choco_path.split("\\") | Where-Object { $_ -ne "choco.exe" -And $_ -ne "bin" }
	return $choco_path -join "\"
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


function Right-Trim($text, $suffix) {
    if((Has-Text $text) -And (Has-Text $suffix)) {
        while($text -like "*$suffix") {
            $text = $text.substring(0, $text.length-$suffix.length)
        }
    }
    return $text
}

function Left-Trim($text, $prefix) {
    if((Has-Text $text) -And (Has-Text $prefix)) {
        while($text -like "$prefix*") {
            $text = $text.substring($prefix.length)
        }
    }
    return $text
}

function Has-Text($value) {
    return -Not [string]::IsNullOrEmpty($value)
}




