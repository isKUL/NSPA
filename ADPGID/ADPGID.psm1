<#
Created by _KUL
#>

#Requires -Modules ActiveDirectory

class ADPGID
{
    hidden [string]  $server;
    hidden [int]  $processedUsers;
    
    ADPGID([string]$server)
    {
        if (!$server)
        {
            throw [System.ArgumentNullException]::new();
        }
        $this.server = $server;
    }

    hidden [PSObject[]] GetMembersOfGroup([string]$strGroupIdentity)
    {
        try
        {
            if ($strGroupIdentity)
            {
                [Microsoft.ActiveDirectory.Management.ADGroup]$groupIdentity = Get-ADGroup -Server $this.server -Identity $strGroupIdentity `
                                                                                 -Properties primaryGroupToken,DistinguishedName -ErrorAction Stop
                
				# Weak point. Recursion will not work (if there is a group in the group). Need to refine!
                # But thanks to this, you can do work between trusted domains in different forests (it will not work through Get-ADGroupMember -Recursive)
                return Get-ADUser -Server $this.server `
                 -LDAPFilter "(&(objectClass=user)(|(primaryGroupID=$($groupIdentity.primaryGroupToken))(memberOf=$($groupIdentity.DistinguishedName))))" `
                 -Properties PrimaryGroupID,Name,SID -ErrorAction Stop;
            }
            else
            {
                return Get-ADUser -server $this.server -Filter * -Properties PrimaryGroupID -ErrorAction Stop
            }
        }
        catch [System.SystemException]
        {
            Write-Warning "$strGroupIdentity : $($_.Exception.Message)";
        }
        return @();
    }

    hidden [bool] IsNotEqualPGIDofUser([Microsoft.ActiveDirectory.Management.ADGroup]$group, [Microsoft.ActiveDirectory.Management.ADUser]$user)
    {
        if ($user.PrimaryGroupID -and $group.primaryGroupToken -and ($user.PrimaryGroupID -ne $group.primaryGroupToken))
        {
            return $true;
        }
        else 
        {
            return $false;
        }
    }

    hidden [bool] ChangeUserPGID( [Microsoft.ActiveDirectory.Management.ADUser]$user,
                                  [Microsoft.ActiveDirectory.Management.ADGroup]$group
                                    )
    {
        if ($user.PrimaryGroupID)
        {
            try
            {
                Set-ADUser -Server $this.server -Identity $user -Replace @{PrimaryGroupID=$group.primaryGroupToken} -ErrorAction Stop;
                return $true;
            }
            catch [System.SystemException]
            {
                Write-Warning "$($group.Name) | $($user.Name) : $($_.Exception.Message)";
            }
        }
        return $false;
    }

    hidden [bool] AddUserToGroup( [Microsoft.ActiveDirectory.Management.ADUser]$user, 
                                  [Microsoft.ActiveDirectory.Management.ADGroup]$group)
    {
        try
        {
            Add-ADGroupMember -Server $this.server -Identity $group -Members $user -ErrorAction Stop;
            return $true;
        }
        catch [System.SystemException]
        {
            Write-Warning "$($group.Name) | $($user.Name) : $($_.Exception.Message)";
            return $false;
        }
    }

    # Special business logic. Change the Primary Group ID for the user. 
    # Caution! Look at the remark in the GetMembersOfGroup function.
    [int] DoAnalysisPGID( [string]$strGeneralGroup,
                        [string]$strStashGroup, 
                        [string]$workPlace)
    {
        $this.processedUsers = 0;
        [Microsoft.ActiveDirectory.Management.ADGroup]$generalGroup = Get-ADGroup -Server $this.server -Identity $strGeneralGroup `
                                                                         -Properties primaryGroupToken,Name,SID,GroupScope,DistinguishedName -ErrorAction Stop;
        [Microsoft.ActiveDirectory.Management.ADGroup]$stashGroup = Get-ADGroup -Server $this.server -Identity $strStashGroup `
                                                                         -Properties primaryGroupToken,Name,SID,GroupScope,DistinguishedName -ErrorAction Stop;

        if ($stashGroup.GroupScope -eq [Microsoft.ActiveDirectory.Management.ADGroupScope]::DomainLocal)
        {
            Write-Warning "The target group for changing the Primary Group ID should not have a DomainLocal scope!"
            return $this.processedUsers;
        }

        [PSObject[]]$users = $this.GetMembersOfGroup($workPlace);
        
        foreach($user in $users)
        {
            if ($this.IsNotEqualPGIDofUser($generalGroup, $user) -and $this.IsNotEqualPGIDofUser($stashGroup, $user))
            {

                if ($this.DoChangePGID($user.SID, $stashGroup.SID))
                {
                    $this.processedUsers++;
                }
                else
                {
                    continue;
                }
            }
        }

        return $this.processedUsers;
    }

    # Change the Primary Group ID for the user. 
    [bool] DoChangePGID( [string]$strUser, 
                        [string]$strNewGroup)
    {
        [Microsoft.ActiveDirectory.Management.ADUser]$user = Get-ADUser -Server $this.server -Identity $strUser `
                                                             -Properties PrimaryGroupID,Name,SID,MemberOf -ErrorAction Stop;
        [Microsoft.ActiveDirectory.Management.ADGroup]$newGroup = Get-ADGroup -Server $this.server -Identity $strNewGroup `
                                                             -Properties primaryGroupToken,Name,SID,GroupScope,DistinguishedName -ErrorAction Stop;

        if ($newGroup.GroupScope -eq [Microsoft.ActiveDirectory.Management.ADGroupScope]::DomainLocal)
        {
            Write-Warning "The target group for changing the Primary Group ID should not have a DomainLocal scope!"
            return $false;
        }

        if ($user.PrimaryGroupID -eq $newGroup.primaryGroupToken)
        {
            return $true;
        }

        if ($user.MemberOf -notcontains $newGroup.DistinguishedName)
        {
            if (!$this.AddUserToGroup($user, $newGroup))
            {
                return $false;
            }
            else {
                for ([int]$i = 0; $i -le 100; $i++)
                {
                    [Microsoft.ActiveDirectory.Management.ADUser]$user = Get-ADUser -Server $this.server -Identity $strUser `
                                                             -Properties PrimaryGroupID,Name,SID,MemberOf -ErrorAction Stop;
                    if ($user.MemberOf -contains $newGroup.DistinguishedName)
                    {
                        break;
                    }
                    if ($i -eq 99)
                    {
                        return $false;
                    }
                    Start-Sleep -Milliseconds 100;
                }
            }
        }

        return $this.ChangeUserPGID($user, $newGroup);
    }
}