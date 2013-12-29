##Get-Stakrank
=============
Get-Stakrank came out of the need to parse hundreds, thousands, tens of thousands... of csv files containging various kinds of data collected from distributed computer systems. Consider csv output from tools like Sysinternals autorunsc.exe, sigcheck.exe, or the native Windows tasklist.exe with loaded modules, collected from many hosts during the process of hunting for indications of compromise in large distributed networks. Many attackers want to maintain persistence in environments and there are a variety of means for accomplishing this from credential harvesting, to planting code on the host. If the attacker plants code on a small number of hosts, small being a relative term given the overall environment size, stack ranking the frequency of occurrence for a given autorun, process or loaded module can be a useful lead generation tool for incident response teams.

For more on the idea of stack ranking as a means of hunting evil, check out Mandiant's post, "An In-Depth Look Into Data Stacking," here: https://www.mandiant.com/blog/indepth-data-stacking/.

One of the capability goals for the script was to be able to process any separated values file. This is an early release and has been through limited testing. If you find bugs, I'm sure there will be some, please use the Issues function in github and let me know about it. I'll do what I can to fix it, or if you're ambitious, fork the repo and fix it yourself.

####Example scenario:
Say your organization is comprised of Sales &amp; Marketing, R&amp;D, Operations, HR, Finance and IT. You want to engage in systematic, goal oriented breach hunts across your organization and decide to focus on one aspect of each business unit -- Windows Autostart Extension Points or ASEPs more commonly known as autoruns.

Your IT group uses smart naming conventions for computers in your organization that tie each resource to its role, for example, computers belonging to Sales &amp; Marketing have "MKTG" in the hostname; computers belonging to R&amp;D have "RND" in the hostname; Operations systems have "OPS" in the hostname; "HRES" for HR; "FIN" for Finance; and "INFO" for IT.

A sample listing of hostnames for each environment might look like the following:<br />
```
534AZMKTG -- a Sales & Marketing host
277AARND  -- a R&D host
182AROPS  -- an Operations host
011AHRES  -- a HR host
1040EZFIN -- a Finance host
1337INFO  -- a host from IT
```
Knowing your organization's smart naming convention, allows you to sort data and make comparisons within each role. Say for example it's common for your R&amp;D folks to have certain software development tools installed on their systems, but outside of that role, it's relatively uncommon. You will likely find intra-role commonalities within each division. Your Finance team will likely have software packages installed that are unique to their role. Of course, if your organization doesn't use such naming conventions, you can still collect the data and analyze it all up, without regard to role, but being able to sort it out by role has the advantage of helping you spot a malicious process on an IT machine that an attacker has named to resemble a process common to Finance machines.

You create a script that uses Sysinternals Autorunsc.exe to collect all ASEPs from every profile on every host, complete with MD5, SHA1 and SHA256 hashes of each ASEP file and write the output to csv files that include the name of each host the data came from, very roughly, something like the following executed on every host:<br />
```Powershell
& \\hunter\tools\autorunsc.exe -a -v -f -c '*' > \\hunter\data\$env:computername.autoruns.csv
```
You orchestrate this collection in whatever way you can, SCCM, Powershell Remoting, PSExec, GPO push, etc. Maybe your organization is large and highly geographically distributed and collection takes a week or two. The result is a pile of data in the \\hunter\data share, maybe hundreds, thousands, tens or hundreds of thousands of csv files listing every Autorun for every system in your organization.

You can now use Get-Stakrank to perform frequency analysis of this data and help you find follow up items that may warrant further investigation. Since our scenario involves an organization that uses smart system naming conventions, you can use that to your advantage and sort the data by system role. You do this by putting the role identifiers in a text file, one per line and saving that file to disk, maybe call it roles.txt.

You then call Get-Stakrank.ps1 from within the directory (or a parent directory) where your collected Autoruns data is, as follows:<br />
```Powershell
.\Get-Stakrank -FileNamePattern *autoruns.csv -RoleFile .\roles.txt -Fields MD5, "Image Path"
```
Where did the -Fields arguments come from? Those are fields in the Autoruns output that you're using to stack rank the data, you can choose whatever fields you want, so long as they are present in the input file's header or match the user supplied header, which can be passed as an argument. If you run the command as shown above, depending on the size of your data collection, it may run for a few seconds, or for hours, the script, as run above, provides no feedback as to its progress, for that you may want to run it with the -Verbose flag. When run with the -Verbose flag, you may see something like the following:<br />
<br />
```
VERBOSE: Starting up Get-StakRank.ps1
VERBOSE: Entering Get-Roles
VERBOSE: Found the following roles in .\roles.txt: MKTG RND OPS HRES FIN INFO
VERBOSE: Exiting Get-Roles
VERBOSE: Entering Get-Files
VERBOSE: Looking for files matching user supplied pattern, .\data\*autoruns.csv
VERBOSE: This process traverses subdirectories so it may take some time.
VERBOSE: File(s) matching pattern, .\data\*autoruns.csv:
E:\hunt\data\ATL001FIN_autoruns.csv
E:\hunt\data\ATL002FIN_autoruns.csv
E:\hunt\data\ATL003FIN_autoruns.csv
E:\hunt\data\ATL004FIN_autoruns.csv
E:\hunt\data\ATL001HRES_autoruns.csv
E:\hunt\data\ATL002HRES_autoruns.csv
E:\hunt\data\ATL003HRES_autoruns.csv
E:\hunt\data\ATL004HRES_autoruns.csv
E:\hunt\data\ATL005HRES_autoruns.csv
E:\hunt\data\ATL006HRES_autoruns.csv
E:\hunt\data\ATL007HRES_autoruns.csv
E:\hunt\data\ATL001INFO_autoruns.csv
E:\hunt\data\ATL002INFO_autoruns.csv
...
E:\hunt\data\ATLFFFINFO_autoruns.csv
E:\hunt\data\ATL001MKTG_autoruns.csv
E:\hunt\data\ATL002MKTG_autoruns.csv
E:\hunt\data\ATL003MKTG_autoruns.csv
E:\hunt\data\ATL004MKTG_autoruns.csv
...
E:\hunt\data\ATLFFFMKTG_autoruns.csv
...
VERBOSE: Exiting Get-Files
VERBOSE: Entering Get-FileHeader
VERBOSE: Attempting to extract input file headers from E:\hunt\data\ATL0001FIN_autoruns.csv.
VERBOSE: Extracted the following fields: Entry Location,Entry,Enabled,Description,Publisher,Image Path,Launch String,MD5,SHA-1,SHA-256
VERBOSE: Exiting Get-FileHeader
VERBOSE: Entering Check-Fields
VERBOSE: Exiting Check-Fields
VERBOSE: Entering Get-Rank
VERBOSE: Entering Get-FieldList
VERBOSE: $FieldList is $_."MD5" + "`t" + $_."Image Path".
VERBOSE: Exiting Get-FieldList
VERBOSE: We have roles...
VERBOSE: Processing role FIN.
VERBOSE: E:\hunt\data\ATL001FIN_autoruns.csv
VERBOSE: E:\hunt\data\ATL002FIN_autoruns.csv
VERBOSE: E:\hunt\data\ATL003FIN_autoruns.csv
VERBOSE: E:\hunt\data\ATL004FIN_autoruns.csv
VERBOSE: Building dictionary of stack ranked elements for FIN.
VERBOSE: Adding FIN MD5 Image Path.
VERBOSE: Adding FIN 3b536a8bec3b4f23ffdfd78b11a2ab93 c:\windows\system32\autochk.exe.
VERBOSE: Adding FIN 3290d6946b5e30e70414990574883ddb c:\windows\system32\alg.exe.
VERBOSE: Adding FIN f23fef6d569fce88671949894a8becf1 c:\windows\system32\audiosrv.dll.
VERBOSE: Incrementing FIN f23fef6d569fce88671949894a8becf1 c:\windows\system32\audiosrv.dll.
VERBOSE: Adding FIN f22f7f2395560a83e7d1da705e3ba759 c:\windows\system32\bfe.dll.
VERBOSE: Adding FIN 1ea7969e3271cbc59e1730697dc74682 c:\windows\system32\qmgr.dll.
VERBOSE: Adding FIN a8edb86fc2a4d6d1285e4c70384ac35a c:\windows\system32\dllhost.exe.
VERBOSE: Adding FIN c118a82cd78818c29ab228366ebf81c3 c:\windows\system32\lsass.exe.
VERBOSE: Adding FIN b4447f606bb19fd8ad0bafb59b90f5d9 c:\windows\system32\fntcache.dll.
VERBOSE: Incrementing FIN c118a82cd78818c29ab228366ebf81c3 c:\windows\system32\lsass.exe.
...
VERBOSE: Writing out by value.
VERBOSE: Exiting Get-Rank
VERBOSE: Exiting Get-StakRank.ps1
```
When the script completes, you're left with one tsv file summarizing the frequency of each Autorun for each role based on the -Fields you provided. Of course, if you run the script without the -RolesFile option because you don't have a naming convention you can rely on, you'll end up with a single tsv file summarizing the frequency of each Autorun across all the systems for which you have collected data.

Get-Stakrank is not limited to frequency analysis of Autoruns output. It should be applicable for any collection of separated values files.
