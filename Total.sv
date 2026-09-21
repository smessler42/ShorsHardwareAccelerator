module top (
    input logic signed [1:0] q_in [2][1],
    input logic xflip, zflip,
    input logic [2:0] location,
    output logic [1:0] error,
);

    logic signed [1:0] CNOT [4][4] = '{
        '{2'sd1, 2'sd0, 2'sd0, 2'sd0},
        '{2'sd0, 2'sd1, 2'sd0, 2'sd0},
        '{2'sd0, 2'sd0, 2'sd0, 2'sd1},
        '{2'sd0, 2'sd0, 2'sd1, 2'sd0}
    };

    logic signed [1:0] HGATE [2][2] = '{
        '{ 2'sd1,  2'sd1},
        '{ 2'sd1, -2'sd1}
    };

    logic signed [1:0] XGATE [2][2] = '{
        '{2'sd0, 2'sd1},
        '{2'sd1, 2'sd0}
    };
    logic signed [1:0] ZGATE [2][2] = '{
        '{2'sd1,  2'sd0},
        '{2'sd0, -2'sd1}
    };    

    logic signed [1:0] q1 [2][1]; 
    logic signed [1:0] q2 [2][1]; 

    assign error = 2'b00;


endmodule


    // logic signed [1:0] CNOT [4][4] = '{
    //     '{2'sd1, 2'sd0, 2'sd0, 2'sd0},
    //     '{2'sd0, 2'sd1, 2'sd0, 2'sd0},
    //     '{2'sd0, 2'sd0, 2'sd0, 2'sd1},
    //     '{2'sd0, 2'sd0, 2'sd1, 2'sd0}
    // };

module cnot_entangled (
    input  logic signed [1:0] q1 [2][1],
    input  logic signed [1:0] q2 [2][1],
    output logic signed [1:0] q1ent [2][1],
    output logic signed [1:0] q2ent [2][1]
);

    logic signed [1:0] qCombined [4][1];
    logic [1:0] values;

    always_comb begin
        if(q1[0][0]&q2[0][0]) begin
                values = 2'd3;
        end else if (!q1[0][0]&!q2[0][0]) begin
                values = 2'd0;
        end else if (q1[0][0]&!q2[0][0]) begin
                values = 2'd2;
        end else if (!q1[0][0]&q2[0][0]) begin
                values = 2'd1;
        end 

        case (values)
            2'd0 : begin
                    q1ent = '{'{2'sd0}, '{2'sd1}};
                    q2ent = '{'{2'sd0}, '{2'sd1}};
                end
            2'd1 : begin
                    q1ent = '{'{2'sd0}, '{2'sd1}};
                    q2ent = '{'{2'sd1}, '{2'sd0}};
                end
            2'd2 : begin
                    q1ent = '{'{2'sd1}, '{2'sd0}};
                    q2ent = '{'{2'sd1}, '{2'sd0}};
                end
            2'd3 : begin
                    q1ent = '{'{2'sd1}, '{2'sd0}};
                    q2ent = '{'{2'sd0}, '{2'sd1}};
                end
            default : begin
                    q1ent = '{'{2'sd0}, '{2'sd0}};
                    q2ent = '{'{2'sd0}, '{2'sd0}};
                end
        endcase
    end

endmodule


module matrixMultiply2x2 (
  input logic signed [1:0] A [2][2],
  input logic signed [1:0] B [2][1],
  output logic signed [1:0] result [2][1]
);
  
  logic c1, c2;
  
  
  assign result[0][0][1] = '0;
  assign result[1][0][1] = result[1][0][0] & A[1][1][1]^B[1][0][1] & !(A[1][0][0] & B[0][0][0]);


  //result = [A[6]*B[2]+A[4]*B[0]]
  //         [A[2]*B[2]+A[0]*B[0]]
  fa row0 (.a(A[0][0][0] & B[0][0][0]), .b(A[0][1][0] & B[1][0][0]), .ci('0), .s(result[0][0][0]), .co(c1));
  fa row1 (.a(A[1][0][0] & B[0][0][0]), .b(A[1][1][0] & B[1][0][0]), .ci('0), .s(result[1][0][0]), .co(c2));

  
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

module bit_flip_detect(
    // ERROR FIXED: Added hz100, rst_n, and q3 to module ports, changed semicolons to commas
    input  logic              hz100,
    input  logic              rst_n,
    input  logic signed [1:0] q1 [2][1],
    input  logic signed [1:0] q2 [2][1],
    input  logic signed [1:0] q3 [2][1],
    output logic        [1:0] error
);

    // ERROR FIXED: Declared HGATE constant locally so it is visible in this module
    localparam logic signed [1:0] HGATE [2][2] = '{
        '{ 2'sd1,  2'sd1},
        '{ 2'sd1, -2'sd1}
    };

    // ERROR FIXED: Declared counter
    logic [2:0] counter;
    logic signed [1:0] e1 [2][1], e2 [2][1];
    // ERROR FIXED: Declared individual temp wires to prevent multiple-driver contention on temp
    logic signed [1:0] temp1 [2][1], temp2 [2][1], temp3 [2][1], temp4 [2][1];
    logic signed [1:0] h1 [2][1], h2 [2][1];
    logic signed [1:0] c11 [2][1], c12 [2][1], c21 [2][1], c22 [2][1];

    always_ff @(posedge hz100 or negedge rst_n) begin
        if (!rst_n) begin
            counter <= '0;
            e1      <= '{'{2'sd0}, '{2'sd1}};
            e2      <= '{'{2'sd0}, '{2'sd1}};
            error   <= 2'b00;
        end else begin
            counter <= counter + 3'd1;
            case(counter)
                3'd0: begin
                    e1 <= h1; 
                    e2 <= h2;
                end
                3'd1: begin
                    e1 <= c11; 
                    e2 <= c21;
                end
                3'd3: begin 
                    e1 <= c12; 
                    e2 <= c22;
                end
                3'd4: begin
                    e1 <= h1; 
                    e2 <= h2;
                end
                3'd5: begin
                    // ERROR FIXED: Corrected out-of-bounds index e1[0][1][0] to e1[1][0][0]
                    error <= {e1[0][0][0], e1[1][0][0]};
                end
                default: counter <= 0;
            endcase
        end
    end

    matrixMultiply2x2 H1 (.A(HGATE), .B(e1), .result(h1));
    matrixMultiply2x2 H2 (.A(HGATE), .B(e2), .result(h2));
    // ERROR FIXED: Connected separate temp nets to prevent multiple driver conflict
    cnot_entangled C11(.q1(q1), .q2(e1), .q1ent(temp1), .q2ent(c11));
    cnot_entangled C12(.q1(q2), .q2(e1), .q1ent(temp2), .q2ent(c12));
    cnot_entangled C21(.q1(q3), .q2(e2), .q1ent(temp3), .q2ent(c21));
    cnot_entangled C22(.q1(q2), .q2(e2), .q1ent(temp4), .q2ent(c22));  

endmodule

module bit_error (
  input logic [1:0] error,
  input logic signed [1:0] in1 [2][1], in2 [2][1], in3 [2][1],
  output logic signed [1:0] out1 [2][1], out2 [2][1], out3 [2][1]
);

function automatic void apply_x_flip (
    input  logic signed [1:0] q_in  [2][1],
    output logic signed [1:0] q_out [2][1]
  );
    q_out[0][0] = q_in[1][0];
    q_out[1][0] = q_in[0][0];
  endfunction
  
always_comb begin
    out1 = in1;
    out2 = in2;
    out3 = in3;

    case (error)
      2'b01: begin
        apply_x_flip(in1, out1);
      end
      2'b10: begin
        apply_x_flip(in2, out2);
      end
      2'b11: begin
        apply_x_flip(in3, out3);
      end
      default: begin
        out1 = in1;
        out2 = in2;
        out3 = in3;
      end
    endcase
  end
  
  
endmodule

module sign_error (
  input logic [3:0] error,
  input logic signed [1:0] in1 [2][1], in2 [2][1], in3 [2][1], in4 [2][1], in5 [2][1], in6 [2][1], in7 [2][1], in8 [2][1], in9 [2][1], 
  output logic signed [1:0] out1 [2][1], out2 [2][1], out3 [2][1], out4 [2][1], out5 [2][1], out6 [2][1], out7 [2][1], out8 [2][1], out9 [2][1]
);

function automatic void apply_z_flip (
    input  logic signed [1:0] q_in  [2][1],
    output logic signed [1:0] q_out [2][1]
  );
    q_out[0][0] =  q_in[0][0]; 
    q_out[1][0] = -q_in[1][0]; 
  endfunction
  
  always_comb begin
    out1 = in1;
    out2 = in2;
    out3 = in3;
    out4 = in4;
    out5 = in5;
    out6 = in6;
    out7 = in7;
    out8 = in8;
    out9 = in9;

    case (error)
      4'd1: apply_z_flip(in1, out1);
      4'd2: apply_z_flip(in2, out2);
      4'd3: apply_z_flip(in3, out3);
      4'd4: apply_z_flip(in4, out4);
      4'd5: apply_z_flip(in5, out5);
      4'd6: apply_z_flip(in6, out6);
      4'd7: apply_z_flip(in7, out7);
      4'd8: apply_z_flip(in8, out8);
      4'd9: apply_z_flip(in9, out9);
      default: ;
    endcase
  end

endmodule


module cloning (
  input  logic signed [1:0] in1 [2][1], in2 [2][1], in3 [2][1],
  output logic signed [1:0] out1 [2][1], out2 [2][1], out3 [2][1]
);

  localparam logic signed [1:0] HGATE [2][2] = '{
      '{ 2'sd1,  2'sd1},
      '{ 2'sd1, -2'sd1}
  };

  logic signed [1:0] int1 [2][1], int2 [2][1], int3 [2][1];
  logic signed [1:0] d1 [2][1], d2 [2][1];
  
  cnot_entangled first  (.q1(in1), .q2(in2), .q1ent(int1), .q2ent(d1));
  cnot_entangled second (.q1(in2), .q2(in3), .q1ent(int2), .q2ent(d2));

  assign int3 = in3;

  matrixMultiply2x2 H1 (.A(HGATE), .B(in1),  .result(out1));
  matrixMultiply2x2 H2 (.A(HGATE), .B(int2), .result(out2));
  matrixMultiply2x2 H3 (.A(HGATE), .B(int3), .result(out3));

endmodule