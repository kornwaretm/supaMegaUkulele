# supaMegaUkulele
tool for building android ANE (Air Native Extension)

Required tool
1. AIR sdk, Android studio + Android SDK
2. apache ANT
3. AutoIt

How to build your ANE with android studio
1. follow the instruction from here  http://www.myflashlabs.com/build-ane-android-studio/
2. setting up your build.xml

   here is a sample content of build-conf.config
    ```batch
    flex.sdk = path_to_your_AIR_sdk/ascsdk/26.0.0
    bin.ext = .bat
    arr_name =  app-release.aar
    android_aar = path_to_your_android_studio_project/app/build/outputs/aar/
    SWF_VERSION = 32
    name = name_your_ane
    DEBUG = false
    EXTENSION_XML = path_to_your_extension_xml_file/extension.xml
    ```
    
    <project name="Air Native Extension Build Scripts" default="android-all">
    <target name="android-all" depends="clean,android,supa_mega_ukulele,swc,package" description="Full build of extension"/>
    
   here is the clean up section. delete the temp directory
   ```xml
    <target name="clean" description="clean up all">
		<delete dir="temp/"/>
	  </target>
    ```
    
   here is example of your build xml file. this section processes the aar file created by android studio 
   build process. this process extracted .jar and res out from the aar file.
    ```xml
    <target name="android" description="Build Android Library with debugging disabled">
		<!-- process arr -->
		<mkdir dir="temp/aar/"/>
		<mkdir dir="temp/android/"/>
		<copy todir="temp/" file="${android_aar}${arr_name}"/>
		<unzip src="temp/${arr_name}" dest="temp/aar/" overwrite="true"/>
		<copy tofile="temp/android/${name}.jar" file="temp/aar/classes.jar"/>
		<copy todir="temp/android/res"><fileset dir="temp/aar/res"/></copy>
		<delete dir="temp/aar"/>
		<delete file="temp/${arr_name}"/>
		<!-- remove adobe package -->
		<mkdir dir="temp/jar/"/>
		<unzip src="temp/android/peane.jar" dest="temp/jar/" overwrite="true"/>
		<delete dir="temp/jar/com/adobe"/>
		<jar basedir="temp/jar/" destfile="temp/android/peane.jar" />
		<delete dir="temp/jar"/>
    </target>
    ```
    
   this section compiles the swc, and process it.
   ```xml
    <!-- Actionscript -->
    <target name="swc" description="Build SWC library">
        <mkdir dir="temp/swc/content/"/>
        <fileset dir="../actionscript/src" casesensitive="yes" id="classfiles">
            <include name="**/*.as"/>
        </fileset>
        <pathconvert property="classlist" refid="classfiles" pathsep=" " dirsep=".">
            <regexpmapper from=".*src.(.*)\.as" to="\1"/>
        </pathconvert>
        <exec executable="${flex.sdk}/bin/compc${bin.ext}" failonerror="true">
            <env key="AIR_SDK_HOME" value="${flex.sdk}"/>
			<arg line='+configname=airmobile'/>
            <arg line='-source-path ../actionscript/src'/>
            <arg line='-output temp/swc/${name}.swc'/>
            <arg line='-swf-version=${SWF_VERSION}'/>
            <arg line='-external-library-path+="${flex.sdk}/frameworks/libs/air/airglobal.swc"'/>
            <arg line='-include-classes ${classlist}'/>
        </exec>

        <unzip src="temp/swc/${name}.swc" dest="temp/swc/content" overwrite="true"/>
        <copy file="temp/swc/content/library.swf" todir="temp/android" overwrite="true"/>
        <copy file="temp/swc/content/library.swf" todir="temp/default" overwrite="true"/>
    </target>
    ```
    
   this section execute the tool for dependencies packing (jar and res)
    ```xml
    <target name="supa_mega_ukulele" description="pack library">
		<!-- run autopacker -->
		<exec executable="repacker.exe" failonerror="true" dir="temp/"></exec>
	  </target>
    ```
    
   finally pack the ANE
   ```xml
    <target name="package" description="Create the extension package">
		<property name="TARGET_ANE" value="${name}.ane"/>
		<property name="SWC_LIB" value="swc/${name}.swc"/>
		<exec executable="${flex.sdk}/bin/adt${bin.ext}" failonerror="true" dir="temp/">
            <arg line="-package"/>
			<arg line="-target ane ${TARGET_ANE} ${EXTENSION_XML}"/>
            <arg line="-swc ${SWC_LIB}"/>
			<arg line="-platform Android-ARM"/>
			<arg line="-platformoptions ../platform.xml"/>
			<arg line="-C android/ ."/>
    </exec>
    <move file="temp/${name}.ane" todir="../bin"/>
    </target>
    ```

3. setting up your supaMegaUkulele.ini
      ```batch
      [settings]
      path=path_to_your_android_studio_project
      main_package_name=your_package_name
      airSDKversion=air_sdk_version
      ```
      
4. build your android arr (see tutorial on point 1)
5. run your apache ant
      ant 

