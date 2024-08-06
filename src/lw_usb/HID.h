/* HID support header */

#ifndef _HID_h_
#define _HID_h

/* HID device structure */
typedef struct {
	BYTE addr;
	BYTE interface;
} HID_DEVICE;
/* Boot mouse report 8 bytes */
typedef struct {
//    struct {
//        unsigned one:1;
//        unsigned two:1;
//        unsigned three:1;
//        unsigned :5;
//        } button;
	BYTE button;
	BYTE Xdispl;
	BYTE Ydispl;
	BYTE bytes3to7[5];   //optional bytes
} BOOT_MOUSE_REPORT;
/* boot keyboard report 8 bytes */
typedef struct {
	BYTE mod;
//    struct {
//        unsigned LCtrl:1;
//        unsigned LShift:1;
//        unsigned LAlt:1;
//        unsigned LWin:1;
//        /**/
//        unsigned RCtrl:1;
//        unsigned RShift:1;
//        unsigned RAlt:1;
//        unsigned RWin:1;
//        } mod;
	BYTE reserved;
	BYTE keycode[6];
} BOOT_KBD_REPORT;

typedef struct {
//	BYTE Joystick;
//	BYTE reserved[2];
//	BYTE gamepadX[1];
//	BYTE gamepadY[1];
//	BYTE buttons[1];
//	BYTE triggers[1];
//	BYTE gamepadRZ[1];
	BYTE LR; //Left = 0 Right = FF
	BYTE UD; //Up = 0 Down = FF
	BYTE buttons; //LB = 10 RB = 20 A = 1 B = 2 X= 4 Y= 8
	BYTE TC; //Turbo= Clear=
} BOOT_GAMEPAD_REPORT;

/* Function prototypes */
BOOL HIDMProbe(BYTE address, DWORD flags);
BOOL HIDKProbe(BYTE address, DWORD flags);
BOOL HIDGProbe(BYTE address, DWORD flags);
void HID_init(void);
BYTE mousePoll(BOOT_MOUSE_REPORT* buf);
BYTE kbdPoll(BOOT_KBD_REPORT* buf);
BYTE gpdPoll(BOOT_GAMEPAD_REPORT* buf);
BOOL HIDMEventHandler(BYTE addr, BYTE event, void *data, DWORD size);
BOOL HIDKEventHandler(BYTE addr, BYTE event, void *data, DWORD size);
BOOL HIDGEventHandler(BYTE addr, BYTE event, void *data, DWORD size);
#endif // _HID_h_
