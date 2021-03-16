#requires -version 5.1
#requires -RunAsAdministrator

#create linked script copies in Installed Scripts

[cmdletbinding(SupportsShouldProcess)]
Param(
    [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, HelpMessage = "Specify the path of the file to link.")]
    [ValidateScript( {Test-Path $_})]
    [String[]]$Path
)

Begin {
    $installPath = "$env:ProgramFiles\WindowsPowerShell\Scripts"
    Write-Verbose "Creating links to $installpath"
}
Process {
    if (Test-Path -Path $installPath) {

        foreach ($file in $Path) {
            Try {
                #convert filepaths to normal filesystem paths
                $cfile = Convert-Path $File -ErrorAction Stop
            }
            Catch {
                Throw "Failed to find or convert $file"
            }
            if ($cfile) {
                $name = Split-Path -Path $cfile -Leaf
                $target = Join-Path -path $installPath -ChildPath $name
                Write-Verbose "Creating a link from $cfile to $target. A 0 byte file is normal."

                #overwrite the target if it already exists
                New-Item -Path $target -value $cfile -ItemType SymbolicLink -Force
            }
        } #foreach file
    }
    else {
        Write-Warning "Can't find $installPath. This script might require a Windows platform."
    }
}
End {
    Write-Verbose "Finished linking script files."
}

# Get-command -CommandType ExternalScript
