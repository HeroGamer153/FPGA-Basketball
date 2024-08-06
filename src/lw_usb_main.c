#include <stdio.h>
#include <stdlib.h>
#include "platform.h"
#include "lw_usb/GenericMacros.h"
#include "lw_usb/GenericTypeDefs.h"
#include "lw_usb/MAX3421E.h"
#include "lw_usb/USB.h"
#include "lw_usb/usb_ch9.h"
#include "lw_usb/transfer.h"
#include "lw_usb/HID.h"

#include "xparameters.h"
#include <xgpio.h>
#include <math.h>
#include <sleep.h>

extern HID_DEVICE hid_device;

static XGpio Gpio_hex;

static BYTE addr = 1; 				//hard-wired USB address
const char* const devclasses[] = { " Uninitialized", " HID Keyboard", " HID Mouse"," HID Gamepad", " Mass storage"};

BYTE GetDriverandReport() {
	BYTE i;
	BYTE rcode;
	BYTE device = 0xFF;
	BYTE tmpbyte;

	DEV_RECORD* tpl_ptr;
	xil_printf("Reached USB_STATE_RUNNING (0x40)\n");
	for (i = 1; i < USB_NUMDEVICES; i++) {
		tpl_ptr = GetDevtable(i);
		if (tpl_ptr->epinfo != NULL) {
			xil_printf("Device: %d", i);
			xil_printf("%s \n", devclasses[tpl_ptr->devclass]);
			device = tpl_ptr->devclass;
		}
	}
	//Query rate and protocol
	rcode = XferGetIdle(addr, 0, hid_device.interface, 0, &tmpbyte);
	if (rcode) {   //error handling
		xil_printf("GetIdle Error. Error code: ");
		xil_printf("%x \n", rcode);
	} else {
		xil_printf("Update rate: ");
		xil_printf("%x \n", tmpbyte);
	}
	xil_printf("Protocol: ");
	rcode = XferGetProto(addr, 0, hid_device.interface, &tmpbyte);
	if (rcode) {   //error handling
		xil_printf("GetProto Error. Error code ");
		xil_printf("%x \n", rcode);
	} else {
		xil_printf("%d \n", tmpbyte);
	}
	return device;
}

void printHex (u32 data, unsigned channel)
{
	XGpio_DiscreteWrite (&Gpio_hex, channel, data);
}

int main() {
    init_platform();
    XGpio_Initialize(&Gpio_hex, XPAR_GPIO_USB_KEYCODE_DEVICE_ID);
   	XGpio_SetDataDirection(&Gpio_hex, 1, 0x00000000); //configure hex display GPIO
   	XGpio_SetDataDirection(&Gpio_hex, 2, 0x00000000); //configure hex display GPIO


   	BYTE rcode;
	BOOT_MOUSE_REPORT buf;		//USB mouse report
	BOOT_KBD_REPORT kbdbuf;
	BOOT_GAMEPAD_REPORT gmpdbuf;

	BYTE runningdebugflag = 0;//flag to dump out a bunch of information when we first get to USB_STATE_RUNNING
	BYTE errorflag = 0; //flag once we get an error device so we don't keep dumping out state info
	BYTE device;

	xil_printf("initializing MAX3421E...\n");
	MAX3421E_init();
	xil_printf("initializing USB...\n");
	USB_init();

	volatile uint32_t* handX = (volatile uint32_t*)XPAR_PLAYERX_GPIO_BASEADDR;
	volatile uint32_t* handY = (volatile uint32_t*)XPAR_PLAYERY_GPIO_BASEADDR;
	int hoopX = 123;
	int hoopY = 204;
	int hoopXR = 516;
	int hoopYR = 204;
	volatile uint32_t* ballX = (volatile uint32_t*)XPAR_BALLX_GPIO_BASEADDR;
	volatile uint32_t* ballY = (volatile uint32_t*)XPAR_BALLY_GPIO_BASEADDR;
	volatile uint32_t* shoot = (volatile uint32_t*)XPAR_SHOOT_GPIO_BASEADDR;
	volatile uint32_t* dir = (volatile uint32_t*)XPAR_DIR_GPIO_BASEADDR;
	volatile uint32_t* madeshot = (volatile uint32_t*)XPAR_MADESHOT_GPIO_BASEADDR;
	volatile uint32_t* shotFinished = (volatile uint32_t*)XPAR_SHOTFINISHED_GPIO_BASEADDR;


	int startX = 641;
	int startY = 0;
	int endX;
	int endY;
	int currentStep = 0;
	int circleL = 0;
	int circleR = 0;
	int point = 0;

	while (1) {
		xil_printf("."); //A tick here means one loop through the USB main handler
		MAX3421E_Task();
		USB_Task();
		if (GetUsbTaskState() == USB_STATE_RUNNING) {
			if (!runningdebugflag) {
				runningdebugflag = 1;
				device = GetDriverandReport();
			} else if (device == 1) {
				//run keyboard debug polling
				rcode = kbdPoll(&kbdbuf);
				if (rcode == hrNAK) {
					continue; //NAK means no new data
				} else if (rcode) {
					xil_printf("Rcode: ");
					xil_printf("%x \n", rcode);
					continue;
				}
				xil_printf("keycodes: ");
				for (int i = 0; i < 6; i++) {
					xil_printf("%x ", kbdbuf.keycode[i]);
				}
				//Outputs the first 4 keycodes using the USB GPIO channel 1
				printHex (kbdbuf.keycode[0] + (kbdbuf.keycode[1]<<8) + (kbdbuf.keycode[2]<<16) + + (kbdbuf.keycode[3]<<24), 1);
				//Modify to output the last 2 keycodes on channel 2.
				xil_printf("\n");
			}

			else if (device == 2) {
				rcode = mousePoll(&buf);
				if (rcode == hrNAK) {
					//NAK means no new data
					continue;
				} else if (rcode) {
					xil_printf("Rcode: ");
					xil_printf("%x \n", rcode);
					continue;
				}
				xil_printf("X displacement: ");
				xil_printf("%d ", (signed char) buf.Xdispl);
				xil_printf("Y displacement: ");
				xil_printf("%d ", (signed char) buf.Ydispl);
				xil_printf("Buttons: ");
				xil_printf("%x\n", buf.button);
			}
			else if(device == 3){
				rcode = gpdPoll(&gmpdbuf);
				if (rcode == hrNAK) {
					continue; //NAK means no new data
				} else if (rcode) {
					xil_printf("Rcode: ");
					xil_printf("%x \n", rcode);
					continue;
				}
//				xil_printf("keycodes: ");
//                for (int i = 0; i < 6; i++) {
//                    xil_printf("%x ", gmpdbuf.gamepadbuttons[i]);
//                }
//
				//xil_printf("LR: %x\n",gmpdbuf.LR);
				//xil_printf("UD: %x\n",gmpdbuf.UD);
				//xil_printf("buttons: %x\n",gmpdbuf.buttons);
//				xil_printf("TC: %x\n",gmpdbuf.TC);



				//Outputs the first 4 keycodes using the USB GPIO channel 1
				printHex (gmpdbuf.LR + (gmpdbuf.UD<<8) + (gmpdbuf.buttons<<16) + (gmpdbuf.TC<<24), 1);
				//Modify to output the last 2 keycodes on channel 2.
				xil_printf("\n");
			}
		} else if (GetUsbTaskState() == USB_STATE_ERROR) {
			if (!errorflag) {
				errorflag = 1;
				xil_printf("USB Error State\n");
				//print out string descriptor here
			}
		} else //not in USB running state
		{

//			xil_printf("USB task state: ");
//			xil_printf("%x\n", GetUsbTaskState());
			if (runningdebugflag) {	//previously running, reset USB hardware just to clear out any funky state, HS/FS etc
				runningdebugflag = 0;
				MAX3421E_init();
				USB_init();
			}
			errorflag = 0;
		}
			circleL = (((*handX + 20) - 223) * ((*handX+20)-223)) + (((*handY + 56) - 299) * ((*handY + 56) - 299));
			circleR = ((*handX - 416) * (*handX-416)) + (((*handY + 56) - 299) * ((*handY + 56) - 299));

//			*madeshot = 0;
			if(*shoot){
				*shotFinished = 0;
				int chance = rand() % 10;
				if(*dir == 0){
					if((*handY + 56) < 265 || (*handY + 56) > 345 || (*handX > 223 && circleL > 961) ){
						if(chance >= 0 && chance <= 3){ //Ball makes it in
							startX = *handX;
							startY = *handY;
							endX = hoopX;
							endY = hoopY;
							currentStep = 0;
							*madeshot = 3;
						}
						else{
							startX = *handX;
							startY = *handY;
							endX = hoopX + 15;
							endY = hoopY + 10;
							currentStep = 0;
							*madeshot = 0;
						}
					}
					else{
						if(chance >= 0 && chance <= 5){ //Ball makes it in
							startX = *handX;
							startY = *handY;
							endX = hoopX;
							endY = hoopY;
							currentStep = 0;
							*madeshot = 2;
						}
						else{
							startX = *handX;
							startY = *handY;
							endX = hoopX + 15;
							endY = hoopY + 10;
							currentStep = 0;
							*madeshot = 0;

						}
					}
				}
				else{
					if((*handY + 56) < 265 || (*handY + 56) > 345 || (*handX < 416 && circleR > 961) ){
						if(chance >= 0 && chance <= 3){ //Ball makes it in
							startX = *handX;
							startY = *handY;
							endX = hoopXR;
							endY = hoopYR;
							currentStep = 0;
							*madeshot = 3;
						}

						else{ //ball misses
							startX = *handX;
							startY = *handY;
							endX = hoopXR - 15;
							endY = hoopYR + 10;
							currentStep = 0;
							*madeshot = 0;
						}
					}
					else{
						if(chance >= 0 && chance <= 5){ //Ball makes it in
							startX = *handX;
							startY = *handY;
							endX = hoopXR;
							endY = hoopYR;
							currentStep = 0;
							*madeshot = 2;
						}
						else{
							startX = *handX;
							startY = *handY;
							endX = hoopXR - 15;
							endY = hoopYR + 10;
							currentStep = 0;
							*madeshot = 0;

						}
					}
				}
			}

		if (currentStep > 1000) {
//			if(point == 3){
//				*madeshot = 3;
//				point = 0;
//			}
//			else if(point == 2){
//				*madeshot = 2;
//				point = 0;
//			}
			startX = 641;
			startY = 0;
			endX = 641;
			endY = 0;
			currentStep = 0;
			*shotFinished = 1;

		}
		double t = (double)currentStep / 1000;
//		double midY = (startY + endY) / 2.0 - 30;
//
//		double x = startX + t * (endX - startX);
//		double y = midY - 30 * sin(M_PI*t);
		double dx = endX - startX;
		double dy = endY - startY;

		double x = startX + dx * t;
		double y = startY + dy * t - 40*sin(M_PI*t);
		xil_printf("%f", *ballX);

		//(1 - (t - 0.5) * (t - 0.5) * 4
		*ballX = (uint32_t)x;
		*ballY = (uint32_t)y;
		//xil_printf(" Y: %f\n", y);

		currentStep++;

	}
    cleanup_platform();
	return 0;
}
