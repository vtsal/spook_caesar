module InvLBox128(
sin,
sout
);

input [127:0] sin;
output [127:0] sout;

wire [127:0] sin_rvend, sin_lend, after_lbox_lend, after_lbox_bend;

genvar i;
generate
for (i=0; i<32; i=i+1) begin: generate_rvend
    assign sin_rvend[128-i-1] = sin[96+i];
    assign sin_rvend[96-i-1] = sin[64+i];
    assign sin_rvend[64-i-1] = sin[32+i];
    assign sin_rvend[32-i-1] = sin[i];
end
endgenerate 

genvar j;
generate
for (j=0; j<4; j=j+1) begin: generate_lend
    assign sin_lend[128-j*32-1:128-j*32-32] = 
    {sin_rvend[128-j*32-32+7:128-j*32-32+0],
     sin_rvend[128-j*32-32+15:128-j*32-32+8],
     sin_rvend[128-j*32-32+23:128-j*32-32+16],
     sin_rvend[128-j*32-32+31:128-j*32-32+24]};
end
endgenerate 

genvar k;
generate
for (k=0; k<2; k=k+1) begin: generate_invlb
	InvLB invlboxinst(
	.x(sin_lend[128-2*k*32-1:128-2*k*32-32]),
	.y(sin_lend[128-2*k*32-32-1:128-2*k*32-64]), 
	.a(after_lbox_lend[128-2*k*32-1:128-2*k*32-32]),
	.b(after_lbox_lend[128-2*k*32-32-1:128-2*k*32-64])
	);
end
endgenerate

genvar l;
generate
for (l=0; l<4; l=l+1) begin: generate_bend
    assign after_lbox_bend[128-l*32-1:128-l*32-32] = 
    {after_lbox_lend[128-l*32-32+7:128-l*32-32+0],
     after_lbox_lend[128-l*32-32+15:128-l*32-32+8],
     after_lbox_lend[128-l*32-32+23:128-l*32-32+16],
     after_lbox_lend[128-l*32-32+31:128-l*32-32+24]};
end
endgenerate 

genvar m;
generate
for (m=0; m<32; m=m+1) begin: generate_rvrvend
    assign sout[128-m-1] = after_lbox_bend[96+m];
    assign sout[96-m-1] = after_lbox_bend[64+m];
    assign sout[64-m-1] = after_lbox_bend[32+m];
    assign sout[32-m-1] = after_lbox_bend[m];
end
endgenerate 

endmodule