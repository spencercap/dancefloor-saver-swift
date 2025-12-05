# dancefloor saver 🪩
<img width="975" height="547" alt="Screenshot 2025-12-05 at 09 35 58" src="https://github.com/user-attachments/assets/c153c414-15ec-4e7e-a906-1a60e788f6a4" />

## building + installing

1. run `./build-src-e-install.sh` script from cli
1. open System Settings > Screen Saver > open Other at bottom 
1. select "DancefloorSaver"

> NOTE: DONT press ESC after "previewing" it or the screen goes black + have to restart... (TODO fix this)


## uninstalling 

1. open screen savers directory `/Users/[NAME]/Library/Screen\ Savers`
1. delete `DancefloorSaver.saver`


## development

when rapidly building, installing, uninstalling etc, it's helpful to on Activity Monitor. search for "screen" and Force Quit all the `legacyScreenSaver` processes + the `Screen Saver (System Settings)` process (which will crash the settings panel if open). then delete the `.saver` file and then reinstall. 
<img width="1470" height="956" alt="Screenshot 2025-12-05 at 08 22 09" src="https://github.com/user-attachments/assets/12137b1b-bb1b-4d8e-b903-269cf80b2f46" />
<img width="1470" height="956" alt="Screenshot 2025-12-05 at 08 22 20" src="https://github.com/user-attachments/assets/57d36e54-2b39-4bc9-a3fa-bbbec48d9038" />
<img width="1470" height="956" alt="Screenshot 2025-12-05 at 08 22 26" src="https://github.com/user-attachments/assets/e792dc21-e9b5-40d1-8d87-a1ea855e9bad" />

sometimes it's helpful to inspect the build `.saver` file + see the used `index.html` + `index.js` etc at: `DancefloorSaver.saver > Content > Resources`. you can even edit these files directly and restart the screensaver and it shows without a rebuild (tho this isnt recommended as it's inconsistent)
<img width="1470" height="956" alt="Screenshot 2025-12-05 at 08 22 49" src="https://github.com/user-attachments/assets/3585227b-5909-49ca-9d33-964c262cc3e8" />
<img width="1032" height="604" alt="Screenshot 2025-12-05 at 08 23 55" src="https://github.com/user-attachments/assets/67cfddac-af4a-4eb7-a541-770747932de1" />


### dev notes

FYI, the tiny preview pane in System Settings does NOT render the same as fullscreen... (at times its better! as it was consistently animating the three.js scene but appeared frozen in fullscreen)
<img width="224" height="205" alt="Screenshot 2025-12-05 at 08 51 11" src="https://github.com/user-attachments/assets/7db2f3da-79af-40f0-87ad-3b4455b6aa84" />


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


it's important that the JS request animation function is super small and then calls another function (likely some safari memory saving "help")
```js
function animate() {
  requestAnimationFrame(animate);
  window.tick(); // when copying from build three.js scene, need to copy entire animate func into this
}
animate();
```

after that js is built, i also insert this snippet to get FPS in JS:
```js
// FPS tracking for JS layer
let jsFrameCount = 0;
let jsLastFPSTime = performance.now();
let jsFPS = 0;

// Create FPS display element
const fpsDisplay = document.createElement('div');
fpsDisplay.id = 'fps-display';
fpsDisplay.style.cssText = `
  position: fixed;
  top: 10px;
  left: 10px;
  background: rgba(0, 0, 0, 0.7);
  color: #0f0;
  font-family: monospace;
  font-size: 14px;
  padding: 8px 12px;
  border-radius: 4px;
  z-index: 99999;
  pointer-events: none;
`;
document.body.appendChild(fpsDisplay);

// Tick function exposed to window for Swift screen saver to call directly
// This renders one frame without scheduling the next (Swift drives the timing)
window.tick = function() {
  // FPS calculation
  jsFrameCount++;
  const now = performance.now();
  const elapsed = now - jsLastFPSTime;
  if (elapsed >= 1000) {
    jsFPS = (jsFrameCount / elapsed) * 1000;
    fpsDisplay.textContent = `JS FPS: ${jsFPS.toFixed(1)}`;
    jsFrameCount = 0;
    jsLastFPSTime = now;
  }
```
