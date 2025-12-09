module carry_adder(A, B, S, overflow, Cin, Cout);
    input [31:0] A, B;
    input Cin;
    output [31:0] S;
    output Cout, overflow;
    
    wire [32:0] carry;
    
    assign carry[0] = Cin;
    
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : adder_bits
            assign S[i] = A[i] ^ B[i] ^ carry[i];
            assign carry[i+1] = (A[i] & B[i]) | (carry[i] & (A[i] ^ B[i]));
        end
    endgenerate
    
    assign Cout = carry[32];
    
    assign overflow = (A[31] == B[31]) & (A[31] != S[31]);
endmodule