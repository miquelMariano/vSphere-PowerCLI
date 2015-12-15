$rand = New-Object system.random
[int]$v = $rand.next(1,10)

$x=[string]$v+":OK"
write-host $x

exit 0
