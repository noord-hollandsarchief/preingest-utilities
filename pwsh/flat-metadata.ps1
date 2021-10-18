#Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
$workfolder = "/data/"
$container=$args[0]
$decompress = "http://localhost:9000/hooks/decompress-collection?archiveName=$($container)"

try{

    if (Get-Module -ListAvailable -Name ImportExcel) {
        Write-Host "ImportExcel Module exists"
    } 
    else {
        Write-Host "ImportExcel Module does not exist"
        Install-Module -Name ImportExcel -Force
    }
    
    $responseUnpakFiles = Invoke-WebRequest -Uri $decompress -Method GET -UseBasicParsing 

    $splitResult = $responseUnpakFiles.Content.Split([Environment]::NewLine)

    $archiveName = $splitResult[0].Replace("/", "")

    Write-Host $archiveName

    $totalDictionary = New-Object "System.Collections.Generic.Dictionary``2[System.String,System.Collections.Generic.Dictionary``2[System.String,System.String]]"
    $totalHeaderColumns = New-Object "System.Collections.Generic.HashSet[string]"
    $totalHeaderColumns.Add("Bestandslocatie")

    foreach($line in $splitResult.Where({$_.EndsWith(".metadata")}))
    {

        $fileSource = $workfolder + $line
        $transform = "http://localhost:9000/hooks/flat-transform?file=$($fileSource)"
 
        $responseFlatten = Invoke-WebRequest -Uri $transform -Method GET -UseBasicParsing 
    
        $splitKeyValueLines = $responseFlatten.Content.Split([Environment]::NewLine)

        $singleMetadatadict = New-Object "System.Collections.Generic.Dictionary``2[System.String,System.String]"

        foreach($keyValue in $splitKeyValueLines)
        {        
            #simplify current flatten output
            $split = $keyValue.Split("|").Count
        
            if($split -eq 2){

                $key = $keyValue.Split("|")[0].Trim()
                $val = $keyValue.Split("|")[1].Trim()
               
                #add to column list to track headers (unique names)
                $isSet = $totalHeaderColumns.Add($key)

                if($singleMetadatadict.ContainsKey($key)){
                    $newValue = $singleMetadatadict[$key] + [Environment]::NewLine + $val
                    $singleMetadatadict[$key] = $newValue
                }
                else{
                    $singleMetadatadict.Add($key, $val)
                }
            }        
        }
    
        $totalDictionary.Add($line, $singleMetadatadict)
        
    }

    
    Write-Host "Total count :" $totalHeaderColumns.Count
    #Write-Host $totalHeaderColumns
    #//add column headers first
    $dataTable = New-Object System.Data.DataTable("Flatten")
    foreach($header in $totalHeaderColumns){    
        $column = $dataTable.Columns.Add($header)
    }

    Write-Host "Total dictionary :" $totalDictionary.Count #count metadata files
    foreach($record in $totalDictionary.Keys){#dictionary
        $currentFile = $record
        $currentData = $totalDictionary[$record]
    
        #create new datatable row and add a record with values
        $row=$dataTable.NewRow()
        Write-Host $currentFile 
        $row["Bestandslocatie"] = $currentFile  
        foreach($item in $currentData.Keys){
            $dataHeader = $item
            $dataValue = $currentData[$item]
            $row[$dataHeader]=$currentData[$item]
        }
        $dataTable.Rows.Add($row)#add and loop next    
    }

    $xlfile = $workfolder+$archiveName+".xlsx"
    Remove-Item $xlfile -ErrorAction SilentlyContinue

    $dataTable | Export-Excel $xlfile -TableName Metadata -WorksheetName Metadata
    
    Remove-Item $($workfolder+$archiveName)-Recurse -Force
}
catch{

    Write-Host $_.Exception.Message
    Write-Host $_.Exception.ItemName

}