/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xparameters.h"

#include <unistd.h>

// Maximum dimension of a matrix is 8x8
#define MAX_DIMENSION 7
#define N 4
#define M 7
#define P 3



//#define XPAR_BRAM_CTRL_A_S_AXI_BASEADDR 0x40000000U
//#define XPAR_BRAM_CTRL_B_S_AXI_BASEADDR 0x42000000U
//#define XPAR_BRAM_CTRL_C_S_AXI_BASEADDR 0x44000000U
//#define XPAR_MATRIX_MULTIPLIER_0_S00_AXI_BASEADDR 0x43C00000

int main()
{
	int i = 0;
	u32 start =0;
	u32 ready = 0;
	u32 n = 0;
	u32 m = 0;
	u32 p = 0;
	u32 read_data = 0;
    init_platform();

    printf("Hello World ******************************************************\n\r");
    printf("Writing data to matrix A: \n");
    for (i = 0; i<(N*M); i++)
    {
    	Xil_Out32(XPAR_BRAM_CTRL_A_S_AXI_BASEADDR+(i*4),(u32)(i+4000));
    	//printf("%d  ", i+1);
    	//if((i+1)%M ==0)
    	//    	   printf("\n");

    }
    printf("Reading data from matrix A: \n");
    for (i = 0; i<(N*M); i++)
    {
    	read_data = Xil_In32(XPAR_BRAM_CTRL_A_S_AXI_BASEADDR+(i*4));
    	printf("%lu  ", read_data);
    	if((i+1)%M ==0)
    	    	   printf("\n");

    }
    printf("Matrix B: \n");
    for (i = 0; i<(M*P); i++)
     {
        Xil_Out32(XPAR_BRAM_CTRL_B_S_AXI_BASEADDR+(i*4),(u32)(i+4000));//(DIMENSION*DIMENSION)));
       // printf("%d  ", i+(DIMENSION*DIMENSION));
       // if((i+1)%P ==0)
     	//    	   printf("\n");

     }
    printf("Reading data from matrix B: \n");
    for (i = 0; i<(M*P); i++)
    {

    	read_data = Xil_In32(XPAR_BRAM_CTRL_B_S_AXI_BASEADDR+(i*4));
    	printf("%lu  ", read_data);
    	if((i+1)%P ==0)
    	    	   printf("\n");

    }
    printf("Matrices written\n\n");
    printf("Reading ready from mat_mult\n");
    ready = Xil_In32(XPAR_MATRIX_MULTIPLIER_0_S00_AXI_BASEADDR);
    printf("Ready is %lu\n", ready);

    printf("Setting parameters (n,p,m) of mat_mult\n");

    Xil_Out32(XPAR_MATRIX_MULTIPLIER_0_S00_AXI_BASEADDR+8,(u32)N);
    n = Xil_In32(XPAR_MATRIX_MULTIPLIER_0_S00_AXI_BASEADDR+8);
    printf("After writing %d to n parameter, read value is n=%lu\n",N, n);

    Xil_Out32(XPAR_MATRIX_MULTIPLIER_0_S00_AXI_BASEADDR+12,(u32)M);
    m = Xil_In32(XPAR_MATRIX_MULTIPLIER_0_S00_AXI_BASEADDR+12);
    printf("After writing %d to m parameter, read value is m=%lu\n",M, m);

    Xil_Out32(XPAR_MATRIX_MULTIPLIER_0_S00_AXI_BASEADDR+16,(u32)P);
    p = Xil_In32(XPAR_MATRIX_MULTIPLIER_0_S00_AXI_BASEADDR+16);
    printf("After writing %d to p parameter, read value is p=%lu\n",P, p);



    printf("Sending start signal to mat_mul\n");
    Xil_Out32(XPAR_MATRIX_MULTIPLIER_0_S00_AXI_BASEADDR+4,(u32)1);
    start = Xil_In32(XPAR_MATRIX_MULTIPLIER_0_S00_AXI_BASEADDR+4);
    printf("After writing 1, read value start=%lu\n",start);
    Xil_Out32(XPAR_MATRIX_MULTIPLIER_0_S00_AXI_BASEADDR+4,(u32)0);

    ready = Xil_In32(XPAR_MATRIX_MULTIPLIER_0_S00_AXI_BASEADDR);
    printf("Ready is now %lu\n", ready);

    printf("Sleeping 2 seconds now\n");
    sleep(2);
    printf("Woke up!\n");

    ready = Xil_In32(XPAR_MATRIX_MULTIPLIER_0_S00_AXI_BASEADDR);
    printf("Ready is now %lu\n", ready);

    printf("Matrix C: \n");
    read_data = 0;
    for (i = 0; i<(N*P); i++)
    {
       read_data = Xil_In32(XPAR_BRAM_CTRL_C_S_AXI_BASEADDR+(i*4));
       printf("%lu  ",read_data);
       if((i+1)%P ==0)
    	   printf("\n");
    }





    print("Successfully ran Hello World application ******************************************************\n\r");
    cleanup_platform();
    return 0;
}
