module top (
    input  logic              clk,
    input  logic              rst_n,
    input  logic signed [1:0] q_in        [2][1],
    input  logic        [1:0] tb_bit_err,           // "error from tb" for bit_error[cite: 1]
    input  logic        [3:0] tb_sign_err,          // "error from tb" for sign_error[cite: 1]
    output logic        [1:0] bit_error_syndrome,   // 2-bit output from bit_flip_detect[cite: 1]
    output logic        [3:0] sign_error_syndrome   // 4-bit output from sign_flip_detect[cite: 1]
);

    localparam logic signed [1:0] ZERO_STATE [2][1] = '{'{2'sd1}, '{2'sd0}};

    // -------------------------------------------------------------
    // Stage 1: Initial Cloning (1 qubit -> 3 qubits)
    // -------------------------------------------------------------
    logic signed [1:0] stage1_q1 [2][1], stage1_q2 [2][1], stage1_q3 [2][1];

    cloning clone_stage1 (
        .in1  (q_in),
        .in2  (ZERO_STATE),
        .in3  (ZERO_STATE),
        .out1 (stage1_q1),
        .out2 (stage1_q2),
        .out3 (stage1_q3)
    );

    // -------------------------------------------------------------
    // Stage 2: Bit Error Injection
    // -------------------------------------------------------------
    logic signed [1:0] bit_err_q1 [2][1], bit_err_q2 [2][1], bit_err_q3 [2][1];

    bit_error u_bit_error (
        .error (tb_bit_err),
        .in1   (stage1_q1),
        .in2   (stage1_q2),
        .in3   (stage1_q3),
        .out1  (bit_err_q1),
        .out2  (bit_err_q2),
        .out3  (bit_err_q3)
    );

    // -------------------------------------------------------------
    // Stage 3: Three Parallel Cloning Blocks (3 -> 9 qubits)
    // -------------------------------------------------------------
    logic signed [1:0] pre_sign_q [1:9] [2][1];

    // Branch 1: Qubits 1, 2, 3[cite: 1]
    cloning clone_branch1 (
        .in1  (bit_err_q1),
        .in2  (ZERO_STATE),
        .in3  (ZERO_STATE),
        .out1 (pre_sign_q[1]),
        .out2 (pre_sign_q[2]),
        .out3 (pre_sign_q[3])
    );

    // Branch 2: Qubits 4, 5, 6
    cloning clone_branch2 (
        .in1  (bit_err_q2),
        .in2  (ZERO_STATE),
        .in3  (ZERO_STATE),
        .out1 (pre_sign_q[4]),
        .out2 (pre_sign_q[5]),
        .out3 (pre_sign_q[6])
    );

    // Branch 3: Qubits 7, 8, 9
    cloning clone_branch3 (
        .in1  (bit_err_q3),
        .in2  (ZERO_STATE),
        .in3  (ZERO_STATE),
        .out1 (pre_sign_q[7]),
        .out2 (pre_sign_q[8]),
        .out3 (pre_sign_q[9])
    );

    // -------------------------------------------------------------
    // Stage 4: Sign Error Injection (9 Qubits)
    // -------------------------------------------------------------
    logic signed [1:0] post_sign_q [1:9] [2][1];

    sign_error u_sign_error (
        .error (tb_sign_err),
        .in1   (pre_sign_q[1]), .in2   (pre_sign_q[2]), .in3   (pre_sign_q[3]),
        .in4   (pre_sign_q[4]), .in5   (pre_sign_q[5]), .in6   (pre_sign_q[6]),
        .in7   (pre_sign_q[7]), .in8   (pre_sign_q[8]), .in9   (pre_sign_q[9]),
        .out1  (post_sign_q[1]), .out2 (post_sign_q[2]), .out3 (post_sign_q[3]),
        .out4  (post_sign_q[4]), .out5 (post_sign_q[5]), .out6 (post_sign_q[6]),
        .out7  (post_sign_q[7]), .out8 (post_sign_q[8]), .out9 (post_sign_q[9])
    );

    // -------------------------------------------------------------
    // Stage 5: Sign Flip Detect (All 9 Qubits -> 4-bit output)
    // -------------------------------------------------------------
    sign_flip_detect u_sign_detect (
        .in1 (post_sign_q[1]), .in2 (post_sign_q[2]), .in3 (post_sign_q[3]),
        .in4 (post_sign_q[4]), .in5 (post_sign_q[5]), .in6 (post_sign_q[6]),
        .in7 (post_sign_q[7]), .in8 (post_sign_q[8]), .in9 (post_sign_q[9]),
        .sign_error_syndrome (sign_error_syndrome)
    );

    // -------------------------------------------------------------
    // Stage 6: Bit Flip Detect (Monitors 1st Triplet -> 2-bit output)
    // -------------------------------------------------------------
    bit_flip_detect u_bit_detect (
        .hz100 (clk),
        .rst_n (rst_n),
        .q1    (post_sign_q[1]),
        .q2    (post_sign_q[2]),
        .q3    (post_sign_q[3]),
        .error (bit_error_syndrome)
    );

endmodule

module cnot_entangled (
    input  logic signed [1:0] q1 [2][1],
    input  logic signed [1:0] q2 [2][1],
    output logic signed [1:0] q1ent [2][1],
    output logic signed [1:0] q2ent [2][1]
);

    // Control qubit q1 passes straight through
    assign q1ent = q1;

    always_comb begin
        // If control qubit q1 is in state |1> (row [1][0] has amplitude)
        if (q1[1][0] != 2'sd0) begin
            // Target qubit q2 is bit-flipped (swaps row 0 and row 1)
            q2ent[0][0] = q2[1][0];
            q2ent[1][0] = q2[0][0];
        end else begin
            // Otherwise, target qubit passes through unperturbed
            q2ent = q2;
        end
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

module bit_flip_detect (
    input  logic              hz100,
    input  logic              rst_n,
    input  logic signed [1:0] q1 [2][1],
    input  logic signed [1:0] q2 [2][1],
    input  logic signed [1:0] q3 [2][1],
    output logic        [1:0] error
);

    logic [2:0] counter;
    logic signed [1:0] e1 [2][1], e2 [2][1];
    logic signed [1:0] temp1 [2][1], temp2 [2][1], temp3 [2][1], temp4 [2][1];
    logic signed [1:0] c11 [2][1], c12 [2][1], c21 [2][1], c22 [2][1];

    // CNOT parity connections:
    // e1 measures parity between q1 and q2: CNOT(q1, e1) then CNOT(q2, e1)
    cnot_entangled C11 (.q1(q1), .q2(e1),  .q1ent(temp1), .q2ent(c11));
    cnot_entangled C12 (.q1(q2), .q2(e1),  .q1ent(temp2), .q2ent(c12));

    // e2 measures parity between q2 and q3: CNOT(q2, e2) then CNOT(q3, e2)
    cnot_entangled C21 (.q1(q2), .q2(e2),  .q1ent(temp3), .q2ent(c21));
    cnot_entangled C22 (.q1(q3), .q2(e2),  .q1ent(temp4), .q2ent(c22));  

    always_ff @(posedge hz100 or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 3'd0;
            // Ancillas initialized to |0> = [1, 0]^T
            e1      <= '{'{2'sd1}, '{2'sd0}};
            e2      <= '{'{2'sd1}, '{2'sd0}};
            error   <= 2'b00;
        end else begin
            counter <= counter + 3'd1;
            case (counter)
                // Step 0: First parity CNOT (q1 -> e1, q2 -> e2)
                3'd0: begin
                    e1 <= c11; 
                    e2 <= c21;
                end
                // Step 1: Second parity CNOT (q2 -> e1, q3 -> e2)
                3'd1: begin 
                    e1 <= c12; 
                    e2 <= c22;
                end
                // Step 2: Latch syndrome from |1> amplitude of e1 and e2
                // e1[1][0] is parity(q1, q2), e2[1][0] is parity(q2, q3)
                3'd2: begin
                    error <= {e1[1][0][0], e2[1][0][0]};
                end
                default: begin
                    // Hold output steady until next rst_n pulse
                    counter <= 3'd3;
                end
            endcase
        end
    end

endmodule


module sign_flip_detect (
    input  logic signed [1:0] in1 [2][1], in2 [2][1], in3 [2][1],
    input  logic signed [1:0] in4 [2][1], in5 [2][1], in6 [2][1],
    input  logic signed [1:0] in7 [2][1], in8 [2][1], in9 [2][1],
    output logic        [3:0] sign_error_syndrome
);

    // Check sign inversion of |1> component on each qubit (negative amplitude indicator)
    logic [8:0] z_flipped;

    assign z_flipped[0] = in1[1][0] < 0;
    assign z_flipped[1] = in2[1][0] < 0;
    assign z_flipped[2] = in3[1][0] < 0;
    assign z_flipped[3] = in4[1][0] < 0;
    assign z_flipped[4] = in5[1][0] < 0;
    assign z_flipped[5] = in6[1][0] < 0;
    assign z_flipped[6] = in7[1][0] < 0;
    assign z_flipped[7] = in8[1][0] < 0;
    assign z_flipped[8] = in9[1][0] < 0;

    always_comb begin
        // Priority decode which physical qubit experienced the phase flip (1-9)
        casez (z_flipped)
            9'b???????1: sign_error_syndrome = 4'd1;
            9'b??????10: sign_error_syndrome = 4'd2;
            9'b?????100: sign_error_syndrome = 4'd3;
            9'b????1000: sign_error_syndrome = 4'd4;
            9'b???10000: sign_error_syndrome = 4'd5;
            9'b??100000: sign_error_syndrome = 4'd6;
            9'b?1000000: sign_error_syndrome = 4'd7;
            9'b10000000: sign_error_syndrome = 4'd8;
            default: begin
                if (z_flipped[8])
                    sign_error_syndrome = 4'd9;
                else
                    sign_error_syndrome = 4'd0; // No sign error
            end
        endcase
    end

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