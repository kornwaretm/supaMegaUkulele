#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2
 Author:         Kornelius Heru Cakra Murti

 Script Function:
   Air Native Extension Packager.

#ce ----------------------------------------------------------------------------

#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <File.au3>
#include <FileConstants.au3>
#include <MsgBoxConstants.au3>
#include <EditConstants.au3>


; global project constants
Global $supaMegaUkulelePath = @ScriptDir&'\';
Global $mainProjectPath = ""	; path to the main directory, the directory of the .ini directory
Global $projectFile = ""		; path of the project.ini file
Global $projectPath = ""		; path to the android studio project
Global $as3SourcePath = ""		; path to the as3 source path
Global $flexSDKPath = ""		; path to Flex / ASC SDK
Global $binExtension = ".exe"	; .exe or .bat, differs between SDKs
Global $swfVersion = "37"		; SWF version
Global $airNamespace = ""		; air name space used in xmls ex : "http://ns.adobe.com/air/extension/26.0.0"
Global $anePackageName = ""		; the package name ex : com.mycompany.myane
Global $aneName = ""			; the resulting .ane file ex myane. do not supply extension
Global $initializer = ""		; initializer  ex : com.mycompany.myane.myanemainclass
Global $finalizer = ""			; finalizer ex : com.mycompany.myane.myanemainclass
Global $extensionVersion = ""	; user defined version of the ane
Global $cacheLocation = ""		; gladle build cache location


; gui element for anywhere access
Global $console, $flexPath, $binExten, $swfVersi, $airNames
Global $aneNameTxt, $anePackageTxt, $initializerTxt
Global $finalizerTxt, $as3PathTxt, $androidProjectTxt
Global $anePackageTxt, $aneVersionTxt, $cachePathTxt

Global $swfVersions   = []
Global $airNamespaces = []

Func getDOSOutput($sCMD, $dir)
   Local       $sTMP = ''
   Local       $sSTD = ''
   Local       $sCOM = @ComSpec & ' /c ' & $sCMD
   Local Const $iPID = Run($sCOM, $dir, @SW_HIDE, 2 + 4)

   While True
	  $sTMP = StdoutRead($iPID, False, False)
	  If @error Then
		 ExitLoop 1
	  ElseIf $sTMP Then
		 $sTMP  = StringReplace($sTMP, @CR & @CR, '')
		 $sSTD &= $sTMP
		 ConsoleWrite($sTMP)
		 GUICtrlSetData($console, $sSTD);
		 Sleep(50);
	  EndIf
   WEnd
   GUICtrlSetData($console, $sSTD);
   Return SetError(@error, @extended, $sSTD)
EndFunc

Func errorAlert($msg)
   MsgBox($MB_SYSTEMMODAL, "ERROR", $msg, 10)
EndFunc

Func createBuildConfig()

   ; empty file
   $handler = FileOpen("build-conf.config", $FO_OVERWRITE);
   FileWrite($handler,"");
   FileClose($handler);

   ;start building config file
   $handler = FileOpen('build-conf.config', $FO_APPEND);
   FileWriteLine($handler, 'flex.sdk = ' & $flexSDKPath);
   FileWriteLine($handler, 'bin.ext = ' & $binExtension);
   FileWriteLine($handler, 'arr_name =  app-release.aar');
   FileWriteLine($handler, 'android_aar = '& $projectPath &'/app/build/outputs/aar/');
   FileWriteLine($handler, 'SWF_VERSION = '& $swfVersion);
   FileWriteLine($handler, 'name = ' & $aneName);
   FileWriteLine($handler, 'DEBUG = false');
   FileWriteLine($handler, 'EXTENSION_XML = ../extension.xml');
   FileWriteLine($handler, 'as3source = '&$as3SourcePath);
   FileClose($handler);
EndFunc

Func createExtensionXML()
   ; empty file
   $handler = FileOpen("extension.xml", $FO_OVERWRITE);
   FileWrite($handler,"");
   FileClose($handler);

   ;start building extension file
   $handler = FileOpen('extension.xml', $FO_APPEND);
   FileWriteLine($handler, '<extension xmlns="'& $airNamespace &'">');
   FileWriteLine($handler, @TAB&'<id>'& $anePackageName &'</id>');
   FileWriteLine($handler, @TAB&'<versionNumber>'& $extensionVersion &'</versionNumber>');
   FileWriteLine($handler, @TAB&'<platforms>');
   FileWriteLine($handler, @TAB&@TAB&'<platform name="Android-ARM">');
   FileWriteLine($handler, @TAB&@TAB&@TAB&'<applicationDeployment>');
   FileWriteLine($handler, @TAB&@TAB&@TAB&@TAB&'<nativeLibrary>'& $aneName &'.jar</nativeLibrary>');
   FileWriteLine($handler, @TAB&@TAB&@TAB&@TAB&'<initializer>'& $initializer &'</initializer>');
   FileWriteLine($handler, @TAB&@TAB&@TAB&@TAB&'<finalizer>'& $finalizer &'</finalizer>');
   FileWriteLine($handler, @TAB&@TAB&@TAB&'</applicationDeployment>');
   FileWriteLine($handler, @TAB&@TAB&'</platform>');
   FileWriteLine($handler, @TAB&'</platforms>');
   FileWriteLine($handler, '</extension>');
   FileClose($handler);
EndFunc

Func createBuildXML()
   ; empty file
   $handler = FileOpen("build.xml", $FO_OVERWRITE);
   FileWrite($handler,"");
   FileClose($handler);

   $handler = FileOpen('build.xml', $FO_APPEND);
   FileWriteLine($handler, '<?xml version="1.0" encoding="UTF-8"?>');
   FileWriteLine($handler, '<project name="Air Native Extension Build Scripts" default="android-all">');
   FileWriteLine($handler, @TAB&'<property file="build-conf.config"/>');

   ; default task
   FileWriteLine($handler, @TAB&'<target name="android-all" depends="clean,android,supa_mega_ukulele,swc,package" description="Full build of extension"/>')

   ; project clean up task
   FileWriteLine($handler, @TAB&'<target name="clean" description="clean up all">')
   FileWriteLine($handler, @TAB&@TAB&'<delete dir="temp/"/>')
   FileWriteLine($handler, @TAB&'</target>')

   ; android build task
   FileWriteLine($handler, @TAB&'<target name="android" description="Build Android Library with debugging disabled">')
   FileWriteLine($handler, @TAB&@TAB&'<mkdir dir="temp/aar/"/>')
   FileWriteLine($handler, @TAB&@TAB&'<mkdir dir="temp/android/"/>')
   FileWriteLine($handler, @TAB&@TAB&'<copy todir="temp/" file="${android_aar}${arr_name}"/>')
   FileWriteLine($handler, @TAB&@TAB&'<unzip src="temp/${arr_name}" dest="temp/aar/" overwrite="true"/>')
   FileWriteLine($handler, @TAB&@TAB&'<copy tofile="temp/android/${name}.jar" file="temp/aar/classes.jar"/>')
   FileWriteLine($handler, @TAB&@TAB&'<copy todir="temp/android/res"><fileset dir="temp/aar/res"/></copy>')
   FileWriteLine($handler, @TAB&@TAB&'<delete dir="temp/aar"/>')
   FileWriteLine($handler, @TAB&@TAB&'<delete file="temp/${arr_name}"/>')
   FileWriteLine($handler, @TAB&@TAB&'<mkdir dir="temp/jar/"/>')
   FileWriteLine($handler, @TAB&@TAB&'<unzip src="temp/android/${name}.jar" dest="temp/jar/" overwrite="true"/>')
   FileWriteLine($handler, @TAB&@TAB&'<delete dir="temp/jar/com/adobe"/>')
   FileWriteLine($handler, @TAB&@TAB&'<jar basedir="temp/jar/" destfile="temp/android/${name}.jar" />')
   FileWriteLine($handler, @TAB&@TAB&'<delete dir="temp/jar"/>')
   FileWriteLine($handler, @TAB&'</target>')

   ; repacker task
   FileWriteLine($handler, @TAB&'<target name="supa_mega_ukulele" description="pack library">')
   FileWriteLine($handler, @TAB&@TAB&'<exec executable="repacker.exe" failonerror="true" dir="temp/"></exec>')
   FileWriteLine($handler, @TAB&'</target>')

   ; build as3 part, the swc
   FileWriteLine($handler, @TAB&'<target name="swc" description="Build SWC library">')
   FileWriteLine($handler, @TAB&@TAB&'<mkdir dir="temp/swc/content/"/>')
   FileWriteLine($handler, @TAB&@TAB&'<fileset dir="${as3source}" casesensitive="yes" id="classfiles">')
   FileWriteLine($handler, @TAB&@TAB&@TAB&'<include name="**/*.as"/>')
   FileWriteLine($handler, @TAB&@TAB&'</fileset>')
   FileWriteLine($handler, @TAB&@TAB&'<pathconvert property="classlist" refid="classfiles" pathsep=" " dirsep=".">')
   FileWriteLine($handler, @TAB&@TAB&@TAB&'<regexpmapper from=".*src.(.*)\.as" to="\1"/>')
   FileWriteLine($handler, @TAB&@TAB&'</pathconvert>')
   FileWriteLine($handler, @TAB&@TAB&'<exec executable="${flex.sdk}/bin/compc${bin.ext}" failonerror="true">')
   FileWriteLine($handler, @TAB&@TAB&@TAB&'<env key="AIR_SDK_HOME" value="${flex.sdk}"/>')
   FileWriteLine($handler, @TAB&@TAB&@TAB&'<arg line='&"'"&'+configname=airmobile'&"'"&'/>')
   FileWriteLine($handler, @TAB&@TAB&@TAB&'<arg line='&"'"&'-source-path ${as3source}'&"'"&'/>')
   FileWriteLine($handler, @TAB&@TAB&@TAB&'<arg line='&"'"&'-output temp/swc/${name}.swc'&"'"&'/>')
   FileWriteLine($handler, @TAB&@TAB&@TAB&'<arg line='&"'"&'-swf-version=${SWF_VERSION}'&"'"&'/>')
   FileWriteLine($handler, @TAB&@TAB&@TAB&'<arg line='&"'"&'-external-library-path+="${flex.sdk}/frameworks/libs/air/airglobal.swc"'&"'"&'/>')
   FileWriteLine($handler, @TAB&@TAB&@TAB&'<arg line='&"'"&'-include-classes ${classlist}'&"'"&'/>')
   FileWriteLine($handler, @TAB&@TAB&'</exec>')
   FileWriteLine($handler, @TAB&@TAB&'<unzip src="temp/swc/${name}.swc" dest="temp/swc/content" overwrite="true"/>')
   FileWriteLine($handler, @TAB&@TAB&'<copy file="temp/swc/content/library.swf" todir="temp/android" overwrite="true"/>')
   FileWriteLine($handler, @TAB&@TAB&'<copy file="temp/swc/content/library.swf" todir="temp/default" overwrite="true"/>')
   FileWriteLine($handler, @TAB&'</target>')

   FileWriteLine($handler, @TAB&'<target name="package" description="Create the extension package">')
   FileWriteLine($handler, @TAB&@TAB&'<property name="TARGET_ANE" value="${name}.ane"/>')
   FileWriteLine($handler, @TAB&@TAB&'<property name="SWC_LIB" value="swc/${name}.swc"/>')
   FileWriteLine($handler, @TAB&@TAB&'<exec executable="${flex.sdk}/bin/adt${bin.ext}" failonerror="true" dir="temp/">')
   FileWriteLine($handler, @TAB&@TAB&@TAB&'<arg line="-package"/>')
   FileWriteLine($handler, @TAB&@TAB&@TAB&'<arg line="-target ane ${TARGET_ANE} ${EXTENSION_XML}"/>')
   FileWriteLine($handler, @TAB&@TAB&@TAB&'<arg line="-swc ${SWC_LIB}"/>')
   FileWriteLine($handler, @TAB&@TAB&@TAB&'<arg line="-platform Android-ARM"/>')
   FileWriteLine($handler, @TAB&@TAB&@TAB&'<arg line="-platformoptions ../platform.xml"/>')
   FileWriteLine($handler, @TAB&@TAB&@TAB&'<arg line="-C android/ ."/>')
   FileWriteLine($handler, @TAB&@TAB&'</exec>')
   FileWriteLine($handler, @TAB&@TAB&'<move file="temp/${name}.ane" todir="bin"/>')
   FileWriteLine($handler, @TAB&'</target>')
   FileWriteLine($handler, '</project>');
   FileClose($handler);

EndFunc

Func populateSWFVersions()
   $swfVersionsText = "";
   _ArrayDelete($airNamespaces, "0-"&UBound($airNamespaces));
   _ArrayDelete($swfVersions, "0-"&UBound($swfVersions));

   $filehadle = FileOpen($flexSDKPath&'\airsdk.xml');
   $result = "";

   $begin = '<descriptorNamespace>'
   $end = '</descriptorNamespace>'
   $beginlen = StringLen($begin);

   $begin2 = '<swfVersion>'
   $end2 = '</swfVersion>'
   $beginlen2 = StringLen($begin2);

   ;skip to the extension namespace
   $lineResult = FileReadLine($filehadle);
   while true
	  $pos = StringInStr($lineResult,  '</applicationNamespaces>');
	  if $pos > 0 Then
		 ExitLoop;
	  EndIf

	  if Not(@error == 0) Then
		 ExitLoop
	  EndIf
	  $lineResult = FileReadLine($filehadle);
   WEnd

   ConsoleWrite('all application skipped '&@CRLF);

   $lineResult = FileReadLine($filehadle);
   while true
	  ; namespace sxtraction
	  $pos = StringInStr($lineResult,  $begin);
	  if $pos > 0 Then
		 $pos2 = StringInStr($lineResult,  $end, 0, 1, $pos + $beginlen);
		 $result = StringMid($lineResult, $pos + $beginlen, $pos2 - $pos - $beginlen);
		 _ArrayAdd($airNamespaces, $result);
	  EndIf

	  ; swf version extraction
	  $lineResult = FileReadLine($filehadle);
	  if Not(@error == 0) Then
		 ExitLoop
	  EndIf

	  $pos = StringInStr($lineResult,  $begin2);
	  if $pos > 0 Then
		 $pos2 = StringInStr($lineResult,  $end2, 0, 1, $pos + $beginlen2);
		 $result = StringMid($lineResult, $pos + $beginlen2, $pos2 - $pos - $beginlen2);
		 $swfVersionsText &= $result & '|';
		 _ArrayAdd($swfVersions, $result);
	  EndIf

	  $lineResult = FileReadLine($filehadle);
	  if Not(@error == 0) Then
		 ExitLoop
	  EndIf
   WEnd
   FileClose($filehadle);

   $swfVersionsText = StringLeft($swfVersionsText, StringLen($swfVersionsText) - 1);
   GUICtrlSetData($swfVersi, $swfVersionsText, $swfVersion);
   updateAIRNamespace();
EndFunc

Func updateAIRNamespace();
   $swfVersion = GUICtrlRead($swfVersi);
   For $i = 0 To UBound($swfVersions)
	  If $swfVersions[$i] == $swfVersion Then
		 $swfVersion = $swfVersions[$i];
		 $airNamespace = $airNamespaces[$i];
		 GUICtrlSetData($airNames, $airNamespace);
		 Return;
	  EndIf
   Next
EndFunc

Func saveProject()
   $projectPath 	= StringReplace($projectPath, '\', '/');
   $flexSDKPath 	= StringReplace($flexSDKPath, '\', '/');
   $cacheLocation 	= StringReplace($cacheLocation, '\', '/');
   $as3SourcePath 	= StringReplace($as3SourcePath, '\', '/');

   IniWrite($projectFile, 'settings', 'path', $projectPath);
   IniWrite($projectFile, 'settings', 'ane_package_name', $anePackageName);
   IniWrite($projectFile, 'settings', 'air_namespace', $airNamespace);
   IniWrite($projectFile, 'settings', 'flex_sdk_path', $flexSDKPath);
   IniWrite($projectFile, 'settings', 'bin_extension', $binExtension);
   IniWrite($projectFile, 'settings', 'swf_version', $swfVersion);
   IniWrite($projectFile, 'settings', 'ane_package_name', $anePackageName);
   IniWrite($projectFile, 'settings', 'air_namespace', $airNamespace);
   IniWrite($projectFile, 'settings', 'ane_name', $aneName);
   IniWrite($projectFile, 'settings', 'initializer', $initializer);
   IniWrite($projectFile, 'settings', 'finalizer', $finalizer);
   IniWrite($projectFile, 'settings', 'gradle_cache', $cacheLocation);
   IniWrite($projectFile, 'settings', 'version', $extensionVersion);
   IniWrite($projectFile, 'settings', 'as3_source_path', $as3SourcePath);
EndFunc

Func openProject()
   $projectFile = FileOpenDialog ( "Select project", $supaMegaUkulelePath, "Ini file (*.ini)" );

   if @error == 1 Then
	  Return;
   EndIf

   $projectPath 	= IniRead($projectFile, 'settings', 'path', "");
   $anePackageName 	= IniRead($projectFile, 'settings', 'ane_package_name', "");
   $airNamespace 	= IniRead($projectFile, 'settings', 'air_namespace', "");
   $flexSDKPath 	= IniRead($projectFile, 'settings', 'flex_sdk_path', "");
   $binExtension 	= IniRead($projectFile, 'settings', 'bin_extension', "");
   $swfVersion 		= IniRead($projectFile, 'settings', 'swf_version', "");
   $airNamespace	= IniRead($projectFile, 'settings', 'air_namespace', "");
   $anePackageName 	= IniRead($projectFile, 'settings', 'ane_package_name', "");
   $aneName			= IniRead($projectFile, 'settings', 'ane_name', "");
   $initializer		= IniRead($projectFile, 'settings', 'initializer', "");
   $finalizer		= IniRead($projectFile, 'settings', 'finalizer', "");
   $cacheLocation 	= IniRead($projectFile, 'settings', 'gradle_cache', "");
   $extensionVersion= IniRead($projectFile, 'settings', 'version', "");
   $as3SourcePath	= IniRead($projectFile, 'settings', 'as3_source_path', "");

   $projectPath 	= StringReplace($projectPath, '\', '/');
   $flexSDKPath 	= StringReplace($flexSDKPath, '\', '/');
   $cacheLocation 	= StringReplace($cacheLocation, '\', '/');
   $as3SourcePath 	= StringReplace($as3SourcePath, '\', '/');

   GUICtrlSetData($androidProjectTxt, $projectPath);
   GUICtrlSetData($anePackageTxt, $anePackageName);
   GUICtrlSetData($airNames, $airNamespace);
   GUICtrlSetData($flexPath, $flexSDKPath);
   GUICtrlSetData($binExten, $binExtension);
   GUICtrlSetData($swfVersi, $swfVersion);
   GUICtrlSetData($anePackageTxt, $anePackageName);
   GUICtrlSetData($aneNameTxt, $aneName);
   GUICtrlSetData($initializerTxt, $initializer);
   GUICtrlSetData($finalizerTxt, $finalizer);
   GUICtrlSetData($aneVersionTxt, $extensionVersion);
   GUICtrlSetData($cachePathTxt, $cacheLocation);
   GUICtrlSetData($as3PathTxt, $as3SourcePath);

   $sDrive = ""
   $sDir = ""
   $sFileName = ""
   $sExtension = ""
   $aPathSplit = _PathSplit($projectFile, $sDrive, $sDir, $sFileName, $sExtension)
   $mainProjectPath = $sDrive&$sDir;
   $mainProjectPath= StringReplace($mainProjectPath, '\\', '/', "");
   FileChangeDir($mainProjectPath);

   populateSWFVersions();

EndFunc

Func changeFlexSDK()
   ; get  the flex sdk
   $flexSDKPath = FileSelectFolder ( "Point your Flex SDK location", $supaMegaUkulelePath )

   ; check folder selection
   if @error == 1 Then
	  ; folder selection failed, user cancel or window closed
	  Return;
   EndIf

   ; get AIR namespace
   if Not(FileExists($flexSDKPath&'\air-sdk-description.xml')) Then
	  errorAlert('path selected is not a valid flex SDK');
	  Return;
   EndIf

   ; populate swf version

   ; set Flex SDK path text
   GUICtrlSetData($flexPath, $flexSDKPath);

   ; get adt extension
   $fileSearch = FileFindFirstFile($flexSDKPath &'\bin\adt.*');
   $adtFile = FileFindNextFile($fileSearch);
   $binExtension = StringRight($adtFile, 4);
   GUICtrlSetData($binExten, $binExtension);

   $descriptor = FileOpen($flexSDKPath&'\air-sdk-description.xml');
   $lineResult = FileReadLine($descriptor);
   while true
	  $pos = StringInStr($lineResult,  '<version>');
	  if $pos > 0 Then
		 $pos2 = StringInStr($lineResult,  '</version>', 0, 1, $pos + 9);
		 $airNamespace = StringMid($lineResult, $pos + 9, $pos2 - $pos - 9);
		 GUICtrlSetData($airNames, $airNamespace);
		 ExitLoop;
	  EndIf

	  if Not(@error == 0) Then
		 ExitLoop
	  EndIf

	  $lineResult = FileReadLine($descriptor);
   WEnd
   FileClose($descriptor);

   saveProject();
EndFunc

Func changeAndroidStudioProject()
   ; get  the flex sdk
   $projectPath = FileSelectFolder ( "Point your Android Studio Project location", $supaMegaUkulelePath )

   ; check folder selection
   if @error == 1 Then
	  ; folder selection failed, user cancel or window closed
	  Return;
   EndIf

   ; check the gradle.properties for cache-settings and location
   if Not(FileExists($projectPath&'\gradle.properties')) Then
	  errorAlert('path selected is not a valid android studio project');
	  Return;
   EndIf

   ; check if build cache is enabled
   $cacheEnable = searchStringInFileBetween($projectPath&'\gradle.properties', 'android.enableBuildCache=', @CRLF);
   If ($cacheEnable == '') Or ($cacheEnable == 'false') Then
	  errorAlert('cache is not enabled'&@CRLF&'to enable build cache, put'&@CRLF&'android.enableBuildCache=true'&@CRLF&'in your gradle.properties file');
	  Return;
   EndIf

   ; check if cache path is valid
   $cacheLocation = searchStringInFileBetween($projectPath&'\gradle.properties', 'android.buildCacheDir=', @CRLF);
   If $cacheLocation == '' Then
	  errorAlert('cache path is not specified'&@CRLF&'to specify cache path, put'&@CRLF&'android.buildCacheDir=dir_to_your_cache'&@CRLF&'in your gradle.properties file');
	  Return;
   EndIf

   ; check if cache path is good
   IF Not(FileExists($cacheLocation)) then
	  errorAlert('could not found or understand the location of ['&$cacheLocation&']'&@CRLF&'please makesure the path is exist and use absolute path.');
	  Return;
   EndIf

   ; set android studio project path
   GUICtrlSetData($androidProjectTxt, $projectPath);
   GUICtrlSetData($cachePathTxt, $cacheLocation);

   saveProject()
EndFunc

Func changeAS3Path()
   $as3SourcePath = FileSelectFolder ( "Point your Android Studio Project location", $supaMegaUkulelePath )

   ; check folder selection
   if @error == 1 Then
	  ; folder selection failed, user cancel or window closed
	  Return;
   EndIf

   saveProject();
EndFunc

Func searchStringInFileBetween($file, $begin, $end)
   $filehadle = FileOpen($file);
   $lineResult = FileReadLine($filehadle);
   $beginlen = StringLen($begin);
   $result = "";
   while true
	  $pos = StringInStr($lineResult,  $begin);
	  if $pos > 0 Then
		 $pos2 = StringInStr($lineResult,  $end, 0, 1, $pos + $beginlen);
		 $result = StringMid($lineResult, $pos + $beginlen, $pos2 - $pos - $beginlen);
		 ExitLoop;
	  EndIf

	  if Not(@error == 0) Then
		 ExitLoop
	  EndIf

	  $lineResult = FileReadLine($filehadle);
   WEnd
   FileClose($filehadle);

   ; return result
   Return $result;
EndFunc

Func buildProject()
   ; creating extension.xml
   createExtensionXML();

   ; creating build config
   createBuildConfig();

   ; create build xml
   createBuildXML();

   ; copy repacker.exe to build dir
   FileCopy($supaMegaUkulelePath&'/repacker.exe', $mainProjectPath&'/repacker.exe', $FC_OVERWRITE );

   ; executing ant build, full build command
   ConsoleWrite($mainProjectPath);
   getDOSOutput("ant", $mainProjectPath);

   EndFunc

Func updateAIRNamespaceAndSave()
   updateAIRNamespace();
   saveProject();
EndFunc

Func main()
   $hGUI = GUICreate("Supa Mega Ukulele", 1200, 700)
   $openProjectBtn = GUICtrlCreateButton( "open project" , 5 , 5, 100, 20);
   $buildProjectBtn = GUICtrlCreateButton( "build project" , 110 , 5, 100, 20);

   ; tool setting group
   GUICtrlCreateGroup("Tool settings", 5, 30, 390, 130);

   GUICtrlCreateLabel("Flex SDK path ",20, 60);
   GUICtrlCreateLabel("Bin extension ",20, 80);
   GUICtrlCreateLabel("AIR namespace ",20, 100);
   GUICtrlCreateLabel("SWF version "  ,20, 120);

   $flexPath = GUICtrlCreateInput("", 120, 58, 230, 20);
   GUICtrlSetState($flexPath, $GUI_DISABLE);
   $changeFlexBtn = GUICtrlCreateButton("...",350, 58,20,20);

   $binExten = GUICtrlCreateInput("", 120, 78, 230, 20);
   GUICtrlSetState($binExten, $GUI_DISABLE);
   $airNames = GUICtrlCreateInput("", 120, 98, 230, 20);
   GUICtrlSetState($airNames, $GUI_DISABLE);
   ;$swfVersi = GUICtrlCreateInput("", 120, 118, 230, 20);
   $swfVersi = GUICtrlCreateCombo("", 120, 118, 230, 20);

   ; project setting group
   GUICtrlCreateGroup("Project settings", 5, 170, 390, 220);
   GUICtrlCreateLabel("ANE name ",20, 200);
   GUICtrlCreateLabel("ANE package name ",20, 220);
   GUICtrlCreateLabel("ANE initializer ",20, 240);
   GUICtrlCreateLabel("ANE finalizer ",20, 260);
   GUICtrlCreateLabel("AS3 source directory ",20, 280);
   GUICtrlCreateLabel("Android studio path ",20, 300);
   GUICtrlCreateLabel("Gradle cache path ",20, 320);
   GUICtrlCreateLabel("ANE version ",20, 340);

   $aneNameTxt = GUICtrlCreateInput("", 120, 198, 230, 20);
   $anePackageTxt = GUICtrlCreateInput("", 120, 218, 230, 20);
   $initializerTxt = GUICtrlCreateInput("", 120, 238, 230, 20);
   $finalizerTxt = GUICtrlCreateInput("", 120, 258, 230, 20);

   $as3PathTxt = GUICtrlCreateInput("", 120, 278, 230, 20);
   GUICtrlSetState($as3PathTxt, $GUI_DISABLE);
   $changeAs3PathBtn = GUICtrlCreateButton("...",350, 278,20,20);
   $androidProjectTxt = GUICtrlCreateInput("", 120, 298, 230, 20);
   GUICtrlSetState($androidProjectTxt, $GUI_DISABLE);
   $changeAndroidPath = GUICtrlCreateButton("...",350, 298,20,20);
   $cachePathTxt = GUICtrlCreateInput("", 120, 318, 230, 20);
   GUICtrlSetState($cachePathTxt, $GUI_DISABLE);
   $aneVersionTxt = GUICtrlCreateInput("", 120, 338, 230, 20);

   ; side console
   $console = GUICtrlCreateEdit("", 405, 5, 790, 690, $WS_VSCROLL);
   ;GUICtrlSetState($console, $GUI_DISABLE);

   GUISetState(@SW_SHOW)

   Local $iMsg = 0

   While 1
	  $iMsg = GUIGetMsg()
	  Switch $iMsg
		 Case $swfVersi
			updateAIRNamespaceAndSave();
		 case $changeAs3PathBtn
			changeAS3Path();
		 Case $buildProjectBtn
			buildProject();
		 Case $changeAndroidPath
			changeAndroidStudioProject();
		 Case $changeFlexBtn
			changeFlexSDK()
		 Case $openProjectBtn
			openProject()
		 Case $GUI_EVENT_CLOSE
			ExitLoop
		 EndSwitch
   WEnd
   GUIDelete($hGUI)
EndFunc

main();