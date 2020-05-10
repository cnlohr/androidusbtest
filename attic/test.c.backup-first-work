//Copyright (c) 2011-2020 <>< Charles Lohr - Under the MIT/x11 or NewBSD License you choose.
// NO WARRANTY! NO GUARANTEE OF SUPPORT! USE AT YOUR OWN RISK
// Super basic test - see rawdrawandroid's thing for a more reasonable test.

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include "os_generic.h"
#include <GLES3/gl3.h>
#include <asset_manager.h>
#include <asset_manager_jni.h>
#include <android_native_app_glue.h>
#include <android/log.h>
#include <android/sensor.h>


#include <sys/ioctl.h>
#include <linux/usbdevice_fs.h>
#include <asm/byteorder.h>

#define CNFG_IMPLEMENTATION
#include "CNFG.h"

#define printf( x...) LOGI( x )

unsigned frames = 0;
unsigned long iframeno = 0;

void AndroidDisplayKeyboard(int pShow);
volatile int suspended;

short screenx, screeny;
int lastbuttonx = 0;
int lastbuttony = 0;
int lastmotionx = 0;
int lastmotiony = 0;
int lastbid = 0;
int lastmask = 0;
int lastkey, lastkeydown;

static int keyboard_up;

void HandleKey( int keycode, int bDown )
{
	lastkey = keycode;
	lastkeydown = bDown;
	if( keycode == 10 && !bDown ) { keyboard_up = 0; AndroidDisplayKeyboard( keyboard_up );  }
}

void HandleButton( int x, int y, int button, int bDown )
{
	lastbid = button;
	lastbuttonx = x;
	lastbuttony = y;

	if( bDown ) { keyboard_up = !keyboard_up; AndroidDisplayKeyboard( keyboard_up ); }
}

void HandleMotion( int x, int y, int mask )
{
	lastmask = mask;
	lastmotionx = x;
	lastmotiony = y;
}

extern struct android_app * gapp;


void HandleDestroy()
{
	printf( "Destroying\n" );
	exit(10);
}

void HandleSuspend()
{
	suspended = 1;
}

void HandleResume()
{
	suspended = 0;
}

jobject deviceConnection = 0;
int deviceConnectionFD = 0;
int lastFDWrite = 0;

int main()
{
	int i, x, y;
	double ThisTime;
	double LastFPSTime = OGGetAbsoluteTime();
	double LastFrameTime = OGGetAbsoluteTime();
	double SecToWait;
	int linesegs = 0;

	CNFGBGColor = 0x400000;
	CNFGDialogColor = 0x444444;
	CNFGSetupFullscreen( "Test Bench", 0 );

	int hasperm = AndroidHasPermissions( "WRITE_EXTERNAL_STORAGE" );
	if( !hasperm )
	{
		AndroidRequestAppPermissions( "WRITE_EXTERNAL_STORAGE" );
	}


	char assettext[8192];
	char * ats = assettext;

	{
		struct android_app* app = gapp;
		const struct JNINativeInterface * env = 0;
		const struct JNINativeInterface ** envptr = &env;
		const struct JNIInvokeInterface ** jniiptr = app->activity->vm;
		const struct JNIInvokeInterface * jnii = *jniiptr;
		jnii->AttachCurrentThread( jniiptr, &envptr, NULL);
		env = (*envptr);

		// Retrieves NativeActivity.
		jobject lNativeActivity = gapp->activity->clazz;

		//https://stackoverflow.com/questions/13280581/using-android-to-communicate-with-a-usb-hid-device

		//UsbManager manager = (UsbManager)getSystemService(Context.USB_SERVICE);
		jclass ClassContext = env->FindClass( envptr, "android/content/Context" );
		jfieldID lid_USB_SERVICE = env->GetStaticFieldID( envptr, ClassContext, "USB_SERVICE", "Ljava/lang/String;" );
		jobject USB_SERVICE = env->GetStaticObjectField( envptr, ClassContext, lid_USB_SERVICE );

		jmethodID MethodgetSystemService = env->GetMethodID( envptr, ClassContext, "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;" );
		jobject manager = env->CallObjectMethod( envptr, lNativeActivity, MethodgetSystemService, USB_SERVICE);
				//Actually returns an android/hardware/usb/UsbManager
		jclass ClassUsbManager = env->FindClass( envptr, "android/hardware/usb/UsbManager" );

		//HashMap<String, UsbDevice> deviceList = mManager.getDeviceList();
		jmethodID MethodgetDeviceList = env->GetMethodID( envptr, ClassUsbManager, "getDeviceList", "()Ljava/util/HashMap;" );
		jobject deviceList = env->CallObjectMethod( envptr, manager, MethodgetDeviceList );

		//Iterator<UsbDevice> deviceIterator = deviceList.values().iterator();
		jclass ClassHashMap = env->FindClass( envptr, "java/util/HashMap" );
		jmethodID Methodvalues = env->GetMethodID( envptr, ClassHashMap, "values", "()Ljava/util/Collection;" );
		jobject deviceListCollection = env->CallObjectMethod( envptr, deviceList, Methodvalues );
		jclass ClassCollection = env->FindClass( envptr, "java/util/Collection" );
		jmethodID Methoditerator = env->GetMethodID( envptr, ClassCollection, "iterator", "()Ljava/util/Iterator;" );
		jobject deviceListIterator = env->CallObjectMethod( envptr, deviceListCollection, Methoditerator );
		jclass ClassIterator = env->FindClass( envptr, "java/util/Iterator" );

		//while (deviceIterator.hasNext())
		jmethodID MethodhasNext = env->GetMethodID( envptr, ClassIterator, "hasNext", "()Z" );
		jboolean bHasNext = env->CallBooleanMethod( envptr, deviceListIterator, MethodhasNext );

		ats+=sprintf(ats, "Has Devices: %d\n", bHasNext );

		jmethodID Methodnext = env->GetMethodID( envptr, ClassIterator, "next", "()Ljava/lang/Object;" );

		jclass ClassUsbDevice = env->FindClass( envptr, "android/hardware/usb/UsbDevice" );
		jclass ClassUsbInterface = env->FindClass( envptr, "android/hardware/usb/UsbInterface" );
		jclass ClassUsbEndpoint = env->FindClass( envptr, "android/hardware/usb/UsbEndpoint" );
		jclass ClassUsbDeviceConnection = env->FindClass( envptr, "android/hardware/usb/UsbDeviceConnection" );
		jmethodID MethodgetDeviceName = env->GetMethodID( envptr, ClassUsbDevice, "getDeviceName", "()Ljava/lang/String;" );
		jmethodID MethodgetVendorId = env->GetMethodID( envptr, ClassUsbDevice, "getVendorId", "()I" );
		jmethodID MethodgetProductId = env->GetMethodID( envptr, ClassUsbDevice, "getProductId", "()I" );
		jmethodID MethodgetInterfaceCount = env->GetMethodID( envptr, ClassUsbDevice, "getInterfaceCount", "()I" );
		jmethodID MethodgetInterface = env->GetMethodID( envptr, ClassUsbDevice, "getInterface", "(I)Landroid/hardware/usb/UsbInterface;" );

		jmethodID MethodgetEndpointCount = env->GetMethodID( envptr, ClassUsbInterface, "getEndpointCount", "()I" );
		jmethodID MethodgetEndpoint = env->GetMethodID( envptr, ClassUsbInterface, "getEndpoint", "(I)Landroid/hardware/usb/UsbEndpoint;" );

		jmethodID MethodgetAddress = env->GetMethodID( envptr, ClassUsbEndpoint, "getAddress", "()I" );
		jmethodID MethodgetMaxPacketSize = env->GetMethodID( envptr, ClassUsbEndpoint, "getMaxPacketSize", "()I" );

		jobject matchingDevice = 0;
		jobject matchingInterface = 0;

		while( bHasNext )
		{
			//  UsbDevice device = deviceIterator.next();
        	//	Log.i(TAG,"Model: " + device.getDeviceName());
			jobject device = env->CallObjectMethod( envptr, deviceListIterator, Methodnext );
			uint16_t vendorId = env->CallIntMethod( envptr, device, MethodgetVendorId );
			uint16_t productId = env->CallIntMethod( envptr, device, MethodgetProductId );
			int ifaceCount = env->CallIntMethod( envptr, device, MethodgetInterfaceCount );
			const char *strdevname = env->GetStringUTFChars(envptr, env->CallObjectMethod( envptr, device, MethodgetDeviceName ), 0);
			ats+=sprintf(ats, "DEV:%s,%04x:%04x Ct: %d\n", strdevname,
				vendorId,
				productId, ifaceCount );

			if( vendorId == 0xabcd && productId == 0xf410 )
			{
				if( ifaceCount )
				{
					matchingDevice = device;
					matchingInterface = env->CallObjectMethod( envptr, device, MethodgetInterface, 0 );
				}
			}

			bHasNext = env->CallBooleanMethod( envptr, deviceListIterator, MethodhasNext );
		}
		
		jobject matchingEp = 0;

		if( matchingInterface )
		{
			//matchingInterface is of type android/hardware/usb/UsbInterface
			int epCount = env->CallIntMethod( envptr, matchingInterface, MethodgetEndpointCount );
			ats+=sprintf(ats, "Found device %d eps\n", epCount );
			int i;
			for( i = 0; i < epCount; i++ )
			{
				jobject endpoint = env->CallObjectMethod( envptr, matchingInterface, MethodgetEndpoint, i );
				jint epnum = env->CallIntMethod( envptr, endpoint, MethodgetAddress );
				jint mps = env->CallIntMethod( envptr, endpoint, MethodgetMaxPacketSize );
				if( epnum == 0x02 ) matchingEp = endpoint;
				ats+=sprintf(ats, "%p: %02x: MPS: %d (%c)\n", endpoint, epnum, mps, (matchingEp == endpoint)?'*':' ' );
			}			
		}

		jmethodID MethodopenDevice = env->GetMethodID( envptr, ClassUsbManager, "openDevice", "(Landroid/hardware/usb/UsbDevice;)Landroid/hardware/usb/UsbDeviceConnection;" );
		jmethodID MethodrequestPermission = env->GetMethodID( envptr, ClassUsbManager, "requestPermission", "(Landroid/hardware/usb/UsbDevice;Landroid/app/PendingIntent;)V" );
		jmethodID MethodclaimInterface = env->GetMethodID( envptr, ClassUsbDeviceConnection, "claimInterface", "(Landroid/hardware/usb/UsbInterface;Z)Z" );
		jmethodID MethodsetInterface = env->GetMethodID( envptr, ClassUsbDeviceConnection, "setInterface", "(Landroid/hardware/usb/UsbInterface;)Z" );
		jmethodID MethodgetFileDescriptor = env->GetMethodID( envptr, ClassUsbDeviceConnection, "getFileDescriptor", "()I" );
		jmethodID MethodbulkTransfer = env->GetMethodID( envptr, ClassUsbDeviceConnection, "bulkTransfer", "(Landroid/hardware/usb/UsbEndpoint;[BII)I" );  
			//see https://android.googlesource.com/platform/frameworks/base/+/master/core/java/android/hardware/usb/UsbDeviceConnection.java
			//Calls: native_bulk_request -> android_hardware_UsbDeviceConnection_bulk_request -> usb_device_bulk_transfer

		//				UsbEndpoint endpoint, byte[] buffer, int length, int timeout
		//bulkTransfer(UsbEndpoint endpoint, byte[] buffer, int length, int timeout) 

		//UsbDeviceConnection bulkTransfer

		if( matchingEp )
		{
			//UsbDeviceConnection deviceConnection = manager.openDevice( device )
			deviceConnection = env->CallObjectMethod( envptr, manager, MethodopenDevice, matchingDevice );
			jint epnum = env->CallIntMethod( envptr, matchingEp, MethodgetAddress );

			if( !deviceConnection )
			{
				env->CallVoidMethod( envptr, manager, MethodrequestPermission, matchingDevice, 0 );
			}
			else
			{
				jboolean claimOk = env->CallBooleanMethod( envptr, deviceConnection, MethodclaimInterface, matchingInterface, true );
				//jboolean claimOk = env->CallBooleanMethod( envptr, deviceConnection, MethodsetInterface, matchingInterface );
				//jboolean claimOk = 1;
				if( claimOk )
				{
					uint8_t writebuff[65];
					deviceConnectionFD = env->CallIntMethod( envptr, deviceConnection, MethodgetFileDescriptor );
					//lastFDWrite = env->CallIntMethod( envptr, deviceConnection, MethodbulkTransfer, matchingEp, writebuff, 64, 100 );
					//lastFDWrite = write( deviceConnectionFD, writebuff, 64 ); 
					writebuff[0] = 0;
					writebuff[1] = 0x80 | (30); //DMA + length
					writebuff[2] = 0x00; //skip
					writebuff[3] = 0x80; //data

					struct usbdevfs_bulktransfer  ctrl;
					memset(&ctrl, 0, sizeof(ctrl));
					ctrl.ep = /*epnum*/0x02;
					ctrl.len = 64;
					ctrl.data = writebuff+1;
					ctrl.timeout = 100;
					lastFDWrite = ioctl(deviceConnectionFD, USBDEVFS_BULK, &ctrl);
				}

				ats+=sprintf(ats, "DC: %p; Claim: %d; FD: %d; Write: %d\n", deviceConnection, claimOk, deviceConnectionFD, lastFDWrite );
			}

		}

		jnii->DetachCurrentThread( jniiptr );
	}

//"com.android.example.USB_PERMISSION


	/* 
		UsbManager mManager = (UsbManager) getSystemService(Context.USB_SERVICE);
		HashMap<String, UsbDevice> deviceList = mManager.getDeviceList();
		Iterator<UsbDevice> deviceIterator = deviceList.values().iterator();
	*/


	while(1)
	{
		int i, pos;
		float f;
		iframeno++;
		RDPoint pto[3];

		CNFGHandleInput();

		if( suspended ) { usleep(50000); continue; }

		CNFGClearFrame();
		CNFGColor( 0xFFFFFF );
		CNFGGetDimensions( &screenx, &screeny );

		// Mesh in background
		CNFGColor( 0xffffff );
		CNFGPenX = 20; CNFGPenY = 900;
		CNFGDrawText( assettext, 7 );
		void FlushRender();
		FlushRender();

//		int lastwrite = -5;
		if( deviceConnectionFD )
		{
//			uint8_t writebuff[65];
//			writebuff[0] = 0;
//			lastwrite = write( deviceConnectionFD, writebuff, 64 ); 
		}

		CNFGPenX = 20; CNFGPenY = 480;
		char st[50];
		sprintf( st, "%dx%d %d %d %d %d %d %d\n%d %d\n%d", screenx, screeny, lastbuttonx, lastbuttony, lastmotionx, lastmotiony, lastkey, lastkeydown, lastbid, lastmask, lastFDWrite );
		CNFGDrawText( st, 10 );
		glLineWidth( 2.0 );

		// Square behind text

		frames++;
		CNFGSwapBuffers();

		ThisTime = OGGetAbsoluteTime();
		if( ThisTime > LastFPSTime + 1 )
		{
			printf( "FPS: %d\n", frames );
			frames = 0;
			linesegs = 0;
			LastFPSTime+=1;
		}
	}

	return(0);
}

