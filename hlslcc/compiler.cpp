#include "hlslcc.h"

class HLSLccReflectionCallbacks : public HLSLccReflection
{
public:
    //HLSLccReflection() {}
    //virtual ~HLSLccReflection() {}

    // Called on errors or diagnostic messages
    void OnDiagnostics(const std::string& error, int line, bool isError) {
        puts("OnDiagnostics");
    }

    void OnInputBinding(const std::string& name, int bindIndex) {
        puts("OnInputBinding");
    }

    // Returns false if this constant buffer is not needed for this shader. This info can be used for pruning unused
    // constant buffers and vars from compute shaders where we need broader context than a single kernel to know
    // if something can be dropped, as the constant buffers are shared between all kernels in a .compute file.
    bool OnConstantBuffer(const std::string& name, size_t bufferSize, size_t memberCount) {
        puts("OnConstantBuffer");
        return true;
    }

    // Returns false if this constant var is not needed for this shader. See above.
    bool OnConstant(const std::string& name, int bindIndex, SHADER_VARIABLE_TYPE cType, int rows, int cols, bool isMatrix, int arraySize, bool isUsed) {
        puts("OnConstant");
        return true;
    }

    void OnConstantBufferBinding(const std::string& name, int bindIndex) {
        puts("OnConstantBufferBinding");
    }
    void OnTextureBinding(const std::string& name, int bindIndex, int samplerIndex, bool multisampled, HLSLCC_TEX_DIMENSION dim, bool isUAV) {
        puts("OnTextureBinding");
    }
    void OnBufferBinding(const std::string& name, int bindIndex, bool isUAV) {
        puts("OnBufferBinding");
    }
    void OnThreadGroupSize(unsigned int xSize, unsigned int ySize, unsigned int zSize) {
        puts("OnThreadGroupSize");
    }
    void OnTessellationInfo(uint32_t tessPartitionMode, uint32_t tessOutputWindingOrder, uint32_t tessMaxFactor, uint32_t tessNumPatchesInThreadGroup) {
        puts("OnTessellationInfo");
    }
    void OnTessellationKernelInfo(uint32_t patchKernelBufferCount) {
        puts("OnTessellationKernelInfo");
    }

    // these are for now metal only (but can be trivially added for other backends if needed)
    // they are useful mostly for diagnostics as interim values are actually hidden from user
    void OnVertexProgramOutput(const std::string& name, const std::string& semantic, int semanticIndex) {
        puts("OnVertexProgramOutput");
    }
    void OnBuiltinOutput(SPECIAL_NAME name) {
        puts("OnBuiltinOutput");
    }
    void OnFragmentOutputDeclaration(int numComponents, int outputIndex) {
        puts("OnFragmentOutputDeclaration");
    }


    enum AccessType
    {
        ReadAccess = 1 << 0,
        WriteAccess = 1 << 1
    };

    void OnStorageImage(int bindIndex, unsigned int access) {
        puts("OnStorageImage");
    }
};

/*
HLSLCC_API int HLSLCC_APIENTRY TranslateHLSLFromFile(const char* filename,
    unsigned int flags,
    GLLang language,
    const GlExtensions *extensions,
    GLSLCrossDependencyData* dependencies,
    HLSLccSamplerPrecisionInfo& samplerPrecisions,
    HLSLccReflection& reflectionCallbacks,
    GLSLShader* result
);
*/

int main(int argc, char* argv[]) {

    if (argc != 2) {
        puts("Missing file argument");
        return 1;
    }

    unsigned int flags = HLSLCC_FLAG_UNIFORM_BUFFER_OBJECT;
    GLLang language = LANG_GL_LAST;
    GlExtensions ext;

    HLSLccSamplerPrecisionInfo samplerPrecisions;
    HLSLccReflectionCallbacks reflectionCallbacks;
    GLSLCrossDependencyData dependencies;
    GLSLShader* result = (GLSLShader*)calloc(sizeof(GLSLShader), 1);
    int compiledOK = TranslateHLSLFromFile(
        argv[1],
        flags,
        language,
        &ext,
        nullptr,
        samplerPrecisions,
        reflectionCallbacks,
        result
    );
    printf("result: %s\n", compiledOK ? "success" : "failed");
    printf("shaderType: %i\n", result->shaderType);
    printf("sourceCode: %s\n", result->sourceCode.c_str());
    return 0;
}