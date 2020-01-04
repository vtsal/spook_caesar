//Spook 128su512v1 
// William Diehl
// Virginia Tech
// 06-16-2019

module CipherCore(
        //! Global
        clk,
        rst,
        //! PreProcessor (data)
        key,
        bdi,
        //! PreProcessor (controls)
        key_ready,
        key_valid,
        key_update,
        decrypt,
        bdi_ready,
        bdi_valid,
        bdi_type, 
        bdi_partial,
        bdi_eot,    
        bdi_eoi,    
        bdi_size,   
        bdi_valid_bytes,
        bdi_pad_loc,
        //! PostProcessor
        bdo,
        bdo_valid,
        bdo_ready,
        bdo_size,
		end_of_block,
        msg_auth,
		msg_auth_ready,
        msg_auth_valid
    );
	
input clk, rst, key_valid, key_update, decrypt, bdi_valid, bdi_partial, bdi_eot, bdi_eoi, bdo_ready, msg_auth_ready;
input [2:0] bdi_size;
input [3:0] bdi_type, bdi_valid_bytes, bdi_pad_loc;
input [31:0] key, bdi;

output key_ready, bdi_ready, bdo_valid, end_of_block, msg_auth, msg_auth_valid;
output [3:0] bdo_size;
output [31:0] bdo;

wire en_key, en_bdi, en_pad, clr_bdi, sel_tag;
wire start_tls, start_perm, tls_done, perm_done, en_ext_state, msg_auth;
wire inv, lock_tag, lock_message;
wire reg_2_sel, reg_3_sel, tweak_sel, bdo_last_word;
wire [1:0] reg_0_sel, reg_1_sel, reg_2_xor_sel;
wire [2:0] ld_ctr;

Datapath data_path_inst(
        .clk(clk),
        .rst(rst),

        //! Input Processor
        .key(key),
        .bdi(bdi),

        //! Output Processor
        .bdo(bdo),

        //! Controller
        .en_key(en_key),
        .en_pad(en_pad),
        .en_bdi(en_bdi),
		.clr_bdi(clr_bdi),
		.inv(inv),
        .sel_tag(sel_tag),		
        .start_tls(start_tls),
		.start_perm(start_perm),
		.tls_done(tls_done),
		.perm_done(perm_done),
		.en_ext_state(en_ext_state),
		.lock_tag(lock_tag),
		.lock_message(lock_message),
		.bdo_last_word(bdo_last_word),
		.msg_auth(msg_auth),
		.bdi_size(bdi_size),
		.reg_0_sel(reg_0_sel),
		.reg_1_sel(reg_1_sel),
		.reg_2_sel(reg_2_sel),
		.reg_3_sel(reg_3_sel),
		.reg_2_xor_sel(reg_2_xor_sel),
		.tweak_sel(tweak_sel),
		.ld_ctr(ld_ctr)
    );

Controller ctrl_inst(
        .clk(clk),
        .rst(rst),

        //! Input
        .key_ready(key_ready),
        .key_valid(key_valid),
        .key_update(key_update),
        .decrypt(decrypt),
        .bdi_ready(bdi_ready),
        .bdi_valid(bdi_valid),
		.bdi_type(bdi_type),
        .bdi_eot(bdi_eot),
        .bdi_eoi(bdi_eoi),
		.bdi_partial(bdi_partial),
		.bdi_size(bdi_size),

		//! Output
        .msg_auth_valid(msg_auth_valid),
		.msg_auth_ready(msg_auth_ready),
		.end_of_block(end_of_block),
        .bdo_ready(bdo_ready),
        .bdo_valid(bdo_valid),

        //! Datapath
        .en_key(en_key),
        .en_pad(en_pad),
        .en_bdi(en_bdi),
		.clr_bdi(clr_bdi),
        .start_tls(start_tls),
		.start_perm(start_perm),
		.inv(inv),
		.lock_tag(lock_tag),
		.lock_message(lock_message),
		.bdo_last_word(bdo_last_word),
		.sel_tag(sel_tag),
     	.tls_done(tls_done),
		.perm_done(perm_done),
		.en_ext_state(en_ext_state),
		.reg_0_sel(reg_0_sel),
		.reg_1_sel(reg_1_sel),
		.reg_2_sel(reg_2_sel),
		.reg_3_sel(reg_3_sel),
		.reg_2_xor_sel(reg_2_xor_sel),
		.tweak_sel(tweak_sel),
		.ld_ctr(ld_ctr)
    );

endmodule