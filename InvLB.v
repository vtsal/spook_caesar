module InvLB(
x,
y,
a,
b
);

input [31:0] x,y;
output [31:0] a,b;

wire [31:0] a1, b1, a2, b2, a3, b3, c, d, c1, d1, c2, d2;

assign a1 = x ^ {x[6:0],x[31:7]}; // lrot 25
assign b1 = y ^ {y[6:0],y[31:7]}; // lrot 25

assign c = x ^ {a1[0],a1[31:1]}; // lrot 31
assign d = y ^ {b1[0],b1[31:1]}; // lrot 31

assign c1 = c ^ {a1[11:0],a1[31:12]}; // lrot 20
assign d1 = d ^ {b1[11:0],b1[31:12]}; // lrot 20

assign a2 = c1 ^ {c1[0],c1[31:1]}; // lrot 31
assign b2 = d1 ^ {d1[0],d1[31:1]}; // lrot 31

assign c2 = c1 ^ {b2[5:0],b2[31:6]}; // lrot 26
assign d2 = d1 ^ {a2[6:0],a2[31:7]}; // lrot 25

assign a3 = a2 ^ {c2[14:0],c2[31:15]}; // lrot 17
assign b3 = b2 ^ {d2[14:0],d2[31:15]}; // lrot 17

assign a = {a3[15:0], a3[31:16]}; // lrot 16
assign b = {b3[15:0], b3[31:16]}; // lrot 16

endmodule

