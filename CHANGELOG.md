## 1.0.0

Initial release of Flight Check — a Flutter debug-mode tool for previewing your
app against popular mobile device profiles while running on desktop.

Spoofs device metrics at the binding layer (logical size, safe area insets,
device pixel ratio) without injecting wrapper widgets. Auto-resizes the desktop
window to fit the emulated device and provides a floating badge + slide-out
panel for device selection and orientation toggle.

**Initial device profiles:**

- iPhone SE (3rd gen), iPhone 14, iPhone 15, iPhone 15 Pro Max
- iPhone 17, iPhone 17 Air, iPhone 17 Pro, iPhone 17 Pro Max
- Google Pixel 7a, Pixel 10, Pixel 10 Pro
- Samsung Galaxy A15, A16, A55, A56, S25, S26
- iPad mini (A17 Pro), iPad (A16)
