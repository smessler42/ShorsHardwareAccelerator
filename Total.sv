module top (
    input logic signed [1:0] q_in [2][1];
    input logic xflip, zflip;
    input logic [2:0] location;
    output logic [1:0] error;
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

    logic signed [1:0] q1, q2 [2][1];

    


endmodule


    // logic signed [1:0] CNOT [4][4] = '{
    //     '{2'sd1, 2'sd0, 2'sd0, 2'sd0},
    //     '{2'sd0, 2'sd1, 2'sd0, 2'sd0},
    //     '{2'sd0, 2'sd0, 2'sd0, 2'sd1},
    //     '{2'sd0, 2'sd0, 2'sd1, 2'sd0}
    // };

module CNOTentangled (
    input logic signed [1:0] q1, q2 [2][1];
    output logic signed [1:0] q1ent, q2ent [2][1]
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
        endcase
    end

endmodule


module matrixMultiply2x2 (
  input logic signed [1:0] A [2][2],
  input logic signed [1:0] B [2][1],
  output logic signed [1:0] result [2][1],
);
  
//   logic[1:0] r1, r2
//   logic c1, c2;
  
  
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
