# Using USB devices in apps on Android in C

This toolset uses rawdrawandroid: https://github.com/cnlohr/rawdrawandroid if you are curious how to develop C applications on Android, check that out.

This toolset operates as a copy-pastable demo of how to do USB in C apps on Android.  This is **not** intended as catch-all or clean demo, but rather a minimal demonstration of getting permissions, and opening up USB devices in C on Android.

Originally it worked with this hardware: https://github.com/cnlohr/tensigral_lamp

But, now, it can be easily used with the ch32v003's [rv003usb](https://github.com/cnlohr/rv003usb) driver "demo_custom_device".

## Cutting to the chase

There are three fundamental parts to using USB working on Android in C.  Three out of the four of these are completely covered in the `void RequestPermissionOrGetConnectionFD()` function in `test.c`.  You will need to do all of this in the JNI.

1. You must iterate through the device list from UsbManager, with `.getDeviceList()` and find your device.
2. You must request permission from Android to use the device with `.requestPermission()`; caveat: You can just try connecting, if you don't have permission it won't let you connect.
3. You must claim the interface to the device with `.claimInterface()`.
4. You can then use bulk endpoint functions from Android, OR, even better! You can use `.getFileDescriptor()` and then perform ioctl operations on the file descriptor, sending and receiving data.  Interrupt and bulk data is normal.  It says you can even make control messages, though I haven't tried.


