//Spook-128su512v1 
// William Diehl
// Virginia Tech
// 06-16-2019

module Datapath(
clk,
rst,

// Input
bdi,
bdi_size,
key,

// Output 
bdo,
msg_auth,

// Controller

start_perm,
start_tls,
perm_done,
tls_done,
inv,
en_bdi,
clr_bdi,
en_pad,
en_key,
en_ext_state,
lock_tag,
lock_message,
bdo_last_word,
reg_0_sel,
reg_1_sel,
reg_2_sel,
reg_3_sel,
reg_2_xor_sel,
tweak_sel,
ld_ctr,
sel_tag
);

input start_tls, start_perm, clk, rst, inv, en_ext_state, lock_tag, lock_message, bdo_last_word;
input clr_bdi, en_bdi, en_pad, en_key;
input reg_2_sel, reg_3_sel, tweak_sel, sel_tag;
input [1:0] reg_0_sel, reg_1_sel, reg_2_xor_sel;
input [2:0] ld_ctr;
input [2:0] bdi_size;
input [31:0] bdi, key;

output perm_done, tls_done, msg_auth;
output [31:0] bdo;

wire en_bdi_0, en_bdi_1, en_bdi_2, en_bdi_3, en_bdi_4, en_bdi_5, en_bdi_6, en_bdi_7; 
wire steps_finished, perm_rounds_finished, tls_finished;
wire en_perm_0, en_perm_1, en_perm_2, en_perm_3, en_perm_0_dec, en_perm_1_dec, en_perm_2_dec, en_perm_3_dec;
wire en_state_0, en_state_1, en_state_2, en_state_3, en_state_mask;
wire [1:0] next_round_ctr, round_ctr, state_0_sel;
wire [2:0] next_step_ctr, step_ctr, bdi_size_reg;
wire [3:0] next_lfsr_reg, lfsr_reg, lfsr_start, next_lfsr, tls_round_finished;
wire [31:0] w, x, y, z, u, v, a, b, c, d;
wire [31:0] next_bdi_reg_0, next_bdi_reg_1, next_bdi_reg_2, next_bdi_reg_3, next_bdi_reg_4, next_bdi_reg_5, next_bdi_reg_6, next_bdi_reg_7;
wire [31:0] next_bdi_reg, next_bdi_padded_reg;
wire [31:0] bdi_reg_0, bdi_reg_1, bdi_reg_2, bdi_reg_3, bdi_reg_4, bdi_reg_5, bdi_reg_6, bdi_reg_7;
wire [31:0] tag, bdo_word;
wire [31:0] bdo_word_mask, bdo_word_mask_last;
wire [127:0] next_state_reg0, state_reg0, next_state_reg1, state_reg1, next_state_reg2, state_reg2, next_state_reg3, state_reg3;
wire [127:0] next_state_int_reg0;
wire [127:0] next_state_perm_reg0, next_state_perm_reg1, next_state_perm_reg2, next_state_perm_reg3; 
wire [127:0] next_state_ext_reg0, next_state_ext_reg1, next_state_ext_reg2, next_state_ext_reg3, reg_2_xored;
wire [127:0] sbox_in, sbox_in_perm, sbox_out, lbox_in, lbox_out, rc_out, rc_out0, rc_out1, rc_out2, rc_out3;
wire [127:0] diff_out0, diff_out1, diff_out2, diff_out3;   
wire [127:0] tls_step_out, tk0, stk0, next_state_tls_reg0, next_t_reg_enc, next_t_reg_dec, next_t_reg, t_reg, tk;
wire [127:0] inv_sbox_out, inv_lbox_out, lbox_in_perm, rc_tls_enc, rc_tls_dec;
wire [127:0] lock_tag_reg;
wire [127:0] P, N, t;
wire [127:0] next_key_reg, key_reg;
wire [255:0] bdi_reg;
wire [255:0] C, C_padded; 
wire [255:0] lock_message_reg, state_mask, next_state_mask, next_state_mask_clr;

reg en_round, en_step, en_diff, en_lfsr, en_state, perm_done, tls_done, en_tls;
reg [1:0] dinsel;
reg [3:0] next_fsm_state, fsm_state;

localparam MAX_STEPS = 3'b101,
		   MAX_ROUNDS = 2'b11,
		   RND_FINISHED_ENC = 4'b0111,
           RND_FINISHED_DEC = 4'b1000;

// bdi input registers

assign next_bdi_reg = (en_pad == 0) ? bdi : next_bdi_padded_reg;

assign next_bdi_reg_0 = (clr_bdi == 1) ? 0 : next_bdi_reg; 
assign next_bdi_reg_1 = (clr_bdi == 1) ? 0 : next_bdi_reg; 
assign next_bdi_reg_2 = (clr_bdi == 1) ? 0 : next_bdi_reg; 
assign next_bdi_reg_3 = (clr_bdi == 1) ? 0 : next_bdi_reg; 
assign next_bdi_reg_4 = (clr_bdi == 1) ? 0 : next_bdi_reg; 
assign next_bdi_reg_5 = (clr_bdi == 1) ? 0 : next_bdi_reg; 
assign next_bdi_reg_6 = (clr_bdi == 1) ? 0 : next_bdi_reg; 
assign next_bdi_reg_7 = (clr_bdi == 1) ? 0 : next_bdi_reg; 

assign en_bdi_0 = (clr_bdi == 1 || en_bdi == 1 && ld_ctr == 0) ? 1 : 0;
assign en_bdi_1 = (clr_bdi == 1 || en_bdi == 1 && ld_ctr == 1) ? 1 : 0;
assign en_bdi_2 = (clr_bdi == 1 || en_bdi == 1 && ld_ctr == 2) ? 1 : 0;
assign en_bdi_3 = (clr_bdi == 1 || en_bdi == 1 && ld_ctr == 3) ? 1 : 0;
assign en_bdi_4 = (clr_bdi == 1 || en_bdi == 1 && ld_ctr == 4) ? 1 : 0;
assign en_bdi_5 = (clr_bdi == 1 || en_bdi == 1 && ld_ctr == 5) ? 1 : 0;
assign en_bdi_6 = (clr_bdi == 1 || en_bdi == 1 && ld_ctr == 6) ? 1 : 0;
assign en_bdi_7 = (clr_bdi == 1 || en_bdi == 1 && ld_ctr == 7) ? 1 : 0;

d_ff #(32) bdi_rg_0(
.clk(clk),
.rst(rst),
.en(en_bdi_0), 
.d(next_bdi_reg_0),
.q(bdi_reg_0)
);

d_ff #(32) bdi_rg_1(
.clk(clk),
.rst(rst),
.en(en_bdi_1), 
.d(next_bdi_reg_1),
.q(bdi_reg_1)
);

d_ff #(32) bdi_rg_2(
.clk(clk),
.rst(rst),
.en(en_bdi_2), 
.d(next_bdi_reg_2),
.q(bdi_reg_2)
);

d_ff #(32) bdi_rg_3(
.clk(clk),
.rst(rst),
.en(en_bdi_3), 
.d(next_bdi_reg_3),
.q(bdi_reg_3)
);

d_ff #(32) bdi_rg_4(
.clk(clk),
.rst(rst),
.en(en_bdi_4), 
.d(next_bdi_reg_4),
.q(bdi_reg_4)
);

d_ff #(32) bdi_rg_5(
.clk(clk),
.rst(rst),
.en(en_bdi_5), 
.d(next_bdi_reg_5),
.q(bdi_reg_5)
);

d_ff #(32) bdi_rg_6(
.clk(clk),
.rst(rst),
.en(en_bdi_6), 
.d(next_bdi_reg_6),
.q(bdi_reg_6)
);

d_ff #(32) bdi_rg_7(
.clk(clk),
.rst(rst),
.en(en_bdi_7), 
.d(next_bdi_reg_7),
.q(bdi_reg_7)
);

assign bdi_reg = {bdi_reg_0, bdi_reg_1, bdi_reg_2, bdi_reg_3, bdi_reg_4, bdi_reg_5, bdi_reg_6, bdi_reg_7};
assign P = 0;
assign N = bdi_reg[255:128]; // also functions as exp_tag

// bdi padding

assign next_bdi_padded_reg = (bdi_size == 0) ? 0 : 32'bz;
assign next_bdi_padded_reg = (bdi_size == 1) ? {bdi[31:24], 8'b0000_0001, {{16}{1'b0}}} : 32'bz;
assign next_bdi_padded_reg = (bdi_size == 2) ? {bdi[31:16], 8'b0000_0001, {{8}{1'b0}}} : 32'bz;
assign next_bdi_padded_reg = (bdi_size == 3) ? {bdi[31:8], 8'b0000_0001} : 32'bz;
assign next_bdi_padded_reg = (bdi_size == 4) ? bdi : 32'bz;

assign C_padded = {bdi_reg[255:128] ^ state_reg0, bdi_reg[127:0] ^ state_reg1};  

assign next_state_mask_clr = (clr_bdi == 1) ? {{256}{1'b1}} : next_state_mask;
assign next_state_mask = (bdi_size == 3'b000) ? state_mask : 256'bz;
assign next_state_mask = (bdi_size == 3'b001) ? {{{8}{1'b0}}, state_mask[255:8]} : 256'bz;
assign next_state_mask = (bdi_size == 3'b010) ? {{{16}{1'b0}}, state_mask[255:16]} : 256'bz;
assign next_state_mask = (bdi_size == 3'b011) ? {{{24}{1'b0}}, state_mask[255:24]} : 256'bz;
assign next_state_mask = (bdi_size == 3'b100) ? {{{32}{1'b0}}, state_mask[255:32]} : 256'bz;

assign C = bdi_reg ^ ({state_reg0, state_reg1} & state_mask);
assign en_state_mask = (clr_bdi == 1 || en_bdi == 1) ? 1 : 0;

d_ff #(256) st_msk(
.clk(clk),
.rst(rst),
.en(en_state_mask), 
.d(next_state_mask_clr),
.q(state_mask)
);

// Secret Key

assign next_key_reg = {key_reg[95:0],key};

d_ff #(128) key_rg(
.clk(clk),
.rst(rst),
.en(en_key), 
.d(next_key_reg),
.q(key_reg)
);

// TLS tweakey

	// prestep
	
assign t = (tweak_sel == 0) ? P : {state_reg1[127:8],1'b1, state_reg1[6:0]}; // strict interpretation of P[0] required to be 0 for su is not enforced
assign tk0 = t ^ key_reg;
assign stk0 = (tweak_sel == 0 || inv == 1) ? N  ^ tk0 : state_reg0 ^ tk0;
		  
	// poststep

assign tls_step_out = (inv == 0) ? rc_tls_enc : inv_sbox_out;
assign next_state_tls_reg0 = (round_ctr[0] == 1'b1) ? tls_step_out ^ tk : tls_step_out;
assign tls_sout = (tls_finished == 1) ? next_state_tls_reg0 : state_reg0;

// tweak generation on the fly

assign next_t_reg_enc = (lfsr_reg == 4'b0100) ? {t[127:64]^t[63:0],t[127:64]} : {t_reg[127:64]^t_reg[63:0],t_reg[127:64]}; 
assign next_t_reg_dec = (lfsr_reg == 4'b1110) ? {t[63:0],t[127:64]^t[63:0]} : {t_reg[63:0],t_reg[127:64]^t_reg[63:0]}; 

assign next_t_reg = (inv == 0) ? next_t_reg_enc : next_t_reg_dec;
assign tk = next_t_reg ^ key_reg;
	
d_ff #(128) t_rg(
.clk(clk),
.rst(rst),
.en(round_ctr[0]), // effectively a toggle
.d(next_t_reg),
.q(t_reg)
);
	
// S-Box

assign sbox_in_perm = (round_ctr == 2'b00) ? state_reg0 : 128'bz;
assign sbox_in_perm = (round_ctr == 2'b01) ? state_reg1 : 128'bz;
assign sbox_in_perm = (round_ctr == 2'b10) ? state_reg2 : 128'bz;
assign sbox_in_perm = (round_ctr == 2'b11) ? state_reg3 : 128'bz;

assign sbox_in = (en_tls == 1) ? state_reg0 : sbox_in_perm;

genvar i;
generate
for (i=0; i<32; i=i+1) begin: generate_sb
  SB sboxinst(
  .din({sbox_in[i],sbox_in[32+i],sbox_in[64+i],sbox_in[96+i]}),
  .dout({sbox_out[i],sbox_out[32+i],sbox_out[64+i],sbox_out[96+i]})
  );
end
endgenerate

// Inv S-Box

genvar j;
generate
for (j=0; j<32; j=j+1) begin: generate_invsb
  InvSB invsboxinst(
  .din({inv_lbox_out[j],inv_lbox_out[32+j],inv_lbox_out[64+j],inv_lbox_out[96+j]}),
  .dout({inv_sbox_out[j],inv_sbox_out[32+j],inv_sbox_out[64+j],inv_sbox_out[96+j]})
  );
end
endgenerate

// Inv L-Box

InvLBox128 InvLBox128_inst(
.sin(rc_tls_dec),
.sout(inv_lbox_out)
);

// L Box

assign lbox_in_perm = (round_ctr == 2'b00) ? state_reg0 : 128'bz;
assign lbox_in_perm = (round_ctr == 2'b01) ? state_reg1 : 128'bz;
assign lbox_in_perm = (round_ctr == 2'b10) ? state_reg2 : 128'bz;
assign lbox_in_perm = (round_ctr == 2'b11) ? state_reg3 : 128'bz;

assign lbox_in = (en_tls == 1 ) ? sbox_out : lbox_in_perm;

LBox128 LBox128_inst(
.sin(lbox_in),
.sout(lbox_out)
);

// RC

assign rc_out0 = {state_reg0[127:121],state_reg0[120]^lfsr_reg[3], state_reg0[119:96],
                 state_reg0[95:89],state_reg0[88]^lfsr_reg[2], state_reg0[87:64],
                 state_reg0[63:57],state_reg0[56]^lfsr_reg[1], state_reg0[55:32],
                 state_reg0[31:25],state_reg0[24]^lfsr_reg[0], state_reg0[23:0]};
 
assign rc_out1 = {state_reg1[127:122],state_reg1[121]^lfsr_reg[3], state_reg1[120:96],
                 state_reg1[95:90],state_reg1[89]^lfsr_reg[2], state_reg1[88:64],
                 state_reg1[63:58],state_reg1[57]^lfsr_reg[1], state_reg1[56:32],
                 state_reg1[31:26],state_reg1[25]^lfsr_reg[0], state_reg1[24:0]};

assign rc_out2 = {state_reg2[127:123],state_reg2[122]^lfsr_reg[3], state_reg2[121:96],
                 state_reg2[95:91],state_reg2[90]^lfsr_reg[2], state_reg2[89:64],
                 state_reg2[63:59],state_reg2[58]^lfsr_reg[1], state_reg2[57:32],
                 state_reg2[31:27],state_reg2[26]^lfsr_reg[0], state_reg2[25:0]};

assign rc_out3 = {state_reg3[127:124],state_reg3[123]^lfsr_reg[3], state_reg3[122:96],
                 state_reg3[95:92],state_reg3[91]^lfsr_reg[2], state_reg3[90:64],
                 state_reg3[63:60],state_reg3[59]^lfsr_reg[1], state_reg3[58:32],
                 state_reg3[31:28],state_reg3[27]^lfsr_reg[0], state_reg3[26:0]};
	
assign rc_out = (round_ctr == 2'b00) ? rc_out0 : 128'bz;
assign rc_out = (round_ctr == 2'b01) ? rc_out1 : 128'bz;
assign rc_out = (round_ctr == 2'b10) ? rc_out2 : 128'bz;
assign rc_out = (round_ctr == 2'b11) ? rc_out3 : 128'bz;

assign rc_tls_enc = {lbox_out[127:121],lbox_out[120]^lfsr_reg[3], lbox_out[119:96],
                 lbox_out[95:89],lbox_out[88]^lfsr_reg[2], lbox_out[87:64],
                 lbox_out[63:57],lbox_out[56]^lfsr_reg[1], lbox_out[55:32],
                 lbox_out[31:25],lbox_out[24]^lfsr_reg[0], lbox_out[23:0]};

assign rc_tls_dec = {state_reg0[127:121],state_reg0[120]^lfsr_reg[3], state_reg0[119:96],
                 state_reg0[95:89],state_reg0[88]^lfsr_reg[2], state_reg0[87:64],
                 state_reg0[63:57],state_reg0[56]^lfsr_reg[1], state_reg0[55:32],
                 state_reg0[31:25],state_reg0[24]^lfsr_reg[0], state_reg0[23:0]};
				 
// Diffuser

assign w = (round_ctr == 2'b00) ? state_reg0[127:96] : 128'bz;
assign w = (round_ctr == 2'b01) ? state_reg0[95:64] : 128'bz;
assign w = (round_ctr == 2'b10) ? state_reg0[63:32] : 128'bz;
assign w = (round_ctr == 2'b11) ? state_reg0[31:0] : 128'bz;

assign x = (round_ctr == 2'b00) ? state_reg1[127:96] : 128'bz;
assign x = (round_ctr == 2'b01) ? state_reg1[95:64] : 128'bz;
assign x = (round_ctr == 2'b10) ? state_reg1[63:32] : 128'bz;
assign x = (round_ctr == 2'b11) ? state_reg1[31:0] : 128'bz;

assign y = (round_ctr == 2'b00) ? state_reg2[127:96] : 128'bz;
assign y = (round_ctr == 2'b01) ? state_reg2[95:64] : 128'bz;
assign y = (round_ctr == 2'b10) ? state_reg2[63:32] : 128'bz;
assign y = (round_ctr == 2'b11) ? state_reg2[31:0] : 128'bz;

assign z = (round_ctr == 2'b00) ? state_reg3[127:96] : 128'bz;
assign z = (round_ctr == 2'b01) ? state_reg3[95:64] : 128'bz;
assign z = (round_ctr == 2'b10) ? state_reg3[63:32] : 128'bz;
assign z = (round_ctr == 2'b11) ? state_reg3[31:0] : 128'bz;

assign u = w ^ x;
assign v = y ^ z;
assign a = x ^ v;
assign b = w ^ v;
assign c = u ^ z;
assign d = u ^ y;

assign diff_out0 = (round_ctr == 2'b00) ? {a, state_reg0[95:0]} : 128'bz;
assign diff_out0 = (round_ctr == 2'b01) ? {state_reg0[127:96], a, state_reg0[63:0]} : 128'bz;
assign diff_out0 = (round_ctr == 2'b10) ? {state_reg0[127:64], a, state_reg0[31:0]} : 128'bz;
assign diff_out0 = (round_ctr == 2'b11) ? {state_reg0[127:32], a} : 128'bz;

assign diff_out1 = (round_ctr == 2'b00) ? {b, state_reg1[95:0]} : 128'bz;
assign diff_out1 = (round_ctr == 2'b01) ? {state_reg1[127:96], b, state_reg1[63:0]} : 128'bz;
assign diff_out1 = (round_ctr == 2'b10) ? {state_reg1[127:64], b, state_reg1[31:0]} : 128'bz;
assign diff_out1 = (round_ctr == 2'b11) ? {state_reg1[127:32], b} : 128'bz;

assign diff_out2 = (round_ctr == 2'b00) ? {c, state_reg2[95:0]} : 128'bz;
assign diff_out2 = (round_ctr == 2'b01) ? {state_reg2[127:96], c, state_reg2[63:0]} : 128'bz;
assign diff_out2 = (round_ctr == 2'b10) ? {state_reg2[127:64], c, state_reg2[31:0]} : 128'bz;
assign diff_out2 = (round_ctr == 2'b11) ? {state_reg2[127:32], c} : 128'bz;

assign diff_out3 = (round_ctr == 2'b00) ? {d, state_reg3[95:0]} : 128'bz;
assign diff_out3 = (round_ctr == 2'b01) ? {state_reg3[127:96], d, state_reg3[63:0]} : 128'bz;
assign diff_out3 = (round_ctr == 2'b10) ? {state_reg3[127:64], d, state_reg3[31:0]} : 128'bz;
assign diff_out3 = (round_ctr == 2'b11) ? {state_reg3[127:32], d} : 128'bz;

// State Registers

assign next_state_perm_reg0 = (dinsel == 2'b00) ? sbox_out : 128'bz;
assign next_state_perm_reg0 = (dinsel == 2'b01) ? lbox_out : 128'bz;
assign next_state_perm_reg0 = (dinsel == 2'b10) ? rc_out : 128'bz;
assign next_state_perm_reg0 = (dinsel == 2'b11) ? diff_out0 : 128'bz;

assign next_state_ext_reg0 = (reg_0_sel == 2'b00) ? P : 128'bz;
assign next_state_ext_reg0 = (reg_0_sel == 2'b01) ? bdi_reg[255:128] ^ state_reg0 : 128'bz;
assign next_state_ext_reg0 = (reg_0_sel == 2'b10) ? C[255:128] : 128'bz;
assign next_state_ext_reg0 = (reg_0_sel == 2'b11) ? C_padded[255:128] : 128'bz;

assign state_0_sel = {en_state, en_tls};

assign next_state_int_reg0 = (state_0_sel == 2'b00) ? next_state_perm_reg0 : 128'bz;
assign next_state_int_reg0 = (state_0_sel == 2'b01) ? next_state_tls_reg0  : 128'bz;
assign next_state_int_reg0 = (state_0_sel == 2'b10) ? state_reg0 : 128'bz; 
assign next_state_int_reg0 = (state_0_sel == 2'b11) ? stk0  : 128'bz;

assign next_state_reg0 = (en_ext_state == 1) ? next_state_ext_reg0 : next_state_int_reg0;

d_ff #(128) state_rg0(
.clk(clk),
.rst(rst),
.en(en_state_0),
.d(next_state_reg0),
.q(state_reg0)
); 

assign next_state_perm_reg1 = (dinsel == 2'b00) ? sbox_out : 128'bz;
assign next_state_perm_reg1 = (dinsel == 2'b01) ? lbox_out : 128'bz;
assign next_state_perm_reg1 = (dinsel == 2'b10) ? rc_out : 128'bz;
assign next_state_perm_reg1 = (dinsel == 2'b11) ? diff_out1 : 128'bz;

assign next_state_ext_reg1 = (reg_1_sel == 2'b00) ? N : 128'bz;
assign next_state_ext_reg1 = (reg_1_sel == 2'b01) ? bdi_reg[127:0] ^ state_reg1 : 128'bz;
assign next_state_ext_reg1 = (reg_1_sel == 2'b10) ? C[127:0] : 128'bz;
assign next_state_ext_reg1 = (reg_1_sel == 2'b11) ? C_padded[127:0] : 128'bz;

assign next_state_reg1 = (en_ext_state == 1) ?  next_state_ext_reg1 : next_state_perm_reg1; 

d_ff #(128) state_rg1(
.clk(clk),
.rst(rst),
.en(en_state_1),
.d(next_state_reg1),
.q(state_reg1)
); 

assign next_state_perm_reg2 = (dinsel == 2'b00) ? sbox_out : 128'bz;
assign next_state_perm_reg2 = (dinsel == 2'b01) ? lbox_out : 128'bz;
assign next_state_perm_reg2 = (dinsel == 2'b10) ? rc_out : 128'bz;
assign next_state_perm_reg2 = (dinsel == 2'b11) ? diff_out2 : 128'bz;

assign next_state_ext_reg2 = (reg_2_sel == 0) ? 0 : reg_2_xored;

assign reg_2_xored = (reg_2_xor_sel == 2'b00) ? state_reg2 : 128'bz;
assign reg_2_xored = (reg_2_xor_sel == 2'b01) ? {state_reg2[127:122], state_reg2[121:120] ^ 2'b01, state_reg2[119:0]} : 128'bz;
assign reg_2_xored = (reg_2_xor_sel == 2'b10) ? {state_reg2[127:122], state_reg2[121:120] ^ 2'b10, state_reg2[119:0]} : 128'bz;
assign reg_2_xored = (reg_2_xor_sel == 2'b11) ? {state_reg2[127:122], state_reg2[121:120] ^ 2'b11, state_reg2[119:0]} : 128'bz;

assign next_state_reg2 = (en_ext_state == 1) ?  next_state_ext_reg2 : next_state_perm_reg2; 

d_ff #(128) state_rg2(
.clk(clk),
.rst(rst),
.en(en_state_2),
.d(next_state_reg2),
.q(state_reg2)
); 

assign next_state_perm_reg3 = (dinsel == 2'b00) ? sbox_out : 128'bz;
assign next_state_perm_reg3 = (dinsel == 2'b01) ? lbox_out : 128'bz;
assign next_state_perm_reg3 = (dinsel == 2'b10) ? rc_out : 128'bz;
assign next_state_perm_reg3 = (dinsel == 2'b11) ? diff_out3 : 128'bz;

assign next_state_ext_reg3 = (reg_3_sel == 0) ? state_reg0 : state_reg3;

assign next_state_reg3 = (en_ext_state == 1) ?  next_state_ext_reg3 : next_state_perm_reg3; 

d_ff #(128) state_rg3(
.clk(clk),
.rst(rst),
.en(en_state_3),
.d(next_state_reg3),
.q(state_reg3)
); 

// Round Constant LFSR

d_ff #(4) lfsr_rg(
.clk(clk),
.rst(rst),
.en(en_lfsr),
.d(next_lfsr_reg),
.q(lfsr_reg)
);


assign tls_round_finished = (inv == 0) ? RND_FINISHED_ENC : RND_FINISHED_DEC;
assign tls_finished = (lfsr_reg == tls_round_finished) ? 1 : 0;
assign lfsr_start = (inv == 0) ? RND_FINISHED_DEC : RND_FINISHED_ENC;
assign next_lfsr_reg = (start_tls == 1 || start_perm == 1) ? lfsr_start : next_lfsr;

assign next_lfsr = (inv == 0) ? {lfsr_reg[0], lfsr_reg[0] ^ lfsr_reg[3], lfsr_reg[2], lfsr_reg[1]} :
                                {lfsr_reg[3] ^ lfsr_reg[2], lfsr_reg[1], lfsr_reg[0], lfsr_reg[3]} ;

// round and step counters

assign steps_finished = (step_ctr == MAX_STEPS) ? 1 : 0;
assign perm_rounds_finished = (round_ctr == MAX_ROUNDS) ? 1 : 0;

assign next_step_ctr = (start_perm == 1) ? 0 : step_ctr + 1;
assign next_round_ctr = (start_perm == 1 || start_tls == 1) ? 0 : round_ctr + 1;

d_ff #(3) step_cntr(
.clk(clk),
.rst(rst),
.en(en_step),
.d(next_step_ctr),
.q(step_ctr)
);

d_ff #(2) round_cntr(
.clk(clk),
.rst(rst),
.en(en_round),
.d(next_round_ctr),
.q(round_ctr)
);

// state decoder

assign en_perm_0 = (en_diff == 1) ? 1 : en_perm_0_dec;				 
assign en_perm_1 = (en_diff == 1) ? 1 : en_perm_1_dec;
assign en_perm_2 = (en_diff == 1) ? 1 : en_perm_2_dec;
assign en_perm_3 = (en_diff == 1) ? 1 : en_perm_3_dec;

assign en_perm_0_dec = (round_ctr == 2'b00 && en_round == 1) ? 1 : 0;
assign en_perm_1_dec = (round_ctr == 2'b01 && en_round == 1) ? 1 : 0;
assign en_perm_2_dec = (round_ctr == 2'b10 && en_round == 1) ? 1 : 0;
assign en_perm_3_dec = (round_ctr == 2'b11 && en_round == 1) ? 1 : 0;

assign en_state_0 = en_ext_state | en_state | en_perm_0  | en_tls;
assign en_state_1 = en_ext_state | (en_state | en_perm_1) & ~en_tls;
assign en_state_2 = en_ext_state | (en_state | en_perm_2) & ~en_tls;
assign en_state_3 = en_ext_state | (en_state | en_perm_3) & ~en_tls;

// output

// plaintext or ciphertext

d_ff #(256) lck_msg_rg(
.clk(clk),
.rst(rst),
.en(lock_message),
.d(C_padded),
.q(lock_message_reg)
);

d_ff #(3) bdi_sz_rg(
.clk(clk),
.rst(rst),
.en(en_bdi),
.d(bdi_size),
.q(bdi_size_reg)
);

assign bdo_word_mask = (bdo_last_word == 1) ? bdo_word_mask_last : 32'hFFFFFFFF;

assign bdo_word_mask_last = (bdi_size_reg == 3'b000) ? 32'h0000_0000 : 32'bz;
assign bdo_word_mask_last = (bdi_size_reg == 3'b001) ? 32'hFF00_0000 : 32'bz;
assign bdo_word_mask_last = (bdi_size_reg == 3'b010) ? 32'hFFFF_0000 : 32'bz;
assign bdo_word_mask_last = (bdi_size_reg == 3'b011) ? 32'hFFFF_FF00 : 32'bz;
assign bdo_word_mask_last = (bdi_size_reg == 3'b100) ? 32'hFFFF_FFFF : 32'bz;

assign bdo_word = (ld_ctr == 3'b000) ? lock_message_reg[255:224] & bdo_word_mask : 32'bz;
assign bdo_word = (ld_ctr == 3'b001) ? lock_message_reg[223:192] & bdo_word_mask: 32'bz;
assign bdo_word = (ld_ctr == 3'b010) ? lock_message_reg[191:160] & bdo_word_mask: 32'bz;
assign bdo_word = (ld_ctr == 3'b011) ? lock_message_reg[159:128] & bdo_word_mask: 32'bz;
assign bdo_word = (ld_ctr == 3'b100) ? lock_message_reg[127:96] & bdo_word_mask: 32'bz;
assign bdo_word = (ld_ctr == 3'b101) ? lock_message_reg[95:64] & bdo_word_mask: 32'bz;
assign bdo_word = (ld_ctr == 3'b110) ? lock_message_reg[63:32] & bdo_word_mask: 32'bz;
assign bdo_word = (ld_ctr == 3'b111) ? lock_message_reg[31:0] & bdo_word_mask: 32'bz;

// tag
assign tag = (ld_ctr == 3'b000) ? state_reg0[127:96] : 32'bz;
assign tag = (ld_ctr == 3'b001) ? state_reg0[95:64] : 32'bz;
assign tag = (ld_ctr == 3'b010) ? state_reg0[63:32] : 32'bz;
assign tag = (ld_ctr == 3'b011) ? state_reg0[31:0] : 32'bz;
assign tag = (ld_ctr == 3'b100) ? state_reg0[127:96] : 32'bz;
assign tag = (ld_ctr == 3'b101) ? state_reg0[95:64] : 32'bz;
assign tag = (ld_ctr == 3'b110) ? state_reg0[63:32] : 32'bz;
assign tag = (ld_ctr == 3'b111) ? state_reg0[31:0] : 32'bz;

assign bdo = (sel_tag == 1) ? tag : bdo_word; 

assign msg_auth = (lock_tag_reg == state_reg0) ? 1 : 0;

d_ff #(128) lck_tg_rg(
.clk(clk),
.rst(rst),
.en(lock_tag),
.d(state_reg0),
.q(lock_tag_reg)
);

// Shadow controller

//Synchronous Process
localparam INIT_ST = 4'b0000,
           SBOX_1_ST = 4'b0001,		   
           LBOX_ST = 4'b0010,
		   RC_1_ST = 4'b0011,
		   SBOX_2_ST = 4'b0100,
		   DIFF_ST = 4'b0101,
		   RC_2_ST = 4'b0110,
		   TLS_RUN_ST = 4'b1000;
		   
always @(posedge clk)
begin
	if (rst == 1'b1) fsm_state <= INIT_ST; 
	else fsm_state <= next_fsm_state;
end

// State Process
always @(fsm_state or start_tls or start_perm or steps_finished or perm_rounds_finished or tls_finished)
begin

// defaults to eliminate latches

en_round <= 0; // result assumed to not be ready
en_step <= 0;
en_lfsr <= 0;
en_diff <= 0;
en_state <= 0;
en_tls <= 0;
dinsel <= 2'b00;
next_fsm_state <= INIT_ST;
perm_done <= 0;
tls_done <= 0;

      case (fsm_state)

	  INIT_ST: 
      begin
	    
		if (start_perm == 1) begin
			en_round <= 1;
			en_step <= 1;
			en_lfsr <= 1;
			en_state <= 1;
			next_fsm_state <= SBOX_1_ST;
		end else if (start_tls == 1) begin
			en_round <= 1;
			en_lfsr <= 1;
			en_tls <= 1; // test
			en_state <= 1;
			next_fsm_state <= TLS_RUN_ST;
		end else begin
			perm_done <= 1;
			tls_done <= 1;
			next_fsm_state <= INIT_ST;
			end
		end
 
       SBOX_1_ST:
	   begin
			en_round <= 1;
			dinsel <= 2'b00;
			if (perm_rounds_finished == 1) 
				next_fsm_state <= LBOX_ST;
			else
				next_fsm_state <= SBOX_1_ST;
	   end	

       LBOX_ST:
	   begin
			en_round <= 1;
			dinsel <= 2'b01;
			if (perm_rounds_finished == 1) 
				next_fsm_state <= RC_1_ST;
			else
				next_fsm_state <= LBOX_ST;
	   end	

       RC_1_ST:
	   begin
			en_round <= 1;
			dinsel <= 2'b10;
			if (perm_rounds_finished == 1) begin
                en_lfsr <= 1;			
				next_fsm_state <= SBOX_2_ST;
			end else
				next_fsm_state <= RC_1_ST;
	   end	

	   SBOX_2_ST:
	   begin
			en_round <= 1;
			dinsel <= 2'b00;
			if (perm_rounds_finished == 1) 
				next_fsm_state <= DIFF_ST;
			else
				next_fsm_state <= SBOX_2_ST;
	   end	

	   DIFF_ST:
	   begin
			dinsel <= 2'b11;
			en_diff <= 1;
			en_round <= 1;
			if (perm_rounds_finished == 1) 
				next_fsm_state <= RC_2_ST;
			else
				next_fsm_state <= DIFF_ST;
	   end	

       RC_2_ST:
	   begin
			en_round <= 1;
			dinsel <= 2'b10;
			if (perm_rounds_finished == 1) begin
                en_lfsr <= 1;
               	if (steps_finished == 1) begin
					perm_done <= 1;
					next_fsm_state <= INIT_ST;
				end else begin
				    
				    en_step <= 1;
					next_fsm_state <= SBOX_1_ST;
				end
			end else begin
				next_fsm_state <= RC_2_ST;
				
			end
	   end	
	   
	   TLS_RUN_ST:
	   begin
	   en_tls <= 1;
	   en_round <= 1;
	   en_lfsr <= 1;
	   if (tls_finished == 1)begin
			tls_done <= 1;
			next_fsm_state <= INIT_ST;
	   end else
		   next_fsm_state <= TLS_RUN_ST;
	   end
	   
	   default: begin 
					next_fsm_state <= INIT_ST; // should never get here
				end
   	   endcase
end

endmodule