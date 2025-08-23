#!/usr/bin/env python3

import UnityPy
import argparse
import sys
import os

from pathlib import Path


graphics_apis = {2: "DirectX 11", 8: "OpenGLES 2", 11: "OpenGLES 3", 16: "Metal", 17: "OpenGL Core", 18: "DirectX 12", 21: "Vulkan"}

def run(path, force):
    for path in Path(sys.argv[1]).glob('**/globalgamemanagers'):
        file = str(path)
        env = UnityPy.load(file)
        obj = env.objects[10]
        raw_dict = obj.read_typetree()
        print("Unity version: " + raw_dict["m_Version"])
        print("Graphics APIs: " + str([graphics_apis[api] if api in graphics_apis else "unknown" for api in raw_dict["m_GraphicsAPIs"]]))

        if force == None:
            return

        print("Patch to force using " + (graphics_apis[force] if force in graphics_apis else "unknown"))
        raw_dict["m_GraphicsAPIs"][0] = force
        obj.save_typetree(raw_dict)
        os.rename(file, file + ".bak")
        with open(file, "wb") as out:
            out.write(env.file.save())

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="renderers")
    parser.add_argument("path", type=str, help="Unity game path")
    parser.add_argument(
        "--force",
        type=int,
        default=None,
        help="Force using a different Graphics API: " + str(graphics_apis),
    )

    args = parser.parse_args()
    run(args.path, args.force)