#Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
$workfolder = "/data/"
$guid=$args[0]


try{
    $path = $workfolder+$guid

    $result = Test-Path -Path $path
    
    if ($result)
    {
        $files = Get-ChildItem -Path $path -Recurse -File | Where { !$_.Name.EndsWith(".opex", [System.StringComparison]::InvariantCultureIgnoreCase) -or $_.Name.EndsWith(".metadata", [System.StringComparison]::InvariantCultureIgnoreCase) -or $_.Name.EndsWith(".mdto.xml", [System.StringComparison]::InvariantCultureIgnoreCase)} 
       
       
        $dataTable = New-Object System.Data.DataTable("checksum")        
        $column = $dataTable.Columns.Add("fileLocation")
        $column = $dataTable.Columns.Add("md5")
        $column = $dataTable.Columns.Add("sha1")
        $column = $dataTable.Columns.Add("sha224")
        $column = $dataTable.Columns.Add("sha256")
        $column = $dataTable.Columns.Add("sha384")
        $column = $dataTable.Columns.Add("sha512")
        
        foreach($file in $files){

            $row=$dataTable.NewRow()
            $row["Bestandslocatie"] = $file

            $md5Url = "http://localhost:9000/hooks/checksum-md5?file=$($file)"
            $sha1Url = "http://localhost:9000/hooks/checksum-sha1?file=$($file)"
            $sha256Url = "http://localhost:9000/hooks/checksum-sha256?file=$($file)"
            $sha224Url = "http://localhost:9000/hooks/checksum-sha224?file=$($file)"            
            $sha384Url = "http://localhost:9000/hooks/checksum-sha512?file=$($file)"
            $sha512Url = "http://localhost:9000/hooks/checksum-sha512?file=$($file)"

            $response = Invoke-WebRequest -Uri $md5Url -Method GET -UseBasicParsing 
            $md5 = $response.Content.Split("  ")
            $row["md5"] = $md5[0]
            
            $response = Invoke-WebRequest -Uri $sha1Url -Method GET -UseBasicParsing
            $sha1 = $response.Content.Split("  ") 
            $row["sha1"] = $sha1[0]

            $response = Invoke-WebRequest -Uri $sha256Url -Method GET -UseBasicParsing
            $sha256 = $response.Content.Split("  ")
            $row["sha256"] = $sha256[0]

            $response = Invoke-WebRequest -Uri $sha224Url -Method GET -UseBasicParsing
            $sha224 = $response.Content.Split("  ")
            $row["sha224"] = $sha224[0]

            $response = Invoke-WebRequest -Uri $sha384Url -Method GET -UseBasicParsing
            $sha384 = $response.Content.Split("  ")
            $row["sha384"] = $sha384[0]

            $response = Invoke-WebRequest -Uri $sha512Url -Method GET -UseBasicParsing
            $sha512 = $response.Content.Split("  ")  
            $row["sha512"] = $sha512[0]

            $dataTable.Rows.Add($row)#add and loop next            
        }
      
        #$csvfile = $path + "/" + $guid +".csv" 
        $jsonFile = $path + "/" + "ExportChecksumHandler" +".json" 
        Remove-Item $jsonFile -ErrorAction SilentlyContinue

        #$dataTable | Export-Csv $csvfile -NoTypeInformation       
        $dataTable | Select-Object * -ExcludeProperty ItemArray, Table, RowError, RowState, HasErrors | ConvertTo-Json | Out-File $jsonFile
        #$dataTable | ConvertTo-Json $jsonFile
    }
    else{
        Write-Host "Folder not found: " + $path
    }
}
catch{

    Write-Host $_.Exception.Message
    Write-Host $_.Exception.ItemName

}