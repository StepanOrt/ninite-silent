#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=system_software_update.ico
#AutoIt3Wrapper_Outfile=ninite_silent_x86.exe
#AutoIt3Wrapper_Outfile_x64=ninite_silent_x64.exe
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_LegalCopyright=Štìpán Ort
#AutoIt3Wrapper_Res_Language=1029
#AutoIt3Wrapper_Res_Field=ProductName|Ninite Silent
#AutoIt3Wrapper_Res_Field=ProductVersion|1
#AutoIt3Wrapper_Res_Field=InternalName|Ninite Silent
#AutoIt3Wrapper_Res_Field=OriginalFilename|ninite_silent.exe
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Array.au3>
#include <StaticConstants.au3>
#include <Process.au3>
#include <Misc.au3>

$APP_NAME = "Ninite Silent"

_Singleton($APP_NAME)

$NINITE_FILE_NAME = IniRead("config.ini", "Ninite", "FileName", "ninite.exe")

$SETTING_LANG = IniRead("config.ini", "Language", "id", -1)
$ANSWER_BUTTONS = IniRead("config.ini", "Answers", "codes", "-1;1;32;64")
$answerCodes = StringSplit($ANSWER_BUTTONS, ";")

Local $langFile = getLangFile($SETTING_LANG)

Local $SINGLETON_CHECK_MESSAGE = IniRead($langFile, "Translation", "singleton_check", "Close all running instances of Ninite before continue!")
Local $UPDATE_DONE_MESSAGE = IniRead($langFile, "Translation", "update_done", "Instalations finished")
Local $AFTER_FINISH_QUESTION_MESSAGE = IniRead($langFile, "Translation", "after_finish_question", "What do you want to do after installations?")
Local $NINITE_NOT_EXIST_MESSAGE = IniRead($langFile, "Translation", "ninite_not_exist", "Ninite executable does not exist!")
Local $translations = IniReadSection($langFile, "Translation")
If @error Then
	$translations = -1
EndIf

If Not FileExists($NINITE_FILE_NAME) Then
	MsgBox(16, $APP_NAME, $NINITE_NOT_EXIST_MESSAGE)
	Exit
EndIf

Local $defaultTranslations[4][2]
$defaultTranslations[0][0] = -1
$defaultTranslations[0][1] = "Nothing"
$defaultTranslations[1][0] = 1
$defaultTranslations[1][1] = "Shutdown"
$defaultTranslations[2][0] = 32
$defaultTranslations[2][1] = "Suspend"
$defaultTranslations[3][0] = 64
$defaultTranslations[3][1] = "Hibernate"

Local $numButtons = $answerCodes[0]
Local $answerArray[$numButtons][2]
For $i = 1 To $numButtons
	Local $answerCode = $answerCodes[$i]
	Local $label = ""
	For $j = 0 To UBound($defaultTranslations, 1) - 1
		If $answerCode = $defaultTranslations[$j][0] Then
			$label = $defaultTranslations[$j][1]
			ExitLoop
		EndIf
	Next
	If $translations <> -1 Then
		For $j = 1 To $translations[0][0]
			If $answerCode = $translations[$j][0] Then
				$label = $translations[$j][1]
				ExitLoop
			EndIf
		Next
	EndIf

	If $label = "" Then
		$label = $answerCode
	EndIf
	$answerArray[$i - 1][0] = $answerCode
	$answerArray[$i - 1][1] = $label
Next

Opt("WinTitleMatchMode", 3)


While ProcessExists($NINITE_FILE_NAME)
   Local $pid = ProcessExists($NINITE_FILE_NAME)
   Local $winList = WinList("Ninite")
   For $i = 1 To $winList[0][0]
	  Local $title = $winList[$i][0]
	  $p = WinGetProcess($title)
	  WinActivate($title)
   Next
   MsgBox(48, $APP_NAME, $SINGLETON_CHECK_MESSAGE)
   ProcessWaitClose($pid)
WEnd



Local $shutdownCode = FinishDialog($answerArray, $AFTER_FINISH_QUESTION_MESSAGE)

Local $pid = Run($NINITE_FILE_NAME)
Local $buttonText = ""
Do
   Sleep(100)
   If WinExists("Ninite") Then
	  $buttonText = ControlGetText("Ninite", "", "[CLASS:Button]")
   EndIf
Until $buttonText = "Close"
ControlClick ("Ninite", "Close", "[CLASS:Button]")
Local $begin = TimerInit()
$dif = 0
While ProcessExists($pid) Or $dif > 5000
   $dif = TimerDiff($begin)
WEnd
If ProcessExists($pid) Then
   ProcessClose($pid)
   WinKill("Ninite")
EndIf

RegistryCleanUp()

If $shutdownCode >= 0 Then
   Shutdown($shutdownCode)
Else
	MsgBox(0, $APP_NAME, $UPDATE_DONE_MESSAGE)
EndIf

Func getLangFile(Const $settingsLang)
	$langToCheck = @OSLang

	If $settingsLang <> -1 Then
		$langToCheck = $settingsLang
	EndIf
	Local $search = FileFindFirstFile("lang\*.lang")
	If $search <> -1 Then
		While 1
			Local $file = FileFindNextFile($search)
			If @error Then ExitLoop
			$file = "lang\" & $file
			Local $langid = IniRead($file, "Language", "id", "")
			If $langid = $langToCheck Then
				FileClose($search)
				Return $file
			EndIf
		WEnd
	EndIf
	FileClose($search)
	Return ""
EndFunc

Func RegistryCleanUp()
	$ini = IniReadSection("config.ini", "AutoUpdatersRegistryKeys")
	If $ini <> 0 Then
		For $i = 1 To $ini[0][0]
			$key = $ini[$i][1]
			RegDelete("HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run", $key)
			RegDelete("HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", $key)
			RegDelete("HKLM64\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run", $key)
			RegDelete("HKLM64\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", $key)
			RegDelete("HKCU\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run", $key)
			RegDelete("HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", $key)
			RegDelete("HKCU64\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run", $key)
			RegDelete("HKCU64\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", $key)
		Next
	EndIf
EndFunc

Func FinishDialog($answerArray, $message)
   Local $buttonGap = 5
   Local $padding = 10
   Local $buttonPadding = 5
   Local $charWidth = 6

   Local $numButtons = UBound($answerArray, 1)
   Local $handlersArray[$numButtons]

   Local $longestButtonLabel = 0
   For $i = 0 To $numButtons - 1
	  $len = StringLen($answerArray[$i][1])
	  If $len  > $longestButtonLabel Then
		 $longestButtonLabel = StringLen($answerArray[$i][1])
	  EndIf
   Next

   Local $buttonWidth = $longestButtonLabel * $charWidth + 2 * $buttonPadding
   Local $labelLen = StringLen($message) * $charWidth;
   Local $labelWidth = $numButtons * $buttonWidth + ($numButtons - 1) * $buttonGap
   Local $left = $padding
   If $labelLen > $labelWidth Then
	   $left = $padding + ($labelLen - $labelWidth) / 2
	   $labelWidth = $labelLen
   EndIf
   Local $windowWidth = $labelWidth + $padding * 2 + 4

   GUICreate($APP_NAME, $windowWidth, 96 , -1 , -1, $WS_SYSMENU)
   GUICtrlCreateLabel ($message, $padding,  $padding, $labelWidth, 16, $SS_CENTER)

   For $i = 0 To $numButtons - 1
	  $handlersArray[$i] = GUICtrlCreateButton($answerArray[$i][1], $left, 32, $buttonWidth)
	  $left = $left + $buttonWidth + $buttonGap
   Next

   Local $shutdownCode = -1

   GUISetState(@SW_SHOW)
   While 1
	  $msg = GUIGetMsg()
	  If $msg = $GUI_EVENT_CLOSE Then
		 GUIDelete()
		 Exit
	  EndIF

	  For $i = 0 To $numButtons - 1
		 $handler = $handlersArray[$i]
		 If $msg = $handler Then
			$shutdownCode = $answerArray[$i][0]
			GUIDelete()
			Return $shutdownCode
		 EndIf
	  Next
   WEnd
EndFunc