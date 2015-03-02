description: 'HEAT template for configuring Pull Server'
heat_template_version: '2014-10-16'
outputs:
   public_ip:
       description: public IP of the windows server
       value:
           get_attr: [rs_pull_server, accessIPv4]
   admin_password:
       value: { get_attr: [ rs_pull_server, admin_pass] }
       description: Administrator Password
parameters:
   flavor:
       constraints:
       -   allowed_values: [1 GB Performance, 2 GB Performance, 4 GB Performance,
               8 GB Performance, 15 GB Performance]
           description: must be a valid Rackspace Cloud Server flavor.
       default: 2 GB Performance
       description: Rackspace Cloud Server flavor
       type: string
   image:
        constraints:
        -   allowed_values: [Windows Server 2012, Windows Server 2012 R2]
            description: Windows Server Image
        default: Windows Server 2012 R2
        type: string
        description: Windows Server Image
   pullserver_hostname:
       constraints:
       -   length: {max: 15, min: 1}
       default: CIPullServer
       description: Windows Server Name
       type: string
resources:
 rs_pull_server:
   type: Rackspace::Cloud::WinServer
   properties:
     flavor: {get_param: flavor}
     image: {get_param: image}
     name: {get_param: pullserver_hostname}
     metadata: 
       rax_dsc_config: rsPullServer.ps1
       build_config: core
     save_admin_pass: true
     user_data: |
      if(!(Test-Path -Path 'C:\DevOps')) { New-Item -ItemType Directory -Path 'C:\DevOps' -Force }
      (New-Object System.Net.webclient).DownloadFile('https://raw.githubusercontent.com/mkey0bc/boot5/master/boot0.ps1','C:\DevOps\boot0.ps1')
      Set-Content -Path "C:\DevOps\DevOpsBoot.cmd" -Value "Powershell.exe Set-ExecutionPolicy Bypass -Force; Powershell.exe ""C:\DevOps\boot0.ps1"""
      start "C:\DevOps\DevOpsBoot.cmd"
