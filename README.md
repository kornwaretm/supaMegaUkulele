# supaMegaUkulele
tool for building android ANE (Air Native Extension)

tested using the latest Android SDK, Gradle 3.3, JDK 1.8, AIR ascsdk 26.

Required tool
1. AIR sdk, Android studio + Android SDK
2. apache ANT, needs to be in your system variable path
3. AutoIt

How to build your ANE with android studio
1. follow the instruction from here  http://www.myflashlabs.com/build-ane-android-studio/
2. add  setting in the gradle.properties
  ```
  android.enableBuildCache=true
  android.buildCacheDir=the_desired_path_of_your_cache
  // replace the_desired_path_of_your_cache whith your desired path of your cache. the path must be an absolute path
  ```
3. create your project directory, with one empty .ini file or just copy the example project (still working on somekind of template project)
4. launch the supaMegaUkulele.exe, open the ini file, fill all the missing or wrong values.
5. hit build.
6. result in the bin folder.
7. enjoy.
