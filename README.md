

if build fails (like below), open XCode and check for errors. try build script again, or, "clean" the project and build again from XCode directly.
```bash
...
--- xcodebuild: WARNING: Using the first of multiple matching destinations:
{ platform:macOS, arch:arm64, id:00008112-001918313E45401E }
{ platform:macOS, arch:x86_64, id:00008112-001918313E45401E }
{ platform:macOS, name:Any Mac }
** ARCHIVE FAILED **


The following build commands failed:
        SwiftCompile normal x86_64
...
```