#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2
 Author:         Kornelius Heru Cakra Murti

 Script Function:
	Crawl over android project to populate all dependencies and resources for
	bilding an android Air Native Extension.

#ce ----------------------------------------------------------------------------

#include <Array.au3>
#include <MsgBoxConstants.au3>
#include <File.au3>
#include <FileConstants.au3>

; project settings, read on ini file nearby
$iniFiles = _FileListToArray(@ScriptDir, "*.ini", $FLTA_FILES, True);
$iniFile = $iniFiles[1];

$path				= IniRead($iniFile, 'settings','path','');
$ane_package_name 	= IniRead($iniFile, 'settings','ane_package_name','');
$air_namespace 		= IniRead($iniFile, 'settings','air_namespace','');
$cache_path			= IniRead($iniFile, 'settings','gradle_cache','');

ConsoleWrite( $path & @CRLF);
ConsoleWrite( $ane_package_name & @CRLF);
ConsoleWrite( $air_namespace & @CRLF);

; important constants
ConsoleWrite(@CRLF);
ConsoleWrite("+-----------------------------------------------------------------------------------------" & @CRLF);
ConsoleWrite("|_________________________________________________________________________________________" & @CRLF);
ConsoleWrite("|____________________________SUPA___MEGA__UKULELE__MEEEEEWWW___MEEEEWWW___________________" & @CRLF);
ConsoleWrite("|_________________________________________________________________________________________" & @CRLF);

ConsoleWrite("|PROJECT CONFIGURATION FILE : "&$iniFile&@CRLF);
ConsoleWrite("|PATH : "&$path&@CRLF);

; CRAWL FOR JARS
$allJars = _FileListToArrayRec($cache_path, "*.jar", $FLTAR_FILES, $FLTAR_RECUR, $FLTAR_SORT, $FLTAR_FULLPATH);
Local $jarNewNames = [];
Local $jarPath = [];

;check directory
DirCreate(@ScriptDir & "\temp\android\");

; rename jars
for $i=1 To UBound($allJars) - 1
   $name = $allJars[$i];
   $jarFilePath = $name;

   ; MAKE NAME SHORTER
   $name = StringReplace($name, $cache_path, "");
   $name = StringReplace($name, $path, "");
   $name = StringReplace($name, "\jars\classes.jar", "");
   $name = StringReplace($name, "_output", "");
   $name = StringReplace($name, ".jar", "");
   $name = StringReplace($name, "com.", "");
   $name = StringReplace($name, "android.", "");
   $name = StringReplace($name, "google.", "");
   $name = StringReplace($name, "org.", "");
   $name = StringReplace($name, "net.", "");

   ; MAKE NAME A LEGAL FILE NAME
   $name = StringReplace($name, ".", "_");
   $name = StringReplace($name, "\", "_");
   $name = StringReplace($name, "/", "_");
   $name = StringReplace($name, "-", "_");
   $name = StringReplace($name, "_", "");
   $name = $name&".jar";
   _ArrayAdd( $jarNewNames, $name);
   _ArrayAdd( $jarPath, $jarFilePath);

   ; copy the jars to temporary directory
   FileCopy($jarFilePath, @ScriptDir & "\temp\android\"&$name);
   Next

;CREATE platform.xml
$platformFile = FileOpen(@ScriptDir & "\platform.xml", $FO_OVERWRITE);
FileClose($platformFile);
$platformFile = FileOpen(@ScriptDir & "\platform.xml",  $FO_APPEND);
FileWrite($platformFile, "");
FileWriteLine($platformFile, '<platform xmlns="'&$air_namespace&'">');

; PACKAGE DEPENDENCIES
ConsoleWrite("|"&@CRLF);
ConsoleWrite("|POPULATING LIBRARY DEPENDENCIES" & @CRLF);
FileWriteLine($platformFile, @TAB&'<packagedDependencies>');
for $i=1 To UBound($jarNewNames) - 1
   FileWriteLine($platformFile, @TAB&@TAB&"<packagedDependency>"&$jarNewNames[$i]&"</packagedDependency>");
   ConsoleWrite("|" & @TAB & @TAB & $jarNewNames[$i] & @CRLF);
Next
FileWriteLine($platformFile, @TAB&'</packagedDependencies>');
FileWriteLine($platformFile, "");

;PACKAGE RESOURCES
FileWriteLine($platformFile, @TAB&'<packagedResources>');
FileWriteLine($platformFile, @TAB&@TAB&'<packagedResource>');
FileWriteLine($platformFile, @TAB&@TAB&@TAB&'<packageName>' & $ane_package_name & '</packageName>');
FileWriteLine($platformFile, @TAB&@TAB&@TAB&'<folderName>res</folderName>');
FileWriteLine($platformFile, @TAB&@TAB&'</packagedResource>');
FileWriteLine($platformFile, "");


; FIND ALL RES REQUIRED FOR THE BUILD
ConsoleWrite("|"&@CRLF);
ConsoleWrite("|POPULATING LIBRARY RESOURCES AND PACKAGES" & @CRLF);
$allJars = _FileListToArrayRec($cache_path, "", $FLTAR_FILESFOLDERS , $FLTAR_RECUR, $FLTAR_SORT, $FLTAR_FULLPATH);
Local $resFolders =[];
Local $resFolderNames =[];
for $i=1 To UBound($allJars) - 1
   $name = $allJars[$i];
   $res = StringRight($name, 4);
   ;ConsoleWrite($name&@CRLF);

   ; CHECK IF FOLDER IS A RESOURCE FOLDER
   if $res == '\res' Then
	  ; CHECK IF RESOURCE FOLDER CONTAINS ANY FILE
	  $tempArr =_FileListToArray($name);
	  ;ConsoleWrite($name&' : '& UBound($tempArr) &' files'&@CRLF);

	  if  UBound($tempArr) > 1 Then
		 _ArrayAdd($resFolders, $name);
		 $resdirname = $name;
		 $resdirname = StringReplace($resdirname, $cache_path, "");
		 $resdirname = StringReplace($resdirname, $path, "");
		 $resdirname = StringReplace($resdirname, "com.", "");
		 $resdirname = StringReplace($resdirname, "android", "");
		 $resdirname = StringReplace($resdirname, "google.", "");
		 $resdirname = StringReplace($resdirname, "org.", "");
		 $resdirname = StringReplace($resdirname, "net.", "");
		 $resdirname = StringReplace($resdirname, ".", "");
		 $resdirname = StringReplace($resdirname, "\", "");
		 $resdirname = StringReplace($resdirname, "/", "");
		 $resdirname = StringReplace($resdirname, "-", "");
		 $resdirname = StringReplace($resdirname, "_", "");
		 ;ConsoleWrite($resdirname&@CRLF);

		 ; CREATE RESH DIRECTORY
		 DirCreate(@ScriptDir & "\temp\android\"&$resdirname);

		 ; COPY ORIGINAL RESOURCE DIRECTORY TO RESULT DIRECTORY
		 DirCopy($name, @ScriptDir & "\temp\android\"&$resdirname, $FC_OVERWRITE);

		 ;  FIND WHAT IS THE PACKAGE NAME OF THE FILE
		 $manifestFilePath = $name;
		 ;ConsoleWrite($name&@CRLF);
		 $manifestFilePath = StringLeft($manifestFilePath, StringLen($manifestFilePath) - 4);
		 $manifestFilePath = $manifestFilePath & "\AndroidManifest.xml";
		 $manifestFile = FileOpen($manifestFilePath, $FO_READ);
		 $lineResult = FileReadLine($manifestFile);
		 $pos = -1;
		 while true
			$pos = StringInStr($lineResult,  'package="');
			if $pos > 0 Then
			   $pos2 = StringInStr($lineResult,  '"', 0, 1, $pos + 9);
			   $packageName = StringMid($lineResult, $pos + 9, $pos2 - $pos - 9);
			   ConsoleWrite("|" & @TAB & @TAB & $packageName & @CRLF);
			   FileWriteLine($platformFile, @TAB&@TAB&'<packagedResource>');
			   FileWriteLine($platformFile, @TAB&@TAB&@TAB&'<packageName>' & $packageName & '</packageName>');
			   FileWriteLine($platformFile, @TAB&@TAB&@TAB&'<folderName>'&$resdirname&'</folderName>');
			   FileWriteLine($platformFile, @TAB&@TAB&'</packagedResource>');
			   FileWriteLine($platformFile, "");
			   ExitLoop;
			   EndIf
			$lineResult = FileReadLine($manifestFile);

			if Not(@error == 0) Then
			   ExitLoop
			   EndIf
			WEnd

		 FileClose($manifestFile);

		 EndIf
	  EndIf
   Next
;_ArrayDisplay($resFolderNames, "Non-recur with filter")

FileWriteLine($platformFile, @TAB&'</packagedResources>');
FileWriteLine($platformFile, '</platform>');
FileClose($platformFile);
ConsoleWrite("|" & @CRLF);
ConsoleWrite("|_________________________________________________________________________________________" & @CRLF);
ConsoleWrite("+-----------------------------------------------------------------------------------------" & @CRLF);

ConsoleWrite("");