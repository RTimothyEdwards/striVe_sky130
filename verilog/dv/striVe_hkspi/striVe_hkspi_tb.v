/*
 *  StriVe housekeeping SPI testbench
 *
 */

`timescale 1 ns / 1 ps

// `include "../striVe_chip.v"
`include "striVe.v"
`include "spiflash.v"
`include "tbuart.v"

module striVe_hkspi_tb;
	reg XCLK;

//	reg real VDD3V3;
//	reg VDD3V3;
	wire VDD3V3;
	assign VDD3V3 = 1'b1;

	reg XI;

	reg real adc_h, adc_l;
	reg real adc_0, adc_1;
	reg real comp_n, comp_p;

	integer i;

	always #10 XCLK <= (XCLK === 1'b0);
	always #220 XI <=  (XI === 1'b0);

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

	wire [15:0] gpio;

	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;
	wire flash_io2;
	wire flash_io3;

	reg SDI, CSB, SCK, RSTB;
	wire SDO;

        // The main testbench is here.  Put the housekeeping SPI into
        // pass-thru mode and read several bytes from the flash SPI.

        // First define tasks for SPI functions

	task start_csb;
	    begin
		SCK <= 1'b0;
		SDI <= 1'b0;
		CSB <= 1'b0;
		#50;
	    end
	endtask

	task end_csb;
	    begin
		SCK <= 1'b0;
		SDI <= 1'b0;
		CSB <= 1'b1;
		#50;
	    end
	endtask

	task write_byte;
	    input [7:0] odata;
	    begin
		SCK <= 1'b0;
		for (i=7; i >= 0; i--) begin
		    #50;
		    SDI <= odata[i];
                    #50;
		    SCK <= 1'b1;
                    #100;
		    SCK <= 1'b0;
		end
	    end
	endtask

	task read_byte;
	    output [7:0] idata;
	    begin
		SCK <= 1'b0;
		SDI <= 1'b0;
		for (i=7; i >= 0; i--) begin
		    #50;
                    idata[i] = SDO;
                    #50;
		    SCK <= 1'b1;
                    #100;
		    SCK <= 1'b0;
		end
	    end
	endtask

	task read_write_byte
	    (input [7:0] odata,
	    output [7:0] idata);
	    begin
		SCK <= 1'b0;
		for (i=7; i >= 0; i--) begin
		    #50;
		    SDI <= odata[i];
                    idata[i] = SDO;
                    #50;
		    SCK <= 1'b1;
                    #100;
		    SCK <= 1'b0;
		end
	    end
	endtask

        // Now drive the digital signals on the housekeeping SPI
	reg [7:0] tbdata;

	initial begin
	    $dumpfile("striVe_hkspi.vcd");
	    $dumpvars(0, striVe_hkspi_tb);

	    CSB <= 1'b1;
	    SCK <= 1'b0;
	    SDI <= 1'b0;
	    RSTB <= 1'b0;

	    // Delay, then bring chip out of reset
	    #1000;
	    RSTB <= 1'b1;

	    #2000;

            // First do a normal read from the housekeeping SPI to
	    // make sure the housekeeping SPI works.

            start_csb();
            write_byte(8'h40);	// Read stream command
            write_byte(8'h03);	// Address (register 3 = product ID)
	    read_byte(tbdata);
	    end_csb();
	    #10;
	    $display("Read data = 0x%02x (should be 0x05)", tbdata);

	    // Toggle external reset
            start_csb();
            write_byte(8'h80);	// Write stream command
            write_byte(8'h07);	// Address (register 7 = external reset)
            write_byte(8'h01);	// Data = 0x01 (apply external reset)
            end_csb();

            start_csb();
            write_byte(8'h80);	// Write stream command
            write_byte(8'h07);	// Address (register 7 = external reset)
            write_byte(8'h00);	// Data = 0x00 (release external reset)
            end_csb();

	    // Read all registers (0 to 8)
            start_csb();
            write_byte(8'h40);	// Read stream command
            write_byte(8'h00);	// Address (register 3 = product ID)
	    read_byte(tbdata);
	    $display("Read register 0 = 0x%02x (should be 0x00)", tbdata);
		if(tbdata != 8'h00) begin $display("Monitor: Test HK SPI (RTL) Failed"); $finish; end
	    read_byte(tbdata);
	    $display("Read register 1 = 0x%02x (should be 0x04)", tbdata);
		if(tbdata != 8'h04) begin $display("Monitor: Test HK SPI (RTL) Failed"); $finish; end
	    read_byte(tbdata);
	    $display("Read register 2 = 0x%02x (should be 0x56)", tbdata);
		if(tbdata != 8'h56) begin $display("Monitor: Test HK SPI (RTL) Failed"); $finish; end
	    read_byte(tbdata);
	    $display("Read register 3 = 0x%02x (should be 0x05)", tbdata);
		if(tbdata != 8'h05) begin $display("Monitor: Test HK SPI (RTL) Failed"); $finish; end
	    read_byte(tbdata);
	    $display("Read register 4 = 0x%02x (should be 0x07)", tbdata);
		if(tbdata != 8'h07) begin $display("Monitor: Test HK SPI (RTL) Failed"); $finish; end
	    read_byte(tbdata);
	    $display("Read register 5 = 0x%02x (should be 0x01)", tbdata);
		if(tbdata != 8'h01) begin $display("Monitor: Test HK SPI (RTL) Failed"); $finish; end
	    read_byte(tbdata);
	    $display("Read register 6 = 0x%02x (should be 0x00)", tbdata);
		if(tbdata != 8'h00) begin $display("Monitor: Test HK SPI (RTL) Failed"); $finish; end
	    read_byte(tbdata);
	    $display("Read register 7 = 0x%02x (should be 0x00)", tbdata);
		if(tbdata != 8'h00) begin $display("Monitor: Test HK SPI (RTL) Failed"); $finish; end
	    read_byte(tbdata);
	    $display("Read register 8 = 0x%02x (should be 0x00)", tbdata);
		if(tbdata != 8'h00) begin $display("Monitor: Test HK SPI (RTL) Failed"); $finish; end
		
        end_csb();

		$display("Monitor: Test HK SPI (RTL) Passed");

	    #10000;
 	    $finish;
	end

	// wire real VDD1V8;
	// wire real VSS;

	// assign VSS = 0.0;

	wire VDD1V8;
	wire VSS;

	assign VSS = 1'b0;
	assign VDD1V8 = 1'b1;

	striVe uut (
		.vdd	  (VDD3V3  ),
		.vdd1v8	  (VDD1V8),
		.vss	  (VSS),
		.xi	  (XI),
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
		.FILENAME("striVe_hkspi.hex")
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
