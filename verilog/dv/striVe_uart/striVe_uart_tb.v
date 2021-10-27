/*
 *  StriVe - A full example SoC using PicoRV32 in SkyWater s8
 *
 *  Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
 *  Copyright (C) 2018  Tim Edwards <tim@efabless.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

`timescale 1 ns / 1 ps

`include "striVe.v"
`include "spiflash.v"
`include "tbuart.v"

module striVe_uart_tb;
	reg XCLK;
//	reg real VDD3V3;
//	reg VDD3V3;
	wire VDD3V3;
	assign VDD3V3 = 1'b1;

	reg XI;

	reg real adc_h, adc_l;
	reg real adc_0, adc_1;
	reg real comp_n, comp_p;

	// External clock is used by default.  Make this artificially fast for the
	// simulation.  Normally this would be a slow clock and the digital PLL
	// would be the fast clock.

	always #12.5 XCLK <= (XCLK === 1'b0);
	always #220 XI <= (XI === 1'b0);

	initial begin
		XI = 0;
		XCLK = 0;
	end

//	initial begin
//		// Ramp VDD3V3 from 0 to 3.3V
//		// VDD3V3 = 0.0;
//		// #50;
//		// repeat (33) begin
//		//    #3;
//		//    VDD3V3 = VDD3V3 + 0.1;
//		// end
//		VDD3V3 = 1'b0;
//		#150;
//		VDD3V3 = 1'b1;
//	end

	initial begin
		// Analog input pin values (static)

		adc_h = 0.0;
		adc_l = 0.0;
		adc_0 = 0.0;
		adc_1 = 0.0;
		comp_n = 0.0;
		comp_p = 0.0;
	end

	initial begin
		$dumpfile("striVe_uart.vcd");
		$dumpvars(0, striVe_uart_tb);

		$display("Wait for UART o/p");
		repeat (150) begin
			repeat (10000) @(posedge XCLK);
			// Diagnostic. . . interrupts output pattern.
		end
		$finish;
	end

	wire [15:0] gpio;

	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;
	wire flash_io2;
	wire flash_io3;

	reg SDI, CSB, SCK, RSTB;
	wire SDO;

	initial begin
		CSB <= 1'b1;
		SCK <= 1'b0;
		SDI <= 1'b0;
		RSTB <= 1'b0;
		#1000;
		RSTB <= 1'b1;	    // Release reset
		#2000;
		CSB <= 1'b0;
	end


	always @(gpio) begin
		//#1 $display("GPIO state = %X ", gpio);
		if(gpio == 16'hA000) begin
			$display("UART Test started");
		end
		else if(gpio == 16'hAB00) begin
			#1000;
			$finish;
		end
	end

//	wire real VDD1V8;
//	wire real VSS;

	wire VDD1V8;
	wire VSS;

	assign VSS = 1'b0;
	assign VDD1V8 = 1'b1;

	striVe uut (
		.vdd	  (VDD3V3  ),
		.vdd1v8	  (VDD1V8),
		.vss	  (VSS),
		.xi	  (XI),
		.xo	  (),
		.xclk	  (XCLK),
		.SDI	  (SDI),
		.SDO	  (SDO),
		.CSB	  (CSB),
		.SCK	  (SCK),
		.ser_rx	  (1'b0	    ),
		.ser_tx	  (tbuart_rx),
		.irq	  (1'b0	    ),
		.gpio     (gpio     ),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.flash_io2(flash_io2),
		.flash_io3(flash_io3),
		.adc_high (adc_h),
		.adc_low  (adc_l),
		.adc0_in  (adc_0),
		.adc1_in  (adc_1),
		.RSTB	  (RSTB),
		.comp_inp (comp_p),
		.comp_inn (comp_n)
	);

	spiflash #(
		.FILENAME("striVe_uart.hex")
	) spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(flash_io2),
		.io3(flash_io3)
	);

	// Testbench UART

	tbuart tbuart (
		.ser_rx(tbuart_rx)
	);
		
endmodule
