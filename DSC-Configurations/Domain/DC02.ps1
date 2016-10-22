configuration DC02             
{             
   param             
    (             
        [Parameter(Mandatory)]             
        [pscredential]$safemodeAdministratorCred,             
        [Parameter(Mandatory)]            
        [pscredential]$domainCred            
    )             
            
    Import-DscResource -ModuleName xActiveDirectory, xDHCpServer             
            
    Node $AllNodes.Where{$_.Role -eq "Primary DC"}.Nodename             
    {             
            
        LocalConfigurationManager            
        {            
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyOnly'            
            RebootNodeIfNeeded = $true            
        }            
            
        File ADFiles            
        {            
            DestinationPath = 'N:\NTDS'            
            Type = 'Directory'            
            Ensure = 'Present'            
        }            
                    
        WindowsFeature ADDSInstall             
        {             
            Ensure = "Present"             
            Name = "AD-Domain-Services"             
        }            
            
        # Optional GUI tools            
        WindowsFeature ADDSTools            
        {             
            Ensure = "Present"             
            Name = "RSAT-ADDS"             
        }            
            
        # No slash at end of folder paths            
        xADDomain FirstDS             
        {             
            DomainName = $Node.DomainName             
            DomainAdministratorCredential = $domainCred             
            SafemodeAdministratorPassword = $safemodeAdministratorCred            
            DatabasePath = 'N:\NTDS'            
            LogPath = 'N:\NTDS'            
            DependsOn = "[WindowsFeature]ADDSInstall","[File]ADFiles"            
        }
        WindowsFeature DHCP
         {
            Name = 'DHCP'
            Ensure = 'Present'
         }

         xDhcpServerScope Scope 
         { 
             Ensure = 'Present'
             IPStartRange = '192.168.1.2' 
             IPEndRange = '192.168.1.30' 

             Name = 'Lundnet' 
             SubnetMask = '255.255.255.0' 
             LeaseDuration = '00:08:00' 
             State = 'Active' 
             AddressFamily = 'IPv4'
             DependsOn = '[WindowsFeature]DHCP'
         } 

         xDhcpServerOption Option 
         { 
             Ensure = 'Present' 
             ScopeID = '192.168.1.0' 
             DnsDomain = 'lundnet.local' 
             DnsServerIPAddress = '192.168.1.71','192.168.1.72' 
             AddressFamily = 'IPv4' 
             Router = '192.168.1.254'
             DependsOn = '[WindowsFeature]DHCP' 
         }             
            
    }             
}            
            
# Configuration Data for AD              
$ConfigData = @{             
    AllNodes = @(             
        @{             
            Nodename = "localhost"             
            Role = "Primary DC"             
            DomainName = "lundnet.local"             
            RetryCount = 20              
            RetryIntervalSec = 30            
            PsDscAllowPlainTextPassword = $true            
        }            
    )             
}             
            
lundnetDomain -ConfigurationData $ConfigData `
    -safemodeAdministratorCred (Get-Credential -UserName '(Password Only)' `
        -Message "New Domain Safe Mode Administrator Password") `
    -domainCred (Get-Credential -UserName lundnet\administrator `
        -Message "New Domain Admin Credential")            
            
# Make sure that LCM is set to continue configuration after reboot            
Set-DSCLocalConfigurationManager -Path .\DC02 –Verbose            
            
# Build the domain            
Start-DscConfiguration -Wait -Force -Path .\DC02 -Verbose