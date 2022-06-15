#####
# Get-FileInventory 
#####
# Usage: 
#    1. Update the values for $searchdir and $outputFile and either:
#       - Rename to .ps1 and execute (if the server is configured to execute .ps1 files) 
#       - or paste the script line-by-line to a PowerShell command line. 
#####
# Change log:
# 2014-02-01 | Eli Robillard | Script created based on source from http://social.technet.microsoft.com/Forums/windowsserver/en-US/ef4fab1f-a3e6-47e0-ba39-f6db3ab2dc61/script-to-make-a-file-inventory-on-a-file-server?forum=winserverpowershell 
#                            | Changes: get only file extensions, get dates created and last accessed, fail gracefully when permissions denied, added comments and usage
# 2015-08-20 | Eli Robillard | Added functions from https://gallery.technet.microsoft.com/scriptcenter/PowerShell-Take-the-240be7ed 
#####

function loopNodes {  
        param (  
            $oElmntParent,  
            $strPath 
        )  
    # Write-Host $strPath 
    $dirInfo = New-Object System.IO.DirectoryInfo $strPath 
    try {
        $dirInfo.GetDirectories() | % { 
            $OutNull = $oElmntChild = $xmlDoc.CreateElement("folder") 
            $OutNull = $oElmntChild.SetAttribute("name", $_.Name) 
            $OutNull = $oElmntParent.AppendChild($oElmntChild) 
            loopNodes $oElmntChild ($strPath + "\" + $_.Name) 
        } 
    }
    catch { 
        #Silently continue 
    }

    try {
        $dirInfo.GetFiles() | % { 
            $OutNull = $oElmntChild = $xmlDoc.CreateElement("file") 
            $OutNull = $oElmntChild.SetAttribute("name", $_.Name) 
            $OutNull = $oElmntChild.SetAttribute("bytesSize", $_.Length) 
            $OutNull = $oElmntParent.AppendChild($oElmntChild) 
        } 
    }
    catch { 
        #Silently continue 
    }
} 

function Dir2Xml {
	param (
		$searchDir,
		$outputPath
	)
    $xmlDoc = New-Object xml 
    if($path -ne ''){ 
        $OutNull = $xmlDoc.AppendChild($xmlDoc.CreateProcessingInstruction("xml", "version='1.0'")) 
        $OutNull = $oElmntRoot = $xmlDoc.CreateElement("baseDir") 
        $OutNull = $oElmntRoot.SetAttribute("path", $searchDir) 
        $OutNull = $oElmntRoot.SetAttribute("description", "Root") 
        $OutNull = $xmlDoc.AppendChild($oElmntRoot) 
        loopNodes $oElmntRoot $searchDir 
    } 
    $OutNull = $xmlDoc.Save("$outputPath") 
}


# Paths / folders to inventory. Note: Trailing backslash needed ("\") on the search dir. 
# Examples: "C:\Users\","D:\"
$searchDir = "C:\cloud\"
$outputDir = "c:\dev\File Inventory\"
$outputFile = "output.csv"
$outputPath = $outputDir + $outputFile

# Changes are not recommended for the following lines
#$ext = "*.aac","*.accdb","*.aiff","*.asp*","*.avi","*.cfg","*.config","*.css","*.db","*.dbf","*.dll","*.doc*","*.exe","*.gif","*.htm*","*.ini","*.iso","*.jpg","*.jpeg","*.js","*.ldf","*.log","*.mdb*","*.mdf","*.mov","*.mp3","*.mp4","*.mpp*","*.msi","*.one*","*.pdf","*.png","*.ppt*","*.txt","*.vsd*","*.wav","*.xls*","*.xml","*.zip"

$ext = "*.aac","*.accdb","*.aiff","*.application","*.asa","*.asax","*.asp","*.aspx","*.au","*.avi","*.backup","*.bak","*.bak2","*.bat","*.bin","*.bkp","*.bmp","*.btr","*.cab","*.cat","*.cfg","*.cfm","*.cgi","*.ci","*.class","*.cnf","*.cnt","*.compiled","*.config","*.cpp","*.cpt","*.cr2","*.cs","*.csi","*.css","*.csv","*.dat","*.db","*.dbf","*.dcr","*.dct","*.deploy","*.dic","*.dir","*.disco","*.discomap","*.divx","*.dll","*.doc","*.docm","*.docx","*.dot","*.dotx","*.dsk","*.dwg","*.emz","*.eot","*.err","*.exe","*.flac","*.flv","*.fmt","*.fn","*.fp_folder_info","*.gif","*.gml","*.gz","*.h","*.History","*.hl","*.hsh","*.htaccess","*.htm","*.html","*.htx","*.ico","*.id","*.idc","*.idq","*.idx","*.inc","*.ind","*.inf","*.ini","*.inv","*.iso","*.java","*.jpeg","*.jpg","*.js","*.jsf","*.jsp","*.key","*.lck","*.ldf","*.lnk","*.log","*.m1","*.m4a","*.manifest","*.map","*.markdown","*.master","*.md","*.mdb","*.mdf","*.mht","*.mhtm","*.mhtml","*.mic",`
"*.mid","*.mif","*.mmp","*.mno","*.mov","*.mp3","*.mp4","*.mpa","*.mpeg","*.mpg","*.mpp","*.mppx","*.msg","*.msi","*.mso","*.mxd","*.nak","*.nsf","*.nvram","*.odf","*.ogg","*.ol2","*.old","*.one","*.orig","*.otf","*.ovl","*.pcz","*.pdb","*.pdd","*.pdf","*.php","*.pl","*.png","*.pps","*.ppt","*.pptm","*.pptx","*.pqg","*.prp","*.ps1","*.psd","*.pst","*.py","*.ra","*.ram","*.rar","*.raw","*.res","*.resx","*.rm","*.robots","*.rtf","*.sav","*.sdc","*.shs","*.shtm","*.sql","*.src","*.stm","*.svg","*.swf","*.swv","*.tab","*.tar","*.thmx","*.tif","*.tiff","*.tmp","*.tpl","*.ttf","*.txt","*.url","*.utf8","*.vb","*.vbproj","*.vbs","*.vdi","*.vhd","*.vmc","*.vmdk","*.vob","*.vsd","*.wav","*.wbk","*.wcm","*.webinfo","*.wk","*.wma","*.wmf","*.wmv","*.wmz","*.woff","*.WOR","*.wpd","*.wsdl","*.xhtml","*.xls","*.xlsm","*.xlsx","*.xml","*.xps","*.xsd","*.xsl","*.xslt","*.zcfg","*.zdat","*.zip"

Write-Host "Target path: $searchDir"
Write-Host "Output path: $outputPath"
Write-Host "Building CSV for analysis..."
# From the root folder 
#	Recurse directories (gci=dir)
#	   If the object is a file (not a container) 
#         Get the path, fileext, created, modified, bytes, owner
# Export the results into a csv output file
$searchDir | % { gci $_ -recurse -include $ext -ErrorAction silentlyContinue | where {!$_.PsIsContainer} | select Directory,Extension,CreationTime,LastAccessTime,@{Name="Bytes";expression={$_.Length}},@{Name="Owner";expression={$_.getaccesscontrol().Owner}}} | Export-Csv "$outputPath" -notype
Write-Host "Generated $outputPath" 

# Retrieve and sort folder names:
#$outputPath = $outputDir + $outputFile
#Write-Host "Output path: $outputPath"
#Write-Host "Building TXT of folder structure..."
#$searchDir | % { gci $_ -recurse -directory -ErrorAction silentlyContinue | select FullName } | sort FullName | Export-Csv $outputPath -notype
#Write-Host "Generated $outputPath" 

#$outputPath = $outputDir + "output.xml"
#Write-Host "Output path: $outputPath"
#Write-Host "Building XML of folder structure..."
#Dir2Xml $searchDir $outputPath
#Write-Host "Generated $outputPath" 

