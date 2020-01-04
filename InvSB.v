module InvSB(
din,
dout
);

input [3:0] din;
output [3:0] dout;

reg [3:0] dout;

always @(din)
case(din)
    4'h0 : dout = 4'h0;
    4'h1 : dout = 4'h2;
    4'h2 : dout = 4'h4;
    4'h3 : dout = 4'hd;
    4'h4 : dout = 4'h8;
    4'h5 : dout = 4'ha;
    4'h6 : dout = 4'hb;
    4'h7 : dout = 4'h6;
    4'h8 : dout = 4'h1;
    4'h9 : dout = 4'h7;
    4'ha : dout = 4'h5;
    4'hb : dout = 4'he;
    4'hc : dout = 4'hf;
    4'hd : dout = 4'h9;
    4'he : dout = 4'hc;
    4'hf : dout = 4'h3;	
endcase

endmodule
