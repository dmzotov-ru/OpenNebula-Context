$swap_disk_number = 1
$swap_disk_letter = "S"
# This is the decimal representation of the S drive (swap) to pass to the registry setting
$disk_hidden = 262144 
$swap_disk_label = "SWAP"
$data_disk_label = "DATA"
function Set-PageFile {
  
    PARAM(
        [string]$Path = "C:\pagefile.sys",
        [int]$InitialSize = 512,
        [int]$MaximumSize = 512
    )
     
    $ComputerSystem = $null
    $CurrentPageFile = $null
    $modify = $false
 
    # Disables automatically managed page file setting first
    $ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem -EnableAllPrivileges
    if ($ComputerSystem.AutomaticManagedPagefile) {
        $ComputerSystem.AutomaticManagedPagefile = $false
        $ComputerSystem.Put()
    }
 
    $CurrentPageFile = Get-WmiObject -Class Win32_PageFileSetting
    if ($CurrentPageFile.Name -eq $Path) {
        # Keeps the existing page file
        if ($CurrentPageFile.InitialSize -ne $InitialSize) {
            $CurrentPageFile.InitialSize = $InitialSize
            $modify = $true
        }
        if ($CurrentPageFile.MaximumSize -ne $MaximumSize) {
            $CurrentPageFile.MaximumSize = $MaximumSize
            $modify = $true
        }
        if ($modify) { $CurrentPageFile.Put() }
    }
    else {
        # Creates a new page file
        $CurrentPageFile.Delete()
        Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{Name=$Path; InitialSize = $InitialSize; MaximumSize = $MaximumSize}
    }
}


$raw_disks = Get-Disk | Where-Object -FilterScript {$_.PartitionStyle -eq "RAW"}

foreach ($disk_number in $raw_disks.Number){
    if ($disk_number -eq $swap_disk_number){
        $drive_letter_option = @{DriveLetter = $swap_disk_letter}
        $disk_label = $swap_disk_label
        $swap_disk = $true
    }
    else {
        $drive_letter_option = @{AssignDriveLetter = $true}
        $disk_label = $data_disk_label
        $swap_disk = $false
    }
        Initialize-Disk -Number $disk_number -PartitionStyle GPT
        New-Partition -DiskNumber $disk_number @drive_letter_option -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel $disk_label
    if ($swap_disk){
        [int]$pagefile_size = (Get-Partition $disk_number -PartitionNumber 2).Size / 100 * 95 / 1MB
        Set-PageFile "${swap_disk_letter}:\pagefile.sys" $pagefile_size $pagefile_size
        Set-ItemProperty -path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -name NoDrives -value $disk_hidden -type DWORD
        Add-Type -AssemblyName System.Windows.Forms
        $global:balmsg = New-Object System.Windows.Forms.NotifyIcon
        $path = (Get-Process -id $pid).Path
        $balmsg.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
        $balmsg.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
        $balmsg.BalloonTipText = "Параметры файла подкачки изменены. Перезагрузите, пожалуйста, виртуальную машину"
        $balmsg.BalloonTipTitle = "Требуется перезагрузка"
        $balmsg.Visible = $true
        $balmsg.ShowBalloonTip(30000)
    }
}
