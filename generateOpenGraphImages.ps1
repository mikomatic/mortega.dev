Get-ChildItem .\content\posts | ForEach-Object { tcardgen -f .\static\font -o .\static\images\tcard -c .\ogtemplate.yaml $_.FullName }