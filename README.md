<a href="https://github.com/JDM170/ReVanced_Builder/actions"><img src="https://img.shields.io/github/actions/workflow/status/JDM170/ReVanced_Builder/Build.yml?label=GitHub%20Actions&logo=GitHub"></a>

# ReVanced builder

Build ReVanced package (.apk) easily than ever using latest ReVanced patches and dependencies locally or via cloud

## Usage

### Locally

* To build `revanced.apk` locally you need just to run [`Build.ps1`](https://github.com/JDM170/ReVanced_Builder/blob/main/Build.ps1) via PowerShell;
* All [patches](https://github.com/revanced/revanced-patches) except the followings applied to `revanced.apk`:
  * always-autorepeat
  * enable-wide-searchbar
  * disable-fullscreen-panels
  * premium-heading
  * tablet-mini-player
* The script downloads latest available YouTube package (having parsed [JSON](https://github.com/revanced/revanced-patches/blob/main/patches.json)) supported by ReVanced Team from <https://apkmirror.com> and all dependencies and build package using [Zulu JDK](https://www.azul.com/downloads/?package=jdk);
* Script installs no apps — everything will be held in your `Script location folder\ReVanced`;
* After compiling you get `revanced.apk` & `microg.apk` ready to be installed;
* Release notes are generated dynamically using the [ReleaseNotesTemplate.md](https://github.com/JDM170/ReVanced_Builder/blob/main/ReleaseNotesTemplate.md) template.

### By using CI/CD

```powershell
git clone https://github.com/JDM170/ReVanced_Builder
```

Trigger the [`Build`](https://github.com/JDM170/ReVanced_Builder/actions/workflows/Build.yml) Action manually to create [release page](https://github.com/JDM170/ReVanced_Builder/releases/latest) with configured release notes showing dependencies used for building.

![image](https://user-images.githubusercontent.com/10544660/187949763-82fd7a07-8e4e-4527-b631-11920077141f.png)

`ReVanced.zip` will contain a built `revanced.apk` & latest `microg.apk`.

## Requirements if you compile locally

* Windows 10 x64 or Windows 11
* Windows PowerShell 5.1
  * PowerShell 7 won't work due to it doesn't contain Trident HTML parser, so I have to use a 3rd party parser [AngleSharp](https://github.com/AngleSharp/AngleSharp);
  * If you still want it, [get](https://github.com/JDM170/ReVanced_Builder/blob/main/.github/workflows/Build.yml) code from Actions (it's run in PowerShell 7).

## Links

* [ReVanced Patches](https://github.com/revanced/revanced-patches)
* [ReVanced Manager](https://github.com/revanced/revanced-manager)
* [Telegram](https://t.me/sophia_chat)
* [AngleSharp](https://github.com/AngleSharp/AngleSharp)
