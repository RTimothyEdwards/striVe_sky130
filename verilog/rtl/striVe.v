/*----------------------------------------------------------*/
/* striVe, a raven/ravenna-like architecture in SkyWater s8 */
/*							    */
/* 1st edition, test of SkyWater s8 process		    */
/* This version is missing all analog functionality,	    */
/* including crystal oscillator, voltage regulator, and PLL */
/* For simplicity, the pad arrangement of Raven has been    */
/* retained, even though many pads have no internal	    */
/* connection.						    */
/*							    */
/* Copyright 2020 efabless, Inc.			    */
/* Written by Tim Edwards, December 2019		    */
/* This file is open source hardware released under the	    */
/* Apache 2.0 license.  See file LICENSE.		    */
/*							    */
/*----------------------------------------------------------*/

`timescale 1 ns / 1 ps

/* Always define USE_PG_PIN (used by SkyWater cells) */
/* But do not define SC_USE_PG_PIN */
`define USE_PG_PIN

/* Define LVS (equivalent to USE_PG_PIN, used by qflow) */
/* `define LVS */

/* Must define functional for now because otherwise the timing delays	*/
/* are assumed, but they have been stripped out because some are not	*/
/* parsed by iverilog.							*/

`define functional

// Define GL to use the gate-level netlists
//`define GL

// PDK IP
// Digital standard cells
//`include "/usr/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v"

// I/O padframe cells
// `include "/usr/share/pdk/sky130A/libs.ref/sky130_fd_io/verilog/sky130_fd_io.v"
// `include "/usr/share/pdk/sky130A/libs.ref/sky130_fd_io/verilog/sky130_ef_io.v"
// 
// `ifdef GL
//     // Core cells, synthesized versions
//     `include "../gl/striVe_soc.synthesis.v"
//     `include "../gl/striVe_spi.synthesis.v"
//     `include "../gl/digital_pll.synthesis.v"
//     `include "../gl/striVe_clkrst.synthesis.v"
// `else
//     // Core cells, functional source versions
//     `include "striVe_soc.v"
//     `include "striVe_spi.v"
//     `include "digital_pll.v"
//     `include "striVe_clkrst.v"
// `endif
// 
// `ifdef PFG
//     `include "sky130_fd_sc_hd_conb_1.v"
// `endif
// 
// `include "lvlshiftdown.v"
`ifdef SYNTH_OPENLANE
	`include "/usr/share/pdk/sky130A/libs.ref/sky130_fd_io/verilog/sky130_fd_io.v"
	`include "/usr/share/pdk/sky130A/libs.ref/sky130_ef_io/verilog/sky130_ef_io.v"
`else

    `ifndef LVS
	`include "/usr/share/pdk/sky130A/libs.ref/sky130_fd_io/verilog/sky130_fd_io.v"
	`include "/usr/share/pdk/sky130A/libs.ref/sky130_ef_io/verilog/sky130_ef_io.v"
	`include "/usr/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v"
	`include "lvlshiftdown.v"
	`ifdef GL
		// Core cells, synthesized versions
		`include "../gl/striVe_soc.synthesis.v"
		`include "../gl/striVe_spi.synthesis.v"
		`include "../gl/digital_pll.synthesis.v"
		`include "../gl/striVe_clkrst.synthesis.v"
	`else
		`include "striVe_soc.v"
		`include "striVe_spi.v"
		`include "digital_pll.v"
		`include "striVe_clkrst.v"
	`endif
    `endif
`endif

// padframe generator needs these
`ifdef PFG
	`include "sky130_fd_sc_hd_conb_1.v"
	`include "lvlshiftdown.v"
`endif
 
module striVe (vdd, vdd1v8, vss, gpio, xi, xo, adc0_in, adc1_in, adc_high, adc_low,
	comp_inn, comp_inp, RSTB, ser_rx, ser_tx, irq, SDO, SDI, CSB, SCK,
	xclk, flash_csb, flash_clk, flash_io0, flash_io1, flash_io2, flash_io3);
    inout vdd;
    inout vdd1v8;
    inout vss;
    inout [15:0] gpio;
    input xi;		// CMOS clock input, not a crystal
    output xo;		// divide-by-16 clock output
    input adc0_in;
    input adc1_in;
    input adc_high;
    input adc_low;
    input comp_inn;
    input comp_inp;
    input RSTB;		// NOTE:  Replaces analog_out pin from raven chip
    input ser_rx;
    output ser_tx;
    input irq;
    output SDO;
    input SDI;
    input CSB;
    input SCK;
    input xclk;
    output flash_csb;
    output flash_clk;
    output flash_io0;
    output flash_io1;
    output flash_io2;
    output flash_io3;

    wire [15:0] gpio_out_core;
    wire [15:0] gpio_in_core;
    wire [15:0]	gpio_mode0_core;
    wire [15:0]	gpio_mode1_core;
    wire [15:0]	gpio_outenb_core;
    wire [15:0]	gpio_inenb_core;

    wire analog_a, analog_b;	    /* Placeholders for analog signals */

    wire porb_h;
    wire porb_l;
    wire por_h;
    wire por;
    wire SCK_core;
    wire SDI_core;
    wire CSB_core;
    wire SDO_core;
    wire SDO_enb;
    wire spi_ro_xtal_ena_core;
    wire spi_ro_reg_ena_core;
    wire spi_ro_pll_dco_ena_core;
    wire [2:0] spi_ro_pll_sel_core;
    wire [4:0] spi_ro_pll_div_core;
    wire [25:0] spi_ro_pll_trim_core;
    wire ext_clk_sel_core;
    wire irq_spi_core;
    wire ext_reset_core;
    wire trap_core;
    wire [11:0] spi_ro_mfgr_id_core;
    wire [7:0] spi_ro_prod_id_core;
    wire [3:0] spi_ro_mask_rev_core;

    // Instantiate power cells for VDD3V3 domain (8 total; 4 high clamps and
    // 4 low clamps)
    s8iom0_vdda_hvc_pad vdd3v3hclamp [1:0] (
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.drn_hvc(),
	.src_bdy_hvc(),
	.vswitch(vdd),
	.vcchib(vdd1v8),	// Hibernation supply
	.vccd(vdd1v8),
	.vdda(vdd),	// Analog power supply
	.vssa(vss),	// Analog ground
	.vddio(vdd),	// Main (digital) power supply
	.vssio(vss),	// Main (digital) ground
	.vssd(vss),
	.vddio_q(vddio_q),  // (vdd low-noise) Tied to vddio in vddio pad
	.vssio_q(vssio_q)   // (vss low-noise) Tied to vssio in vssio pad
    );

    s8iom0_vddio_hvc_pad vddiohclamp [1:0] (
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.drn_hvc(),
	.src_bdy_hvc(),
	.vswitch(vdd),
	.vcchib(vdd1v8),	// Hibernation supply
	.vccd(vdd1v8),
	.vdda(vdd),	// Analog power supply
	.vssa(vss),	// Analog ground
	.vddio(vdd),	// Main (digital) power supply
	.vssio(vss),	// Main (digital) ground
	.vssd(vss),
	.vddio_q(vddio_q),
	.vssio_q(vssio_q)
    );


    s8iom0_vdda_lvc_pad vdd3v3lclamp [3:0] (
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.bdy2_b2b(),
	.drn_lvc1(),
	.drn_lvc2(),
	.src_bdy_lvc1(),
	.src_bdy_lvc2(),
	.vssa(vss),
	.vdda(vdd),
	.vswitch(vdd),
	.vddio_q(vddio_q),
	.vcchib(vdd1v8),
	.vddio(vdd),
	.vccd(vdd1v8),
	.vssio(vss),
	.vssd(vss),
	.vssio_q(vssio_q)
    );

    // Instantiate the core voltage supply (since it is not generated on-chip)
    // (1.8V) (4 total, 2 high and 2 low clamps)

    s8iom0_vccd_hvc_pad vdd1v8hclamp [1:0] (
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.drn_hvc(),
	.src_bdy_hvc(),
	.vswitch(vdd),
	.vcchib(vdd1v8),	// Hibernation supply
	.vccd(vdd1v8),
	.vdda(vdd),	// Analog power supply
	.vssa(vss),	// Analog ground
	.vddio(vdd),	// Main (digital) power supply
	.vssio(vss),	// Main (digital) ground
	.vssd(vss),
	.vddio_q(vddio_q),	// (vdd low-noise) Tie to vddio if not using analog mux
	.vssio_q(vssio_q)	// (vss low-noise) Tie to vssio if not using analog mux
    );

    s8iom0_vccd_lvc_pad vdd1v8lclamp [1:0] (
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.bdy2_b2b(),
	.drn_lvc1(),
	.drn_lvc2(),
	.src_bdy_lvc1(),
	.src_bdy_lvc2(),
	.vssa(vss),
	.vdda(vdd),
	.vswitch(vdd),
	.vddio_q(vddio_q),
	.vcchib(vdd1v8),
	.vddio(vdd),
	.vccd(vdd1v8),
	.vssio(vss),
	.vssd(vss),
	.vssio_q(vssio_q)
    );

    // Instantiate ground cells (7 total, 4 high clamps and 3 low clamps)

    s8iom0_vssa_hvc_pad vsshclamp [3:0] (
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.drn_hvc(),
	.src_bdy_hvc(),
	.vssa(vss),
	.vdda(vdd),
	.vswitch(vdd),
	.vddio_q(vddio_q),
	.vcchib(vdd1v8),
	.vddio(vdd),
	.vccd(vdd1v8),
	.vssio(vss),
	.vssd(vss),
	.vssio_q(vssio_q)
    );

    s8iom0_vssa_lvc_pad vssalclamp (
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.bdy2_b2b(),
	.drn_lvc1(),
	.drn_lvc2(),
	.src_bdy_lvc1(),
	.src_bdy_lvc2(),
	.vssa(vss),
	.vdda(vdd),
	.vswitch(vdd),
	.vddio_q(vddio_q),
	.vcchib(vdd1v8),	// Core voltage
	.vddio(vdd),	// ESD power supply
	.vssio(vss),	// ESD ground
	.vccd(vdd1v8),
	.vssio_q(vssio_q)
    );

    s8iom0_vssd_lvc_pad vssdlclamp (
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.bdy2_b2b(),
	.drn_lvc1(),
	.drn_lvc2(),
	.src_bdy_lvc1(),
	.src_bdy_lvc2(),
	.vssa(vss),
	.vdda(vdd),
	.vswitch(vdd),
	.vddio_q(vddio_q),
	.vcchib(vdd1v8),	// Core voltage
	.vddio(vdd),	// ESD power supply
	.vssio(vss),	// ESD ground
	.vccd(vdd1v8),
	.vssio_q(vssio_q)
    );

    s8iom0_vssio_lvc_pad vssiolclamp (
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.bdy2_b2b(),
	.drn_lvc1(),
	.drn_lvc2(),
	.src_bdy_lvc1(),
	.src_bdy_lvc2(),
	.vssa(vss),
	.vdda(vdd),
	.vswitch(vdd),
	.vddio_q(vddio_q),
	.vcchib(vdd1v8),	// Core voltage
	.vddio(vdd),	// ESD power supply
	.vssio(vss),	// ESD ground
	.vccd(vdd1v8),
	.vssio_q(vssio_q)
    );



    // Instantiate GPIO v2 cell.  These are used for both digital and analog
    // functions, configured appropriately.
    //
    // GPIO pin description:
    //
    // general:  signals with _h suffix are in the vddio (3.3V) domain.  All
    // other signals are in 1.8V domains (vccd or vcchib)

    // out = Signal from core to pad (digital, 1.8V domain)
    // oe_n = Output buffer enable (sense inverted)
    // hld_h_n = Hold signals during deep sleep (sense inverted)
    // enable_h = Power-on-reset (inverted)
    // enable_inp_h = Defines state of input buffer output when disabled.
    //	    Connect via loopback to tie_hi_esd or tie_lo_esd.
    // enable_vdda_h = Power-on-reset (inverted) to analog section
    // enable_vswitch_h = set to 0 if not using vswitch
    // enable_vddio = set to 1 if vddio is up during deep sleep
    // inp_dis = Disable input buffer
    // ib_mode_sel = Input buffer mode select, 0 for 3.3V external signals, 1 for
    //		1.8V external signals
    // vtrip_se = Input buffer trip select, 0 for CMOS level, 1 for TTL level
    // slow = 0 for fast slew, 1 for slow slew
    // hld_ovr = override for pads that need to be enabled during deep sleep
    // analog_en = enable analog functions
    // analog_sel = select analog channel a or b
    // analog_pol = analog select polarity
    // dm = digital mode (3 bits) 000 = analog 001 = input only, 110 = output only
    // vddio = Main 3.3V supply
    // vddio_q = Quiet 3.3V supply
    // vdda = Analog 3.3V supply
    // vccd = Digital 1.8V supply
    // vswitch = High-voltage supply for analog switches
    // vcchib = Digital 1.8V supply live during deep sleep mode
    // vssa = Analog ground
    // vssd = Digital ground
    // vssio_q = Quiet main ground
    // vssio = Main ground
    // pad = Signal on pad
    // pad_a_noesd_h = Direct core connection to pad
    // pad_a_esd_0_h = Core connection to pad through 150 ohms (primary)
    // pad_a_esd_1_h = Core connection to pad through 150 ohms (secondary)
    // amuxbus_a = Analog bus A
    // amuxbus_b = Analog bus B
    // in = Signal from pad to core (digital, 1.8V domain)
    // in_h = Signal from pad to core (3.3V domain)
    // tie_hi_esd = 3.3V output for loopback to enable_inp_h
    // tie_lo_esd = ground output for loopback to enable_inp_h

    // 37 instances:  16 general purpose digital, 2 for the crystal oscillator,
    // 4 for the ADC, 1 for the analog out, 2 for the comparator inputs,
    // one for the IRQ input, one for the xclk input, 6 for the SPI flash
    // signals, and 4 for the housekeeping SPI signals.

    // NOTE:  To pass a vector to array dm in an array of instances gpio_pad,
    // the array needs to be rearranged.  Reconstruct the needed 48-bit vector
    // (3 bit signal * 16 instances).
    //
    // Also note:  Preferable to use a generate block, but that is incompatible
    // with the current version of padframe_generator. . .

    wire [47:0] dm_all;

    assign dm_all = {gpio_mode1_core[15], gpio_mode1_core[15], gpio_mode0_core[15],
		 gpio_mode1_core[14], gpio_mode1_core[14], gpio_mode0_core[14],
		 gpio_mode1_core[13], gpio_mode1_core[13], gpio_mode0_core[13],
		 gpio_mode1_core[12], gpio_mode1_core[12], gpio_mode0_core[12],
		 gpio_mode1_core[11], gpio_mode1_core[11], gpio_mode0_core[11],
		 gpio_mode1_core[10], gpio_mode1_core[10], gpio_mode0_core[10],
		 gpio_mode1_core[9], gpio_mode1_core[9], gpio_mode0_core[9],
		 gpio_mode1_core[8], gpio_mode1_core[8], gpio_mode0_core[8],
		 gpio_mode1_core[7], gpio_mode1_core[7], gpio_mode0_core[7],
		 gpio_mode1_core[6], gpio_mode1_core[6], gpio_mode0_core[6],
		 gpio_mode1_core[5], gpio_mode1_core[5], gpio_mode0_core[5],
		 gpio_mode1_core[4], gpio_mode1_core[4], gpio_mode0_core[4],
		 gpio_mode1_core[3], gpio_mode1_core[3], gpio_mode0_core[3],
		 gpio_mode1_core[2], gpio_mode1_core[2], gpio_mode0_core[2],
		 gpio_mode1_core[1], gpio_mode1_core[1], gpio_mode0_core[1],
		 gpio_mode1_core[0], gpio_mode1_core[0], gpio_mode0_core[0]};

    // GPIO pads
    s8iom0_gpiov2_pad gpio_pad [15:0] (
	.out(gpio_out_core),	// Signal from core to pad
	.oe_n(gpio_outenb_core), // Output enable (sense inverted)
	.hld_h_n(vdd),		// Hold signals during deep sleep (sense inverted)
	.enable_h(porb_h),	// Post-reset enable
	.enable_inp_h(loopb0),	// Input buffer state when disabled
	.enable_vdda_h(porb_h),	// 
	.enable_vswitch_h(vss),	// 
	.enable_vddio(vdd1v8),	//
	.inp_dis(gpio_inenb_core),		// Disable input buffer
	.ib_mode_sel(vss),	//
	.vtrip_sel(vss),	//
	.slow(vss),		//
	.hld_ovr(vss),		//
	.analog_en(vss),	//
	.analog_sel(vss),	//
	.analog_pol(vss),	//
	.dm(dm_all), // (3 bits) Mode control
	.vddio(vdd),		
        .vddio_q(vddio_q),
        .vdda(vdd),
        .vccd(vdd1v8),
        .vswitch(vdd),
        .vcchib(vdd1v8),
        .vssa(vss),
        .vssd(vss),
        .vssio_q(vssio_q),
        .vssio(vss),
	.pad(gpio),
	.pad_a_noesd_h(),   // Direct pad connection
	.pad_a_esd_0_h(),   // Pad connection through 150 ohms
	.pad_a_esd_1_h(),   // Pad connection through 150 ohms
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.in(gpio_in_core),  // Signal from pad to core
	.in_h(),	    // VDDA domain signal (unused)
	.tie_hi_esd(),
	.tie_lo_esd(loopb0)
    );

    s8iom0_gpiov2_pad xi_pad (
	.out(),			// Signal from core to pad
	.oe_n(vdd1v8),		// Output enable (sense inverted)
	.hld_h_n(vdd),		// Hold
	.enable_h(porb_h),	// Enable
	.enable_inp_h(loopb1),	// Enable input buffer
	.enable_vdda_h(porb_h),	// 
	.enable_vswitch_h(vss),	// 
	.enable_vddio(vdd1v8),	//
	.inp_dis(por),		// Disable input buffer
	.ib_mode_sel(vss),	//
	.vtrip_sel(vss),	//
	.slow(vss),		//
	.hld_ovr(vss),		//
	.analog_en(vss),	//
	.analog_sel(vss),	//
	.analog_pol(vss),	//
	.dm({vss, vss, vdd1v8}), // (3 bits) Mode control
	.vddio(vdd),		
        .vddio_q(vddio_q),
        .vdda(vdd),
        .vccd(vdd1v8),
        .vswitch(vdd),
        .vcchib(vdd1v8),
        .vssa(vss),
        .vssd(vss),
        .vssio_q(vssio_q),
        .vssio(vss),
	.pad(xi),
	.pad_a_noesd_h(),   // Direct pad connection
	.pad_a_esd_0_h(),   // Pad connection through 150 ohms
	.pad_a_esd_1_h(),   // Pad connection through 150 ohms
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.in(xi_core),	    // Signal from pad to core
	.in_h(),
	.tie_hi_esd(),
	.tie_lo_esd(loopb1)
    );

    s8iom0_gpiov2_pad xo_pad (
	.out(pll_clk16),	// Signal from core to pad
	.oe_n(vss),		// Output enable (sense inverted)
	.hld_h_n(vdd),		// Hold
	.enable_h(porb_h),	// Enable
	.enable_inp_h(loopb2),	// Enable input buffer
	.enable_vdda_h(porb_h),	// 
	.enable_vswitch_h(vss),	// 
	.enable_vddio(vdd1v8),	//
	.inp_dis(vdd1v8),	// Disable input buffer
	.ib_mode_sel(vss),	//
	.vtrip_sel(vss),	//
	.slow(vss),		//
	.hld_ovr(vss),		//
	.analog_en(vss),	//
	.analog_sel(vss),	//
	.analog_pol(vss),	//
	.dm({vdd1v8, vdd1v8, vss}),	// (3 bits) Mode control
	.vddio(vdd),		
        .vddio_q(vddio_q),
        .vdda(vdd),
        .vccd(vdd1v8),
        .vswitch(vdd),
        .vcchib(vdd1v8),
        .vssa(vss),
        .vssd(vss),
        .vssio_q(vssio_q),
        .vssio(vss),
	.pad(xo),
	.pad_a_noesd_h(),   // Direct pad connection
	.pad_a_esd_0_h(),   // Pad connection through 150 ohms
	.pad_a_esd_1_h(),   // Pad connection through 150 ohms
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.in(),	    // Signal from pad to core
	.in_h(),
	.tie_hi_esd(),
	.tie_lo_esd(loopb2)
    );

    s8iom0_gpiov2_pad adc0_in_pad (
	.out(vss),		// Signal from core to pad
	.oe_n(vdd1v8),		// Output enable (sense inverted)
	.hld_h_n(vdd),		// Hold
	.enable_h(porb_h),	// Enable
	.enable_inp_h(loopb3),	// Enable input buffer
	.enable_vdda_h(porb_h),	// 
	.enable_vswitch_h(vss),	// 
	.enable_vddio(vdd1v8),	//
	.inp_dis(vdd1v8),	// Disable input buffer
	.ib_mode_sel(vss),	//
	.vtrip_sel(vss),	//
	.slow(vss),		//
	.hld_ovr(vss),		//
	.analog_en(vdd1v8),	//
	.analog_sel(vss),	//
	.analog_pol(vss),	//
	.dm({vss, vss, vss}),			// (3 bits) Mode control
	.vddio(vdd),		
        .vddio_q(vddio_q),
        .vdda(vdd),
        .vccd(vdd1v8),
        .vswitch(vdd),
        .vcchib(vdd1v8),
        .vssa(vss),
        .vssd(vss),
        .vssio_q(vssio_q),
        .vssio(vss),
	.pad(adc0_in),
	.pad_a_noesd_h(),   // Direct pad connection
	.pad_a_esd_0_h(),   // Pad connection through 150 ohms
	.pad_a_esd_1_h(),   // Pad connection through 150 ohms
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.in(),		    // Signal from pad to core
	.in_h(),
	.tie_hi_esd(),
	.tie_lo_esd()
    );

    s8iom0_gpiov2_pad adc1_in_pad (
	.out(vss),		// Signal from core to pad
	.oe_n(vdd1v8),		// Output enable (sense inverted)
	.hld_h_n(vdd),		// Hold
	.enable_h(porb_h),	// Enable
	.enable_inp_h(loopb4),	// Enable input buffer
	.enable_vdda_h(porb_h),	// 
	.enable_vswitch_h(vss),	// 
	.enable_vddio(vdd1v8),	//
	.inp_dis(vdd1v8),	// Disable input buffer
	.ib_mode_sel(vss),	//
	.vtrip_sel(vss),	//
	.slow(vss),		//
	.hld_ovr(vss),		//
	.analog_en(vdd1v8),	//
	.analog_sel(vss),	//
	.analog_pol(vss),	//
	.dm({vss, vss, vss}),			// (3 bits) Mode control
	.vddio(vdd),		
        .vddio_q(vddio_q),
        .vdda(vdd),
        .vccd(vdd1v8),
        .vswitch(vdd),
        .vcchib(vdd1v8),
        .vssa(vss),
        .vssd(vss),
        .vssio_q(vssio_q),
        .vssio(vss),
	.pad(adc1_in),
	.pad_a_noesd_h(),   // Direct pad connection
	.pad_a_esd_0_h(),   // Pad connection through 150 ohms
	.pad_a_esd_1_h(),   // Pad connection through 150 ohms
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.in(),		    // Signal from pad to core
	.in_h(),
	.tie_hi_esd(),
	.tie_lo_esd()
    );

    s8iom0_gpiov2_pad adc_high_pad (
	.out(vss),		// Signal from core to pad
	.oe_n(vdd1v8),		// Output enable (sense inverted)
	.hld_h_n(vdd),		// Hold
	.enable_h(porb_h),	// Enable
	.enable_inp_h(loopb5),	// Enable input buffer
	.enable_vdda_h(porb_h),	// 
	.enable_vswitch_h(vss),	// 
	.enable_vddio(vdd1v8),	//
	.inp_dis(vdd1v8),	// Disable input buffer
	.ib_mode_sel(vss),	//
	.vtrip_sel(vss),	//
	.slow(vss),		//
	.hld_ovr(vss),		//
	.analog_en(vdd1v8),	//
	.analog_sel(vdd1v8),	//
	.analog_pol(vdd1v8),	//
	.dm({vss, vss, vss}),			// (3 bits) Mode control
	.vddio(vdd),		
        .vddio_q(vddio_q),
        .vdda(vdd),
        .vccd(vdd1v8),
        .vswitch(vdd),
        .vcchib(vdd1v8),
        .vssa(vss),
        .vssd(vss),
        .vssio_q(vssio_q),
        .vssio(vss),
	.pad(adc_high),
	.pad_a_noesd_h(),   // Direct pad connection
	.pad_a_esd_0_h(),   // Pad connection through 150 ohms
	.pad_a_esd_1_h(),   // Pad connection through 150 ohms
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.in(),		    // Signal from pad to core
	.in_h(),
	.tie_hi_esd(),
	.tie_lo_esd()
    );

    s8iom0_gpiov2_pad adc_low_pad (
	.out(vss),		// Signal from core to pad
	.oe_n(vdd1v8),		// Output enable (sense inverted)
	.hld_h_n(vdd),		// Hold
	.enable_h(porb_h),	// Enable
	.enable_inp_h(loopb6),	// Enable input buffer
	.enable_vdda_h(porb_h),	// 
	.enable_vswitch_h(vss),	// 
	.enable_vddio(vdd1v8),	//
	.inp_dis(vdd1v8),	// Disable input buffer
	.ib_mode_sel(vss),	//
	.vtrip_sel(vss),	//
	.slow(vss),		//
	.hld_ovr(vss),		//
	.analog_en(vdd1v8),	//
	.analog_sel(vss),	//
	.analog_pol(vss),	//
	.dm({vss, vss, vss}),			// (3 bits) Mode control
	.vddio(vdd),		
        .vddio_q(vddio_q),
        .vdda(vdd),
        .vccd(vdd1v8),
        .vswitch(vdd),
        .vcchib(vdd1v8),
        .vssa(vss),
        .vssd(vss),
        .vssio_q(vssio_q),
        .vssio(vss),
	.pad(adc_low),
	.pad_a_noesd_h(),   // Direct pad connection
	.pad_a_esd_0_h(),   // Pad connection through 150 ohms
	.pad_a_esd_1_h(),   // Pad connection through 150 ohms
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.in(),		    // Signal from pad to core
	.in_h(),
	.tie_hi_esd(),
	.tie_lo_esd()
    );

    s8iom0_gpiov2_pad comp_inn_pad (
	.out(vss),		// Signal from core to pad
	.oe_n(vdd1v8),		// Output enable (sense inverted)
	.hld_h_n(vdd),		// Hold
	.enable_h(porb_h),	// Enable
	.enable_inp_h(loopb7),	// Enable input buffer
	.enable_vdda_h(porb_h),	// 
	.enable_vswitch_h(vss),	// 
	.enable_vddio(vdd1v8),	//
	.inp_dis(vdd1v8),	// Disable input buffer
	.ib_mode_sel(vss),	//
	.vtrip_sel(vss),	//
	.slow(vss),		//
	.hld_ovr(vss),		//
	.analog_en(vdd1v8),	//
	.analog_sel(vss),	//
	.analog_pol(vss),	//
	.dm({vss, vss, vss}),			// (3 bits) Mode control
	.vddio(vdd),		
        .vddio_q(vddio_q),
        .vdda(vdd),
        .vccd(vdd1v8),
        .vswitch(vdd),
        .vcchib(vdd1v8),
        .vssa(vss),
        .vssd(vss),
        .vssio_q(vssio_q),
        .vssio(vss),
	.pad(comp_inn),
	.pad_a_noesd_h(),   // Direct pad connection
	.pad_a_esd_0_h(),   // Pad connection through 150 ohms
	.pad_a_esd_1_h(),   // Pad connection through 150 ohms
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.in(),		    // Signal from pad to core
	.in_h(),
	.tie_hi_esd(),
	.tie_lo_esd()
    );

    s8iom0_gpiov2_pad comp_inp_pad (
	.out(vss),		// Signal from core to pad
	.oe_n(vdd1v8),		// Output enable (sense inverted)
	.hld_h_n(vdd),		// Hold
	.enable_h(porb_h),	// Enable
	.enable_inp_h(loopb8),	// Enable input buffer
	.enable_vdda_h(porb_h),	// 
	.enable_vswitch_h(vss),	// 
	.enable_vddio(vdd1v8),	//
	.inp_dis(vdd1v8),	// Disable input buffer
	.ib_mode_sel(vss),	//
	.vtrip_sel(vss),	//
	.slow(vss),		//
	.hld_ovr(vss),		//
	.analog_en(vdd1v8),	//
	.analog_sel(vdd1v8),	//
	.analog_pol(vss),	//
	.dm({vss, vss, vss}),			// (3 bits) Mode control
	.vddio(vdd),		
        .vddio_q(vddio_q),
        .vdda(vdd),
        .vccd(vdd1v8),
        .vswitch(vdd),
        .vcchib(vdd1v8),
        .vssa(vss),
        .vssd(vss),
        .vssio_q(vssio_q),
        .vssio(vss),
	.pad(comp_inp),
	.pad_a_noesd_h(),   // Direct pad connection
	.pad_a_esd_0_h(),   // Pad connection through 150 ohms
	.pad_a_esd_1_h(),   // Pad connection through 150 ohms
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.in(),		    // Signal from pad to core
	.in_h(),
	.tie_hi_esd(),
	.tie_lo_esd()
    );

    // NOTE:  The analog_out pad from the raven chip has been replaced by
    // the digital reset input RSTB on striVe due to the lack of an on-board
    // power-on-reset circuit.  The XRES pad is used for providing a glitch-
    // free reset.

    s8iom0s8_top_xres4v2 RSTB_pad (
	.pad(RSTB),

	.tie_weak_hi_h(xresloop),   // Loop-back connection to pad through pad_a_esd_h
	.tie_hi_esd(),
	.tie_lo_esd(),
	.pad_a_esd_h(xresloop),
	.xres_h_n(porb_h),
	.disable_pullup_h(vss),	    // 0 = enable pull-up on reset pad
	.enable_h(vdd),		    // Power-on-reset to the power-on-reset input??
	.en_vddio_sig_h(vss),	    // No idea.
	.inp_sel_h(vss),	    // 1 = use filt_in_h else filter the pad input
	.filt_in_h(vss),	    // Alternate input for glitch filter
	.pullup_h(vss),		    // Pullup connection for alternate filter input
	.enable_vddio(vdd1v8),
	.vssio(vss),
	.vddio(vdd),
	.vddio_q(vddio_q),
	.vssio_q(vssio_q),
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.vssd(vss),
	.vssa(vss),
	.vswitch(vdd),
	.vdda(vdd),
	.vccd(vdd1v8),
	.vcchib(vdd1v8)
    );

    s8iom0_gpiov2_pad irq_pad (
	.out(vss),		// Signal from core to pad
	.oe_n(vdd1v8),		// Output enable (sense inverted)
	.hld_h_n(vdd),		// Hold
	.enable_h(porb_h),	// Enable
	.enable_inp_h(loopb10),	// Enable input buffer
	.enable_vdda_h(porb_h),	// 
	.enable_vswitch_h(vss),	// 
	.enable_vddio(vdd1v8),	//
	.inp_dis(por),		// Disable input buffer
	.ib_mode_sel(vss),	//
	.vtrip_sel(vss),	//
	.slow(vss),		//
	.hld_ovr(vss),		//
	.analog_en(vss),	//
	.analog_sel(vss),	//
	.analog_pol(vss),	//
	.dm({vss, vss, vdd1v8}),	// (3 bits) Mode control
	.vddio(vdd),		
        .vddio_q(vddio_q),
        .vdda(vdd),
        .vccd(vdd1v8),
        .vswitch(vdd),
        .vcchib(vdd1v8),
        .vssa(vss),
        .vssd(vss),
        .vssio_q(vssio_q),
        .vssio(vss),
	.pad(irq),
	.pad_a_noesd_h(),   // Direct pad connection
	.pad_a_esd_0_h(),   // Pad connection through 150 ohms
	.pad_a_esd_1_h(),   // Pad connection through 150 ohms
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.in(irq_pin_core),		    // Signal from pad to core
	.in_h(),
	.tie_hi_esd(),
	.tie_lo_esd(loopb10)
    );

    s8iom0_gpiov2_pad SDO_pad (
	.out(SDO_core),		// Signal from core to pad
	.oe_n(SDO_enb),		// Output enable (sense inverted)
	.hld_h_n(vdd),		// Hold
	.enable_h(porb_h),	// Enable
	.enable_inp_h(loopb11),	// Enable input buffer
	.enable_vdda_h(porb_h),	// 
	.enable_vswitch_h(vss),	// 
	.enable_vddio(vdd1v8),	//
	.inp_dis(vdd1v8),	// Disable input buffer
	.ib_mode_sel(vss),	//
	.vtrip_sel(vss),	//
	.slow(vss),		//
	.hld_ovr(vss),		//
	.analog_en(vss),	//
	.analog_sel(vss),	//
	.analog_pol(vss),	//
	.dm({vdd1v8, vdd1v8, vss}),	// (3 bits) Mode control
	.vddio(vdd),		
        .vddio_q(vddio_q),
        .vdda(vdd),
        .vccd(vdd1v8),
        .vswitch(vdd),
        .vcchib(vdd1v8),
        .vssa(vss),
        .vssd(vss),
        .vssio_q(vssio_q),
        .vssio(vss),
	.pad(SDO),
	.pad_a_noesd_h(),   // Direct pad connection
	.pad_a_esd_0_h(),   // Pad connection through 150 ohms
	.pad_a_esd_1_h(),   // Pad connection through 150 ohms
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.in(),		    // Signal from pad to core
	.in_h(),
	.tie_hi_esd(),
	.tie_lo_esd(loopb11)
    );

    s8iom0_gpiov2_pad SDI_pad (
	.out(vss),		// Signal from core to pad
	.oe_n(vdd1v8),		// Output enable (sense inverted)
	.hld_h_n(vdd),		// Hold
	.enable_h(porb_h),	// Enable
	.enable_inp_h(loopb12),	// Enable input buffer
	.enable_vdda_h(porb_h),	// 
	.enable_vswitch_h(vss),	// 
	.enable_vddio(vdd1v8),	//
	.inp_dis(por),	// Disable input buffer
	.ib_mode_sel(vss),	//
	.vtrip_sel(vss),	//
	.slow(vss),		//
	.hld_ovr(vss),		//
	.analog_en(vss),	//
	.analog_sel(vss),	//
	.analog_pol(vss),	//
	.dm({vss, vss, vdd1v8}),	// (3 bits) Mode control
	.vddio(vdd),		
        .vddio_q(vddio_q),
        .vdda(vdd),
        .vccd(vdd1v8),
        .vswitch(vdd),
        .vcchib(vdd1v8),
        .vssa(vss),
        .vssd(vss),
        .vssio_q(vssio_q),
        .vssio(vss),
	.pad(SDI),
	.pad_a_noesd_h(),   // Direct pad connection
	.pad_a_esd_0_h(),   // Pad connection through 150 ohms
	.pad_a_esd_1_h(),   // Pad connection through 150 ohms
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.in(SDI_core),		    // Signal from pad to core
	.in_h(SDI_core_h),
	.tie_hi_esd(),
	.tie_lo_esd()
    );

    s8iom0_gpiov2_pad CSB_pad (
	.out(vss),		// Signal from core to pad
	.oe_n(vdd1v8),		// Output enable (sense inverted)
	.hld_h_n(vdd),		// Hold
	.enable_h(porb_h),	// Enable
	.enable_inp_h(loopb13),	// Enable input buffer
	.enable_vdda_h(porb_h),	// 
	.enable_vswitch_h(vss),	// 
	.enable_vddio(vdd1v8),	//
	.inp_dis(por),	// Disable input buffer
	.ib_mode_sel(vss),	//
	.vtrip_sel(vss),	//
	.slow(vss),		//
	.hld_ovr(vss),		//
	.analog_en(vss),	//
	.analog_sel(vss),	//
	.analog_pol(vss),	//
	.dm({vss, vss, vdd1v8}),	// (3 bits) Mode control
	.vddio(vdd),		
        .vddio_q(vddio_q),
        .vdda(vdd),
        .vccd(vdd1v8),
        .vswitch(vdd),
        .vcchib(vdd1v8),
        .vssa(vss),
        .vssd(vss),
        .vssio_q(vssio_q),
        .vssio(vss),
	.pad(CSB),
	.pad_a_noesd_h(),   // Direct pad connection
	.pad_a_esd_0_h(),   // Pad connection through 150 ohms
	.pad_a_esd_1_h(),   // Pad connection through 150 ohms
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.in(CSB_core),		    // Signal from pad to core
	.in_h(CSB_core_h),
	.tie_hi_esd(),
	.tie_lo_esd(loopb13)
    );

    s8iom0_gpiov2_pad SCK_pad (
	.out(vss),		// Signal from core to pad
	.oe_n(vdd1v8),		// Output enable (sense inverted)
	.hld_h_n(vdd),		// Hold
	.enable_h(porb_h),	// Enable
	.enable_inp_h(loopb14),	// Enable input buffer
	.enable_vdda_h(porb_h),	// 
	.enable_vswitch_h(vss),	// 
	.enable_vddio(vdd1v8),	//
	.inp_dis(por),	// Disable input buffer
	.ib_mode_sel(vss),	//
	.vtrip_sel(vss),	//
	.slow(vss),		//
	.hld_ovr(vss),		//
	.analog_en(vss),	//
	.analog_sel(vss),	//
	.analog_pol(vss),	//
	.dm({vss, vss, vdd1v8}),	// (3 bits) Mode control
	.vddio(vdd),		
        .vddio_q(vddio_q),
        .vdda(vdd),
        .vccd(vdd1v8),
        .vswitch(vdd),
        .vcchib(vdd1v8),
        .vssa(vss),
        .vssd(vss),
        .vssio_q(vssio_q),
        .vssio(vss),
	.pad(SCK),
	.pad_a_noesd_h(),   // Direct pad connection
	.pad_a_esd_0_h(),   // Pad connection through 150 ohms
	.pad_a_esd_1_h(),   // Pad connection through 150 ohms
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.in(SCK_core),		    // Signal from pad to core
	.in_h(SCK_core_h),    // Signal in vdda domain (3.3V)
	.tie_hi_esd(),
	.tie_lo_esd(loopb14)
    );

    s8iom0_gpiov2_pad xclk_pad (
	.out(vss),		// Signal from core to pad
	.oe_n(vdd1v8),		// Output enable (sense inverted)
	.hld_h_n(vdd),		// Hold
	.enable_h(porb_h),	// Enable
	.enable_inp_h(loopb15),	// Enable input buffer
	.enable_vdda_h(porb_h),	// 
	.enable_vswitch_h(vss),	// 
	.enable_vddio(vdd1v8),	//
	.inp_dis(por),		// Disable input buffer
	.ib_mode_sel(vss),	//
	.vtrip_sel(vss),	//
	.slow(vss),		//
	.hld_ovr(vss),		//
	.analog_en(vss),	//
	.analog_sel(vss),	//
	.analog_pol(vss),	//
	.dm({vss, vss, vdd1v8}), // (3 bits) Mode control
	.vddio(vdd),		
        .vddio_q(vddio_q),
        .vdda(vdd),
        .vccd(vdd1v8),
        .vswitch(vdd),
        .vcchib(vdd1v8),
        .vssa(vss),
        .vssd(vss),
        .vssio_q(vssio_q),
        .vssio(vss),
	.pad(xclk),
	.pad_a_noesd_h(),   // Direct pad connection
	.pad_a_esd_0_h(),   // Pad connection through 150 ohms
	.pad_a_esd_1_h(),   // Pad connection through 150 ohms
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.in(ext_clk_core),		    // Signal from pad to core
	.in_h(),
	.tie_hi_esd(),
	.tie_lo_esd(loopb15)
    );

    s8iom0_gpiov2_pad flash_csb_pad (
	.out(flash_csb_core),			// Signal from core to pad
	.oe_n(flash_csb_oeb_core),		// Output enable (sense inverted)
	.hld_h_n(vdd),		// Hold
	.enable_h(porb_h),	// Enable
	.enable_inp_h(loopb16),	// Enable input buffer
	.enable_vdda_h(porb_h),	// 
	.enable_vswitch_h(vss),	// 
	.enable_vddio(vdd1v8),	//
	.inp_dis(flash_csb_ieb_core),	// Disable input buffer
	.ib_mode_sel(vss),	//
	.vtrip_sel(vss),	//
	.slow(vss),		//
	.hld_ovr(vss),		//
	.analog_en(vss),	//
	.analog_sel(vss),	//
	.analog_pol(vss),	//
	.dm({vdd1v8, vdd1v8, vss}),	// (3 bits) Mode control
	.vddio(vdd),		
        .vddio_q(vddio_q),
        .vdda(vdd),
        .vccd(vdd1v8),
        .vswitch(vdd),
        .vcchib(vdd1v8),
        .vssa(vss),
        .vssd(vss),
        .vssio_q(vssio_q),
        .vssio(vss),
	.pad(flash_csb),
	.pad_a_noesd_h(),   // Direct pad connection
	.pad_a_esd_0_h(),   // Pad connection through 150 ohms
	.pad_a_esd_1_h(),   // Pad connection through 150 ohms
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.in(),		    // Signal from pad to core
	.in_h(),
	.tie_hi_esd(),
	.tie_lo_esd()
    );

    s8iom0_gpiov2_pad flash_clk_pad (
	.out(flash_clk_core),			// Signal from core to pad
	.oe_n(flash_clk_oeb_core),		// Output enable (sense inverted)
	.hld_h_n(vdd),		// Hold
	.enable_h(porb_h),	// Enable
	.enable_inp_h(loopb17),	// Enable input buffer
	.enable_vdda_h(porb_h),	// 
	.enable_vswitch_h(vss),	// 
	.enable_vddio(vdd1v8),	//
	.inp_dis(flash_clk_ieb_core),	// Disable input buffer
	.ib_mode_sel(vss),	//
	.vtrip_sel(vss),	//
	.slow(vss),		//
	.hld_ovr(vss),		//
	.analog_en(vss),	//
	.analog_sel(vss),	//
	.analog_pol(vss),	//
	.dm({vdd1v8, vdd1v8, vss}),	// (3 bits) Mode control
	.vddio(vdd),		
        .vddio_q(vddio_q),
        .vdda(vdd),
        .vccd(vdd1v8),
        .vswitch(vdd),
        .vcchib(vdd1v8),
        .vssa(vss),
        .vssd(vss),
        .vssio_q(vssio_q),
        .vssio(vss),
	.pad(flash_clk),
	.pad_a_noesd_h(),   // Direct pad connection
	.pad_a_esd_0_h(),   // Pad connection through 150 ohms
	.pad_a_esd_1_h(),   // Pad connection through 150 ohms
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.in(),		    // Signal from pad to core
	.in_h(),
	.tie_hi_esd(),
	.tie_lo_esd()
    );

    s8iom0_gpiov2_pad flash_io0_pad (
	.out(flash_io0_do_core),			// Signal from core to pad
	.oe_n(flash_io0_oeb_core),		// Output enable (sense inverted)
	.hld_h_n(vdd),		// Hold
	.enable_h(porb_h),	// Enable
	.enable_inp_h(loopb18),	// Enable input buffer
	.enable_vdda_h(porb_h),	// 
	.enable_vswitch_h(vss),	// 
	.enable_vddio(vdd1v8),	//
	.inp_dis(flash_io0_ieb_core),		// Disable input buffer
	.ib_mode_sel(vss),	//
	.vtrip_sel(vss),	//
	.slow(vss),		//
	.hld_ovr(vss),		//
	.analog_en(vss),	//
	.analog_sel(vss),	//
	.analog_pol(vss),	//
	.dm({flash_io0_ieb_core, flash_io0_ieb_core, flash_io0_oeb_core}), // (3 bits) Mode control
	.vddio(vdd),		
        .vddio_q(vddio_q),
        .vdda(vdd),
        .vccd(vdd1v8),
        .vswitch(vdd),
        .vcchib(vdd1v8),
        .vssa(vss),
        .vssd(vss),
        .vssio_q(vssio_q),
        .vssio(vss),
	.pad(flash_io0),
	.pad_a_noesd_h(),   // Direct pad connection
	.pad_a_esd_0_h(),   // Pad connection through 150 ohms
	.pad_a_esd_1_h(),   // Pad connection through 150 ohms
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.in(flash_io0_di_core),		    // Signal from pad to core
	.in_h(),
	.tie_hi_esd(),
	.tie_lo_esd(loopb18)
    );

    s8iom0_gpiov2_pad flash_io1_pad (
	.out(flash_io1_do_core),			// Signal from core to pad
	.oe_n(flash_io1_oeb_core),		// Output enable (sense inverted)
	.hld_h_n(vdd),		// Hold
	.enable_h(porb_h),	// Enable
	.enable_inp_h(loopb19),	// Enable input buffer
	.enable_vdda_h(porb_h),	// 
	.enable_vswitch_h(vss),	// 
	.enable_vddio(vdd1v8),	//
	.inp_dis(flash_io1_ieb_core),		// Disable input buffer
	.ib_mode_sel(vss),	//
	.vtrip_sel(vss),	//
	.slow(vss),		//
	.hld_ovr(vss),		//
	.analog_en(vss),	//
	.analog_sel(vss),	//
	.analog_pol(vss),	//
	.dm({flash_io1_ieb_core, flash_io1_ieb_core, flash_io1_oeb_core}), // (3 bits) Mode control
	.vddio(vdd),		
        .vddio_q(vddio_q),
        .vdda(vdd),
        .vccd(vdd1v8),
        .vswitch(vdd),
        .vcchib(vdd1v8),
        .vssa(vss),
        .vssd(vss),
        .vssio_q(vssio_q),
        .vssio(vss),
	.pad(flash_io1),
	.pad_a_noesd_h(),   // Direct pad connection
	.pad_a_esd_0_h(),   // Pad connection through 150 ohms
	.pad_a_esd_1_h(),   // Pad connection through 150 ohms
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.in(flash_io1_di_core),		    // Signal from pad to core
	.in_h(),
	.tie_hi_esd(),
	.tie_lo_esd(loopb19)
    );

    s8iom0_gpiov2_pad flash_io2_pad (
	.out(flash_io2_do_core),			// Signal from core to pad
	.oe_n(flash_io2_oeb_core),		// Output enable (sense inverted)
	.hld_h_n(vdd),		// Hold
	.enable_h(porb_h),	// Enable
	.enable_inp_h(loopb20),	// Enable input buffer
	.enable_vdda_h(porb_h),	// 
	.enable_vswitch_h(vss),	// 
	.enable_vddio(vdd1v8),	//
	.inp_dis(flash_io2_ieb_core),		// Disable input buffer
	.ib_mode_sel(vss),	//
	.vtrip_sel(vss),	//
	.slow(vss),		//
	.hld_ovr(vss),		//
	.analog_en(vss),	//
	.analog_sel(vss),	//
	.analog_pol(vss),	//
	.dm({flash_io2_ieb_core, flash_io2_ieb_core, flash_io2_oeb_core}), // (3 bits) Mode control
	.vddio(vdd),		
        .vddio_q(vddio_q),
        .vdda(vdd),
        .vccd(vdd1v8),
        .vswitch(vdd),
        .vcchib(vdd1v8),
        .vssa(vss),
        .vssd(vss),
        .vssio_q(vssio_q),
        .vssio(vss),
	.pad(flash_io2),
	.pad_a_noesd_h(),   // Direct pad connection
	.pad_a_esd_0_h(),   // Pad connection through 150 ohms
	.pad_a_esd_1_h(),   // Pad connection through 150 ohms
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.in(flash_io2_di_core),		    // Signal from pad to core
	.in_h(),
	.tie_hi_esd(),
	.tie_lo_esd(loopb20)
    );

    s8iom0_gpiov2_pad flash_io3_pad (
	.out(flash_io3_do_core),			// Signal from core to pad
	.oe_n(flash_io3_oeb_core),		// Output enable (sense inverted)
	.hld_h_n(vdd),		// Hold
	.enable_h(porb_h),	// Enable
	.enable_inp_h(loopb21),	// Enable input buffer
	.enable_vdda_h(porb_h),	// 
	.enable_vswitch_h(vss),	// 
	.enable_vddio(vdd1v8),	//
	.inp_dis(flash_io3_ieb_core),		// Disable input buffer
	.ib_mode_sel(vss),	//
	.vtrip_sel(vss),	//
	.slow(vss),		//
	.hld_ovr(vss),		//
	.analog_en(vss),	//
	.analog_sel(vss),	//
	.analog_pol(vss),	//
	.dm({flash_io3_ieb_core, flash_io3_ieb_core, flash_io3_oeb_core}), // (3 bits) Mode control
	.vddio(vdd),		
        .vddio_q(vddio_q),
        .vdda(vdd),
        .vccd(vdd1v8),
        .vswitch(vdd),
        .vcchib(vdd1v8),
        .vssa(vss),
        .vssd(vss),
        .vssio_q(vssio_q),
        .vssio(vss),
	.pad(flash_io3),
	.pad_a_noesd_h(),   // Direct pad connection
	.pad_a_esd_0_h(),   // Pad connection through 150 ohms
	.pad_a_esd_1_h(),   // Pad connection through 150 ohms
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.in(flash_io3_di_core),		    // Signal from pad to core
	.in_h(),
	.tie_hi_esd(),
	.tie_lo_esd(loopb21)
    );

    // Instantiate GPIO overvoltage (I2C) compliant cell
    // (Use this for ser_rx and ser_tx;  no reason other than testing
    // the use of the cell.) (Might be worth adding in the I2C IP from
    // ravenna just to test on a proper I2C channel.)

    s8iom0s8_top_gpio_ovtv2 ser_rx_pad (
	.out(vss),
	.oe_n(vdd1v8),
	.hld_h_n(vdd),
	.enable_h(porb_h),
	.enable_inp_h(loopb22),
	.enable_vdda_h(porb_h),
	.enable_vddio(vdd1v8),
	.enable_vswitch_h(vss),
	.inp_dis(por),
	.vtrip_sel(vss),
	.hys_trim(vdd1v8),
	.slow(vss),
	.slew_ctl({vss, vss}),	// 2 bits
	.hld_ovr(vss),
	.analog_en(vss),
	.analog_sel(vss),
	.analog_pol(vss),
	.dm({vss, vss, vdd1v8}),		// 3 bits
	.ib_mode_sel({vss, vss}),	// 2 bits
	.vinref(vdd1v8),
	.vddio(vdd),
	.vddio_q(vddio_q),
	.vdda(vdd),
	.vccd(vdd1v8),
	.vswitch(vdd),
	.vcchib(vdd1v8),
	.vssa(vss),
	.vssd(vss),
	.vssio_q(vssio_q),
	.vssio(vss),
	.pad(ser_rx),
	.pad_a_noesd_h(),
	.pad_a_esd_0_h(),
	.pad_a_esd_1_h(),
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.in(ser_rx_core),
	.in_h(),
	.tie_hi_esd(),
	.tie_lo_esd()
    );

    s8iom0s8_top_gpio_ovtv2 ser_tx_pad (
	.out(ser_tx_core),
	.oe_n(vss),
	.hld_h_n(vdd),
	.enable_h(porb_h),
	.enable_inp_h(loopb23),
	.enable_vdda_h(porb_h),
	.enable_vddio(vdd1v8),
	.enable_vswitch_h(vss),
	.inp_dis(vdd1v8),
	.vtrip_sel(vss),
	.hys_trim(vdd1v8),
	.slow(vss),
	.slew_ctl({vss, vss}),	// 2 bits
	.hld_ovr(vss),
	.analog_en(vss),
	.analog_sel(vss),
	.analog_pol(vss),
	.dm({vdd1v8, vdd1v8, vss}),		// 3 bits
	.ib_mode_sel({vss, vss}),	// 2 bits
	.vinref(vdd1v8),
	.vddio(vdd),
	.vddio_q(vddio_q),
	.vdda(vdd),
	.vccd(vdd1v8),
	.vswitch(vdd),
	.vcchib(vdd1v8),
	.vssa(vss),
	.vssd(vss),
	.vssio_q(vssio_q),
	.vssio(vss),
	.pad(ser_tx),
	.pad_a_noesd_h(),
	.pad_a_esd_0_h(),
	.pad_a_esd_1_h(),
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.in(),
	.in_h(),
	.tie_hi_esd(),
	.tie_lo_esd()
    );

    // Corner cells (These are overlay cells;  it is not clear what is normally
    // supposed to go under them.)
    s8iom0_corner_pad corner [3:0] (
	.vssio(vss),
	.vddio(vdd),
	.vddio_q(vddio_q),
	.vssio_q(vssio_q),
	.amuxbus_a(analog_a),
	.amuxbus_b(analog_b),
	.vssd(vss),
	.vssa(vss),
	.vswitch(vdd),
	.vdda(vdd),
	.vccd(vdd1v8),
	.vcchib(vdd1v8)
    );

    // SoC core

    wire [9:0]  adc0_data_core;
    wire [1:0]  adc0_inputsrc_core;
    wire [9:0]  adc1_data_core;
    wire [1:0]  adc1_inputsrc_core;
    wire [9:0]  dac_value_core;
    wire [1:0]  comp_ninputsrc_core;
    wire [1:0]  comp_pinputsrc_core;
    wire [7:0]  spi_ro_config_core;

	wire striVe_clk, striVe_rstn;

    striVe_clkrst clkrst(
`ifdef LVS
	.vdd1v8(vdd1v8),
	.vss(vss),
`endif		
	.ext_clk_sel(ext_clk_sel_core),
	.ext_clk(ext_clk_core),
	.pll_clk(pll_clk_core),
	.reset(por), 
	.ext_reset(ext_reset_core),
	.clk(striVe_clk),
	.resetn(striVe_rstn)
);

    striVe_soc core (
`ifdef LVS
	.vdd1v8(vdd1v8),
	.vss(vss),
`endif
    
	.pll_clk(pll_clk_core),
	.ext_clk(ext_clk_core),
	.ext_clk_sel(ext_clk_sel_core),
	/*
    .ext_reset(ext_reset_core),
	.reset(por),
    */
    .clk(striVe_clk),
    .resetn(striVe_rstn),
	.gpio_out_pad(gpio_out_core),
	.gpio_in_pad(gpio_in_core),
	.gpio_mode0_pad(gpio_mode0_core),
	.gpio_mode1_pad(gpio_mode1_core),
	.gpio_outenb_pad(gpio_outenb_core),
	.gpio_inenb_pad(gpio_inenb_core),
	.adc0_ena(adc0_ena_core),
	.adc0_convert(adc0_convert_core),
	.adc0_data(adc0_data_core),
	.adc0_done(adc0_done_core),
	.adc0_clk(adc0_clk_core),
	.adc0_inputsrc(adc0_inputsrc_core),
	.adc1_ena(adc1_ena_core),
	.adc1_convert(adc1_convert_core),
	.adc1_clk(adc1_clk_core),
	.adc1_inputsrc(adc1_inputsrc_core),
	.adc1_data(adc1_data_core),
	.adc1_done(adc1_done_core),
	.dac_ena(dac_ena_core),
	.dac_value(dac_value_core),
	.analog_out_sel(analog_out_sel_core),
	.opamp_ena(opamp_ena_core),
	.opamp_bias_ena(opamp_bias_ena_core),
	.bg_ena(bg_ena_core),
	.comp_ena(comp_ena_core),
	.comp_ninputsrc(comp_ninputsrc_core),
	.comp_pinputsrc(comp_pinputsrc_core),
	.rcosc_ena(rcosc_ena_core),
	.overtemp_ena(overtemp_ena_core),
	.overtemp(overtemp_core),
	.rcosc_in(rcosc_in_core),
	.xtal_in(xtal_in_core),
	.comp_in(comp_in_core),
	.spi_sck(SCK_core),
	.spi_ro_config(spi_ro_config_core),
	.spi_ro_xtal_ena(spi_ro_xtal_ena_core),
	.spi_ro_reg_ena(spi_ro_reg_ena_core),
	.spi_ro_pll_dco_ena(spi_ro_pll_dco_ena_core),
	.spi_ro_pll_div(spi_ro_pll_div_core),
	.spi_ro_pll_sel(spi_ro_pll_sel_core),
	.spi_ro_pll_trim(spi_ro_pll_trim_core),
	.spi_ro_mfgr_id(spi_ro_mfgr_id_core),
	.spi_ro_prod_id(spi_ro_prod_id_core),
	.spi_ro_mask_rev(spi_ro_mask_rev_core),
	.ser_tx(ser_tx_core),
	.ser_rx(ser_rx_core),
	.irq_pin(irq_pin_core),
	.irq_spi(irq_spi_core),
	.trap(trap_core),
	.flash_csb(flash_csb_core),
	.flash_clk(flash_clk_core),
	.flash_csb_oeb(flash_csb_oeb_core),
	.flash_clk_oeb(flash_clk_oeb_core),
	.flash_io0_oeb(flash_io0_oeb_core),
	.flash_io1_oeb(flash_io1_oeb_core),
	.flash_io2_oeb(flash_io2_oeb_core),
	.flash_io3_oeb(flash_io3_oeb_core),
	.flash_csb_ieb(flash_csb_ieb_core),
	.flash_clk_ieb(flash_clk_ieb_core),
	.flash_io0_ieb(flash_io0_ieb_core),
	.flash_io1_ieb(flash_io1_ieb_core),
	.flash_io2_ieb(flash_io2_ieb_core),
	.flash_io3_ieb(flash_io3_ieb_core),
	.flash_io0_do(flash_io0_do_core),
	.flash_io1_do(flash_io1_do_core),
	.flash_io2_do(flash_io2_do_core),
	.flash_io3_do(flash_io3_do_core),
	.flash_io0_di(flash_io0_di_core),
	.flash_io1_di(flash_io1_di_core),
	.flash_io2_di(flash_io2_di_core),
	.flash_io3_di(flash_io3_di_core)
    );

    // For the mask revision input, use an array of digital constant logic cells

    wire [3:0] mask_rev;

    sky130_fd_sc_hd_conb_1 mask_rev_value [3:0] (
`ifdef LVS
	.vpwr(vdd1v8),
	.vgnd(vss),
`endif
	.HI(),
	.LO(mask_rev)
    );

    // Housekeeping SPI at 1.8V.

    striVe_spi housekeeping (
`ifdef LVS
	.vdd(vdd1v8),
	.vss(vss),
`endif
	.RSTB(porb_l),
	.SCK(SCK_core),
	.SDI(SDI_core),
	.CSB(CSB_core),
	.SDO(SDO_core),
	.sdo_enb(SDO_enb),
        .xtal_ena(spi_ro_xtal_ena_core),
	.reg_ena(spi_ro_reg_ena_core),
	.pll_dco_ena(spi_ro_pll_dco_ena_core),
	.pll_sel(spi_ro_pll_sel_core),
	.pll_div(spi_ro_pll_div_core),
        .pll_trim(spi_ro_pll_trim_core),
	.pll_bypass(ext_clk_sel_core),
	.irq(irq_spi_core),
	.RST(por),
	.reset(ext_reset_core),
	.trap(trap_core),
        .mfgr_id(spi_ro_mfgr_id_core),
	.prod_id(spi_ro_prod_id_core),
	.mask_rev_in(mask_rev),
	.mask_rev(spi_ro_mask_rev_core)
    );

    lvlshiftdown porb_level_shift (
`ifdef LVS
	.vpwr(vdd1v8),
	.vpb(vdd1v8),
	.vnb(vss),
	.vgnd(vss),
`endif
	.A(porb_h),
	.X(porb_l)
    );

    // On-board experimental digital PLL
    // Use xi_core, assumed to be a CMOS digital clock signal.  xo_core
    // is used as an output and set from pll_clk16.

    digital_pll pll (
`ifdef LVS
	.vdd(vdd1v8),
	.vss(vss),
`endif
	.reset(por),
	.extclk_sel(ext_clk_sel_core),
	.osc(xi_core),
	.clockc(pll_clk_core),
	.clockp({pll_clk_core0, pll_clk_core90}),
	.clockd({pll_clk2, pll_clk4, pll_clk8, pll_clk16}),
	.div(spi_ro_pll_div_core),
	.sel(spi_ro_pll_sel_core),
	.dco(spi_ro_pll_dco_ena_core),
	.ext_trim(spi_ro_pll_trim_core)
    );
	
endmodule
