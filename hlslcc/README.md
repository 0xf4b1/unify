Build HLSLcc library

```
cd HLSLcc
mkdir build
cd build
cmake ..
make -j
cd ..
```

Build compiler

```
cp HLSLcc/build/libhlslcc.so .
g++ -IHLSLcc/include -L. compiler.cpp -o compiler -lhlslcc
```

Use compiler

```
LD_LIBRARY_PATH=. ./compiler test.dxbc
```