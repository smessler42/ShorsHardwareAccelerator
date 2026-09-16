`default_nettype none
// Empty top module

module top (
  // I/O ports
  input  logic hz100, reset,
  input  logic [20:0] pb,
  output logic [7:0] left, right,
         ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
  output logic red, green, blue,

  // UART ports
  output logic [7:0] txdata,
  input  logic [7:0] rxdata,
  output logic txclk, rxclk,
  input  logic txready, rxready
);

  // Your code goes here...
  //Matrix A
  //[a1 a2]
  //[a3 a4]
  logic a1 = pb[7];
  logic a2 = pb[6];
  logic a3 = pb[3];
  logic a4 = pb[2];
  logic[3:0] A = {a1, a2, a3, a4};
  //Matirx B
  //[b1]
  //[b2]
  logic b1 = pb[4];
  logic b2 = pb[0];
  logic[1:0] B = {b1, b2};
  // assign A = {a1, a2, a3, a4};
  // assign B = {
  
  mm1 matrixMultiply (A, B, right[1:0]);
  
  
endmodule

// Add more modules down here...
module matrixMultiply (
  input logic[3:0] A,
  input logic[1:0] B,
  output logic [1:0] result
);
  
  logic r1, r2, c1, c2;
  
  //result = [A[3]*B[1]+A[2]*B[0]]
  //         [A[1]*B[1]+A[0]*B[0]]
  assign result = {r1, r2};
  
  row1 fa(A[3]&B[1], A[2]&B[0], 0, r1, c1);
  row2 fa(A[1]&B[1], A[0]&B[0], 0, r2, c2);
  
endmodule
// 1-bit full adder (part 1)
module fa (
  input logic a,
  input logic b,
  input logic ci,
  output logic s,
  output logic co
);
  
  // a XOR b XOR ci
  assign s = a ^ b ^ ci;
  assign co = (a & b) | (a & ci) | (b & ci);
endmodule
