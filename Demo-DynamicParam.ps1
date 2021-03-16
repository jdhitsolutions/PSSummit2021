#will only get a credential parameter if computername contains Dom\d+

# help about_Functions_Advanced_Parameters
Function New-MySession {
  [cmdletbinding()]
  Param(
    [Parameter(Position = 0, Mandatory, ValueFromPipelinebyPropertyName)]
    [string]$Computername,
    [int32]$Port,
    [switch]$UseSSL,
    [ValidateSet("Kerberos", "Credssp", "Default")]
    [string]$Authentication
  )
  DynamicParam {
    if ($Computername -match 'Dom\d+$') {

      #define a parameter attribute object
      $attributes = New-Object System.Management.Automation.ParameterAttribute
      $attributes.ValueFromPipelineByPropertyName = $True
      $attributes.Mandatory = $True
      $attributes.HelpMessage = "Enter an alternate credential in the form domain\username or computername\username"

      #define a collection for attributes
      $attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
      $attributeCollection.Add($attributes)

      #define an alias
      $alias = New-Object System.Management.Automation.AliasAttribute -ArgumentList "runas"
      $attributeCollection.Add($alias)

      #define the dynamic param
      $dynParam1 = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("Credential", [PSCredential], $attributeCollection)
      #set a default value
      $dynParam1.Value = [System.Management.Automation.PSCredential]::Empty

      #create array of dynamic parameters
      $paramDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
      $paramDictionary.Add("Credential", $dynParam1)
      #use the array
      return $paramDictionary

    } #if
  } #dynamic parameter

  Process {

    Write-Host "Connecting to $computername" -ForegroundColor Cyan
    #  Enter-PSSession @PSBoundParameters

  }

}

