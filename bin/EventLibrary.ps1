#############################
##                         ##
## Defines event handlers  ##
##                         ##
#############################

# Bring the main window to the front once loaded
$UI.Window.Add_Loaded({
    $This.Activate()
})

# OpenFileDialog for IntuneWinAppUtil
$UI.BrowseIntuneAppPath.Add_Click({

    # Use the windows forms openfiledialog window
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $env:SystemDrive
    $OpenFileDialog.filter = "IntuneWinAppUtil (IntuneWinAppUtil.exe)| IntuneWinAppUtil.exe"
    $Response = $OpenFileDialog.ShowDialog()

    # If not cancelled
    If ($Response -eq "OK")
    {
        # Select filename and full file path
        $UI.IntuneAppPath.Text = $OpenFileDialog.FileName
    }

})

# FolderBrowserDialog for Setup folder
$UI.BrowseSetupFolder.Add_Click({

    # Use the windows forms openfiledialog window
    $FolderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $Response = $FolderBrowserDialog.ShowDialog()

    # If not cancelled
    If ($Response -eq "OK")
    {
        # Select filename and full file path
        $UI.TextSetupFolder.Text = $FolderBrowserDialog.SelectedPath
    }

})

# OpenFileDialog for Setup file
$UI.BrowseSetupFile.Add_Click({

    # Use the windows forms openfiledialog window
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $UI.TextSetupFolder.Text
    $Response = $OpenFileDialog.ShowDialog()

    # If not cancelled
    If ($Response -eq "OK")
    {
        # Select filename and full file path
        $UI.TextSetupFile.Text = $OpenFileDialog.FileName
    }

})

# FolderBrowserDialog for Output folder
$UI.BrowseOutputFolder.Add_Click({

    # Use the windows forms openfiledialog window
    $FolderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $Response = $FolderBrowserDialog.ShowDialog()

    # If not cancelled
    If ($Response -eq "OK")
    {
        # Select filename and full file path
        $UI.TextOutputFolder.Text = $FolderBrowserDialog.SelectedPath
    }

})

# Run the IntuneWinAppUtil.exe
$UI.Package.Add_Click({
   
    $IntuneWinAppUtilPath = $UI.IntuneAppPath.Text
    $SetupFolder = $UI.TextSetupFolder.Text
    $SetupFile = $UI.TextSetupFile.Text
    $OutputFolder = $UI.TextOutputFolder.Text

    If (!(Test-Path $IntuneWinAppUtilPath))
    {
        $UI.DataSource[0] = "Error: '$IntuneWinAppUtilPath' is not a valid location'"
        $UI.DataSource[1] = "Red"
        Return
    }
    If (!(Test-Path $SetupFolder))
    {
        $UI.DataSource[0] = "Error: '$SetupFolder' is not a valid location'"
        $UI.DataSource[1] = "Red"
        Return
    }
    If (!(Test-Path $SetupFile))
    {
        $UI.DataSource[0] = "Error: '$SetupFile' is not a valid location'"
        $UI.DataSource[1] = "Red"
        Return
    }
    If (!(Test-Path $OutputFolder))
    {
        $UI.DataSource[0] = "Error: '$OutputFolder' is not a valid location'"
        $UI.DataSource[1] = "Red"
        Return
    }

    $UI.DataSource[0] = "Processing..."
    $UI.DataSource[1] = "Blue"

    Try
    {
        $Process = Start-Process -FilePath $IntuneWinAppUtilPath -ArgumentList "-c ""$SetupFolder"" -s ""$SetupFile"" -o ""$OutputFolder"" -q" -Wait -PassThru -ErrorAction Stop
        If ($Process.ExitCode -eq 0)
        {
            $UI.DataSource[0] = "Process exited with code 0...Success!"
            $UI.DataSource[1] = "Green"
        }
        Else
        {
            $UI.DataSource[0] = "Process exited with code $($Process.ExitCode)...Failed!"
            $UI.DataSource[1] = "Red"
        }
        Invoke-Item $OutputFolder
    }
    Catch
    {
        $UI.DataSource[0] = "Error: Could not start '$IntuneWinAppUtilPath'!"
        $UI.DataSource[1] = "Red"
    }

})

# text changed events to enable / disable the Package button
$UI.IntuneAppPath.Add_TextChanged({
    If ($This.Text -ne "" -and $UI.TextSetupFolder.Text -ne "" -and $UI.TextSetupFile.Text -ne "" -and $UI.TextOutputFolder.Text -ne "")
    {
        $UI.Package.IsEnabled = "True"
    }
    Else
    {
        $UI.Package.IsEnabled = $False
    }
})

$UI.TextSetupFolder.Add_TextChanged({
    If ($This.Text -ne "" -and $UI.IntuneAppPath.Text -ne "" -and $UI.TextSetupFile.Text -ne "" -and $UI.TextOutputFolder.Text -ne "")
    {
        $UI.Package.IsEnabled = "True"
    }
    Else
    {
        $UI.Package.IsEnabled = $False
    }
})

$UI.TextSetupFile.Add_TextChanged({
    If ($This.Text -ne "" -and $UI.IntuneAppPath.Text -ne "" -and $UI.TextSetupFolder.Text -ne "" -and $UI.TextOutputFolder.Text -ne "")
    {
        $UI.Package.IsEnabled = "True"
    }
    Else
    {
        $UI.Package.IsEnabled = $False
    }
})

$UI.TextOutputFolder.Add_TextChanged({
    If ($This.Text -ne "" -and $UI.IntuneAppPath.Text -ne "" -and $UI.TextSetupFolder.Text -ne "" -and $UI.TextSetupFile.Text -ne "")
    {
        $UI.Package.IsEnabled = "True"
    }
    Else
    {
        $UI.Package.IsEnabled = $False
    }
})

# Write the IntuneWinAppUtil path to registry for future retrieval
$UI.Window.Add_Closing({
    Set-ItemProperty -Path HKCU:\Software\SMSAgent\Win32ContentPrepUI -Name IntuneAppPath -Value $UI.IntuneAppPath.Text
})