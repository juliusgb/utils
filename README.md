# utils

Utilities that I've found helpful and often use.

## PowerShell

Those for PowerShell are kept as a Module.

I keep them in the git repo and [create](https://github.com/juliusgb/til/blob/main/powershell/create-symbolic-link.md "leads to a TIL") a Symbolic link to them from
one of the PowerShell searches for Modules, i.e., `C:\Program Files\WindowsPowerShell\Modules`.
PowerShell lists those paths through the `$Env:PSModulePath` variable.

Open PowerShell as Administrator, then run

```powershell
New-Item -ItemType SymbolicLink `
-Path "C:\Program Files\WindowsPowerShell\Modules\CustomHelperUtils" `
-Target "C:\path\to\gitrepos\utils\powershell\CustomHelperUtils"
```

Output should be:

```powershell
  Verzeichnis: C:\Program Files\WindowsPowerShell\Modules

Mode          LastWriteTime         Length Name
----          -------------         ------ ----
d----l        04.05.2022 07:14      CustomHelperUtils
```

Check that the directory is listed when you run `Get-Module -ListAvailable`

```powershell
ModuleType Version    Name                                ExportedCommands
---------- -------    ----                                ----------------
Script     0.0.1      CustomHelperUtils                   Get-UrlStatusCode
Script     1.0.1      Microsoft.PowerShell.Operation.V... {Get-OperationValidation, Invoke-OperationValidation}
```

My first attempt at running them on my windows laptop didn't work because of
the [PowerShell's execution policies](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7.2)

When I checked the policies on my laptop with `Get-ExecutionPolicy`,
the output was `Restricted`.

Elevating the PowerShell's session with
`Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process`
allows me to run these utilities.

So far, that works for me.

It mighe also be necessary to elevate the permissions for the whole machine or user,
especially when installing modules through automation.
