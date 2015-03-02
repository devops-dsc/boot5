Configuration myInit {
   Node $env:COMPUTERNAME {
      Import-DscResource -ModuleName xPSDesiredStateConfiguration

      Script GetMakeCert {
         SetScript = {
            (New-Object -TypeName System.Net.webclient).DownloadFile('http://76112b97f58772cd1bdd-6e9d6876b769e06639f2cd7b465695c5.r57.cf1.rackcdn.com/makecert.exe', 'C:\DevOps\makecert.exe')
         }

         TestScript = {
            Test-Path -Path 'C:\DevOps\makecert.exe' 
         }

         GetScript = {
            return @{
               'Result' = $(Test-Path  -Path 'C:\DevOps\makecert.exe')
            }
         }
      }

      Script InstallMakeCert {
         SetScript = {
            Copy-Item -Path 'C:\DevOps\makecert.exe' -Destination 'C:\Windows\System32' -Force
         }

         TestScript = {
            Test-Path -Path 'C:\Windows\System32\makecert.exe' 
         }

         GetScript = {
            return @{
               'Result' = $(Test-Path  -Path 'C:\Windows\System32\makecert.exe')
            }
         }

         DependsOn = '[Script]GetMakeCert'
      }

      WindowsFeature IIS {
         Ensure = 'Present'
         Name = 'Web-Server'
      }

  
      Script GetGit {
         SetScript = {
            (New-Object -TypeName System.Net.webclient).DownloadFile('https://raw.githubusercontent.com/rsWinAutomationSupport/Git/v1.9.4/Git-Windows-Latest.exe','C:\DevOps\Git-Windows-Latest.exe')
         }

         TestScript = {
            Test-Path -Path 'C:\DevOps\Git-Windows-Latest.exe' 
         }

         GetScript = {
            return @{
               'Result' = $(Test-Path  -Path 'C:\DevOps\Git-Windows-Latest.exe')
            }
         }
      }

      Script InstallGit {
         SetScript = {
            Start-Process -Wait -FilePath 'C:\DevOps\Git-Windows-Latest.exe' -ArgumentList '/verysilent'
         }

         TestScript = {
            if(Test-Path -Path 'C:\Program Files (x86)\Git\bin\git.exe') 
            {
               return $true 
            }
            else 
            {
               return $false 
            }
         }

         GetScript = {
            return @{
               'Result' = $(Test-Path -Path 'C:\Program Files (x86)\Git\bin\git.exe')
            }
         }
         DependsOn = '[Script]GetGit'
      }
   
      Script CreateServerCertificate {
         SetScript = {
            $yesterday = (Get-Date).AddDays(-1) | Get-Date -Format MM/dd/yyyy
            Get-ChildItem -Path Cert:\LocalMachine\My\ |
            Where-Object -FilterScript {
               $_.Subject -eq $('CN=', $env:COMPUTERNAME -join '')
            } |
            Remove-Item
            & makecert.exe -b $yesterday -r -pe -n $('CN=', $env:COMPUTERNAME -join ''), -ss my 'C:\DevOps\PullServer.crt', -sr localmachine, -len 2048
         }

         TestScript = {
            if((Get-ChildItem -Path Cert:\LocalMachine\My\ | Where-Object -FilterScript {
                     $_.Subject -eq $('CN=', $env:COMPUTERNAME -join '')
            }) -and (Test-Path -Path 'C:\DevOps\PullServer.crt')) 
            {
               return $true 
            }
            else 
            {
               return $false
            }
         }

         GetScript = {
            return @{
               'Result' = (Get-ChildItem -Path Cert:\LocalMachine\My\ | Where-Object -FilterScript {
                     $_.Subject -eq $('CN=', $env:COMPUTERNAME -join '')
                  }
               ).Thumbprint
            }
         }
      
         DependsOn = @('[Script]InstallMakeCert', '[WindowsFeature]IIS')
      }
   
      Script InstallRootCertificate {
         SetScript = {
            Get-ChildItem -Path Cert:\LocalMachine\Root\ |
            Where-Object -FilterScript {
               $_.Subject -eq $('CN=', $env:COMPUTERNAME -join '')
            } |
            Remove-Item
            & certutil.exe -addstore -f Root 'C:\DevOps\PullServer.crt'
         }

         TestScript = {
            if((Get-ChildItem -Path Cert:\LocalMachine\Root\ | Where-Object -FilterScript {
                     $_.Subject -eq $('CN=', $env:COMPUTERNAME -join '')
               }).Thumbprint -eq (Get-ChildItem -Path Cert:\LocalMachine\My\ | Where-Object -FilterScript {
                     $_.Subject -eq $('CN=', $env:COMPUTERNAME -join '')
                  }
            ).Thumbprint) 
            {
               return $true 
            }
            else 
            {
               return $false 
            }
         }

         GetScript = {
            return @{
               'Result' = (Get-ChildItem -Path Cert:\LocalMachine\Root\ | Where-Object -FilterScript {
                     $_.Subject -eq $('CN=', $env:COMPUTERNAME -join '')
                  }
               ).Thumbprint
            }
         }
         DependsOn = @('[Script]CreateServerCertificate', '[WindowsFeature]IIS')
      }
   
      File PublicPullServerCert {
         Ensure = 'Present'
         SourcePath = 'C:\DevOps\PullServer.crt'
         DestinationPath = 'C:\inetpub\wwwroot'
         MatchSource = $true
         Type = 'File'
         Checksum = 'SHA-256'
         DependsOn = @('[WindowsFeature]IIS', '[Script]CreateServerCertificate')
      }
   }
   
         WindowsFeature DSCServiceFeature
      {
         Ensure = "Present"
         Name = "DSC-Service"
      }
      
      xDscWebService PSDSCPullServer
      {
         Ensure = 'Present'
         EndpointName = 'PSDSCPullServer'
         Port = 8080
         PhysicalPath = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer"
         CertificateThumbPrint = (Get-ChildItem -Path Cert:\LocalMachine\My\ | where { $_.Subject -eq ('CN=', $env:COMPUTERNAME -join '') } ).thumbprint
         ModulePath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
         ConfigurationPath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
         State = "Started"
         DependsOn = @('[WindowsFeature]DSCServiceFeature', '[File]PublicPullServerCert')
      }
      
      xDscWebService PSDSCComplianceServer
      {
         Ensure = "Present"
         EndpointName = "PSDSCComplianceServer"
         Port = 9080
         PhysicalPath = "$env:SystemDrive\inetpub\wwwroot\PSDSCComplianceServer"
         CertificateThumbPrint = (Get-ChildItem -Path Cert:\LocalMachine\My\ | where { $_.Subject -eq ('CN=', $env:COMPUTERNAME -join '') } ).thumbprint
         State = "Started"
         IsComplianceServer = $true
         DependsOn = @('[WindowsFeature]DSCServiceFeature','[xDSCWebService]PSDSCPullServer')
      }
      
      
}


myInit -OutputPath 'C:\Windows\Temp'
Start-DscConfiguration -Path 'C:\Windows\Temp' -Verbose -Wait -Force