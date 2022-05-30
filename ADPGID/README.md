# ADPGID
Changing a user's PrimaryGroupID in Active Directory

## What are the requirements?
- PowerShell
- Installed **ActiveDirectory** module
- The service user must have the rights to change group members and to change the attribute PrimaryGroupID

## How to use it?
In the client code, connect the code with class **ADPGID** using the command:
`Using module ".\ADPGID.psm1"`
Using an object of the class specify your domain of Active Directory and specify which user needs to change the PrimaryGroupID:
```
[ADPGID]::new("mydomain.local").DoChangePGID("kul","groupOfSuperStars")
```
or
```
$worker = [ADPGID]::new("mydomain.local");
$count = $worker.DoAnalysisPGID("Domain Users", "External Users", "RDP_Users");
```

## Detailed description
The module contains: 
**class**
- `ADPGID::new([string])` - The class performing the work. Has a single constructor for specifying the domain name.

and **methods**
- `[bool] DoChangePGID([string], [string])` - A method that changes the user's PrimaryGroupID. Accepts the user identifier and target group identifier as input. The result is True if the operation is successful.
- `[int] DoAnalysisPGID([string], [string], [string])` - A method for special business logic (my logic). Accepts the identifier of the main group, the identifier of the stash group, and a place to search for users. If the user has a PrimaryGroupID other than main group and from stash group, then stash ID is assigned to user. The result returns the number of changed users.