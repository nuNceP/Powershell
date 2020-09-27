$logfolder = "C:\Users\guestadmin\Documents\Robocopy\"
$fileserver = "\\fileserver\e$\"
$clean = $true #Pulisce dalla destinazione i dati non più presenti all'origine
$fast = $true #Velocità elevata di copia

#Condizionali

If ($clean -eq $true) {
    $MIR = "/MIR"
} Else {
    $MIR = ""
}

If ($fast -eq $true) {
    $speed = 40 #Veloce
} Else {
    $speed = 4 #Lento
}

#Copy directory structure for Eagle
#robocopy /e /COPYALL /DCOPY:DAT /SECFIX "$($fileserver)\Eagle\" "E:\Eagle" #/LEV:5 /CREATE /LOG+:$($logfolder)robocopy_$($startdate).txt /tee /xf *

#Migrazione datastore
#robocopy /e /COPYALL /DCOPY:DAT /SECFIX "F:\" "G:\" /np /fp /tee /R:1 /W:5 /MT:40

#Eagle Folder
$startdate = get-date -Format yyyy-MM-dd-hh-mm-ss
robocopy /e /COPYALL /DCOPY:DAT /SECFIX "$($fileserver)\Eagle\" "E:\Eagle\" /np /fp /LOG+:$($logfolder)robocopy_$($startdate).txt /tee /R:1 /W:5 /MT:$($speed) $($MIR)

#ProgettiRiegl
#$startdate = get-date -Format yyyy-MM-dd-hh-mm-ss
#robocopy /e /COPYALL /DCOPY:DAT /SECFIX "$($fileserver)\Eagle\20_SVILUPPO\32_area3D\20_progettiRiegl" "E:\Eagle\20_SVILUPPO\32_area3D\20_progettiRiegl" /np /fp /LOG+:$($logfolder)robocopy_$($startdate).txt /tee /R:1 /W:5 /MT:$($speed) $($MIR)

#OUTPUT3D
#$startdate = get-date -Format yyyy-MM-dd-hh-mm-ss
#robocopy /e /COPYALL /DCOPY:DAT /SECFIX "$($fileserver)\Eagle\20_SVILUPPO\60_output3D" "E:\Eagle\20_SVILUPPO\60_output3D" /np /fp /LOG+:$($logfolder)robocopy_$($startdate).txt /tee /R:1 /W:5 /MT:$($speed) $($MIR)

#ORTOFOTO
#$startdate = get-date -Format yyyy-MM-dd-hh-mm-ss
#robocopy /e /COPYALL /DCOPY:DAT /SECFIX "$($fileserver)\Eagle\90_ORTOFOTO" "E:\Eagle\90_ORTOFOTO" /np /fp /LOG+:$($logfolder)robocopy_$($startdate).txt /tee /R:1 /W:5 /MT:$($speed) $($MIR)

#CLUSTER
#$startdate = get-date -Format yyyy-MM-dd-hh-mm-ss
#robocopy /e /COPYALL /DCOPY:DAT /SECFIX "$($fileserver)\Eagle\30_CLUSTER" "E:\Eagle\30_CLUSTER" /np /fp /LOG+:$($logfolder)robocopy_$($startdate).txt /tee /R:1 /W:5 /MT:$($speed) $($MIR)

#Copy Folder \\fileserver\Eagle\20_SVILUPPO\32_area3D\20_progettiRiegl\umbria to D:\umbria
#"\\fileserver\eagle\20_SVILUPPO\32_area3D\20_progettiRiegl\umbria\" | Out-File D:\umbria.txt
#robocopy /E /COPY:DATSO /DCOPY:DAT /V /LOG+:$($logfolder)robocopy_$($startdate).txt "\\fileserver\eagle\20_SVILUPPO\32_area3D\20_progettiRiegl\umbria\" "D:\umbria\"