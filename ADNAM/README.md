# ADPGID
Using native libraries .NET Framework for working with Active Directory via PowerShell

## What are the requirements?
- PowerShell
- .NET Framework (it is already in each Windows)

## How to use it?
Connect the library
```
Import-Module ".\NSPA\ADNAM\ADNAM.psm1"
```
And get the data you need...
```
Get-NetUserPrincipal -domainName "company.local" -userName "user1"
(Get-NetGroupPrincipal -groupName "Domain Admins").Members
```