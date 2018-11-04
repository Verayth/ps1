
[cmdletbinding()]
param([decimal]$Size)

$sizes='B,KB,MB,GB,TB,PB,EB,ZB' -split ','

for($i=0; ($Size -ge 1000) -and ($i -lt $sizes.Count); $i++) {$Size/=1kb}

$N=2; if($i -eq 0) {$N=0}

"{0:N$($N)} {1}" -f $Size, $sizes[$i]
#"{0,6:N$($N)} {1}" -f $Size, $sizes[$i]
