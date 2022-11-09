<#PSScriptInfo

.VERSION 4.1

.GUID 089016c8-4c80-4909-8a24-ef0cf62f9de0

.AUTHOR Aaron Guilmette

.COMPANYNAME Microsoft

.COPYRIGHT 2020

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

.DESCRIPTION 
Remove email addresses matching specified patterns from Exchange recipients.

.PRIVATEDATA

#>

<#
.SYNOPSIS 
Use this script to remove patterns from Exchange recipients (contacts, mailusers,
and usermailboxes).  This can be useful for removing proxy address patterns for objects
that are going to be migrated to another forest or Office 365.

.PARAMETER OU
Select a specific organizational unit to process.

.PARAMETER RecipientTypes
Select what types of objects to run against.

.PARAMETER ResultSize
Select number of objects of each recipient type to process.

.PARAMETER Identity
Run against a single identity (for testing purposes).

.PARAMETER StringsToRemove
Values that you want to remove from objects.  Can be a single item or an array of items:
CCMAIL,tailspintoys.com,fabrikam.com

Or, it can be passed in as an array/variable:
$Remove = @('CCMAIL:','tailspintoys.com','fabrikam.com')
-StringsToRemove $Remove

.EXAMPLE
.\Remove-ExchangeProxyAddresses.ps1 -Identity adelev@contoso.com -StringsToRemove "@fabrikam.com"
Removes string '@fabrikam.com' inside of proxy address array for adelev@contoso.com.

.EXAMPLE
$Remove = @("CCMAIL:","fabrikam.com")
.\Remove-ExchangeProxyAddresses.ps1 -StringsToRemove $Remove
Removes strings "CCMAIL:" and "fabrikam.com" from all recipient types.

.EXAMPLE
$Remove = @("CCMAIL:","fabrikam.com")
.\Remove-ExchangeProxyAddresses.ps1 -StringsToRemove $Remove -RecipientTypes Mailbox
Removes strings "CCMAIL:" and "fabrikam.com" from only mailboxes.

.NOTES
Author: aaron.guilmette@microsoft.com

2020-04-20 - Updated for PowerShell Gallery.
2019-08-12 - Updated with -OU parameter to allow filtering based on OU.
2019-05-09 - Updated to include RemoteUserMailbox types.
2018-09-08 - Updated logging capability.
           - Resolved issue regarding Get-Mailbox when user identity was not specified
2018-08-24 - Updated casting for $mailboxes, $mailusers, and $contacts
			 Updated examples
			 Updated RecipientTypes validate set
2017-09-05 - Updated with blog post detail data
2017-02-10 - Initial release
#>

PARAM(
	[ValidateSet("Mailbox", "MailUser", "MailContact","RemoteUserMailbox","DistributionGroup")]
	[array]$RecipientTypes = @("Mailbox", "MailUser", "MailContact","RemoteUserMailbox","DistributionGroup"),
	[ValidatePattern("^([1-9]|[1-9][0-9]|[1-9][0-9][0-9]|[1-9][0-9][0-9][0-9]|[1-9][0-9][0-9][0-9][0-9]|[1-9][0-9][0-9][0-9][0-9][0-9]|Unlimited)$")]
	$ResultSize = "Unlimited",
	[string]$Identity,
	[string]$Logfile = (Get-Date -Format yyyy-MM-dd) + "_Remove-ProxyAddresses.txt",
	[string]$OU,
	[array]$StringsToRemove
)

## Functions
# Logging function
function Write-Log([string[]]$Message, [string]$LogFile = $Script:LogFile, [switch]$ConsoleOutput, [ValidateSet("SUCCESS", "INFO", "WARN", "ERROR", "DEBUG")][string]$LogLevel)
{
	$Message = $Message + $Input
	If (!$LogLevel) { $LogLevel = "INFO" }
	switch ($LogLevel)
	{
		SUCCESS { $Color = "Green" }
		INFO { $Color = "White" }
		WARN { $Color = "Yellow" }
		ERROR { $Color = "Red" }
		DEBUG { $Color = "Gray" }
	}
	if ($Message -ne $null -and $Message.Length -gt 0)
	{
		$TimeStamp = [System.DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss")
		if ($LogFile -ne $null -and $LogFile -ne [System.String]::Empty)
		{
			Out-File -Append -FilePath $LogFile -InputObject "[$TimeStamp] [$LogLevel] $Message"
		}
		if ($ConsoleOutput -eq $true)
		{
			Write-Host "[$TimeStamp] [$LogLevel] :: $Message" -ForegroundColor $Color
		}
	}
}

Foreach ($Type in $RecipientTypes)
{
	Switch ($Type)
	{
		RemoteUserMailbox
		{
			if ($Identity)
			{
				Try
				{
					[array]$mailboxes = Get-RemoteMailbox -Identity $Identity
				}
				Catch
				{
					$Message = $Error.Exception.Message.ToString()
					Write-Log -LogFile $Logfile -Message $Message -ConsoleOutput -LogLevel ERROR
				}
			}
			else
			{
				# Define Params
				$params = @{ }
				If ($OU) { $params.Add('OnPremisesOrganizationalUnit', $($OU)) }
				If ($ResultSize) { $params.Add('ResultSize',$ResultSize)}
				[array]$mailboxes = Get-RemoteMailbox @params
				Write-Log -LogFile $Logfile -Message "Procesing $($mailboxes.Count) Mailbox objects." -ConsoleOutput -LogLevel INFO
			}
			ForEach ($mailbox in $mailboxes)
			{
				$Error.Clear()
				Write-Log -Message "Processing $($mailbox.PrimarySmtpAddress)" -LogFile $Logfile -LogLevel INFO -ConsoleOutput
				For ($i = ($mailbox.EmailAddresses.count) - 1; $i -ge 0; $i--)
				{
					Foreach ($string in $StringsToRemove)
					{
						$address = $mailbox.EmailAddresses[$i]
						$ProxyAddressString = $address.ProxyAddressString
						If ($ProxyAddressString -like "*$string*")
						{
							Write-Log -LogFile $Logfile -Message "Attempting to remove address $($ProxyAddressString)." -ConsoleOutput -LogLevel INFO
							Try
							{
								$mailbox.EmailAddresses.removeat($i)
							}
							Catch
							{
								$Message = $Error.Exception.Message.ToString()
								Write-Log -LogFile $Logfile -Message "Error removing $($ProxyAddressString) from $($mailbox.PrimarySmtpAddress) address array." -LogLevel ERROR -ConsoleOutput
								Write-Log -LogFile $Logfile -Message $Message -LogLevel DEBUG
							}
						}
					}
					Try
					{
						$mailbox | Set-RemoteMailbox -EmailAddresses $mailbox.EmailAddresses
					}
					Catch
					{
						Write-Log -LogFile $Logfile -Message "Error removing $($ProxyAddressString) from $($mailbox.PrimarySmtpAddress)." -LogLevel ERROR -ConsoleOutput
						$Message = $Error.Exception.Message.ToString()
						Write-Log -LogFile $Logfile -Message $Message -LogLevel DEBUG
					}
				}
				$Error.Clear()
			}
		} # End RemoteUserMailbox
		
		Mailbox
		{
			if ($Identity)
			{
				Try
				{
					[array]$mailboxes = Get-Mailbox -Identity $Identity
				}
				Catch
				{
					$Message = $Error.Exception.Message.ToString()
					Write-Log -LogFile $Logfile -Message $Message -ConsoleOutput -LogLevel ERROR
				}
			}
			else
			{
				$params = @{ }
				If ($OU) { $params.Add('OrganizationalUnit', $($OU)) }
				If ($ResultSize) { $params.Add('ResultSize', $ResultSize) }
				[array]$mailboxes = Get-Mailbox @params
				Write-Log -LogFile $Logfile -Message "Procesing $($mailboxes.Count) Mailbox objects." -ConsoleOutput -LogLevel INFO
			}
			ForEach ($mailbox in $mailboxes)
			{
				$Error.Clear()
				Write-Log -Message "Processing $($mailbox.PrimarySmtpAddress)" -LogFile $Logfile -LogLevel INFO -ConsoleOutput
				For ($i = ($mailbox.EmailAddresses.count) - 1; $i -ge 0; $i--)
				{
					Foreach ($string in $StringsToRemove)
					{
						$address = $mailbox.EmailAddresses[$i]
						$ProxyAddressString = $address.ProxyAddressString
						If ($ProxyAddressString -like "*$string*")
						{
							Write-Log -LogFile $Logfile -Message "Attempting to remove address $($ProxyAddressString)." -ConsoleOutput -LogLevel INFO
							Try
							{
								$mailbox.EmailAddresses.removeat($i)
							}
							Catch
							{
								$Message = $Error.Exception.Message.ToString()
								Write-Log -LogFile $Logfile -Message "Error removing $($ProxyAddressString) from $($mailbox.PrimarySmtpAddress) address array." -LogLevel ERROR -ConsoleOutput
								Write-Log -LogFile $Logfile -Message $Message -LogLevel DEBUG
							}
						}
					}
					Try
					{
						$mailbox | Set-Mailbox -EmailAddresses $mailbox.EmailAddresses
					}
					Catch
					{
						Write-Log -LogFile $Logfile -Message "Error removing $($ProxyAddressString) from $($mailbox.PrimarySmtpAddress)." -LogLevel ERROR -ConsoleOutput
						$Message = $Error.Exception.Message.ToString()
						Write-Log -LogFile $Logfile -Message $Message -LogLevel DEBUG						
					}
				}
				$Error.Clear()
			}
		} # End Mailbox
		MailUser
		{
			If ($Identity)
			{
				Try
				{
					[array]$mailusers = Get-MailUser -Identity $Identity
				}
				Catch
				{
					$Message = $Error.Exception.Message.ToString()
					Write-Log -LogFile $Logfile -Message $Message -ConsoleOutput -LogLevel ERROR	
				}
			}
			else
			{
				$params = @{ }
				If ($OU) { $params.Add('OrganizationalUnit', $($OU)) }
				If ($ResultSize) { $params.Add('ResultSize', $ResultSize) }
				[array]$mailusers = Get-MailUser -Resultsize $Resultsize
				Write-Log -LogFile $Logfile -Message "Procesing $($mailusers.Count) MailUser objects." -ConsoleOutput -LogLevel INFO
			}
			
			ForEach ($mailuser in $mailusers)
			{
				$Error.Clear()
				Write-Log -Message "Processing $($Mailuser.PrimarySmtpAddress)" -LogFile $Logfile -LogLevel INFO -ConsoleOutput
				For ($i = ($mailuser.EmailAddresses.count) - 1; $i -ge 0; $i--)
				{
					Foreach ($string in $StringsToRemove)
					{
						$address = $mailuser.EmailAddresses[$i]
						$ProxyAddressString = $address.ProxyAddressString
						If ($ProxyAddressString -like "*$string*")
						{
							Write-Log -LogFile $Logfile -Message "Attempting to remove address $($ProxyAddressString)." -ConsoleOutput -LogLevel INFO
							Try
							{
								$mailuser.EmailAddresses.removeat($i)
							}
							Catch
							{
								$Message = $Error.Exception.Message.ToString()
								Write-Log -LogFile $Logfile -Message "Error removing $($ProxyAddressString) from $($mailuser.PrimarySmtpAddress) address array." -LogLevel ERROR -ConsoleOutput
								Write-Log -LogFile $Logfile -Message $Message -LogLevel DEBUG
							}
						}
					}
					try
					{
						$mailuser | Set-Mailuser -EmailAddresses $mailuser.EmailAddresses
					}
					catch
					{
						Write-Log -LogFile $Logfile -Message "Error removing $($ProxyAddressString) from $($mailuser.PrimarySmtpAddress)." -LogLevel ERROR -ConsoleOutput
						$Message = $Error.Exception.Message.ToString()
						Write-Log -LogFile $Logfile -Message $Message -LogLevel DEBUG
					}
				}
				$Error.Clear()
			}
		} # End MailUser
		MailContact
		{
			If ($Identity)
			{
				try
				{
					[array]$contacts = Get-MailContact -Identity $Identity 
				}
				catch
				{
					$Message = $Error.Exception.Message.ToString()
					Write-Log -LogFile $Logfile -Message $Message -ConsoleOutput -LogLevel ERROR
				}
			}
			else
			{
				$params = @{ }
				If ($OU) { $params.Add('OrganizationalUnit', $($OU)) }
				If ($ResultSize) { $params.Add('ResultSize', $ResultSize) }
				[array]$contacts = Get-MailContact @params -wa SilentlyContinue -ea SilentlyContinue
				Write-Log -LogFile $Logfile -Message "Procesing $($contacts.Count) MailUser objects." -ConsoleOutput -LogLevel INFO
			}
			ForEach ($contact in $contacts)
			{
				$Error.Clear()
				Write-Log -Message "Processing $($contact.PrimarySmtpAddress)" -LogFile $Logfile -LogLevel INFO -ConsoleOutput
				For ($i = ($contact.EmailAddresses.count) - 1; $i -ge 0; $i--)
				{
					Foreach ($string in $StringsToRemove)
					{
						$address = $contact.EmailAddresses[$i]
						$ProxyAddressString = $address.ProxyAddressString
						If ($ProxyAddressString -like "*$string*")
						{
							Write-Log -LogFile $Logfile -Message "Attempting to remove address $($ProxyAddressString)." -ConsoleOutput -LogLevel INFO
							try
							{
								$contact.EmailAddresses.removeat($i)
							}
							catch
							{
								$Message = $Error.Exception.Message.ToString()
								Write-Log -LogFile $Logfile -Message "Error removing $($ProxyAddressString) from $($contact.PrimarySmtpAddress) address array." -LogLevel ERROR -ConsoleOutput
								Write-Log -LogFile $Logfile -Message $Message -LogLevel DEBUG
							}
						}
					}
					try
					{
						$contact | Set-MailContact -EmailAddresses $contact.EmailAddresses
					}
					catch
					{
						$Message = $Error.Exception.Message.ToString()
						Write-Log -LogFile $Logfile -Message "Error removing $($ProxyAddressString) from $($contact.PrimarySmtpAddress)." -LogLevel ERROR -ConsoleOutput
						Write-Log -LogFile $Logfile -Message $Message -LogLevel DEBUG
					}
				}
			}
		} # End MailContact
		DistributionGroup
		{
			if ($Identity)
			{
				Try
				{
					[array]$groups = Get-DistributionGroup -Identity $Identity
				}
				Catch
				{
					$Message = $Error.Exception.Message.ToString()
					Write-Log -LogFile $Logfile -Message $Message -ConsoleOutput -LogLevel ERROR
				}
			}
			else
			{
				$params = @{ }
				If ($OU) { $params.Add('OrganizationalUnit', $($OU)) }
				If ($ResultSize) { $params.Add('ResultSize', $ResultSize) }
				[array]$groups = Get-DistributionGroup @params
				Write-Log -LogFile $Logfile -Message "Procesing $($mailboxes.Count) Mailbox objects." -ConsoleOutput -LogLevel INFO
			}
			ForEach ($group in $groups)
			{
				$Error.Clear()
				Write-Log -Message "Processing $($group.PrimarySmtpAddress)" -LogFile $Logfile -LogLevel INFO -ConsoleOutput
				For ($i = ($group.EmailAddresses.count) - 1; $i -ge 0; $i--)
				{
					Foreach ($string in $StringsToRemove)
					{
						$address = $group.EmailAddresses[$i]
						$ProxyAddressString = $address.ProxyAddressString
						If ($ProxyAddressString -like "*$string*")
						{
							Write-Log -LogFile $Logfile -Message "Attempting to remove address $($ProxyAddressString)." -ConsoleOutput -LogLevel INFO
							Try
							{
								$group.EmailAddresses.removeat($i)
							}
							Catch
							{
								$Message = $Error.Exception.Message.ToString()
								Write-Log -LogFile $Logfile -Message "Error removing $($ProxyAddressString) from $($group.PrimarySmtpAddress) address array." -LogLevel ERROR -ConsoleOutput
								Write-Log -LogFile $Logfile -Message $Message -LogLevel DEBUG
							}
						}
					}
					Try
					{
						$group | Set-DistributionGroup -EmailAddresses $group.EmailAddresses
					}
					Catch
					{
						Write-Log -LogFile $Logfile -Message "Error removing $($ProxyAddressString) from $($group.PrimarySmtpAddress)." -LogLevel ERROR -ConsoleOutput
						$Message = $Error.Exception.Message.ToString()
						Write-Log -LogFile $Logfile -Message $Message -LogLevel DEBUG						
					}
				}
				$Error.Clear()
			}
		} # End DistributionGroup
	} # End Switch
} # End Foreach $Type