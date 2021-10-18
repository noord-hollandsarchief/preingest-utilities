#Install-Module -Name ImportExcel -Force


# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
$container=$args[0]
$size= $args[1]

$wrkPath = '/data/'
# Define the target path (where we'll create the new structure)
$targetPath = '/data/'

try{
    $decompress = "http://localhost:9000/hooks/decompress-collection?archiveName=$($container)"

    $responseUnpakFiles = Invoke-WebRequest -Uri $decompress -Method GET -UseBasicParsing 

    [string[]]$splitResult = $responseUnpakFiles.Content.Split([Environment]::NewLine)

    $archiveName = $splitResult[0].Replace("/", "")
    # Define the root path (the one that contains Folder1, Folder2 etc)
    $rootPath = $wrkPath + $archiveName

    # Collect the file information, order by descending size (largest first)
    $files = Get-ChildItem $rootPath -File -Recurse | Where { !$_.Extension.Equals(".metadata") } | Sort-Object Length -Descending 

    #size check, otherwise default 100
    $isNumber = $size -match "^\d+$"
    if($isNumber){
        $size = [int] $args[1]
    }
    else{
        $size = 100
    }

    # Define max bin size as the size of the largest file 
    $max = ($size*1024*1024) # put size here instead (files larger than X bytes will end up in a lone bin)

    Write-Host "Split size is $($max)"

    #Create a list of lists to group our files by
    $bins = [System.Collections.Generic.List[System.Collections.Generic.List[System.IO.FileInfo]]]::new()

    :FileIteration
    foreach($file in $files){
        # Walk through existing bins to find one that has room
        for($i = 0; $i -lt $bins.Count; $i++){
            if(($bins[$i]|Measure Length -Sum).Sum -le ($max - $file.Length)){
                # Add file to bin, continue the outer loop
                $bins[$i].Add($file)
                continue FileIteration
            }
        }
        # No existing bins with capacity found, create a new one and add the file
        $newBin = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
        $newBin.Add($file)
        $bins.Add($newBin)
    }

    $tmpVar = [System.IO.Path]::GetRandomFileName()

    #split the documents first
    $binNumber = 0;
    # Now go through the bins and move the files to the new directory
    foreach($bin in $bins){
        # Create a new randomly named folder for the files in the bin
        $directory = New-Item $targetPath -Name $($tmpVar+$binNumber.ToString("0000")) -ItemType Directory -Force
        foreach($file in $bin){
        
            $finalDestination = $targetPath + $($tmpVar+$binNumber.ToString("0000")) + "/" + $file.FullName.Replace($wrkPath, "")
            #Write-Host $finalDestination
            #touch it, to create parent folders
            $n = New-Item -ItemType File -Path $finalDestination -Force
            #move and overwrite
            $m1 = Move-Item $file.FullName -Destination $finalDestination -Force
            #while here, why not move the metadata too
            $metadata = $file.FullName + ".metadata"
            $m2 = Move-Item $metadata -Destination $($finalDestination + ".metadata") -Force
        }
        $binNumber++
    }

    #now the metadata files
    $files = Get-ChildItem $rootPath -File -Recurse | Where { $_.Extension.Equals(".metadata") } | Sort-Object Length -Descending 
    foreach($file in $files){
        #use copy, cause each bin may contain the parent folder(s)
        For($i=0;$i -lt $binNumber;$i++){

            $finalDestinationFileName = $file.Name
            $finalDestinationFolder = $targetPath + $($tmpVar+$i.ToString("0000")) + "/" + $file.Directory.Fullname.Replace($wrkPath, "")
            $finalDestination = $targetPath + $($tmpVar+$i.ToString("0000")) + "/" + $file.Fullname.Replace($wrkPath, "")
        
            Write-Host (Test-Path $finalDestinationFolder) " - " $finalDestinationFolder

            if((Test-Path $finalDestinationFolder) -eq $true){           
                #Write-Host "From : " $file " To : " $finalDestination
                $c = Copy-Item $file.FullName -Destination $finalDestination -Force
            }
        }
    }


    #remove the target
    Remove-Item $rootPath -Recurse -Force
    
    #http://localhost:9000/hooks/compress-collection?archiveNewName=Provincie%20Noord-Holland.0005.tar&collectionName=Provincie%20Noord-Holland&folder=0005

    For($i=0;$i -lt $binNumber;$i++){

        $archive = $targetPath + $($tmpVar+$i.ToString("0000")) + "/" #/wrk/0000/

        $tarArchiveName = $archiveName + "." + $($tmpVar+$i.ToString("0000")) + ".tar" #Provincie Noord-Holland.0000.tar

        $collectionPartFolder = $($tmpVar+$i.ToString("0000"))

        $compress = "http://localhost:9000/hooks/compress-collection?archiveNewName=$($tarArchiveName)&collectionName=$($archiveName)&folder=$($collectionPartFolder)"

        $responseRename = Invoke-WebRequest -Uri $compress -Method GET -UseBasicParsing
    
        Move-Item $($archive + "*.tar") -Destination $targetPath
        Remove-Item $archive -Recurse -Force
    }

}
catch{
    Write-Host $_.Exception.Message
    Write-Host $_.Exception.ItemName
}