`default_nettype none
// Empty top module

module top ();

  // Your code goes here...
  logic en1, en2, en3, out1, out2;
  logic[1:0] error;
  logic[2:0] counter;
  logic[3:0] q1, q2, h1, h2, x1, x2, z1, z2;
  logic[7:0] X, Z, H;

  assign X = 4'00 01 01 00;
  assign Z = 4'01 00 00 11;
  assign H = 4'01 01 01 11;

  assign error = {out1, out2};



  always_ff @posedge(hz100 or error) begin
    if(error) begin
      counter <= '0;
      q1 <= 4'01 00;
      q2 <= 4'01 00;
    end else begin
      case(counter)
        3'd0: q1 <= h1; q2 <=h2;
        3'd1: begin
                if(en1) q1 <= z1; 
                if(en3) q2 <= z2;
              end
        3'd3: if(en2) q1 <= z1; q2 <= z2;
        3'd4: q1 <= h1; q2 <=h2;
        3'd5: out1 <= q1[0]; out2 <= q2[0];
        default: counter <= 0;
      endcase
    end

  end

  always_comb begin
    H1 matrixMultiply (H, q1, h1);
    H2 matrixMultiply (H, q2, h2);
    Z1 matrixMultiply (H, q1, z1);
    Z2 matrixMultiply (H, q2, z2);
    X1 matrixMultiply (H, q1, x1);
    X2 matrixMultiply (H, q2, x2);
  end
  
  
  
endmodule

// Add more modules down here...
module matrixMultiply (
  input logic[7:0] A,
  input logic[3:0] B,
  output logic [3:0] result
);
  
  logic[1:0] r1, r2
  logic c1, c2;
  
  
  assign r1[1] = r1[0] & A[5]^B[1] & !A[6]&B[2];
  assign r2[1] = r2[0] & A[1]^B[1] & !A[2]&B[2];
  assign result = {r1, r2};

  //result = [A[6]*B[2]+A[4]*B[0]]
  //         [A[2]*B[2]+A[0]*B[0]]
  row1 fa(A[6]&B[2], A[4]&B[0], 0, r1[0], c1);
  row2 fa(A[2]&B[2], A[0]&B[0], 0, r2[0], c2);
  
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
