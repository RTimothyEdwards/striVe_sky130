/* Generated by Yosys 0.8 (git sha1 5706e90, gcc 6.3.1 -fPIC -Os) */

module striVe_clkrst(ext_clk_sel, ext_clk, pll_clk, reset, ext_reset, clk, resetn);
  wire _00_;
  wire _01_;
  wire _02_;
  wire _03_;
  wire _04_;
  wire _05_;
  wire _06_;
  wire _07_;
  wire _08_;
  wire _09_;
  wire _10_;
  wire _11_;
  wire _12_;
  wire _13_;
  wire _14_;
  wire _15_;
  output clk;
  input ext_clk;
  input ext_clk_sel;
  input ext_reset;
  input pll_clk;
  input reset;
  wire [2:0] reset_delay;
  output resetn;
  sky130_fd_sc_hd_inv_4 _16_ (
    .A(_00_),
    .Y(_01_)
  );
  sky130_fd_sc_hd_inv_4 _17_ (
    .A(_10_),
    .Y(_03_)
  );
  sky130_fd_sc_hd_nor2_4 _18_ (
    .A(_05_),
    .B(_06_),
    .Y(_07_)
  );
  sky130_fd_sc_hd_and2_4 _19_ (
    .A(_09_),
    .B(_10_),
    .X(_04_)
  );
  sky130_fd_sc_hd_a21o_4 _20_ (
    .A1(_08_),
    .A2(_03_),
    .B1(_04_),
    .X(_11_)
  );
  sky130_fd_sc_hd_inv_4 _21_ (
    .A(_00_),
    .Y(_12_)
  );
  sky130_fd_sc_hd_inv_4 _22_ (
    .A(_00_),
    .Y(_02_)
  );
  sky130_fd_sc_hd_dfstp_4 _23_ (
    .CLK(clk),
    .D(reset_delay[1]),
    .Q(reset_delay[0]),
    .SETB(_13_)
  );
  sky130_fd_sc_hd_dfstp_4 _24_ (
    .CLK(clk),
    .D(reset_delay[2]),
    .Q(reset_delay[1]),
    .SETB(_14_)
  );
  sky130_fd_sc_hd_dfstp_4 _25_ (
    .CLK(clk),
    .D(1'b0),
    .Q(reset_delay[2]),
    .SETB(_15_)
  );
  assign _00_ = reset;
  assign _15_ = _01_;
  assign _05_ = ext_reset;
  assign _06_ = reset_delay[0];
  assign resetn = _07_;
  assign _08_ = pll_clk;
  assign _09_ = ext_clk;
  assign _10_ = ext_clk_sel;
  assign clk = _11_;
  assign _13_ = _12_;
  assign _14_ = _02_;
endmodule