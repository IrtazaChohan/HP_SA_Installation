# #############################################################################
# NAME: HP_SA_Install.ps1
# 
# AUTHOR:  Irtaza Chohan
# DATE:  18/06/2015
# 
# COMMENT:  This script will install HP SA - if an IP address is entered then it will process that; ensure that the IP entered is a HP SA server which is contactable otherwise the install of HP SA will fail.
#           If there is no IP entered then the install will install the dormant version of HP SA.
#
# VERSION HISTORY
# 1.0 18/06/2015 Initial Version.
# 2.0 01/02/2017 Updated to cater for Windows Server 2012 R2 binaries
#
# #############################################################################

Param(
  [string]$SA_Server1
)

function writelog([string]$result, [string]$logfile) {
    try {
        $objlogfile = new-object system.io.streamwriter("c:\buildlog\complogs\$logfile", [System.IO.FileMode]::Append)
        $objlogfile.writeline("$((Get-Date).ToString()) : $result")
        write-host (Get-Date).ToString() " : $result"  -foregroundcolor yellow
        $objlogfile.close()
    } catch [Exception] {
        Write-Host $result -foregroundcolor red
        $error.clear()
   }
} 

$log = "HP_SA_Install_x64_RU2017.log"
$ScriptName = $MyInvocation.MyCommand.Name

    writelog "================================" $log
    writelog "$ScriptName Script Started" $log
    writelog "--------------------------------" $log


#Putting this error preference in to suppress the error that test-path displays
$ErrorActionPreference = "SilentlyContinue"

#Create folder to store HP SA Log file
New-Item C:\buildlog\HP_SA -type directory -ErrorAction SilentlyContinue

$loggingfile = Get-item C:\buildlog\HP_SA\*.log -ErrorAction SilentlyContinue

If (Test-Path $loggingfile -ErrorAction Ignore)
{
	writelog "Removing older HP_SA log file" $log
    Remove-Item $loggingfile
}
else {
    writelog "Existing log file for HP SA not found - Continuing installation" $log
}

#Resetting error preference back to the default value
$ErrorActionPreference = "Continue"

function checkIP([string]$IP){
    
    Try {
        # Checking for correct formation of IP Address    
        $Correct = $True
        [array]$Serv1 = $IP.split(‘.’)
    
           if ($Serv1.length -ne 4) {
                writelog "ERROR: The IP entered is not valid. IP entered was: $SA_Server1” $log
                throw “The IP entered is not valid. IP entered was: $SA_Server1” 
                $Correct = $False                          
            }
         }
     Catch {
        $Error[0]
        Exit -1
     }      
}

function checkDiskSpace(){

   Try {
        #Lets see how much disk space is available
        $diskspace = Get-Ciminstance win32_logicaldisk | where {$_.name -eq "C:"} | select size
        $calculate = [Math]::Round($diskspace.Size /1MB)

        If ($calculate -lt "50"){
            
            writelog "ERROR: There is not enough disk space to proceed with installation - it needs at least 50MB free to install; do you seriously not have 50MB free?!" $log
            throw "There is not enough disk space to proceed with installation"
            }             
        else {
             writelog "There is enough disk space - the amount is: $calculate" $log
             }
    }
    Catch {
        $Error[0]
        Exit -1
    }
}

function portFree(){

    Try {
            #We need to see if port 1002 is free
            $netstat = netstat -ano
            $checkport = $netstat | Select-String "1002"

                If($checkport -eq $null){
                    
                    writelog "Port 1002 is free" $log
                }
                else {
                    writelog "ERROR: Port 1002 is in use - this port must be free for this product to be installed" $log
                    throw "Port 1002 is in use - this port must be free for this product to be installed"
                }
        }
    Catch {

        $Error[0]
        Exit -1
    }
}

function OSandInstallIP([string]$IP){
    
    Try{
     
        $ScriptPath = $PSScriptRoot
        #Let's determine the OS version to install
        $OSver = (Get-CimInstance Win32_OperatingSystem).version
        $OSShort = $OSver.Substring(0,3)
        #check if it is 32-bit or 64-bit
        $architectureVersion = (Get-CimInstance Win32_Processor -Filter "DeviceID='CPU0'").AddressWidth
        
        $OSShort | ForEach-Object{

        switch -Wildcard ($_)
        {
             "6.3"{
                    writelog "This is Windows Server 2012 R2 - Version found is: $($_)" $log
                    If($architectureVersion -eq "64"){
                    writelog "64-bit architecture found" $log
                    Start-Process "$ScriptPath\opsware-agent-60.0.70957.3-win32-6.3-X64.exe" -ArgumentList "-s","--logfile","C:\buildlog\HP_SA\HP_SA_install.log","--loglevel", "info","--withmsi","--opsw_gw_addr_list","$IP","--force_new_device" -Wait
                    checkfile
                    }
            }
            "6.1"{
                    writelog "This is Windows Server 2008 R2 SP1 - Version found is: $($_)" $log
                    If($architectureVersion -eq "64"){
                    writelog "64-bit architecture found" $log
                    Start-Process "$ScriptPath\opsware-agent-60.0.70957.3-win32-6.1-X64.exe" -ArgumentList "-s","--logfile","C:\buildlog\HP_SA\HP_SA_install.log","--loglevel", "info","--withmsi","--opsw_gw_addr_list","$IP","--force_new_device" -Wait
                    checkfile
                    }
                  }
            "6.0"{
                    writelog "This is Windows Server 2008 SP2 - Version found is: $($_)" $log
                    If($architectureVersion -eq "64"){
                        writelog "64-bit architecture found" $log
                        Start-Process "$ScriptPath\opsware-agent-60.0.70957.3-win32-6.0-X64.exe" -ArgumentList "-s","--logfile","C:\buildlog\HP_SA\HP_SA_install.log","--loglevel", "info","--withmsi","--opsw_gw_addr_list","$IP","--force_new_device" -Wait
                        checkfile
                    }
                    else{
                        writelog "32-bit architecture found" $log
                        Start-Process "$ScriptPath\opsware-agent-60.0.70957.3-win32-6.0.exe" -ArgumentList "-s","--logfile","C:\buildlog\HP_SA\HP_SA_install.log","--loglevel", "info","--withmsi","--opsw_gw_addr_list","$IP","--force_new_device" -Wait
                        checkfile
                    }
                  }
            "5.2"{
                   Write-Host "This is Windows Server 2003 - Version found is: $($_)"
                    If($architectureVersion -eq "64"){
                        writelog "64-bit architecture found" $log
                        Start-Process "$ScriptPath\opsware-agent-60.0.70957.3-win32-5.2-X64.exe" -ArgumentList "-s","--logfile","C:\buildlog\HP_SA\HP_SA_install.log","--loglevel", "info","--withmsi","--opsw_gw_addr_list","$IP","--force_new_device" -Wait
                        checkfile
                    }
                    else{
                        writelog "32-bit architecture found" $log
                        Start-Process "$ScriptPath\opsware-agent-60.0.70957.3-win32-5.2.exe" -ArgumentList "-s","--logfile","C:\buildlog\HP_SA\HP_SA_install.log","--loglevel", "info","--withmsi","--opsw_gw_addr_list","$IP","--force_new_device" -Wait
                        checkfile
                    }
            }
         }
        }
      }
     Catch{

     writelog "Error occurred in installation of agent" $log
     $Error[0]
     Exit -1
     } 
}

function OSandInstallDormant(){

    Try{
     
        $ScriptPath = $PSScriptRoot
        #Let's determine the OS version to install
        $OSver = (Get-CimInstance Win32_OperatingSystem).version
        $OSShort = $OSver.Substring(0,3)
        #check if it is 32-bit or 64-bit
        $architectureVersion = (Get-CimInstance Win32_Processor -Filter "DeviceID='CPU0'").AddressWidth
        
        $OSShort | ForEach-Object{

        switch -Wildcard ($_)
        {
             "6.3"{
                    writelog "This is Windows Server 2012 R2 - Version found is: $($_)" $log
                    If($architectureVersion -eq "64"){
                    writelog "64-bit architecture found" $log
                    Start-Process "$ScriptPath\opsware-agent-60.0.70957.3-win32-6.3-X64.exe" -ArgumentList "-s","--logfile","C:\buildlog\HP_SA\HP_SA_install.log","--loglevel", "info","--withmsi","--opsw_gw_addr_list","$IP","--force_new_device" -Wait
                    checkfile
                    }
            }
            "6.1"{
                    writelog "This is Windows Server 2008 R2 SP1 - Version found is: $($_)" $log
                    If($architectureVersion -eq "64"){
                    writelog "64-bit architecture found" $log
                    Start-Process "$ScriptPath\opsware-agent-60.0.70957.3-win32-6.1-X64.exe" -ArgumentList "-f", "-s", "--withmsi", "--no_opsw_gw", "--logfile", "C:\buildlog\HP_SA\HP_SA_install.log", "--loglevel", "info" -Wait
                    checkfile
                    }
                  }
            "6.0"{
                    writelog "This is Windows Server 2008 SP2 - Version found is: $($_)" $log
                    If($architectureVersion -eq "64"){
                        writelog "64-bit architecture found" $log
                        Start-Process "$ScriptPath\opsware-agent-60.0.70957.3-win32-6.0-X64.exe" -ArgumentList "-f", "-s", "--withmsi", "--no_opsw_gw", "--logfile", "C:\buildlog\HP_SA\HP_SA_install.log", "--loglevel", "info" -Wait
                        checkfile
                    }
                    else{
                        writelog "32-bit architecture found" $log
                        Start-Process "$ScriptPath\opsware-agent-60.0.70957.3-win32-6.0.exe" -ArgumentList "-f", "-s", "--withmsi", "--no_opsw_gw", "--logfile", "C:\buildlog\HP_SA\HP_SA_install.log", "--loglevel", "info" -Wait
                        checkfile
                    }
                  }
            "5.2"{
                   writelog "This is Windows Server 2003 - Version found is: $($_)" $log
                    If($architectureVersion -eq "64"){
                        writelog "64-bit architecture found" $log
                        Start-Process "$ScriptPath\opsware-agent-60.0.70957.3-win32-5.2-X64.exe" -ArgumentList "-f", "-s", "--withmsi", "--no_opsw_gw", "--logfile", "C:\buildlog\HP_SA\HP_SA_install.log", "--loglevel", "info" -Wait
                        checkfile
                    }
                    else{
                        writelog "32-bit architecture found" $log
                        Start-Process "$ScriptPath\opsware-agent-60.0.70957.3-win32-5.2.exe" -ArgumentList "-f", "-s", "--withmsi", "--no_opsw_gw", "--logfile", "C:\buildlog\HP_SA\HP_SA_install.log", "--loglevel", "info" -Wait
                        checkfile
                    }
            }
         }
        }
      }
     Catch{

     writelog "Error occurred in installation of agent" $log
     $Error[0]
     Exit -1
     } 

}

function checkfile(){
      
      Try {
            #We check the log file for any errors at install time and if so then stop the install
            $loggingfile = Get-item C:\buildlog\HP_SA\*.log
            $checkfile = $loggingfile | ? { ($_ | Select-String "No gateway address was specified")}
               if($checkfile -eq $null){
                     writelog "Installation succeeded" $log
               }
                 else{
                     writelog "***ERROR: Installation failed - the gateway entered is not contactable***" $log
                     writelog "***ERROR: Please check error logs for the failure for HP SA - found in C:\buildlog\HP_SA***" $log
                     throw "Installation failed - the gateway entered is not contactable"
              }
        }
      Catch {

      $Error[0]
      Exit -1

      }
}


If ($SA_Server1 -ne "") {

    writelog "IP/FQDN has been entered - proceeding with Live Installation of HP SA" $log
    #checkIP $SA_Server1
    checkDiskSpace
    #portFree
    OSandInstallIP $SA_Server1
}
else {

    writelog "No IP entered so proceeding with Dormant Installation of HP SA" $log
    checkDiskSpace
    #portFree
    OSandInstallDormant
}

writelog "$ScriptName Script ended" $log
writelog "==============================" $log
