param(
    [Parameter(Mandatory = $true)]
    [String]$Querymode = $null ,
    [Parameter(Mandatory = $false)]
    [pscustomobject]$Info
    )

#. .\..\Include.ps1

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$ActiveOnManualMode    = $true
$ActiveOnAutomaticMode = $true
$ActiveOnAutomatic24hMode = $false
$AbbName = 'ZERG'
$WalletMode ='WALLET'
$Result = @()
$RewardType='PPS'




#****************************************************************************************************************************************************************************************
#****************************************************************************************************************************************************************************************
#****************************************************************************************************************************************************************************************

if ($Querymode -eq "info"){
    $Result = [PSCustomObject]@{
                    Disclaimer = "Autoexchange to config.txt wallet, no registration required"
                    ActiveOnManualMode=$ActiveOnManualMode  
                    ActiveOnAutomaticMode=$ActiveOnAutomaticMode
                    ActiveOnAutomatic24hMode=$ActiveOnAutomatic24hMode
                    ApiData = $True
                    AbbName=$AbbName
                    WalletMode=$WalletMode
                    RewardType=$RewardType
                         }
    }






#****************************************************************************************************************************************************************************************
#****************************************************************************************************************************************************************************************
#****************************************************************************************************************************************************************************************



    if ($Querymode -eq "wallet")    {
        
                            
                            try {
                                $http="http://zergpool.com/api/wallet?address="+$Info.user
                                $Request = Invoke-WebRequest -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.101 Safari/537.36"  $http -UseBasicParsing -timeoutsec 10 | ConvertFrom-Json 
                            }
                            catch {}
        
        
                            if ($Request -ne $null -and $Request -ne ""){
                                $Result = [PSCustomObject]@{
                                                        Pool =$name
                                                        currency = $Request.currency
                                                        balance = $Request.balance
                                                    }
                                    remove-variable Request                                                                                                        
                                    }

                        
                        }
                        
     
#****************************************************************************************************************************************************************************************
#****************************************************************************************************************************************************************************************
#****************************************************************************************************************************************************************************************


if ($Querymode -eq "speed")    {
        
                            
    try {
        $http="http://zergpool.com/api/walletEx?address="+$Info.user
        $Request = Invoke-WebRequest -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.101 Safari/537.36"  $http -UseBasicParsing -timeoutsec 5 | ConvertFrom-Json 
    }
    catch {}
    
    $Result=@()

    if ($Request -ne $null -and $Request -ne ""){
            $Request.Miners |ForEach-Object {
                            $Result += [PSCustomObject]@{
                                PoolName =$name
                                Version = $_.version
                                Algorithm = get_algo_unified_name $_.Algo
                                Workername =($_.password -split ",")[1]
                                Diff     = $_.difficulty
                                Rejected = $_.rejected
                                Hashrate = $_.accepted
                          }     
                    }
            remove-variable Request                                                                                                        
            }


}                   


#****************************************************************************************************************************************************************************************
#****************************************************************************************************************************************************************************************
#****************************************************************************************************************************************************************************************
    
if (($Querymode -eq "core" ) -or ($Querymode -eq "Menu")){

        $retries=1
                do {
                        try {
                            $Request = Invoke-WebRequest "http://zergpool.com/api/currencies"  -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.101 Safari/537.36" -UseBasicParsing -timeout 10  | ConvertFrom-Json 
                            start-sleep 5
                            $Request2 = Invoke-WebRequest "http://zergpool.com/api/status"  -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.101 Safari/537.36" -UseBasicParsing -timeout 10 | ConvertFrom-Json  

                        }
                        catch {}
                        $retries++
                    if ($Request -eq $null -or $Request -eq "") {start-sleep 5}
                    } while ($Request -eq $null -and $retries -le 3)
                
                if ($retries -gt 3) {
                                    WRITE-HOST 'ZERGPOOL API NOT RESPONDING...ABORTING'
                                    EXIT
                                    }


        $Request | Get-Member -MemberType properties| ForEach-Object {

                $coin=$Request | Select-Object -ExpandProperty $_.name
                

                    $zerg_Algorithm = get_algo_unified_name $coin.algo
                    $zerg_coin =   get_coin_unified_name $coin.name
                    $zerg_Symbol = $_.name
            

                    $Divisor = Get_Algo_Divisor $zerg_Algorithm
                    
                    $Currency= get_config_variable "CURRENCY"
                    
                    $Result+=[PSCustomObject]@{
                                Algorithm     = $zerg_Algorithm
                                Info          = $zerg_coin
                                Price         = [Double]$coin.estimate / $Divisor
                                Price24h      = [Double]$coin.estimate_last24h  / $Divisor
                                Protocol      = "stratum+tcp"
                                Host          = "zergpool.com"
                                Port          = $coin.port
                                User          = $CoinsWallets.get_item($Currency)
                                Pass          = "c=$Currency,mc=$zerg_symbol,ID=#WorkerName#"
                                Location      = 'US'
                                SSL           = $false
                                Symbol        = $zerg_Symbol
                                AbbName       = $AbbName
                                ActiveOnManualMode    = $ActiveOnManualMode
                                ActiveOnAutomaticMode = $ActiveOnAutomaticMode
                                PoolWorkers       = $coin.Workers
                                PoolHashRate  = $coin.HashRate
                                Blocks_24h    = $coin."24h_blocks"
                                WalletMode    = $WalletMode
                                Walletsymbol = $Currency
                                PoolName = $Name
                                Fee = ($Request2.($coin.algo).Fees)/100
                                RewardType=$RewardType
                                }
                        
                
                }

        remove-variable Request                
        remove-variable Request2                
    }


#****************************************************************************************************************************************************************************************
#****************************************************************************************************************************************************************************************
#****************************************************************************************************************************************************************************************

    $Result |ConvertTo-Json | Set-Content $info.SharedFile
    remove-variable Result
  
