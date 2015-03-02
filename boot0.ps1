 Configuration Boot0 {
    node $env:COMPUTERNAME {
       script DevOpsDir {
          SetScript = {
             New-Item -Path 'C:\DevOps' -ItemType Directory
          }

          TestScript = {
             if(Test-Path -Path 'C:\DevOps') 
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
                'Result' = (Test-Path -Path 'C:\DevOps' -PathType Container)
             }
          }
       }
    
       Script GetBoot {
          SetScript = {
             (New-Object -TypeName System.Net.webclient).DownloadFile('https://raw.githubusercontent.com/mkey0bc/boot5/master/boot.ps1','C:\DevOps\boot.ps1')
             (New-Object -TypeName System.Net.webclient).DownloadFile('https://raw.githubusercontent.com/mkey0bc/boot5/master/boot2.ps1','C:\DevOps\boot2.ps1')
          }
          TestScript = {
             if((Test-Path -Path 'C:\DevOps\boot.ps1') -and (Test-Path -Path 'C:\DevOps\boot2.ps1'))
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
                'Result' = $((Test-Path -Path 'C:\DevOps\boot.ps1') -and (Test-Path -Path 'C:\DevOps\boot2.ps1'))
             }
          }
          DependsOn = '[Script]DevOpsDir'
       }
    
       Script GetWMF5 {
          SetScript = {
             (New-Object -TypeName System.Net.webclient).DownloadFile('http://cc527d412bd9bc2637b1-054807a7b8a5f81313db845a72a4785e.r34.cf1.rackcdn.com/WindowsBlue-KB3037315-x64.msu', 'C:\DevOps\WindowsBlue-KB3037315-x64.msu')
          }

          TestScript = {
             Test-Path -Path 'C:\DevOps\WindowsBlue-KB3037315-x64.msu'
          }

          GetScript = {
             return @{
                'Result' = $(Test-Path  -Path 'C:\DevOps\WindowsBlue-KB3037315-x64.msu')
             }
          }
          DependsOn = '[Script]DevOpsDir'
       }
   
       Script InstallWmf5 {
          SetScript = {
             Start-Process -Wait -FilePath 'C:\DevOps\WindowsBlue-KB3037315-x64.msu' -ArgumentList '/quiet'
          }
          TestScript = {
             if($PSVersionTable.PSVersion.Major -ge 5) 
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
                'Result' = $PSVersionTable.PSVersion.Major
             }
          }
          DependsOn = @('[Script]GetWMF5', '[Script]DevOpsDir', '[Script]CreateBootTask')
       }
   
       Script CreateBootTask {
          SetScript = {
             & schtasks.exe /create /sc Onstart /tn Boot /ru System /tr 'PowerShell.exe -ExecutionPolicy Bypass -file C:\DevOps\boot.ps1'
          }
          TestScript = {
             if(Get-ScheduledTask -TaskName 'Boot' -ErrorAction SilentlyContinue) 
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
          DependsOn = '[Script]DevOpsDir'
       }
    }
   }
   
 Boot0 -OutputPath 'C:\Windows\Temp'
 Start-DscConfiguration -Wait -Force -Path 'C:\Windows\Temp'