. .\core-utils.ps1

function Is-Version($sample) {
    if([string]::IsNullOrEmpty($sample)) {
        return $false
    }

    $sample = $sample.trim()
    if([string]::IsNullOrEmpty($sample)) {
        return $false
    }

    $sample = Right-Trim $sample "!"

    if($sample -eq "*") {
        return $true
    }

    $parts = $sample.split(".")
    if($parts.length -lt 1 -Or $parts.length -gt 4) {
        return $false
    }

    foreach($part in $parts) {
        if(-Not ($part -match "^[\d]+$")) {
            return $false
        }
    }

    return $true
}

function Is-Version-Sufficient($found, $required) {
    if([string]::IsNullOrEmpty($found)) {
        return $false
    }

    $explicit = $required -like "*!"
    $required = Right-Trim $required "!"
    if(-Not (Is-Version $required)) {
        return $false
    }

    if($required -eq "*") {
        return $true
    }

    if($explicit) {
        return $found -eq $required
    }

    $current_tiers = $found.split('.')
    $needed_tiers = $required.split('.')
    for($i=0; $i -lt $needed_tiers.length; $i++) {
        $current = if($i -lt $current_tiers.length) {$current_tiers[$i]} Else {'0'}
        $current = $current -as [int]
        $needed = $needed_tiers[$i] -as [int]
        if($needed -gt $current) {
            return $false
        }
    }
    return $true
}

function Require-Packages {
    $current_package = ""
    $required = @{}

    foreach ($arg in $args) {
        if($arg -like "-*") {
            $current_package = Left-Trim $arg "-"
            if(-Not ($required.ContainsKey($current_package))) {
                $required[$current_package] = "*"
            }
            continue
        }

        if(Has-Text $current_package -And Is-Version $arg) {
            $required[$current_package] = $arg
        }
    }

    $installed = @{}
    foreach($entry in (choco list --localonly)) {
        $parts = $entry.trim().split(" ")
        if($parts.length -eq 2 -And (Is-Version $parts[1])) {
            $installed[$parts[0]] = $parts[1]
        }
    }

    $missing = @{}
    foreach($package in $required.Keys) {
        $required_version = $required[$package]
        $found_version = $installed[$package]
        if(-Not (Is-Version-Sufficient $found_version $required_version)) {
            $missing[$package] = $required_version
        }
    }

    $result = $true
    foreach($package in $missing.Keys) {
        $result = $result -And (Perform-Upgrade $package $missing[$package])
    }
    return $result
}

function Perform-Upgrade($package, $version) {
	$old_preference = $ErrorActionPreference
	$ErrorActionPreference = 'stop'
	try {
        $result = 0
        if((Has-Text $version) -And $version -ne "*") {
            $result = choco upgrade $package -y --version $version
        }
        else {
            $result = choco upgrade $package -y
        }
        $result = if($result -eq 0) { $true } else { $false }
        return $result
	}
	catch{
		return $false
	}
	finally {
		$ErrorActionPreference = $old_preference
	}
}


