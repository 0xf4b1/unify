# unify
Automatically port Unity games for macOS or Windows to Linux

Games based on the Unity engine can be deployed and run on multiple platforms, including Linux.
The platform-specific engine files are mostly generic, so we take the official game files and run them with Unity's Linux binaries.
This way we get a native Linux version of the game without the need of compatibility layers, such as Wine.

This method can work as long as the game was exported with OpenGL or Vulkan renderer enabled.
Windows versions usually default to DirectX and only rarely have OpenGL enabled, but macOS versions often have OpenGL enabled and chances are high to get them to run.

Many Unity titles are officially available for Linux, but there are also some cases where this method can create a missing Linux port.
Lots of Unity Games that were availbale for free on Epic Games have been tested.
Since Epic Games does not support Linux game versions, you can also benefit from this method to play your Unity games that you may have collected on that platform.

Take the [Compatibility Status](https://github.com/0xf4b1/unify#compatibility-status) list as reference if you are only interested in games that are known to be playable.

## Install Unity Games

To determine which games are based on Unity, you can check out [steamdb](https://steamdb.info/tech/Engine/Unity/).

### Epic Games

You can download games with [Legendary](https://github.com/derrod/legendary), the free and open-source Epic Games Launcher alternative.

List all your titles for macOS or Windows

```
legendary list --platform <Mac|Windows>
```

Install the macOS or Windows version of game with

```
legendary install --platform <Mac|Windows> <App name>
```

### Steam

You can download Steam games for a specific platform with steamcmd. To download macOS versions, use the following command:

```
steamcmd +@sSteamCmdForcePlatformType macos
```

Inside steamcmd run the following:

```
login <account_name>
app_update <app_id>
```

## Porting

Install requirements via pip:

```
pip install -r requirements.txt
```

Check available renderers of the game by using the script:

```
./renderers.py <game dir>
```

If the script outputs OpenGL Core or Vulkan as detected Graphics Apis, you are lucky and can continue!
Otherwise you should stop here because the game does not contain shaders that work with Unity on Linux.
If you still want to proceed, read through the [Research section](https://github.com/0xf4b1/unify#research) to see possible experimental ways to get the needed shaders or let me know if you have an idea!

If the game has a `_Data` directory prefixed with the game title (e.g. `The Last Campfire_Data`), you should rename it to just `Data`.
Then run the script with the path of the Unity game as argument

```
./unify.sh <game dir>
```

The script probes the game for the Unity version, then downloads the relevant engine files and copies them into the game directory.
If it succeeded, try to start the game via the `LinuxPlayer` binary.
If it does not run, make sure to check the logs usually in `~/.config/unity3d/<vendor>/<title>`.
In most cases, the game misses some native libraries that need to be replaced.
For Steam games it might work to just copy an arbitrary `.so` file to the place of the expected `libsteam_api64.so`.

The script will cache the downloaded and extracted unity files by default in the folder `~/Unity/Hub/Editor`, but you can override this location using the `UNITY_REPO` environment variable.

If the script is not successful, the game may not be a Unity game or it may have a different structure.
The script in its current state is very basic and does not cover all cases.

## Research

### Shader object extraction

Dump shader objects from games and use them in other games.

If a game needs the exact same shaders that are present in another game with the desired graphics api and same unity version, there is a chance that you can reuse the whole shader objects.

#### Shader object dumping
Dump shader objects from a game that supports the desired graphics api:
```
./shaders.py <game dir> --dump --shader_dir <shader_dump_dir>
```

#### Shader object replacing
Replace the shader objects in a game with previously dumped ones:
```
./shaders.py <game dir> --replace --shader_dir <shader_dump_dir>
```

Force the game to use a different graphics api by patching file `globalgamemanagers`, e.g. 17 for OpenGL Core:
```
./renderers.py <game dir> --force 17
```

### Shader compilation

#### Compile missing shader objects with Unity directly

Buildin-shader source code can be downloaded from the unity archive per unity release, for example [builtin_shaders-6000.2.1f1.zip](https://download.unity3d.com/download_unity/55300504c302/builtin_shaders-6000.2.1f1.zip).
Other shader source code provided via packages should possibly be located on the filesystem after installing.
By creating and exporting a Unity project that contains the shader objects with the desired graphics api, they can be extracted as described above.

#### Compile shader code by using UnityShaderCompiler directly

The Unity Editor comes with a dedicated UnityShaderCompiler executable. The Unity Editor opens a port and starts instances of the UnityShaderCompiler with parameters to connect to Unity's open port.
The communication can be intercepted by setting up a proxy, like described [here](https://discussions.unity.com/t/how-can-i-use-unityshadercompiler-exe/167609).
As proxy tool, [tcpprox](https://github.com/staaldraad/tcpprox) can be used for example.
The communication is a proprietary protocol that needs to be analyzed. One of the supported commands is `c:compileSnippet` that Unity sends followed by plain shader source code to receive compiled shaders and other information back.

### Shader translation via cross-compiling

For games that come only with DirectX and no way to get the shader sources, try to translate DXBC to OpenGL or Vulkan shaders.

#### Translate DirectX byte-code (DXBC) to OpenGL

[HLSLcc](https://github.com/Unity-Technologies/HLSLcc): https://github.com/0xf4b1/unify/issues/11 HLSLcc is part of Unity's shader compiler, see [docs](https://docs.unity3d.com/6000.1/Documentation/Manual/shader-compilation.html).

In the hlslcc branch is an attempt to use the library to translate DXBC to OpenGL. The translation works for the test DXBC object, however it crashes on dumped DXBC objects from unity for yet unknown reasons.

#### Translate DirectX byte-code (DXBC) to SPIR-V (Vulkan)

- [DXVK](https://github.com/doitsujin/dxvk): DXVK reimplements the DirectX api calls to target Vulkan.
This means it must also handle shader translation from DirectX (DXBC) -> Vulkan (SPIR-V).
The needed functionality for the translation should start [here](https://github.com/doitsujin/dxvk/blob/master/src/d3d11/d3d11_shader.cpp#L17C1-L59C6).

- [DirectXShaderCompiler](https://github.com/microsoft/DirectXShaderCompiler): For compiling shader source code and possibly DXBC to SPIR-V using the SPIR-V CodeGen.

### Unity shader object rewriting

Rewrite Unity shader objects with new shader code.

Even if there is a way to directly translate shader byte-code to another graphics api, only replacing the shader code does not work as Unity's shader object contains much for information which means all this required information that Unity writes into the object need to be determined to be able to rewrite the whole unity shader object so that the shader can run.

### More compatibility

- Support for macOS (OpenGL is supported on macOS): https://github.com/0xf4b1/unify/issues/4
- Research if Android is possible (OpenGLES is supported on Windows): https://github.com/0xf4b1/unify/issues/7

### Useful tools
- [AssetRipper](https://github.com/AssetRipper/AssetRipper)
- [UABE](https://github.com/SeriousCache/UABE)
- [UnityPy](https://github.com/K0lb3/UnityPy)

## Compatibility Status

### macOS

| App title                         | App name                         | Unity version | Linux available | OpenGL enabled | Playable | Notes                                         |
|-----------------------------------|----------------------------------|---------------|-----------------|----------------|----------|-----------------------------------------------|
| Duskers                           | 1e9c3a9a10c6463e9c065f371b8b42bf | 5.3.4f1       | yes             | yes            | yes      |                                               |
| Sunless Sea                       | 2420b50453144c07b3b847fff941275d | 5.5.1f1       | yes             | yes            | no       | can not find matching unity engine            |
| Darkwood                          | 923130ebb546417b9d3115507f752d34 | 5.5.3f1       | yes             | yes            | no       | can not find matching unity engine            |
| Night In The Woods                | cd1b8a6e5b6c47369e2a1e2cf7b7f536 | 5.6.2p4       | yes             | yes            | no       | can not find matching unity engine; 5.6.2xf1Linux can be used instead[^4]; needs fmod 1.7.8[^3] |
| Stories Untold                    | Parsley                          | 5.6.3p2       | no              | yes            | no       | can not find matching unity engine; 5.6.3xf1Linux can be used instead[^4]; needs fmod 1.8.0[^3]; needs AVProVideo and more |
| Inside                            | Marigold                         | 5.6.6f2       | no              | yes            | no       | can not find matching unity engine            |
| The First Tree                    | cd98b47155654e1f9a9e84e60d0b49e4 | 2017.4.11f1   | yes             | yes            | yes      | rewired: Rewired_OSX_Lib.dll must be removed  |
| Absolute Drift                    | 19927295d6e3467887d4e830d8c85963 | 2017.4.16f1   | yes             | yes            | no       | needs EOSSDK-Mac-Shipping[^1]; rewired: Assembly-CSharp.dll needs to be patched[^2]; starting but unplayable due to white screen |
| Enter the Gungeon                 | Garlic                           | 2017.4.27f1   | yes             | yes            | no       | needs AkSoundEngine                           |
| Hand of Fate 2                    | 808f0dfbf3b84c2680793724d7f207bf | 2017.4.40f1   | yes             | yes            | no       | needs InControlNative                         |
| Tacoma                            | Flagfin                          | 2018.4.9f1    | yes             | yes            | yes      | rewired: Rewired_OSX_Lib.dll must be removed  |
| Rise of Industry                  | cf6c487e39a14113b75d1f625fed1da7 | 2018.4.11f1   | yes             | yes            | yes      | needs EOSSDK-Mac-Shipping[^1]                 |
| Totally Reliable Delivery Service | Hoatzin                          | 2018.4.14f1   | yes             | yes            | yes      | rewired: External.dll needs to be patched[^2] |
| Faeria                            | Vulture                          | 2018.4.18f1   | yes             | yes            | no       | needs libepic_api.so[^1]; needs rewired       |
| Iratus                            | 82ab0adb6e0b41bea531fcbb0c43cfc7 | 2018.4.26f1   | yes             | yes            | yes      | needs EOSSDK-Mac-Shipping[^1]                 |
| **Crying Suns**                   | 18fafa2d70d64831ab500a9d65ba9ab8 | 2018.4.30f1   | **no**          | yes            | **yes**  | needs AkSoundEngine                           |
| Moonlighter                       | Eagle                            | 2019.2.20f1   | yes             | yes            | no       | needs InControlNative                         |
| Kerbal Space Program              | a1e2ce30defe4a9187ebc14fc9d2bd8b | 2019.4.18f1   | yes             | yes            | yes      | mv GameData KSP.app/Contents/Resources/       |
| Verdun                            | 38c0129b680e4843b4807b98bad67027 | 2019.4.29f1   | yes             | yes            | yes      | needs EOSSDK-Mac-Shipping[^1]; needs to be started with `./LinuxPlayer -epicusername=<something> -epicuserid=<something> -AUTH_PASSWORD=<something>`; rewired: Assembly-CSharp-firstpass.dll needs to be patched[^2]; no sound, needs fmod |
| Tannenberg                        | ecfdc10170eb49b6b61cf16b3aa36d56 | 2019.4.29f1   | yes             | yes            | yes      | needs EOSSDK-Mac-Shipping[^1]; needs to be started with `./LinuxPlayer -epicusername=<something> -epicuserid=<something> -AUTH_PASSWORD=<something>`; rewired: Assembly-CSharp-firstpass.dll needs to be patched[^2]; no sound, needs fmod |
| The Fall                          | daac7fe46e3647cb80530411d7ec1dc5 | 2020.2.2f1    | yes             | yes            | yes      |                                               |
| Magic The Gathering Arena         | stargazer                        | 2020.3.13f1   | no              | yes            | no       |                                               |
| Terraforming Mars                 | 582c8940f499450d9033840efe5937a6 | 2021.3.12f1   | no              | no             | no       |                                               |
| while True: learn()               | 4f272a49a39742b795d63e1f483a7c7d | 2021.3.14f1   | yes             | no             | no       |                                               |
| The Long Dark                     | ed93b18355a84230938c705121c63661 | 2021.3.16f1   | yes             | yes            | no       |                                               |
| **Stacklands**                    | (itch.io release)                | 2022.3.4f1    | **no**          | yes            | **yes**  |                                               |
| Pokémon Trading Card Game Live    | pokemon                          | 2022.3.21f1   | no              | no             | no       |                                               |

### Windows

| App title                         | App name                         | Unity version | Linux available | OpenGL enabled | Playable | Notes                                         |
|-----------------------------------|----------------------------------|---------------|-----------------|----------------|----------|-----------------------------------------------|
| Shadowrun Returns                 | dc29cb42f32e4a17af1d68c715fa459c | 4.2.0f4       | yes             | no             | no       |                                               |
| DARQ                              | ee96375fac2f47de978170a24398e581 | 5.3.6f1       | no              | no             | no       |                                               |
| Yooka-Laylee                      | ce2a78bf70b646e9b9f57c46dac99184 | 5.4.3p3       | yes             | no             | no       |                                               |
| Shadow Tactics                    | Fangtooth                        | 5.4.4f1       | yes             | no             | no       |                                               |
| The Escapists 2                   | Fowl                             | 5.5.0p4       | yes             | no             | no       |                                               |
| AER Memories of Old               | 26b63c46de9e4dcc856b3c6b106b6777 | 5.6.1f1       | yes             | no             | no       |                                               |
| Dungeons 3                        | 351fe5b32e22412d8fa41f4c7395fed1 | 5.6.6f2       | yes             | no             | no       |                                               |
| Sheltered                         | b9af0845f9d64b0d9e851d9811141f67 | 5.6.7f1       | yes             | no             | no       |                                               |
| Halcyon 6                         | b9e848fc5e844f4285b0624789476664 | 2017.2.1f1    | yes             | no             | no       |                                               |
| For The King                      | Discus                           | 2017.2.2p2    | yes             | no             | no       |                                               |
| The Messenger                     | Jay                              | 2017.4.12f1   | no              | no             | no       |                                               |
| Void Bastards                     | 595e35287b824902a2f7107139603732 | 2017.4.21f1   | no              | no             | no       |                                               |
| Car Mechanic Simulator 2018       | 8032b75cf0914afa87c78d6914adc165 | 2017.4.24f1   | no              | no             | no       |                                               |
| PC Building Simulator             | ab277c0995e945d2b2c50c46883627f1 | 2018.4.16f1   | no              | yes            | no       |                                               |
| **Neon Abyss**                    | a26f991a5e6c4e9c9572fc200cbea47f | 2018.4.21f1   | **no**          | yes            | **yes**  | needs fmod 2.0.8[^3]                          |
| Moving Out                        | 8e29583ae4b44a21883038668f7e301e | 2018.4.21f1   | no              | no             | no       |                                               |
| Horizon Chase Turbo               | bb406082b69a47208489d3616b22b5c2 | 2018.4.27f1   | yes             | no             | no       |                                               |
| Overcooked! 2                     | Potoo                            | 2018.4.32f1   | yes             | no             | no       |                                               |
| **Offworld Trading Company**      | Snapper                          | 2018.4.36f1   | **no**          | yes            | **yes**  | needs libEOSSDK-Win32-Shipping.dll[^1]; needs to be started with `./Offworld -AUTH_LOGIN=<something> -AUTH_PASSWORD=<something>` |
| Idle Champions                    | 40cb42e38c0b4a14a1bb133eb3291572 | 2019.3.0f6    | no              | no             | no       |                                               |
| Tunche                            | fd51551d919847beb178985f6daf0306 | 2019.4.0f1    | no              | no             | no       |                                               |
| Pine                              | 6d564ff21f9c45b7b782b7113ad60be8 | 2019.4.10f1   | yes             | no             | no       |                                               |
| Recipe for Disaster               | 61e074e998044594b7bb566fe111687b | 2019.4.24f1   | no              | no             | no       |                                               |
| Fall Guys                         | 0a2d9f6403244d12969e11da6713137b | 2019.4.37f1   | no              | no             | no       |                                               |
| Never Alone                       | f38de9fa4c6d43eabac080942cb394a1 | 2020.3.19f1   | yes             | no             | no       |                                               |
| Among Us                          | 963137e4c29d4c79a81323b8fab03a40 | 2020.3.22f1   | no              | no             | no       |                                               |
| City of Gangsters                 | 002b00085aeb49b1a3f3c42e3f918f2f | 2020.3.28f1   | no              | no             | no       |                                               |
| Gloomhaven                        | 1bcd791d54684eb29ed32ad1c0593d12 | 2020.3.33f1   | no              | no             | no       |                                               |
| Raldi's Crackhouse                | 769103                           | 2020.3.49f1   | no              | no             | no       | candidate for shader replacement?             |
| Stranded Deep                     | 02107cba432c4551a027d25d597adc49 | 2021.2.7f1    | yes             | yes            | no       | needs libBCrypt.so                            |
| Epistory - Typing Chronicles      | 4ec72fd8cbd94aa4acc61624c68fbc4f | 2021.3.3f1    | yes             | no             | no       |                                               |
| Shop Titans                       | 329064225aaf4df29c4658f141173905 | 2021.3.10f1   | no              | no             | no       |                                               |
| Bloons TD 6                       | 7786b355a13b47a6b3915335117cd0b2 | 2021.3.16f1   | no              | no             | no       |                                               |
| Against All Odds                  | ad8aff099d2a445599f9797a24e9ff93 | 2021.3.19f1   | no              | no             | no       |                                               |
| **The Last Campfire**             | 990630                           | 2018.4.24f1   | **no**          | yes            | **yes**  | Needs an arbitrary `.so` file named as `Data/Mono/x86_64/libsteam_api64.so`. Controller input doesn't work (may require patching the Rewired library) |
| Pokémon Trading Card Game Live    | pokemon                          | 2022.3.21f1   | no              | no             | no       |                                               |

[^1]: The file `libEOSSDK-Linux-Shipping.so` can be taken from the EOS-SDK and renamed to replace the missing library.
[^2]: The file can be patched to use `Rewired_Linux.dll` instead of `Rewired_OSX.dll` with [dnSpy](https://github.com/dnSpy/dnSpy). `Rewired_Linux.dll` can be taken from the macOS version of Totally Reliable Delivery Service.
[^3]: FMOD Engine can be downloaded for free after registering from [here](https://www.fmod.com/download).
[^4]: Older Unity builds for Linux can be found in the forum [here](https://forum.unity.com/threads/unity-on-linux-release-notes-and-known-issues.350256/). The `LinuxPlayer` executable can be binary patched to match the expected version.
