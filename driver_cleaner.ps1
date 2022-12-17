Write-Host "Don't forget to 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass'!" -ForegrounColor Yellow

$dismOut = dism /online /get-drivers | select -Skip 10 | select -SkipLast 1
$collection = @()
$count = 1
$filterNext = "pubName"

foreach ( $each in $dismOut){
	$temporary = $each
	$lineValue = $($temporary.Split( ':' ))[1]
	# There are seven lines and a blanks line at the end, so 8 switch statements are required.
	switch ($filterNext) {
		'pubName'	{
					$pubName = $lineValue.Trim()
					$filterNext = 'ogFlName'
					break
				}
		'ogFlName'	{
					$ogFileName =  $lineValue.Trim()
					$filterNext = 'inbox'
					break
				}
		'inbox'		{
					$inbox = $lineValue.Trim()
					$filterNext = 'className'
					break
				}
		'className'	{
					$className =  $lineValue.Trim()
					$filterNext = 'provider'
					break
				}
		'provider'	{
					$provider =  $lineValue.Trim()
					$filterNext = 'date'
					break
				}
		'date'		{
					$date =  $lineValue.Trim()
					$filterNext = 'version'
					break
				}
		'version'	{	
					$version =  $lineValue.Trim()
					$filterNext = 'reset'
					$sort = [ordered]@{
						'Row' = $count
						'Vendor' = $provider
						'Type' = $className 
						'FileName' = $ogFileName
						'Name' = $pubName
						'Date' = $date
						'Version' = $version
						'Inbox' = $inbox
					}
					$obj = New-Object -TypeName PSObject -Property $sort
					$collection += $obj						
					$count++
					break
				}
		'reset'		{
					$ogFileName =  $lineValue
					$filterNext = 'pubName'
					break
				}					
	}
}

Write-Host  "All installed third-party drivers"
$collection | sort Vendor | ft

$input = Read-Host "Which driver(s) would you like to remove? Select rows, comma seperated (ex '10, 2, 4, 22...') "

$toDelete = @()
foreach ( $each in  $input.Split(',')){
	$toDelete += $collection[$each.Trim()-1]
}

Write-Host "The following drivers will be deleted" -ForegroundColor Red
$toDelete | sort Row | ft
$prompt = Read-Host "Are you sure you want to delete these drivers? (y/n) "

if ( $prompt -eq "y" -or $prompt -eq "Y" ) {
	foreach ( $each in $toDelete){
		$Name = $($each.Name).Trim()
		$Vendor = $($each.Vendor).Trim()
		$Type = $($each.Type).Trim()
		$FileName = $($each.FileName).Trim()
		Write-Host "Deleting $Vendor $Type driver with the filename of $FileName !" -ForegroundColor Yellow
		#Write-Host "pnputil.exe -d $Name -f" -ForegroundColor Yellow
		Invoke-Expression -Command "pnputil.exe -d $Name -f"
	}
}
