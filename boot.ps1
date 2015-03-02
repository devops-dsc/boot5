[DSCLocalConfigurationManager()]
Configuration PullServerLCM
{
   
   Node $env:COMPUTERNAME
   {
      Settings
      {
         ActionAfterReboot = 'ContinueConfiguration'
         RebootNodeIfNeeded = $true
         ConfigurationMode = 'ApplyAndAutoCorrect'
         RefreshMode = 'Push'
         ConfigurationModeFrequencyMins = 30
         AllowModuleOverwrite = $true
      }
   }
}

Configuration Boot {
   Node $env:COMPUTERNAME {
      script GetxPSDesiredstateConfiguration {
         SetScript = {
            Install-Package -Name 'xPSDesiredStateConfiguration' -Force
         }
      
         TestScript = {
            if((Get-Package -Name 'xPSDesiredStateConfiguration' -ErrorAction SilentlyContinue).Status -eq 'Installed') 
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
               'Result' = (Get-Package -Name 'xPSDesiredStateConfiguration' -ErrorAction SilentlyContinue).Status
            }
         }
      }

   
      <#script InstallNuget {
         SetScript = {
         register-packagesource -Name 'NugetPackageManager' -Provider PSModule -Trusted -Location http://chocolatey.org/api/v2/ -Verbose
         Install-Package -Name 'NugetPackageManager' -Force
         }
      
         TestScript = {
         if((Get-Package -Name 'NugetPackageManager' -ErrorAction SilentlyContinue).Status -eq 'Installed') 
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
            'Result' = (Get-Package -Name 'NugetPackageManager' -ErrorAction SilentlyContinue).Status
         }
         }
      }#>
   
   
      Script RemoveBootTask {
         SetScript = {
            & schtasks.exe /Delete /TN Boot /F
         }
         TestScript = {
            if(!(Get-ScheduledTask -TaskName 'Boot' -ErrorAction SilentlyContinue))
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
               'Result' = $((Get-ScheduledTask -TaskName 'Boot' -ErrorAction SilentlyContinue).State)
            }
         }
      }
   }
}


PullServerLCM -OutputPath 'C:\Windows\Temp'
Set-DscLocalConfigurationManager -Path 'C:\Windows\Temp'
Boot -OutputPath 'C:\Windows\Temp'
Start-DscConfiguration -Path 'C:\Windows\Temp' -Verbose -Wait -Force 
Invoke-Expression -Command 'C:\DevOps\boot2.ps1'