#!/usr/bin/env python3

import UnityPy
import argparse
import sys
import os

from pathlib import Path


platform_apis = {4: "DirectX", 5: "OpenGLES 2", 9: "OpenGLES 3", 14: "Metal", 15: "OpenGL Core", 18: "Vulkan"}

def run(path, shader_path, dump, replace):
    missing = 0
    for path in Path(sys.argv[1]).glob('**/*'):
        file = str(path)
        if os.path.basename(file) not in ["unity_builtin_extra", "globalgamemanagers.assets", "resources.assets"]:
            continue
        print(file)
        env = UnityPy.load(file)
        for obj in env.objects:
            # only type shader
            if obj.type.value != 48:
                continue
            data = obj.read()
            print("Name: " + data.m_ParsedForm.m_Name)
            print("Platforms: " + str([platform_apis[api] if api in platform_apis else "unknown" for api in data.platforms]))

            if not dump and not replace:
                continue

            filename = shader_path + data.m_ParsedForm.m_Name.replace("/","-")

            if dump:
                if 15 not in data.platforms:
                    print("shader platform not opengl")
                    continue
                if os.path.isfile(filename):
                    print(filename + " already exists")
                    continue
                with open(filename, "wb") as f:
                    f.write(obj.get_raw_data())

            if replace:
                if not os.path.isfile(filename):
                    missing += 1
                    print("Missing!")
                    continue
                
                with open(filename, "rb") as f:
                    obj.set_raw_data(f.read())
        
        if replace:
            os.rename(file, file + ".bak")
            with open(file, "wb") as f:
                f.write(env.file.save())

    if replace:
        print("Missing shaders: " + str(missing))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="shaders")
    parser.add_argument("path", type=str, help="Unity game path")
    parser.add_argument(
        "--shader_path",
        type=str,
        default=None,
        help="Path to dump shader objects",
    )
    parser.add_argument(
        "--dump",
        default=False,
        action="store_true",
        help="Dump shader objects",
    )
    parser.add_argument(
        "--replace",
        default=False,
        action="store_true",
        help="Replace shader objects",
    )
    
    args = parser.parse_args()

    if args.dump and args.replace:
        print("Operations dump and replace can not be used together!")
        exit(1)
    
    if (args.dump or args.replace) and not args.shader_path:
        print("Operations dump and replace require a path!")
        exit(1)

    run(args.path, args.shader_path, args.dump, args.replace)