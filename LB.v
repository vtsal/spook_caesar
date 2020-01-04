module LB(
x,
y,
a,
b
);

input [31:0] x,y;
output [31:0] a,b;

wire [31:0] a1, b1, a2, b2, a3, b3, a4, b4, c, d;

assign a1 = x ^ {x[19:0],x[31:20]}; // lrot 12
assign b1 = y ^ {y[19:0],y[31:20]}; // lrot 12

assign a2 = a1 ^ {a1[28:0],a1[31:29]}; // lrot 3
assign b2 = b1 ^ {b1[28:0],b1[31:29]}; // lrot 3

assign a3 = a2 ^ {x[14:0],x[31:15]}; // lrot 17
assign b3 = b2 ^ {y[14:0],y[31:15]}; // lrot 17

assign c = a3 ^ {a3[0],a3[31:1]}; // lrot 31
assign d = b3 ^ {b3[0],b3[31:1]}; // lrot 31

assign a4 = a3 ^ {d[5:0],d[31:6]}; // lrot 26
assign b4 = b3 ^ {c[6:0],c[31:7]}; // lrot 25

assign a = a4 ^ {c[16:0],c[31:17]}; // lrot 15
assign b = b4 ^ {d[16:0],d[31:17]}; // lrot 15

endmodule

