#Get-ExecutionPolicy -List
#Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
#Set-ExecutionPolicy Undefined -Scope CurrentUser

########Functions############

#Get Tags defined in Metadata #EXTINF
function GetTagValue([string]$iStr, [string]$iTag) {
    
     $lv_Init  = $iStr.IndexOf($iTag) + $iTag.length + 2
     $lv_Last  = $iStr.IndexOf('"', $lv_Init)
     $lv_return = $iStr.Substring($lv_Init ,$lv_Last - $lv_Init)

     return $lv_return

}

#Get File Name ".m3u"
function PickUpFile( ) {
    $lv_Files = Get-ChildItem -Filter '*.m3u'
    $lv_i = 0
    Foreach ( $lv_item in $lv_Files ) {
        $lv_i++
        Write-Host $lv_i $lv_item.name
    }

    Do { 
        $p_nFile = Read-Host Prompt 'Indica el fichero que desea convertir. nï¿½mero?' 
        }until( $p_nFile -gt 0 -and $p_nFile -le $lv_i )

    return $lv_Files[$p_nFile - 1].Name
    
}

#Get Out Format
function get_format( ) {
    $lt_Formats = "Bouque", "Fresatv8"    
    $lv_i = 0
    Foreach ( $lv_item in $lt_Formats ) {
        $lv_i++
        Write-Host $lv_i $lv_item
    }

    Do { 
        $lp_nformat = Read-Host Prompt 'Indica el fichero que desea convertir. número?' 
        }until( $lp_nformat -gt 0 -and $lp_nformat -le $lv_i )

    return $lt_formats[$lp_nformat - 1]
    
}

############ __Main__ ##########
##Promts Parameters

#Get Format
$p_OutFormart = get_Format

Do { 
     switch ($p_OutFormart) {
      'Bouque' {
         $p_Alias = Read-Host Prompt 'Alias Name? userbouquet.<Alias>.tv'
       }
       'Fresatv8' {
         $p_Alias = Read-Host Prompt 'Alias Name?'          
       } 
           
     }
    }until($p_Alias -ne "") #<-- Aï¿½adir expresiï¿½n regular

Do { 
     switch ($p_OutFormart) {
      'Bouque' {
            $p_SplitFile = Read-Host Prompt 'Split file by "group-title"? (Y/N)'
       }
       'Fresatv8' {
            $p_SplitFile = 'N'
       } 
     }
    }until($p_SplitFile -eq "Y" -or $p_SplitFile -eq "N")

$p_FileName = PickUpFile

##Start
$gv_CurrentChannel=0

$gv_File_m3u = Get-Content $p_FileName

$gv_TotalChannels = ( ($gv_File_m3u.Count - 1)/ 2 ) #<-- Controlar Excepciï¿½n

Write-Host  "Total Channels: " $gv_TotalChannels
  
foreach ( $item_m3u in $gv_File_m3u ){
   if ( $item_m3u.Contains("#EXTM3U") ) {
   
    } elseif ( $item_m3u.Contains("#EXTINF:") ) {
       if ( $p_SplitFile -eq 'Y' ) {
           # Pick-up Group         
           $gv_Group = GetTagValue $item_m3u "group-title"
           $gv_Group = $p_alias + "_" + $gv_Group
        } else {
           $gv_Group = $p_alias  
        }

        if ( !( Test-Path $p_alias ) ) { 
          #New Directory
           New-Item  $p_alias -ItemType Directory
         }        
       
        # Pick-up channel        
        $gv_Canal = GetTagValue $item_m3u "tvg-name"     
        
        switch ($p_OutFormart) {
          'Bouque' {
                # File bouquets
                $gv_bouquesTv = $p_alias + "\bouquets.tv"
                if ( !( Test-Path $gv_bouquesTv ) ) {    
                 $gv_Name = "#NAME User - bouquets (TV)"
                 Add-Content -Path $gv_bouquesTv -Value $gv_Name
                }

                # File Userbouquet     
                $gv_out_File = $p_alias + "\userbouquet." + $gv_Group + ".tv"
                if ( !( Test-Path $gv_out_File ) ) {    
                 #New File
                 $gv_Count = 1
                 $gv_Name = "#Name " + $gv_Group  
                 Add-Content -Path $gv_out_File -Value $gv_Name
         
                 # Add File to bouquets
                 $gv_Service = '#SERVICE 1:7:1:0:0:0:0:0:0:0:FROM BOUQUET "userbouquet.' + $gv_Group + '.tv" ORDER BY bouquet'
                 Add-Content -Path $gv_bouquesTv -Value $gv_Service
                }
            
          
          }
          'Fresatv8' {
                $gv_out_File = $p_alias + "\iptvlist.txt"    
          
          }
        }


    } elseif ( $item_m3u.Contains("http://") ) { 

         $gv_Count++
         $gv_CurrentChannel++

         switch ($p_OutFormart) {
           'Bouque' {
             # Add channel
              $gv_Service = "#SERVICE 4097:0:1:" + $gv_Count + ":0:0:0:0:0:0:" + $item_m3u.Replace(':','%3A')
              $gv_Description = "#DESCRIPTION " + $gv_Canal
              Add-Content -Path $gv_out_File -Value $gv_Service
              Add-Content -Path $gv_out_File -Value $gv_Description
            }
            'Fresatv8' {
              # Add channel
              $gv_Service = $gv_Canal + "," + $item_m3u
              Add-Content -Path $gv_out_File -Value $gv_Service           
            }
         }  
          Write-Host  "Current Channel "  $gv_CurrentChannel  "/" $gv_TotalChannels
        } else { 
         #<-- Controlar el Error...
        }
    
 }