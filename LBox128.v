module LBox128(
sin,
sout
);

input [127:0] sin;
output [127:0] sout;

wire [127:0] sin_rvend, sin_lend, after_lbox_lend, after_lbox_bend;
genvar j;
generate
for (j=0; j<32; j=j+1) begin: generate_rvend
    assign sin_rvend[128-j-1] = sin[96+j];
    assign sin_rvend[96-j-1] = sin[64+j];
    assign sin_rvend[64-j-1] = sin[32+j];
    assign sin_rvend[32-j-1] = sin[j];
end
endgenerate 

genvar k;
generate
for (k=0; k<4; k=k+1) begin: generate_lend
    assign sin_lend[128-k*32-1:128-k*32-32] = 
    {sin_rvend[128-k*32-32+7:128-k*32-32+0],
     sin_rvend[128-k*32-32+15:128-k*32-32+8],
     sin_rvend[128-k*32-32+23:128-k*32-32+16],
     sin_rvend[128-k*32-32+31:128-k*32-32+24]};
end
endgenerate 

genvar l;
generate
for (l=0; l<2; l=l+1) begin: generate_lb
	LB lboxinst(
	.x(sin_lend[128-2*l*32-1:128-2*l*32-32]),
	.y(sin_lend[128-2*l*32-32-1:128-2*l*32-64]), 
	.a(after_lbox_lend[128-2*l*32-1:128-2*l*32-32]),
	.b(after_lbox_lend[128-2*l*32-32-1:128-2*l*32-64])
	);
end
endgenerate

genvar m;
generate
for (m=0; m<4; m=m+1) begin: generate_bend
    assign after_lbox_bend[128-m*32-1:128-m*32-32] = 
    {after_lbox_lend[128-m*32-32+7:128-m*32-32+0],
     after_lbox_lend[128-m*32-32+15:128-m*32-32+8],
     after_lbox_lend[128-m*32-32+23:128-m*32-32+16],
     after_lbox_lend[128-m*32-32+31:128-m*32-32+24]};
end
endgenerate 

genvar n;
generate
for (n=0; n<32; n=n+1) begin: generate_rv_rvend
    assign sout[128-n-1] = after_lbox_bend[96+n];
    assign sout[96-n-1] = after_lbox_bend[64+n];
    assign sout[64-n-1] = after_lbox_bend[32+n];
    assign sout[32-n-1] = after_lbox_bend[n];
end
endgenerate 

endmodule