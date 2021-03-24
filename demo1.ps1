# https://github.com/jdhitsolutions/PSSummit2021

Return "This is a demo script file."

#region Custom Script Validation

#make errors easier to see
$host.PrivateData.ErrorForegroundColor = "yellow"

Function Get-FolderSize {
    [cmdletbinding()]
    [alias("gfs")]
    Param(
        [ValidateScript( { Test-Path $_ })]
        [string]$Path = "."
    )

    Get-ChildItem -Path $path -File -Force -Recurse |
    Measure-Object -Property Length -Sum |
    Select-Object -Property @{Name = "Path"; Expression = { Convert-Path $path } },
    Count, Sum
}

#good
Get-FolderSize c:\work

#bad
gfs q:\foo

#let's do better
Function Get-FolderSize {
    [cmdletbinding()]
    [alias("gfs")]
    Param(
        [ValidateScript( {
                if (Test-Path $_) {
                    $True
                }
                else {
                    Throw "Failed to validate the path $($_.toUpper())."
                    $False
                }
            })]
        [string]$Path = "."
    )

    Get-ChildItem -Path $path -File -Force -Recurse |
    Measure-Object -Property Length -Sum |
    Select-Object -Property @{Name = "Path"; Expression = { Convert-Path $path } },
    Count, Sum
}

gfs q:\foo3

#experience might differ based on PowerShell version
$error[0].exception | select *

#if v7
Get-Error -Newest 1

cls

#endregion

#region Leveraging Internal PSDefaultParameterValues

#https://github.com/jdhitsolutions/ADReportingTools

psedit S:\ADReportingTools\functions\get-adcanonicaluser.ps1
Import-Module S:\ADReportingTools\ADReportingTools.psd1 -Force
#test the command in the domain
$PSDefaultParameterValues

Get-ADCanonicalUser company\artd -server dom2 -verbose
Get-ADCanonicalUser company\foo.bar -server dom2 -verbose

$PSDefaultParameterValues

#depending on your work, splatting PSBoundparameters might be easier
psedit S:\ADReportingTools\functions\get-adsummary.ps1

Get-ADSummary -server dom2 -verbose
Get-ADSummary -Server domFoo -Verbose

cls

#endregion

#region Auto Completion

#via parameters. Can be more dynamic than ValidateSet and it allows the user to specify a value
psedit S:\ADReportingTools\functions\get-adusercategory.ps1

#demo in the console
$ADUserReportingConfiguration

Get-ADUserCategory -Identity artd -Category <tab>
#combined with parameter validation
Get-ADUserCategory -Identity artd -Category foo

#or this
Register-ArgumentCompleter -CommandName Get-WinEvent -ParameterName Logname -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    (Get-WinEvent -ListLog "$wordtoComplete*").logname |
    ForEach-Object {
        # completion text,listitem text,result type,Tooltip
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

Get-WinEvent -LogName <tab

#for a function
psedit .\Get-ServiceStatus.ps1

. .\get-servicestatus.ps1

Get-ServiceStatus -computername <tab>

#won't work for dynamic parameters

cls

#endregion

#region Dynamic Parameters

psedit .\Demo-DynamicParam.ps1

Function Export-PSTypeExtension {
    #from https://github.com/jdhitsolutions/PSTypeExtensionTools

    [cmdletbinding(SupportsShouldProcess, DefaultParameterSetName = "Object")]
    Param(
        [Parameter(
            Position = 0,
            Mandatory,
            HelpMessage = "The type name to export like System.IO.FileInfo",
            ParameterSetName = "Name"
        )]
        [ValidateNotNullOrEmpty()]
        [string]$TypeName,

        [Parameter(
            Mandatory,
            HelpMessage = "The type extension name",
            ParameterSetName = "Name"
        )]
        [ValidateNotNullOrEmpty()]
        [string[]]$MemberName,

        [Parameter(
            Mandatory,
            HelpMessage = "The name of the export file. The extension must be .json,.xml or .ps1xml"
        )]
        [ValidatePattern("\.(xml|json|ps1xml)$")]
        [string]$Path,

        [Parameter(ParameterSetName = "Object", ValueFromPipeline)]
        [object]$InputObject,

        [parameter(HelpMessage = "Force the command to accept the name as a type.")]
        [switch]$Force,

        [switch]$Passthru
    )
    DynamicParam {
        #create a dynamic parameter to append to .ps1xml files.
        if ($Path -match '\.ps1xml$') {

            #define a parameter attribute object
            $attributes = New-Object System.Management.Automation.ParameterAttribute
            $attributes.HelpMessage = "Append to an existing .ps1xml file"

            #define a collection for attributes
            $attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
            $attributeCollection.Add($attributes)

            #define the dynamic param
            $dynParam1 = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("Append", [Switch], $attributeCollection)

            #create array of dynamic parameters
            $paramDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
            $paramDictionary.Add("Append", $dynParam1)
            #use the array
            return $paramDictionary

        } #if
    } #dynamic parameter

    Begin {
        Write-Verbose "Starting: $($MyInvocation.Mycommand)"
        Write-Verbose "Detected parameter set $($pscmdlet.ParameterSetName)"
        #...
    }
    Process {
        #test if parent path exists
        #...
    }
    End {
        if ($validPath) {
            Write-Verbose "Exporting data to $path"

            if ($Path -match "\.ps1xml$") {

                if ($PSBoundParameters["Append"]) {
                    $cpath = Convert-Path $path
                    Write-Verbose "Appending to $cpath"
                    #...
                }
            }
        }
        Write-Verbose "Ending: $($MyInvocation.Mycommand)"
    }

} #end Export-PSTypeExtension

#load the function
#demo running the command

#check help for the dynamic parameter
help Export-PSTypeExtension

#using Get-Command
(Get-Command Export-PSTypeExtension).parameters

#but sometimes they are
#this is using a command from the PSScriptTools module
Get-ParameterInfo -Command Get-AdDomain | Select-Object Name, IsDynamic

cls
#endregion

#region Custom Type Extensions

help Update-TypeData
#install from the PSGallery
Import-Module PSTypeExtensionTools
Get-Command -Module PSTypeExtensionTools

Add-PSTypeExtension -TypeName system.io.fileinfo -MemberType AliasProperty -MemberName Size -Value Length
Add-PSTypeExtension -TypeName system.io.fileinfo -MemberType ScriptProperty -MemberName ModifiedAge -Value { New-TimeSpan -Start $this.lastwritetime -End (Get-Date) }

Get-PSTypeExtension system.io.fileinfo

dir c:\work -file | select Name, Size, ModifiedAge

# I incorporated into a module
psedit S:\ADReportingTools\types\aduser.types.ps1xml
Import-Module S:\ADReportingTools\ADReportingTools.psd1 -Force

Get-ADUser artd | Get-PSType | Get-PSTypeExtension
Get-ADUser -Filter "department -eq 'sales'" | select DN, Firstname, Lastname

# more reading -> https://jdhitsolutions.com/blog/powershell/8215/powershell-property-sets-to-the-rescue/

cls

#endregion

#region Custom Formatting

#create ps1xml files with custom format views
# https://github.com/jdhitsolutions/PSScriptTools/blob/master/docs/New-PSFormatXML.md
# Install-Module PSScriptTools

#create a custom view
$n = @{
    Properties = "Mode", "LastWriteTime", "ModifiedAge", "Size", "Name"
    GroupBy    = "Directory"
    ViewName   = "Age"
    Path       = ".\myfile.format.ps1xml"
}

#need a single object
Get-Item C:\work\Test.txt | New-PSFormatXML @n

psedit $n.path
Update-FormatData $n.path
dir c:\work -file | Format-Table -View age
cls

#create view for your module and custom objects
dir S:\ADReportingTools\formats
#here is a default view
psedit S:\ADReportingTools\formats\adsummary.format.ps1xml

Get-ADSummary

#use this from the PSScriptingTools module to discover defined views
Get-FormatView system.diagnostics.process

Get-Process | Format-Table view starttime

#in my AD module
Get-FormatView addomaincontrollerhealth
Get-ADDomainControllerHealth
Get-ADDomainControllerHealth | Format-Table -View info

cls
#endregion

#region Run Scripts from Anywhere

# script links to External Scripts
$env:path -split ";"

# install-script winfetch

#installing will update the path
Get-Command winfetch | Format-List Name, Source, CommandType

#this is a script but I can specify the name without the path!
winfetch
cls

psedit .\CreateScriptLinks.ps1

S:\CreateScriptLinks.ps1 -Path C:\scripts\GetExternalScripts.ps1

Get-Command -CommandType ExternalScript

GetExternalScripts

#see the links
dir "C:\Program Files\WindowsPowerShell\Scripts"

#delete the link
del "C:\Program Files\WindowsPowerShell\Scripts\GetExternalScripts.ps1"

GetExternalScripts
#but this still works
C:\scripts\GetExternalScripts.ps1

cls
#endregion
