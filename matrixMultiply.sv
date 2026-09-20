`default_nettype none
// Empty top module

module top (
  input logic hz100,
  input logic reset_n,
  input logic en1, en2, en3,
  output logic [1:0] error,
  output logic out1, out2
);

  // Your code goes here...
  logic[2:0] counter;
  logic[3:0] q1, q2, h1, h2, x1, x2, z1, z2;
  logic[7:0] X, Z, H;

  assign X = 8'00 01 01 00;
  assign Z = 4'01 00 00 11;
  assign H = 4'01 01 01 11;

  assign error = {out1, out2};



  always_ff @posedge(hz100 or error) begin
    if(error) begin
      counter <= '0;
      q1 <= 4'b0100;
      q2 <= 4'b0100;
    end else begin
      counter <= counter + 3'd1
      case(counter)
        3'd0: begin
          q1 <= h1; 
          q2 <=h2;
        end
        3'd1: begin
                if(en1) q1 <= z1; 
                if(en3) q2 <= z2;
              end
        3'd3: begin 
          if(en2) q1 <= z1; 
          q2 <= z2;
        end
        3'd4: begin
          q1 <= h1; 
          q2 <=h2;
        end
        3'd5: begin
          out1 <= q1[0]; 
          out2 <= q2[0];
        end
        default: counter <= 0;
      endcase
    end

  end

  matrixMultiply H1 (.A(H), .B(q1), .result(h1));
  matrixMultiply H2 (.A(H), .B(q2), .result(h2));
  matrixMultiply Z1 (.A(Z), .B(q1), .result(z1));
  matrixMultiply Z2 (.A(Z), .B(q2), .result(z2));
  matrixMultiply X1 (.A(X), .B(q1), .result(x1));
  matrixMultiply X2 (.A(X), .B(q2), .result(x2));
  
  
  
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
  row1 fa(.a(A[6]&B[2]), .b(A[4]&B[0]), .ci('0), .s(r1[0]), .co(c1));
  row1 fa(.a(A[2]&B[2]), .b(A[0]&B[0]), .ci('0), .s(r2[0]), .co(c2));

  
endmodule
// 1-bit full adder 
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
