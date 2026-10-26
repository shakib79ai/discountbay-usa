"""Adds permissions, app name and network settings after `flutter create`.

Safe to run more than once.
"""
import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent
APP_NAME = "DiscountBay"


def patch_android():
    main = root / "android/app/src/main/AndroidManifest.xml"
    if not main.exists():
        sys.exit("android/ not found — run flutter create first (tool/setup_platforms.sh).")
    s = main.read_text()
    perms = [
        '<uses-permission android:name="android.permission.INTERNET"/>',
    ]
    for p in perms:
        if p not in s:
            s = re.sub(r"(<manifest[^>]*>)", r"\1\n    " + p, s, count=1)
    s = re.sub(r'android:label="[^"]*"', f'android:label="{APP_NAME}"', s, count=1)
    # url_launcher on Android 11+: declare the intents we open (phone, email, web/maps)
    queries = """
    <queries>
        <intent><action android:name="android.intent.action.DIAL"/><data android:scheme="tel"/></intent>
        <intent><action android:name="android.intent.action.SENDTO"/><data android:scheme="mailto"/></intent>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>
    </queries>"""
    if 'android:scheme="tel"' not in s:
        if "<queries>" in s:
            s = s.replace("<queries>", "<queries>" + queries.split("<queries>")[1].split("</queries>")[0], 1)
        else:
            s = s.replace("</manifest>", queries + "\n</manifest>", 1)
    main.write_text(s)

    # debug builds may talk to a local http:// API (e.g. http://10.0.2.2:8000)
    debug = root / "android/app/src/debug/AndroidManifest.xml"
    if debug.exists():
        d = debug.read_text()
        if "usesCleartextTraffic" not in d:
            if "<application" in d:
                d = d.replace("<application", '<application android:usesCleartextTraffic="true"', 1)
            else:
                d = d.replace("</manifest>", '    <application android:usesCleartextTraffic="true"/>\n</manifest>', 1)
            debug.write_text(d)

    # keep minSdk at 21 or above
    for name in ("build.gradle", "build.gradle.kts"):
        g = root / "android/app" / name
        if g.exists():
            t = g.read_text()
            t = re.sub(r"minSdk(Version)?\s*=?\s*flutter\.minSdkVersion", lambda m: m.group(0).replace("flutter.minSdkVersion", "maxOf(21, flutter.minSdkVersion)" if name.endswith("kts") else "Math.max(21, flutter.minSdkVersion)"), t)
            g.write_text(t)
    print("android: internet permission, label, link queries, cleartext (debug only)")


def patch_ios():
    plist = root / "ios/Runner/Info.plist"
    if not plist.exists():
        sys.exit("ios/ not found — run flutter create first (tool/setup_platforms.sh).")
    s = plist.read_text()
    # url_launcher: declare the link types the app opens
    if "<key>LSApplicationQueriesSchemes</key>" not in s:
        s = s.replace("<dict>", "<dict>\n\t<key>LSApplicationQueriesSchemes</key>\n\t<array>\n\t\t<string>https</string>\n\t\t<string>http</string>\n\t\t<string>tel</string>\n\t\t<string>mailto</string>\n\t</array>", 1)
    s = re.sub(r"(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)", rf"\g<1>{APP_NAME}\g<2>", s)
    if "<key>ITSAppUsesNonExemptEncryption</key>" not in s:
        # standard HTTPS only: skips App Store Connect's export-compliance question on every build
        s = s.replace("<dict>", "<dict>\n\t<key>ITSAppUsesNonExemptEncryption</key>\n\t<false/>", 1)
    if "<key>NSAppTransportSecurity</key>" not in s:
        # allows http:// to localhost / LAN IPs during development; public sites still need https
        s = s.replace("<dict>", "<dict>\n\t<key>NSAppTransportSecurity</key>\n\t<dict>\n\t\t<key>NSAllowsLocalNetworking</key>\n\t\t<true/>\n\t</dict>", 1)
    if "<key>UISupportedInterfaceOrientations</key>" in s:
        s = re.sub(
            r"(<key>UISupportedInterfaceOrientations</key>\s*<array>).*?(</array>)",
            r"\1\n\t\t<string>UIInterfaceOrientationPortrait</string>\n\t\2",
            s, count=1, flags=re.S)
    plist.write_text(s)

    # iPhone only: an iPad build would need its own iPad screenshots and review on iPad
    pbx = root / "ios/Runner.xcodeproj/project.pbxproj"
    if pbx.exists():
        t = pbx.read_text()
        t = re.sub(r'TARGETED_DEVICE_FAMILY = "1,2";', "TARGETED_DEVICE_FAMILY = 1;", t)
        pbx.write_text(t)

    podfile = root / "ios/Podfile"
    if podfile.exists():
        p = podfile.read_text()
        p = re.sub(r"^#\s*platform :ios, '[\d.]+'", "platform :ios, '13.0'", p, flags=re.M)
        podfile.write_text(p)
    print("ios: link schemes, display name, encryption flag, local networking (dev), portrait, iPhone only, iOS 13")


def patch_release_signing():
    """Sign release builds with the upload key from android/key.properties (git-ignored).

    Without that file release builds keep using the debug key, so `flutter run --release` still works.
    """
    kts = root / "android/app/build.gradle.kts"
    groovy = root / "android/app/build.gradle"
    g = kts if kts.exists() else groovy
    if not g.exists():
        return
    t = g.read_text()
    if "key.properties" in t:
        print("android: release signing already wired")
        return
    if g.suffix == ".kts":
        loader = (
            'val keystoreProperties = java.util.Properties()\n'
            'val keystorePropertiesFile = rootProject.file("key.properties")\n'
            'if (keystorePropertiesFile.exists()) {\n'
            '    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))\n'
            '}\n\n'
        )
        configs = (
            '    signingConfigs {\n'
            '        create("release") {\n'
            '            keyAlias = keystoreProperties["keyAlias"] as String?\n'
            '            keyPassword = keystoreProperties["keyPassword"] as String?\n'
            '            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }\n'
            '            storePassword = keystoreProperties["storePassword"] as String?\n'
            '        }\n'
            '    }\n\n'
        )
        pick = ('signingConfig = if (keystorePropertiesFile.exists()) signingConfigs.getByName("release") '
                'else signingConfigs.getByName("debug")')
        debug_line = re.compile(r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)')
    else:
        loader = (
            'def keystoreProperties = new Properties()\n'
            'def keystorePropertiesFile = rootProject.file("key.properties")\n'
            'if (keystorePropertiesFile.exists()) {\n'
            '    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))\n'
            '}\n\n'
        )
        configs = (
            '    signingConfigs {\n'
            '        release {\n'
            '            keyAlias = keystoreProperties["keyAlias"]\n'
            '            keyPassword = keystoreProperties["keyPassword"]\n'
            '            storeFile = keystoreProperties["storeFile"] ? file(keystoreProperties["storeFile"]) : null\n'
            '            storePassword = keystoreProperties["storePassword"]\n'
            '        }\n'
            '    }\n\n'
        )
        pick = 'signingConfig = keystorePropertiesFile.exists() ? signingConfigs.release : signingConfigs.debug'
        debug_line = re.compile(r'signingConfig\s*=?\s*signingConfigs\.debug')
    if not re.search(r"^android\s*\{", t, re.M) or "buildTypes {" not in t or not debug_line.search(t):
        print("android: build.gradle layout not recognised — wire release signing by hand (docs/RELEASE.md, step A2)")
        return
    t = re.sub(r"^android\s*\{", lambda m: loader + m.group(0), t, count=1, flags=re.M)
    t = t.replace("    buildTypes {", configs + "    buildTypes {", 1)
    t = debug_line.sub(pick, t, count=1)
    g.write_text(t)
    print("android: release builds signed with android/key.properties when it exists")


patch_android()
patch_release_signing()
patch_ios()
