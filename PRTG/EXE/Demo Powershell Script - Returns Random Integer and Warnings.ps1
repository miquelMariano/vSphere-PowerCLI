$rand = New-Object system.random
[int]$v = $rand.next(1,4)

if ($v -eq 1) {
  $x=[string]$v+":Too Low"
  write-host $x

  exit 1
}

ElseIf ($v -eq 2) {
  $x=[string]$v+":OK"
  write-host $x

  exit 0
}

ElseIf ($v -eq 3) {
  $x=[string]$v+":Too High"
  write-host $x

  exit 1
}

Else 
{
  $x=[string]$v+":Invalid"
  write-host $x

  exit 2
}

