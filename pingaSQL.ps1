param
(
    [string]$serverList = "$(Read-Host 'Instancias [Ex.: srvsql02\sql17, cdb-rodrigo\sql19')"
)

begin {
    [void][Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')
}
process {
    try {
        $servers = $serverList.Split(",")
        $pingResults = @()

        Write-Verbose "Pingando os servidores..."

        foreach ($serverInstance in $servers) {
            $serverInstance = $serverInstance.TrimStart(" ")
            $nm = $serverInstance.Split("\")
            $machine = $nm[0]

            # Pinga os servidores
            $results = Get-WMIObject -query "Select StatusCode from Win32_PingStatus where Address = '$machine'"
            $responds = $false
            foreach ($result in $results) {
                # Se a maquina responder retorna sucesso e quebra o loop
                if ($result.statuscode -eq 0) {
                    $responds = $true
                    break
                }
            }

            if ($responds) {
                # Carrega informacoes
                $server = new-object Microsoft.SqlServer.Management.Smo.Server $serverInstance
                $r = $server.Information | Select-Object Urn, Version, Edition
				
                $pingRecord = New-Object -TypeName PSObject -Property @{
                    Server  = $server
                    Urn     = $r.Urn
                    Version = $r.Version
                    Edition = $r.Edition
                    Status  = "Ping successful"
                }
                $pingResults += $pingRecord

            }
            else {
                $pingRecord = New-Object -TypeName PSObject -Property @{
                    Server  = $machine
                    Urn     = ""
                    Version = ""
                    Edition = ""
                    Status  = "Ping failed"
                }
                $pingResults += $pingRecord
            }
        }
        Write-Output $pingResults
    }
    catch [Exception] {
        Write-Error $Error[0]
        $err = $_.Exception
        while ( $err.InnerException ) {
            $err = $err.InnerException
            Write-Output $err.Message
        }
    }
}