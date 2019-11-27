###############################################
##                                           ##
##     Win32 Content Prep Tool for Intune    ##
##                                           ##
## Author:      Trevor Jones                 ##
## Blog:        smsagent.blog                ##
##                                           ##
###############################################


# Set the location we are running from
$Source = $PSScriptRoot

# Load the required assemblies
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Windows.Forms
Add-Type -Path "$Source\bin\System.Windows.Interactivity.dll"
Add-Type -Path "$Source\bin\ControlzEx.dll"
Add-Type -Path "$Source\bin\MahApps.Metro.dll"

# Load the main window XAML code
[XML]$Xaml = [System.IO.File]::ReadAllLines("$Source\Xaml\App.xaml") 

# Create a synchronized hash table and add the WPF window and its named elements to it
$UI = [System.Collections.Hashtable]::Synchronized(@{})
$UI.Window = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $xaml))
$xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | 
    ForEach-Object -Process {
        $UI.$($_.Name) = $UI.Window.FindName($_.Name)
    }

# Set the window icon from a file
$UI.Window.Icon = "$Source\bin\cloud.ico"

# Load in the other code libraries.
. "$Source\bin\EventLibrary.ps1"

# OC for data binding source
$UI.DataSource = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
$UI.DataSource.Add("Ready") # [0] Status bar text
$UI.DataSource.Add("Black") # [1] Status bar text colour

# Set the datacontext of the window to the OC for databinding
$UI.Window.DataContext = $UI.DataSource

# Create reg keys if needed and set the IntuneAppPath
If (!(Test-Path HKCU:\Software\SMSAgent))
{
    $null = New-Item -Path HKCU:\Software -Name SMSAgent
}
If (!(Test-Path HKCU:\Software\SMSAgent\Win32ContentPrepUI))
{
    $null = New-Item -Path HKCU:\Software\SMSAgent -Name Win32ContentPrepUI 
}
If (!(Get-ItemProperty -Path HKCU:\Software\SMSAgent\Win32ContentPrepUI -Name IntuneAppPath -ErrorAction SilentlyContinue))
{
    $null = New-ItemProperty -Path HKCU:\Software\SMSAgent\Win32ContentPrepUI -Name IntuneAppPath -PropertyType String
}
Else
{
    $UI.IntuneAppPath.Text = Get-ItemProperty -Path HKCU:\Software\SMSAgent\Win32ContentPrepUI -Name IntuneAppPath | Select -ExpandProperty IntuneAppPath
}

# Display the main window
# If code is running in ISE, use ShowDialog()...
if ($psISE)
{
    $null = $UI.window.Dispatcher.InvokeAsync{$UI.window.ShowDialog()}.Wait()
}
# ...otherwise run as an application
Else
{
    # Hide the PowerShell console window
    $windowcode = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
    $asyncwindow = Add-Type -MemberDefinition $windowcode -Name Win32ShowWindowAsync -Namespace Win32Functions -PassThru
    $null = $asyncwindow::ShowWindowAsync((Get-Process -PID $pid).MainWindowHandle, 0)
    
    # Run the main window in an application
    $app = New-Object -TypeName Windows.Application
    $app.Properties
    $app.Run($UI.Window)
}
