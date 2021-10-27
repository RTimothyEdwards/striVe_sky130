// Digital PLL (ring oscillator + controller)
// Technically this is a frequency locked loop, not a phase locked loop.

`include "digital_pll_controller.v"
`include "ring_osc2x13.v"

module digital_pll(reset, extclk_sel, osc, clockc, clockp, clockd, div, sel, dco, ext_trim);

    input	reset;		// Sense positive reset
    input	extclk_sel;	// External clock select (acts as 2nd reset)
    input	osc;		// Input oscillator to match
    input [4:0]	div;		// PLL feedback division ratio
    input [2:0] sel;		// Core clock select
    input 	dco;		// Run in DCO mode
    input [25:0] ext_trim;	// External trim for DCO mode

    output       clockc;	// Selected core clock output
    output [1:0] clockp;	// Two 90 degree clock phases
    output [3:0] clockd;	// Divided clock (2, 4, 8, 16)

    wire [25:0] itrim;		// Internally generated trim bits
    wire [25:0] otrim;		// Trim bits applied to the ring oscillator
    wire [3:0]	nint;		// Internal divided down clocks
    wire	resetb;		// Internal positivie sense reset
    wire	creset;		// Controller reset
    wire	ireset;		// Internal reset (external reset OR extclk_sel)

    assign ireset = reset | extclk_sel;

    // In DCO mode: Hold controller in reset and apply external trim value
    assign itrim = (dco == 1'b0) ? otrim : ext_trim;
    assign creset = (dco == 1'b0) ? ireset : 1'b1;

    ring_osc2x13 ringosc (
	.reset(ireset),
	.trim(itrim),
	.clockp(clockp)
    );

    digital_pll_controller pll_control (
	.reset(creset),
	.clock(clockp[0]),
	.osc(osc),
	.div(div),
	.trim(otrim)
    );

    // Select core clock output
    assign clockc = (sel == 3'b000) ? clockp[0] :
		    (sel == 3'b001) ? clockd[0] :
		    (sel == 3'b010) ? clockd[1] :
		    (sel == 3'b011) ? clockd[2] :
		    		      clockd[3];

    // Derive negative-sense reset from the input positive-sense reset

    sky130_fd_sc_hd_inv_4 irb (
	.A(reset),
	.Y(resetb)
    );

    // Create divided down clocks.  The inverted output only comes
    // with digital standard cells with inverted resets, so the
    // reset has to be inverted as well.
 
    sky130_fd_sc_hd_dfrbp_1 idiv2 (
	.CLK(clockp[1]),
	.D(clockd[0]),
	.Q(nint[0]),
	.QN(clockd[0]),
	.RESETB(resetb)
    );

    sky130_fd_sc_hd_dfrbp_1 idiv4 (
	.CLK(clockd[0]),
	.D(clockd[1]),
	.Q(nint[1]),
	.QN(clockd[1]),
	.RESETB(resetb)
    );

    sky130_fd_sc_hd_dfrbp_1 idiv8 (
	.CLK(clockd[1]),
	.D(clockd[2]),
	.Q(nint[2]),
	.QN(clockd[2]),
	.RESETB(resetb)
    );

    sky130_fd_sc_hd_dfrbp_1 idiv16 (
	.CLK(clockd[2]),
	.D(clockd[3]),
	.Q(nint[3]),
	.QN(clockd[3]),
	.RESETB(resetb)
    );
endmodule
