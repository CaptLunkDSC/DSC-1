
Describe "Domain Controller"  {

    It "Is Installed" {

        $Output = Get-WindowsFeature AD-Domain-Services

        $Output.InstallState | Should Be "Installed"

    }

    It "Is Installed" {

        $Output = Get-WindowsFeature RSAT-ADDS

        $Output.InstallState | Should Be "Installed"

    }

}


<#
Describe "ActiveDirectory Module" {

    It "Is Installed" {

        $Output = Get-WindowsFeature RSAT-AD-PowerShell

        $Output.InstallState | Should Be "Installed"

    }

}
#>