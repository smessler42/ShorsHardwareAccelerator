module top (
    input logic signed [1:0] input [2][1];
    input logic xflip, zflip;
    input logic [2:0] location;
    output logic error1, error2;
);

    logic signed [1:0] CNOT [4][4] = '{
    '{1, 0, 0, 0},
    '{0, 1, 0, 0},
    '{0, 0, 0, 1},
    '{0, 0, 1, 0}
    };

    logic signed [1:0] HGATE [2][2] = '{
    '{1, 1},
    '{1, -1}
    };

    logic signed [1:0] XGATE [2][2] = '{
    '{0, 1},
    '{1, 0}
    };
    logic signed [1:0] ZGATE [2][2] = '{
    '{1, 0},
    '{0, -1}
    };    

    logic signed [1:0] q1, q2 [2][1];


endmodule

module CNOTentangled (
    input logic signed [1:0] q1, q2 [2][1];
);

    logic signed [1:0] qCombined [4][1];
    logic [1:0] values;

    

    always_comb begin
        if(q1 == '{0, 1} & )
        case():
            
    end
endmodule