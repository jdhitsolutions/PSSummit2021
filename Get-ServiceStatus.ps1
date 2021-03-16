#requires -version 5.1

Function Get-ServiceStatus {
    [cmdletbinding()]
    Param([string]$Computername = $env:COMPUTERNAME)

    $p = @{
        Computername = $computername
        ClassName    = "Win32_service"
        Filter       = "StartMode ='Auto' AND State<>'Running'"

    }
    Get-CimInstance @p
}

Register-ArgumentCompleter -CommandName Get-ServiceStatus -ParameterName Computername -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-Content S:\company.txt | Where-Object {$_ -match "\w+"}  |
    ForEach-Object {
                                                            # completion text,listitem text,result type,Tooltip
        [System.Management.Automation.CompletionResult]::new($_.Trim(), $_.Trim(), 'ParameterValue', $_)
    }
}