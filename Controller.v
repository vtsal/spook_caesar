//Spook-128su512v1 
// William Diehl
// Virginia Tech
// 06-16-2019

module Controller(

// input

// AEAD
clk,
rst,
bdi_valid,
bdo_ready,
key_update,
key_valid,
bdi_eoi,
bdi_eot,
bdi_type,
bdi_partial,
bdi_size,
decrypt,
msg_auth_ready,

//output

// AEAD
bdi_ready,
bdo_valid,
key_ready,
end_of_block,
msg_auth_valid,

// Datapath
tls_done,
perm_done,
sel_tag,
en_key,
en_bdi,
clr_bdi,
en_pad,
start_tls,
start_perm,
inv,
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
ld_ctr
);

input clk, rst, bdi_valid, key_update, key_valid, bdi_eoi, bdi_eot, bdi_partial, decrypt, msg_auth_ready, perm_done, tls_done; 
input bdo_ready;
input [2:0] bdi_size;
input [3:0] bdi_type;

output bdi_ready, bdo_valid, key_ready, msg_auth_valid, end_of_block, sel_tag, en_key, en_pad, en_bdi, clr_bdi;
output en_ext_state, start_tls, start_perm; 
output inv, lock_tag, lock_message;
output reg_2_sel, reg_3_sel, tweak_sel, bdo_last_word;
output [1:0] reg_0_sel, reg_1_sel, reg_2_xor_sel;
output [2:0] ld_ctr;

reg key_ready, en_key, clr_ld_ctr, en_ld_ctr, set_wr_ctr, en_decrypt_reg;
reg bdi_ready, bdo_valid, msg_auth_valid, end_of_block, sel_tag, en_bdi, clr_bdi, en_pad;
reg start_tls, start_perm, en_ext_state;
reg set_eot_flag, reset_eot_flag, set_eoi_flag, reset_eoi_flag, eoi_flag, eot_flag, decrypt_reg;
reg store_bdi_type, bdi_type_reg, bdi_partial_reg, store_bdi_partial;
reg reg_2_sel, reg_3_sel, tweak_sel;
reg inv, set_inv, reset_inv, lock_tag, lock_message, bdo_last_word;
reg first_block, set_first_block, reset_first_block;
reg [1:0] reg_0_sel, reg_1_sel, reg_2_xor_sel;
reg [2:0] ld_ctr, wr_ctr;
reg [4:0] fsm_state, next_fsm_state;

//Synchronous Process
localparam RESET_ST = 5'b00000,
           CHECK_KEY_ST = 5'b00001,
		   LOAD_KEY_ST = 5'b00010,
		   LOAD_NPUB_ST = 5'b00011,
		   START_TLS_INIT_ST = 5'b00100,
		   FINISH_TLS_INIT_ST = 5'b00101,
		   LOAD_PERM_INIT_ST = 5'b00110,
		   START_PERM_INIT_ST = 5'b00111,
		   PROC_ST = 5'b01000,
		   WAIT_PROC_PERM_ST = 5'b01001,
		   FINISH_PROC_ST = 5'b01010,
		   WRITE_PTCT_ST = 5'b01011,
		   PRE_TAG_ST = 5'b01100, 
		   START_TLS_TAG_ST = 5'b01101,
		   FINISH_TLS_TAG_ST = 5'b01110,
		   LD_EXP_TAG_ST = 5'b01111, 
		   FINISH_TAG_ST = 5'b10000; 
		   
localparam AD_TYPE = 4'b0001,
           KEY_WORDS = 3'b011,
		   NPUB_WORDS = 3'b011,
		   BDI_WORDS = 3'b111,
		   TAG_WORDS = 3'b011;
		   
always @(posedge clk)
begin
	if (rst == 1'b1) fsm_state <= RESET_ST; 
	else begin
		fsm_state <= next_fsm_state;
		if (set_inv == 1)
		    inv <= 1;
		if (reset_inv == 1)
		    inv <= 0;
		if (clr_ld_ctr == 1)
		    ld_ctr <= 0;
        if (en_ld_ctr == 1)
		    ld_ctr <= ld_ctr + 1;
		if (set_wr_ctr == 1)
		    wr_ctr <= ld_ctr;
		if (set_eoi_flag == 1)
           eoi_flag <= 1;
        if (reset_eoi_flag == 1)
           eoi_flag <= 0;
        if (set_eot_flag == 1)
           eot_flag <= 1;
        if (reset_eot_flag == 1)
           eot_flag <= 0;
	    if (en_decrypt_reg == 1)
		   decrypt_reg <= decrypt;
		if (set_first_block == 1)
		   first_block <= 1;
		if (reset_first_block == 1)
		   first_block <= 0;
		if (store_bdi_type == 1)
			if (bdi_type == AD_TYPE)
				bdi_type_reg <= 1;
			else
				bdi_type_reg <= 0;
		if (store_bdi_partial == 1)
			if (bdi_size[1] == 1 || bdi_size[0] ==1)
				bdi_partial_reg <= 1;
			else
				bdi_partial_reg <= 0;
	end
end

always @(fsm_state or key_update or key_valid or bdi_valid or ld_ctr or bdi_eoi or bdi_eot or perm_done or tls_done or eoi_flag or
         eot_flag or ld_ctr or bdi_type or bdo_ready or decrypt_reg or msg_auth_ready or bdi_partial, bdi_partial_reg or
         bdi_type_reg or wr_ctr or first_block)
begin

//defaults

key_ready <= 0;
en_key <= 0;
clr_ld_ctr <= 0;
en_ld_ctr <= 0;
set_wr_ctr <= 0;
en_decrypt_reg <= 0;
set_eot_flag <= 0;
reset_eot_flag <= 0;
set_eot_flag <= 0;
reset_eot_flag <= 0;
set_eoi_flag <= 0;
reset_eoi_flag <= 0;
bdi_ready <=0;
bdo_valid <=0;
msg_auth_valid <=0;
end_of_block <=0;
sel_tag <=0;
clr_bdi <=0;
en_bdi <=0;
start_tls <= 0;
start_perm <= 0;
en_ext_state <= 0;
store_bdi_type <= 0;
store_bdi_partial <= 0;
reg_0_sel <= 2'b00;
reg_1_sel <= 2'b00;
reg_2_sel <= 0;
reg_3_sel <= 0;
reg_2_xor_sel <= 2'b00;
tweak_sel <= 0;
en_pad <= 0;
set_inv <= 0;
reset_inv <=0;
lock_tag <= 0;
lock_message <= 0;
bdo_last_word <= 0;
set_first_block <= 0;
reset_first_block <= 0;

	case (fsm_state)
	
	RESET_ST:
	begin
	    clr_bdi <= 1;
		en_bdi <= 1;
		clr_ld_ctr <= 1;
		reset_eoi_flag <= 1;
		reset_eot_flag <= 1;
		reset_inv <= 1;
		store_bdi_partial <= 1;
		set_first_block <= 1;
		next_fsm_state <= CHECK_KEY_ST;	
	end
	
	CHECK_KEY_ST:
	begin
		if (key_update == 1)
		     if (key_valid == 1)
		        next_fsm_state <= LOAD_KEY_ST;
             else 
                next_fsm_state <= CHECK_KEY_ST;
         else 
		     if (bdi_valid == 1)
                next_fsm_state <= LOAD_NPUB_ST;
		     else
                next_fsm_state <= CHECK_KEY_ST;
	end
	
	LOAD_KEY_ST:
	begin
        if (key_valid == 1) begin
			key_ready <= 1;
			en_key <= 1;
            if (ld_ctr == KEY_WORDS) begin
				clr_ld_ctr <= 1;
                next_fsm_state <= LOAD_NPUB_ST;
		    end else begin
                en_ld_ctr <= 1;
                next_fsm_state <= LOAD_KEY_ST;
            end
        end else
            next_fsm_state <= LOAD_KEY_ST;
	end

	LOAD_NPUB_ST:
	begin
	    if (bdi_valid == 1) begin
			en_bdi <= 1;
            bdi_ready <= 1;
            if (ld_ctr == NPUB_WORDS) begin
			    en_decrypt_reg <= 1; 
		        clr_ld_ctr <= 1;
			   	next_fsm_state <= START_TLS_INIT_ST; // one cycle delay required to lock npub
				if (bdi_eoi == 1) // no AD or PT
				    set_eoi_flag <= 1;
			end else begin
			         en_ld_ctr <= 1;
			         next_fsm_state <= LOAD_NPUB_ST;
			    end
		  end else
		    next_fsm_state <= LOAD_NPUB_ST;
	end

	START_TLS_INIT_ST:
	begin
		start_tls <= 1;
		next_fsm_state <= FINISH_TLS_INIT_ST;
	end
	
	FINISH_TLS_INIT_ST:
	begin
		if (tls_done == 1) begin
			next_fsm_state <= START_PERM_INIT_ST;
		end else 	
			next_fsm_state <= FINISH_TLS_INIT_ST;
		
	end
    
	START_PERM_INIT_ST:
	begin
		start_perm <= 1;
		en_ext_state <= 1; 
		clr_bdi <= 1;
		if (eoi_flag == 1) 
			next_fsm_state <= PRE_TAG_ST;
		else 
		    next_fsm_state <= PROC_ST;
	end
	
  	PROC_ST:
	begin
	    
		if (bdi_valid == 1) begin
			en_bdi <= 1;
			en_pad <= 1; // the resulting padded input will be loaded to bdi_reg
			bdi_ready <= 1;
			store_bdi_type <= 1;
			if (ld_ctr == BDI_WORDS || bdi_eot == 1) begin
			    if (bdi_eot == 1) begin // last block - could be full or partial
			  		set_eot_flag <= 1;
                    store_bdi_partial <= 1;
                end 
                if (bdi_eoi == 1)  // last block of AD and text
                    set_eoi_flag <= 1;
				next_fsm_state <= WAIT_PROC_PERM_ST;
			end else begin
			     en_ld_ctr <= 1;
			     next_fsm_state <= PROC_ST;
			end
		end else
		    next_fsm_state <= PROC_ST;
	end
	
	WAIT_PROC_PERM_ST:
	begin
	   if (perm_done == 1)
	       next_fsm_state <= FINISH_PROC_ST;
	   else
	       next_fsm_state <= WAIT_PROC_PERM_ST;
	end
			
	FINISH_PROC_ST:
	begin
		if (bdi_type_reg == 1) begin // type is AD
			reg_0_sel <= 2'b01;
			reg_1_sel <= 2'b01;
			reg_2_sel <= 1; 
			reg_3_sel <= 1;
			reset_eot_flag <= 1;
			if (eot_flag == 1) 
			     if (bdi_partial_reg == 1)
			         reg_2_xor_sel <= 2'b10;
			if (eoi_flag == 1) 
			     next_fsm_state <= PRE_TAG_ST;
		    else 
		         next_fsm_state <= PROC_ST;   

		end else begin // type is message
		    if (decrypt_reg == 1) begin
		          reg_0_sel <= 2'b10;
		          reg_1_sel <= 2'b10;
		    end else begin
		          reg_0_sel <= 2'b11;
		          reg_1_sel <= 2'b11;
		    end
		    reg_2_sel <= 1;
		    reg_3_sel <= 1;
		    lock_message <= 1;
           // this section performs domain separation between AD and PT/CT
		    if (first_block == 1) begin
		          reset_first_block <= 1; 
		          if (eot_flag == 1)
		              if (bdi_partial_reg == 1)
		                  reg_2_xor_sel <= 2'b11;
		              else
		                  reg_2_xor_sel <= 2'b01;
		          else
		              reg_2_xor_sel <= 2'b01;
		    end else if (eot_flag == 1)
		          if (bdi_partial_reg == 1)
		              reg_2_xor_sel <= 2'b10;
		    set_wr_ctr <= 1;
		    next_fsm_state <= WRITE_PTCT_ST;
		end
		clr_ld_ctr <= 1;    
		en_ext_state <= 1;
		start_perm <= 1;
        clr_bdi <= 1;
    end
 
  	WRITE_PTCT_ST:
	begin
		if (bdo_ready == 1) begin
		    bdo_valid <= 1;
		    if (ld_ctr == wr_ctr) begin
		         clr_ld_ctr <= 1;
		         bdo_last_word <= 1;
		         if (eot_flag == 1)    
		              end_of_block <= 1;
			     if (eoi_flag == 1) 
			         next_fsm_state <= PRE_TAG_ST;
		         else begin 
		             reset_eot_flag <= 1; 
		             next_fsm_state <= PROC_ST;
		         end
		    end else begin
		        en_ld_ctr <= 1;
		        next_fsm_state <= WRITE_PTCT_ST;
		    end
		 end else 
		      next_fsm_state <= WRITE_PTCT_ST;   
	end

	PRE_TAG_ST:
	begin
		if (perm_done == 1) begin
			if (decrypt_reg == 1) begin
			     set_inv <= 1;
		         next_fsm_state <= LD_EXP_TAG_ST;
		    end else
		         next_fsm_state <= START_TLS_TAG_ST;
		end else
			next_fsm_state <= PRE_TAG_ST;
	end

	LD_EXP_TAG_ST:
	begin
		if (bdi_valid == 1) begin
			en_bdi <= 1;
			bdi_ready <= 1;
			if (ld_ctr == TAG_WORDS) begin
			    clr_ld_ctr <= 1;
			    lock_tag <= 1; // lock value of state_reg0 for future comparison
				next_fsm_state <= START_TLS_TAG_ST;
			end else begin
				en_ld_ctr <= 1;
				next_fsm_state <= LD_EXP_TAG_ST;
			end
		end
	end
	
	START_TLS_TAG_ST:
	begin
        start_tls <= 1;
		tweak_sel <= 1;
		next_fsm_state <= FINISH_TLS_TAG_ST;
	end
		
	FINISH_TLS_TAG_ST:
	begin
	    if (tls_done == 1) 
			next_fsm_state = FINISH_TAG_ST;
		else begin
		    tweak_sel <= 1;
			next_fsm_state <= FINISH_TLS_TAG_ST;
		end
	end
	
	FINISH_TAG_ST:
	begin
		if (decrypt_reg == 1)
				if (msg_auth_ready == 1) begin
					msg_auth_valid <= 1;
					next_fsm_state <= RESET_ST;
				end else
				    next_fsm_state <= FINISH_TAG_ST;
		else if (bdo_ready == 1) begin
				sel_tag <= 1;
				bdo_valid <= 1;
				if (ld_ctr == TAG_WORDS) begin
					end_of_block <= 1;
					next_fsm_state <= RESET_ST;
				end else begin
					en_ld_ctr <= 1;
					next_fsm_state <= FINISH_TAG_ST;
				end
		     end
	end

	default:
	begin 
		next_fsm_state <= RESET_ST; // should never get here
	end
	endcase
end

endmodule